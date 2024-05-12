import 'dart:convert';

//import 'package:crypto/crypto.dart';
import 'package:html/parser.dart';
import 'package:html/dom.dart' as dom;
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter/material.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:prescore_flutter/main.dart';
import 'package:prescore_flutter/util/rsa.dart';
import 'package:prescore_flutter/util/struct.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:synchronized/synchronized.dart';
import 'package:path/path.dart' as path;
import '../constants.dart';

const String userSession = "userSession";
final Lock databaseLock = Lock();

Future<Database> initLocalSessionDataBase() async {
  return await openDatabase(
    path.join(await getDatabasesPath(), 'UserSession.db'),
    onCreate: (db, version) async {
      var tableExists = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='$userSession'");
      if (tableExists.isEmpty) {
        logger.d("tableNotExists, CREATE TABLE $userSession");
        db.execute(
          'CREATE TABLE $userSession (userName TEXT PRIMARY KEY, password TEXT, userId TEXT, st TEXT, sessionId TEXT, xToken TEXT, serverToken TEXT, basicInfo_id TEXT, basicInfo_loginName TEXT, basicInfo_name TEXT, basicInfo_role TEXT, basicInfo_avatar TEXT)',
        );
      }
    },
    version: 1,
  );
}

class User {
  Session? session;
  LoginCredential loginCredential = LoginCredential("", "");
  BasicInfo? basicInfo;
  StudentInfo? studentInfo;
  bool isLoading = false;
  bool isBasicInfoLoaded = false;
  bool isStudentInfoLoaded = false;
  bool keepLocalSession = false;
  Dio dio = Dio();
  Function reLoginFailedCallback = () {};

  User({this.session});

  bool isLoggedIn() {
    if (session == null) {
      return false;
    }
    return true;
  }

  Future<void> readLocalSession() async {
    SharedPreferences sharedPrefs = BaseSingleton.singleton.sharedPreferences;
    return await databaseLock.synchronized(() async {
      Database database = await initLocalSessionDataBase();
      List<Map<String, Object?>> list =
          await database.rawQuery('SELECT * FROM $userSession');
      if (list.length == 1) {
        sharedPrefs.setBool("localSessionExist", true);
        Session localSession = Session(
          list[0]['st'] as String,
          list[0]['sessionId'] as String,
          list[0]['xToken'] as String,
          list[0]['userId'] as String,
          serverToken: list[0]['serverToken'] as String?,
        );
        if (list[0]['basicInfo_id'] != null) {
          basicInfo = BasicInfo(
              list[0]['basicInfo_id'] as String,
              list[0]['basicInfo_loginName'] as String,
              list[0]['basicInfo_name'] as String,
              list[0]['basicInfo_role'] as String,
              list[0]['basicInfo_avatar'] as String);
          isBasicInfoLoaded = true;
        }
        session = localSession;
        Dio client = BaseSingleton.singleton.dio;
        client.options.headers["XToken"] = localSession.xToken;
        loginCredential.userName = list[0]['userName'] as String;
        loginCredential.password = list[0]['password'] as String;
        await database.close();
        return;
      } else {
        await database.close();
        throw Exception("Too many Local Session");
      }
    });
  }

  Future<void> saveLocalSession() async {
    SharedPreferences sharedPrefs = BaseSingleton.singleton.sharedPreferences;
    return await databaseLock.synchronized(() async {
      Database database = await initLocalSessionDataBase();
      await database.rawDelete('DELETE FROM $userSession');
      await database.insert(
        userSession,
        {
          "userName": loginCredential.userName,
          "password": loginCredential.password,
          "serverToken": session?.serverToken,
          "sessionId": session?.sessionId,
          "st": session?.st,
          "userId": session?.userId,
          "xToken": session?.xToken,
          "basicInfo_id": basicInfo?.id,
          "basicInfo_loginName": basicInfo?.loginName,
          "basicInfo_name": basicInfo?.name,
          "basicInfo_role": basicInfo?.role,
          "basicInfo_avatar": basicInfo?.avatar
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await database.close();
      sharedPrefs.setBool("localSessionExist", true);
    });
  }

  Future<void> updateLoginStatus({bool force = false}) async {
    Dio client = BaseSingleton.singleton.dio;
    Response response = await client.get(zhixueLoginStatusUrl);
    Map<String, dynamic> json = jsonDecode(response.data);
    logger.d("updateLoginStatus $response");
    if (json["result"] != "success" || force) {
      Result result = await login(
          loginCredential.userName ?? "", loginCredential.password ?? "",
          useLocalSession: false,
          keepLocalSession: keepLocalSession,
          force: true);
      //if(!result.state && (result.message.contains("用户不存在") || result.message.contains("凭证有误"))) {
      if (!result.state) {
        await logoff();
        reLoginFailedCallback();
      }
    }
  }

  /// Remove **all** cookies and session data to logoff
  Future<bool> logoff() async {
    SharedPreferences sharedPrefs = BaseSingleton.singleton.sharedPreferences;
    session = null;
    loginCredential.password = "";
    loginCredential.userName = "";
    basicInfo = null;
    studentInfo = null;
    isLoading = false;
    isBasicInfoLoaded = false;
    keepLocalSession = false;
    BaseSingleton.singleton.dio.options.headers["XToken"] = null;

    // Remove all cookies from related sites.
    CookieJar cookieJar = BaseSingleton.singleton.cookieJar;
    cookieJar.delete(Uri.parse("https://www.zhixue.com/"));
    cookieJar.delete(Uri.parse("https://open.changyan.com/"));

    return await databaseLock.synchronized(() async {
      Database database = await initLocalSessionDataBase();
      await database.rawDelete('DELETE FROM $userSession');
      await database.close();
      sharedPrefs.setBool("localSessionExist", false);
      return true;
    });
  }

  /// Use RSA to encrypt [password].
  String getEncryptedPassword(String password) {
    // Encrypt password in order to login.
    // Use no padding.
    final Encrypter encrypter = Encrypter(RSAExt(
      publicKey: RSAPublicKey(
          BigInt.parse("0x008c147f73c2593cba0bd007e60a89ade5"),
          BigInt.parse("0x010001")),
      privateKey: null,
    ));

    String encrypted =
        encrypter.encrypt(password.split("").reversed.join()).base16;
    return encrypted;
  }

  /// Generate login params.
  ///
  /// [lt] and [execution] are received from [zhixueLoginUrl].
  ///
  /// [username] and [password] are from user input and is required.
  ///
  /// [password] must be encrypted using [getEncryptedPassword].
  String getParsedParams(
      String lt, String execution, String username, String password) {
    // Static params
    Map<String, String> params = {
      "encode": "true",
      "sourceappname": "tkyh,tkyh",
      "_eventId": "submit",
      "appid": "zx-container-client",
      "client": "web",
      "type": "loginByNormal",
      "key": "auto",
      "customLogoutUrl": "https://www.zhixue.com/login.html",
    };
    // Dynamic params
    params.addEntries({
      "lt": lt,
      "execution": execution,
      "username": username,
      "password": getEncryptedPassword(password),
    }.entries);

    // Parse params
    String parsedParams = "";
    params.forEach((key, value) {
      parsedParams += "$key=$value&";
    });

    // Remove the last '&' character.
    return parsedParams.substring(0, parsedParams.length - 1);
  }

  /// Fetch session id from [st].
  ///
  /// [st] is received from [zhixueLoginUrl].
  Future<Session?> getSessionFromSt(String st) async {
    CookieJar cookieJar = BaseSingleton.singleton.cookieJar;
    Dio client = BaseSingleton.singleton.dio;

    // Get session from st.
    logger.d("st: $st");

    Response loginResponse = await client.post(
      zhixueLoginUrl,
      data: {
        "action": "login",
        "ticket": st,
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    logger.d("loginResponse: ${loginResponse.data}");
    logger.d("loginResponse: ${loginResponse.headers}");

    // Get session id from cookies.
    List<Cookie> cookies =
        await cookieJar.loadForRequest(Uri.parse(zhixueBaseUrl));
    String xToken = await getXToken();
    logger.d("cookies: $cookies");
    for (var element in cookies) {
      if (element.name == "tlsysSessionId") {
        Session currSession = Session(st, element.value, xToken, "");
        session = currSession;
        logger.d(currSession.toString());
        client.options.headers["XToken"] = currSession.xToken;
        return currSession;
      }
    }
    return null;
  }

  /// Get xToken from cookies.
  ///
  /// xToken is required to access some APIs.
  ///
  /// xToken is received from [zhixueXTokenUrl].
  Future<String> getXToken() async {
    Dio client = BaseSingleton.singleton.dio;
    Response tokenResponse = await client.get(zhixueXTokenUrl);
    logger.d("tokenResponse: ${tokenResponse.data}");
    Map<String, dynamic> json = jsonDecode(tokenResponse.data);
    String xToken = json["result"];
    return xToken;
  }

  /// Login to zhixue.com.
  ///
  /// [username] and [password] are from user input and is required.
  Future<Result> login(String username, String password,
      {bool ignoreLoading = true,
      bool force = true,
      Function? callback,
      Future? asyncCallback,
      BuildContext? context,
      bool useLocalSession = false,
      bool keepLocalSession = false}) async {
    // Check if is logging in now.
    // If there is a login request pending, ignore current request.
    if (isLoading & !ignoreLoading) {
      return Result(state: false, message: "正在登录中，请稍后再试");
    }

    // Check if is forced to login.
    // Forcing to login means to ignore previous session and login again.
    if (!force) {
      // Check if there is a previous session.
      if (isLoggedIn()) {
        if (callback != null) {
          callback();
        }
        if (asyncCallback != null) {
          await asyncCallback;
        }
        return Result(state: true, message: "已登录");
      }
    }
    Dio client = BaseSingleton.singleton.dio;
    // Start login and set this flag to true to avoid multiple login requests.
    isLoading = true;
    if (useLocalSession) {
      try {
        this.keepLocalSession = keepLocalSession;
        await readLocalSession();
        /*String xToken = await getXToken();
        client.options.headers["XToken"] = xToken;
        session?.xToken = xToken;
        await saveLocalSession();*/
        try {
          await fetchBasicInfo();
        } catch (e) {
          logger.e("login: fetchBasicInfo error: $e");
        }
        isLoading = false;
        //LocalLogger.write("本地Session登录成功", isError: false);
        return Result(state: true, message: "本地Session登录成功");
      } catch (_) {}
    }
    if (username == "") {
      return Result(state: false, message: "用户名为空");
    }
    // Check if there is a previous session from cookies.
    Response preload = await client.get(changyanSSOUrl);
    String preloadBody = preload.data;
    preloadBody = preloadBody.trim();
    logger.d("loginPreloadBody: $preloadBody");
    preloadBody = preloadBody.replaceAll('\\', '').replaceAll('\'', '');
    preloadBody = preloadBody.replaceAll('(', '').replaceAll(')', '');

    Map<String, dynamic> preloadParsed = jsonDecode(preloadBody);

    // Return code 1000 means not logged in.
    // Return code 1001 means already logged in.
    // Other return code means failed to login.
    if (preloadParsed['code'] != 1000) {
      if (preloadParsed['code'] == 1001) {
        session = await getSessionFromSt(preloadParsed['data']['st']);
        // If session is null, this request is invalid. So return false.
        if (session == null) {
          isLoading = false;
          return Result(state: false, message: "已登录, 但Session缺失");
        }
        if (callback != null) {
          callback();
        }
        loginCredential.userName = username;
        loginCredential.password = password;
        if (keepLocalSession) {
          await saveLocalSession();
        }
        isLoading = false;
        this.keepLocalSession = keepLocalSession;
        return Result(state: true, message: "已登录");
      } else {
        isLoading = false;
        return Result(state: false, message: preloadParsed['data']);
      }
    }
    // Use lt and execution from previous request to do actual login.
    String lt = preloadParsed['data']['lt'];
    String execution = preloadParsed['data']['execution'];

    logger.d(
        "loginUri: $changyanSSOUrl&${getParsedParams(lt, execution, username, password)}");
    Response response = await client.get(
        "$changyanSSOUrl&${getParsedParams(lt, execution, username, password)}");
    String body = response.data;
    body = body.trim();
    logger.d("loginBody: $body");
    body = body.replaceAll('\\', '').replaceAll('\'', '');
    body = body.replaceAll('(', '').replaceAll(')', '');

    // Fetch user basic info.
    try {
      await fetchBasicInfo();
    } catch (e) {
      logger.e("login: fetchBasicInfo error: $e");
    }
    // Parse response.
    // Return code 1000 means not logged in.
    // Return code 1001 means already logged in.
    // Other return code means failed to login.
    // In this case, any code other than 1001 is considered as failed.
    Map<String, dynamic> parsed = jsonDecode(body);
    if (parsed['code'] != 1001) {
      isLoading = false;
      return Result(state: false, message: parsed['data']);
    }
    session = await getSessionFromSt(parsed['data']['st']);
    if (session == null) {
      isLoading = false;
      return Result(state: false, message: "登录失败, Session缺失");
    }
    loginCredential.userName = username;
    loginCredential.password = password;
    this.keepLocalSession = keepLocalSession;
    if (keepLocalSession) {
      await saveLocalSession();
    }
    // Login to private server.
    try {
      await telemetryLogin();
    } catch (e) {
      logger.e("login: telemetryLogin error: $e");
    }

    if (callback != null) {
      callback();
    }
    isLoading = false;
    //LocalLogger.write("登录成功", isError: false);
    return Result(state: true, message: "登录成功");
  }

  /// Login to private server to record exam data.
  Future<Result<String>> telemetryLogin() async {
    // Check if user is agree to our privacy policy.
    SharedPreferences shared = await SharedPreferences.getInstance();
    bool? allowed = shared.getBool("allowTelemetry");
    if (allowed == null || !allowed) {
      return Result(state: false, message: "不允许数据上传");
    }

    Dio client = BaseSingleton.singleton.dio;

    BasicInfo? bi = await fetchBasicInfo();
    Response response = await client.post(telemetryLoginUrl,
        data: {
          'username': bi?.id,
          'password': session?.sessionId,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ));
    logger.d('serverLogin response: ${response.data}');
    Map<String, dynamic> parsed = jsonDecode(response.data);
    session?.serverToken = parsed['access_token'];
    if (keepLocalSession) {
      await saveLocalSession();
    }
    return Result(state: true, message: "成功哒！", result: parsed['access_token']);
  }

  /// Get basic info from [zhixueBasicInfoUrl].
  Future<BasicInfo?> fetchBasicInfo(
      {bool force = false, Function? callback}) async {
    Dio client = BaseSingleton.singleton.dio;
    logger.d("fetchBasicInfo, callback: $callback");

    // Check if basic info is loaded.
    // Forcing this means to ignore previous fetched info and fetch again.
    if (isBasicInfoLoaded && !force) {
      if (callback != null) {
        callback(this.basicInfo);
      }
      logger.d("basicInfo: loaded, ${this.basicInfo}");
      return this.basicInfo;
    }

    // Fetch basic info.
    Response response = await client.get(zhixueInfoUrl);
    logger.d("basicInfo: ${response.data}");
    Map<String, dynamic> json = jsonDecode(response.data);
    logger.d("basicInfo: $json");
    if (json["errorCode"] != 200) {
      logger.d("basicInfo: failed");
      return null;
    }
    String avatar = json["result"]["avatar"] ?? "";
    // Parse basic info.
    BasicInfo basicInfo = BasicInfo(
      json["result"]["id"],
      json["result"]["loginName"],
      json["result"]["name"],
      json["result"]["role"],
      avatar,
    );
    this.basicInfo = basicInfo;
    logger.d("basicInfo: $basicInfo");

    // Set this flag so that we don't fetch again.
    isBasicInfoLoaded = true;
    if (callback != null) {
      logger.d("callback");
      callback(basicInfo);
    }
    if (keepLocalSession) {
      await saveLocalSession();
    }
    logger.d("basicInfo: success,  $basicInfo");
    return basicInfo;
  }

  Future<StudentInfo?> fetchStudentInfo(
      {bool force = false, Function? callback}) async {
    Dio client = BaseSingleton.singleton.dio;
    logger.d("fetchStudentInfo, callback: $callback");

    if (isStudentInfoLoaded && !force) {
      if (callback != null) {
        callback(this.studentInfo);
      }
      logger.d("fetchStudentInfo: loaded, ${this.studentInfo}");
      return this.studentInfo;
    }

    Response response = await client.get(zhixueStudentAccountUrl);
    logger.d("fetchStudentInfo: ${response.data}");
    Map<String, dynamic> json = jsonDecode(response.data);
    logger.d("fetchStudentInfo: $json");
    String avatar = json["student"]["avatar"] ?? "";

    StudentInfo studentInfo = StudentInfo(
      id: json["student"]["id"],
      loginName: json["student"]["loginName"],
      name: json["student"]["name"],
      role: json["student"]["roles"][0]["eName"],
      avatar: avatar,
      studentNo: json["student"]["studentNo"],
      gradeName: json["student"]["clazz"]["grade"]["name"],
      className: json["student"]["clazz"]["name"],
      classId: json["student"]["clazz"]["id"],
      schoolName: json["student"]["clazz"]["school"]["name"],
      schoolId: json["student"]["clazz"]["school"]["id"],
    );
    this.studentInfo = studentInfo;
    logger.d("fetchStudentInfo: $studentInfo");

    isStudentInfoLoaded = true;
    if (callback != null) {
      logger.d("callback");
      callback(studentInfo);
    }
    logger.d("fetchStudentInfo: success,  $studentInfo");
    return studentInfo;
  }

  Future<List<Classmate>> fetchClassmate() async {
    await fetchStudentInfo();
    Dio client = BaseSingleton.singleton.dio;
    Response response = await client.get(
        "$zhixueClassmatesUrl?r=${studentInfo?.id}student&clazzId=${studentInfo?.classId}");
    logger.d("fetchClassmate: ${response.data}");
    List<dynamic> json = jsonDecode(response.data);
    List<Classmate> classmates = [];
    for (var classmate in json) {
      classmates.add(Classmate(
        name: classmate["name"],
        id: classmate["id"],
        code: classmate["code"],
        gender: classmate["gender"] == 1 ? Gender.female : Gender.male,
        mobile: classmate["mobile"],
      ));
    }
    logger.d("fetchClassmate: $classmates");
    return classmates;
  }

  /// Fetch exam list from [zhixueErrorbookSubjectListUrl]
  Future<Result<List<Subject>>> fetchErrorbookSubjectList() async {
    Dio client = BaseSingleton.singleton.dio;

    // Reject if not logged in.
    if (session == null) {
      return Result(state: false, message: "未登录");
    }

    logger.d("fetchErrorbookSubjectList, xToken: ${session?.xToken}");
    Response response = await client.get(zhixueErrorbookSubjectListUrl);
    Map<String, dynamic> json = jsonDecode(response.data);
    logger.d("errorbookSubjectList: $json");
    if (json["errorCode"] != 0) {
      logger.d("errorbookSubjectList: failed");
      return Result(state: false, message: json["errorInfo"]);
    }
    List<Subject> result = [];
    for (var subject in json["result"]["subjects"]) {
      result.add(Subject(code: subject["code"], name: subject["name"]));
    }
    return Result(state: true, message: "", result: result);
  }

  /// Fetch exam list from [zhixueErrorbookListUrl]
  Future<Result<ErrorBookData>> fetchErrorbookList(
      {required String subjectCode,
      required int pageIndex,
      DateTime? beginTime,
      DateTime? endTime}) async {
    Dio client = BaseSingleton.singleton.dio;

    // Reject if not logged in.
    if (session == null) {
      return Result(state: false, message: "未登录");
    }
    String uri = "$zhixueErrorbookListUrl?subjectCode=$subjectCode";
    if (beginTime != null) {
      uri += "&beginTime=${beginTime.millisecondsSinceEpoch}";
    }
    if (endTime != null) {
      uri += "&endTime=${endTime.millisecondsSinceEpoch}";
    }
    uri += "&pageIndex=$pageIndex&pageSize=5&";

    Response response = await client.get(uri);
    Map<String, dynamic> json = jsonDecode(response.data);
    if (json["errorCode"] != 0) {
      logger.d("errorbookList: failed");
      return Result(state: false, message: json["errorInfo"]);
    }
    List<ErrorQuestion> errorQuestionList = [];
    for (var wrongTopic in json["result"]["wrongTopics"]["list"]) {
      Map<String, dynamic> errorBookTopicDTO = wrongTopic["errorBookTopicDTO"];
      dynamic userAnswer =
          errorBookTopicDTO["wrongTopicRecordArchive"]["userAnswer"];
      try {
        if (userAnswer.runtimeType != String || userAnswer[0] == "[") {
          userAnswer =
              errorBookTopicDTO["wrongTopicRecordArchive"]["imageAnswers"];
        }
      } catch (_) {}
      errorQuestionList.add(ErrorQuestion(
          topicNumber: errorBookTopicDTO["wrongTopicRecordArchive"]
              ["topicNumber"],
          analysisHtml: errorBookTopicDTO["analysisHtml"],
          contentHtml: errorBookTopicDTO["contentHtml"],
          difficultyName: errorBookTopicDTO["wrongTopicRecordArchive"]
              ["difficultyName"],
          knowledgeNames: (errorBookTopicDTO["wrongTopicRecordArchive"]
                  ["knowledgeNames"] as List<dynamic>)
              .map((item) => item as String)
              .toList(),
          topicSourcePaperName: errorBookTopicDTO["wrongTopicRecordArchive"]
              ["topicSourcePaperName"],
          userAnswer: userAnswer,
          standardScore: errorBookTopicDTO["wrongTopicRecordArchive"]
              ["standardScore"],
          userScore: errorBookTopicDTO["wrongTopicRecordArchive"]
              ["userScore"]));
    }
    ErrorBookData result = ErrorBookData(
        subjectCode: subjectCode,
        currentPageIndex: pageIndex,
        totalPage: json["result"]["pageInfo"]["lastPage"],
        totalQuestion: json["result"]["pageInfo"]["totalCount"],
        errorQuestions: errorQuestionList);
    return Result(state: true, message: "", result: result);
  }

  /// Fetch exam list from [zhixueExamListUrl]
  Future<Result<List<Exam>>> fetchExams(int pageIndex,
      {bool homework = false}) async {
    updateLoginStatus();
    Dio client = BaseSingleton.singleton.dio;

    // Reject if not logged in.
    if (session == null) {
      return Result(state: false, message: "未登录");
    }

    // Fetch exams.
    logger.d("fetchExams, xToken: ${session?.xToken}");
    String url = "$zhixueExamListUrl?pageIndex=$pageIndex";
    if (homework) {
      url += "&reportType=homework";
    }
    Response response = await client.get(url);
    Map<String, dynamic> json = jsonDecode(response.data);
    logger.d("exams: $json");
    if (json["errorCode"] != 0 && json["errorInfo"].contains("Token")) {
      await updateLoginStatus(force: true);
      Response response = await client.get(url);
      json = jsonDecode(response.data);
    }
    if (json["errorCode"] != 0) {
      logger.d("exams: failed");
      //LocalLogger.write("fetchExams failed: ${json["errorCode"]} ${json["errorInfo"]}", isError: true);
      return Result(state: false, message: json["errorInfo"]);
    }

    // Parse exams.
    List<Exam> exams = [];
    json["result"]["examList"].forEach((element) {
      DateTime dateTime =
          DateTime.fromMillisecondsSinceEpoch(element["examCreateDateTime"]);
      exams.add(Exam(
          uuid: element["examId"],
          examName: element["examName"],
          examType: element["examType"],
          isFinal: element["isFinal"] as bool,
          examTime: dateTime));
    });
    logger.d("exams: success, $exams");
    return Result(state: true, message: "", result: exams);
  }

  /// Fetch exam report from [zhixueNewExamAnswerSheetUrl].
  Future<Result<List<List<Paper>>>> fetchPreviewPaper(String examId,
      {bool requestScore = true}) async {
    Dio client = BaseSingleton.singleton.dio;

    if (session == null) {
      return Result(state: false, message: "未登录");
    }
    logger.d("fetchPreviewPaper, xToken: ${session?.xToken}");
    Response response =
        await client.get("$zhixueNewExamAnswerSheetUrl?examId=$examId");
    Map<String, dynamic> json = jsonDecode(response.data);
    logger.d("fetchPreviewPaper: $json");

    if (json["result"] != "success") {
      logger.d("fetchPreviewPaper: failed");
      return Result(state: false, message: json["message"] ?? "");
    }

    List<Paper> papers = [];
    List<Future<Paper?>> fetchOperations = [];
    for (var subject in jsonDecode(json["message"])["newAdminExamSubjectDTO"]) {
      Future<Paper?> fetchOperation() async {
        double? userScore;
        double? standardScore;
        try {
          if (requestScore) {
            logger.d(
                "fetchPreviewPaper $zhixueTranscriptUrl?subjectCode=${subject["subjectCode"]}&examId=${subject["examId"]}&paperId=${subject["markingPaperId"]}&token=${session?.xToken}");
            Response response = await client.get(
                "$zhixueTranscriptUrl?subjectCode=${subject["subjectCode"]}&examId=${subject["examId"]}&paperId=${subject["markingPaperId"]}&token=${session?.xToken}");
            dom.Document document = parse(response.data);
            List<dom.Element> elements =
                document.getElementsByTagName('script');
            String transcriptData = "";
            for (var element in elements) {
              transcriptData = "$transcriptData${element.innerHtml}\n";
            }
            RegExp regExp = RegExp(r'var hisQueParseDetail = (.*);');
            if (regExp.hasMatch(transcriptData)) {
              transcriptData = regExp.firstMatch(transcriptData)!.group(1)!;
              logger.d("transcriptData: $transcriptData");
              List<dynamic> transcriptDataDynamic = jsonDecode(transcriptData);
              for (var section in transcriptDataDynamic) {
                List<dynamic> topicAnalysisDTOs = section["topicAnalysisDTOs"];
                for (var data in topicAnalysisDTOs) {
                  userScore ??= 0;
                  standardScore ??= 0;
                  userScore += data["score"] as double;
                  standardScore += data["standardScore"] as double;
                }
              }
            }
          }
        } catch (_) {}
        try {
          return Paper(
              examId: subject["examId"],
              paperId: subject["markingPaperId"],
              name: subject["subjectName"],
              subjectId: subject["subjectCode"],
              userScore: userScore,
              fullScore: standardScore,
              source: Source.preview,
              markingStatus: subject["markingStatus"] == "m4CompleteMarking"
                  ? MarkingStatus.m4CompleteMarking
                  : subject["markingStatus"] == "m3marking"
                      ? MarkingStatus.m3marking
                      : MarkingStatus.unknown);
        } catch (_) {}
        return null;
      }

      fetchOperations.add(fetchOperation());
    }
    await Future.wait(fetchOperations).then((result) {
      for (Paper? paper in result) {
        if (paper != null) {
          papers.add(paper);
        }
      }
    });
    logger.d("fetchPreviewPaper: $papers");
    return Result(state: true, message: "", result: [papers, []]);
  }

  /// Fetch exam report from [zhixueMarkingProgressUrl].
  Future<Result<List<QuestionProgress>>> fetchMarkingProgress(
      String paperId) async {
    Dio client = BaseSingleton.singleton.dio;

    if (session == null) {
      return Result(state: false, message: "未登录");
    }
    Response response =
        await client.get("$zhixueMarkingProgressUrl?markingPaperId=$paperId");
    logger.d("fetchMarkingProgress, data: ${response.data}");
    List<dynamic> dynamicJson = jsonDecode(response.data);
    List<Map<String, dynamic>> json = dynamicJson.map((item) {
      return item as Map<String, dynamic>;
    }).toList();

    List<QuestionProgress> result = [];
    for (var element in json) {
      result.add(QuestionProgress(
          dispTitle: element["dispTitle"] as String,
          allCount: element["allCount"],
          realCompleteCount: element["realCompleteCount"]));
    }
    logger.d("fetchMarkingProgress, $result");
    return Result(state: true, message: "", result: result);
  }

  /// Fetch exam report from [zhixueReportUrl].
  Future<Result<List<List<Paper>>>> fetchPaper(String examId) async {
    Dio client = BaseSingleton.singleton.dio;

    if (session == null) {
      return Result(state: false, message: "未登录");
    }
    logger.d("fetchPaper, xToken: ${session?.xToken}");
    Response response = await client.get("$zhixueReportUrl?examId=$examId");
    logger.d("paper: ${response.data}");
    Map<String, dynamic> json = jsonDecode(response.data);
    logger.d("paper: $json");
    if (json["errorCode"] != 0) {
      logger.d("paper: failed");
      return Result(state: false, message: json["errorInfo"]);
    }

    List<Paper> papers = [];
    List<Paper> absentPapers = [];
    dynamic paperList = json["result"]["paperList"];
    dynamic absentPaperList = [];
    if (json["result"].containsKey("absentPaperList")) {
      absentPaperList = json["result"]["absentPaperList"];
    }
    logger.d("absentPaperList: $absentPaperList");

    for (int i = 0; i < absentPaperList.length; i++) {
      Map<String, dynamic> element = absentPaperList[i];
      if (element.containsKey("userScore")) {
        if (element.containsKey("hasAssignScore")) {
          if (element["hasAssignScore"]) {
            absentPapers.add(Paper(
                examId: examId,
                paperId: element["paperId"],
                name: element["subjectName"],
                subjectId: element["subjectCode"],
                userScore: element["preAssignScore"],
                fullScore: element["standardScore"],
                assignScore: element["userScore"],
                source: Source.common));
          } else {
            absentPapers.add(Paper(
                examId: examId,
                paperId: element["paperId"],
                name: element["subjectName"],
                subjectId: element["subjectCode"],
                userScore: element["preAssignScore"],
                fullScore: element["standardScore"],
                source: Source.common));
          }
        } else {
          absentPapers.add(Paper(
              examId: examId,
              paperId: element["paperId"],
              name: element["subjectName"],
              subjectId: element["subjectCode"],
              userScore: element["userScore"],
              fullScore: element["standardScore"],
              source: Source.common));
        }
      } else {
        absentPapers.add(Paper(
            examId: examId,
            paperId: element["paperId"],
            name: element["subjectName"],
            subjectId: element["subjectCode"],
            userScore: 0,
            fullScore: element["standardScore"],
            source: Source.common));
      }
    }

    for (int i = 0; i < paperList.length; i++) {
      Map<String, dynamic> element = paperList[i];
      if (element.containsKey("userScore")) {
        if (element.containsKey("hasAssignScore")) {
          if (element["hasAssignScore"]) {
            papers.add(Paper(
                examId: examId,
                paperId: element["paperId"],
                name: element["subjectName"],
                subjectId: element["subjectCode"],
                userScore: element["preAssignScore"],
                fullScore: element["standardScore"],
                assignScore: element["userScore"],
                source: Source.common));
          } else {
            papers.add(Paper(
                examId: examId,
                paperId: element["paperId"],
                name: element["subjectName"],
                subjectId: element["subjectCode"],
                userScore: element["preAssignScore"],
                fullScore: element["standardScore"],
                source: Source.common));
          }
        } else {
          papers.add(Paper(
              examId: examId,
              paperId: element["paperId"],
              name: element["subjectName"],
              subjectId: element["subjectCode"],
              userScore: element["userScore"],
              fullScore: element["standardScore"],
              source: Source.common));
        }
      } else {
        Response response2 = await client.get(
            "$zhixueChecksheetUrl?examId=$examId&paperId=${element["paperId"]}");
        Map<String, dynamic> json = jsonDecode(response2.data);
        logger.d("paperData: $json");
        if (json["errorCode"] != 0) {
          logger.d("paperData: failed");
          logger.d("paper: ${element["subjectName"]} not finished, $element");
        } else {
          logger.d("paper: ${element["subjectName"]} finished, $element");
          papers.add(Paper(
              examId: examId,
              paperId: element["paperId"],
              name: element["subjectName"],
              subjectId: element["subjectCode"],
              userScore: json["result"]["score"],
              fullScore: json["result"]["standardScore"],
              source: Source.common));
        }
      }
    }
    logger.d("paper: success, $papers");
    return Result(state: true, message: "", result: [papers, absentPapers]);
  }

  Future<Result<ExamDiagnosis>> fetchPaperDiagnosis(String examId) async {
    Dio client = BaseSingleton.singleton.dio;

    if (session == null) {
      return Result(state: false, message: "未登录");
    }
    logger.d("fetchPaperDiagnosis, xToken: ${session?.xToken}");
    Response diagResponse =
        await client.get("$zhixueDiagnosisUrl?examId=$examId");
    logger.d("diag: ${diagResponse.data}");
    Map<String, dynamic> diagJson = jsonDecode(diagResponse.data);
    logger.d("diag: $diagJson");
    if (diagJson["errorCode"] != 0) {
      logger.d("diag: failed");
      return Result(state: false, message: diagJson["errorInfo"]);
    }

    List<PaperDiagnosis> diags = [];
    diagJson["result"]["list"].forEach((element) {
      return diags.add(PaperDiagnosis(
          subjectId: element["subjectCode"],
          subjectName: element["subjectName"],
          diagnosticScore: element["myRank"]));
    });
    diags.sort((a, b) => a.diagnosticScore.compareTo(b.diagnosticScore));
    logger.d("diag: success, $diags");
    String tips = diagJson["result"]["tips"] ?? "";
    String subTips = diagJson["result"]["subTips"] ?? "";
    return Result(
        state: true,
        message: "",
        result: ExamDiagnosis(tips: tips, subTips: subTips, diagnoses: diags));
  }

  Future<Result<List<Question>>> fetchTranscriptData(String subjectId,
      String examId, String paperId, List<Question> questions) async {
    Dio client = BaseSingleton.singleton.dio;

    if (session == null) {
      return Result(state: false, message: "未登录");
    }
    logger.d(
        "fetchTranscriptData, url: $zhixueTranscriptUrl?subjectCode=$subjectId&examId=$examId&paperId=$paperId&token=${session?.xToken}");
    Response response = await client.get(
        "$zhixueTranscriptUrl?subjectCode=$subjectId&examId=$examId&paperId=$paperId&token=${session?.xToken}");
    // logger.d("transcriptData: ${response.data}");

    dom.Document document = parse(response.data);
    List<dom.Element> elements = document.getElementsByTagName('script');
    String transcriptData = "";
    for (var element in elements) {
      transcriptData = "$transcriptData${element.innerHtml}\n";
    }

    RegExp regExp = RegExp(r'var hisQueParseDetail = (.*);');
    if (regExp.hasMatch(transcriptData)) {
      transcriptData = regExp.firstMatch(transcriptData)!.group(1)!;
      logger.d("transcriptData: $transcriptData");

      List<dynamic> transcriptDataDynamic = jsonDecode(transcriptData);
      for (var section in transcriptDataDynamic) {
        List<dynamic> topicAnalysisDTOs = section["topicAnalysisDTOs"];
        for (var data in topicAnalysisDTOs) {
          try {
            logger.d("fetchTranscriptData, data: $data");
            Question question = questions.firstWhere(
                (element2) => element2.topicNumber == data["topicNumber"]);
            question.classScoreRate = data["classScoreRate"];
            logger.d("fetchTranscriptData, data: $question");
          } catch (e) {
            logger.e("fetchTranscriptData: $e");
            return Result(state: false, message: "解析失败");
          }
        }
      }
      return Result(state: true, message: "", result: questions);
    } else {
      return Result(state: false, message: "解析失败");
    }
  }

  Future<Result<List<PaperClass>>> fetchPaperClassList(String paperId) async {
    await fetchStudentInfo();
    Dio client = BaseSingleton.singleton.dio;
    if (session == null) {
      return Result(state: false, message: "未登录");
    }
    
    Response response =
        await client.get(
          "$zhixuePaperClassList?markingPaperId=$paperId&isViewUser=false&schoolId=${studentInfo?.schoolId}", 
          options: Options(headers: {"Token" : session?.xToken}));
    Map<String, dynamic> result = jsonDecode(response.data);
    bool validData = false;
    for (var element in jsonDecode(result["message"])) {
      if (element["scanCount"] != 0) {
        validData = true;
      }
    }
    if (!validData) {
      response =
        await client.get(
          "$zhixuePaperClassList_2?markingPaperId=$paperId&isViewUser=false&schoolId=${studentInfo?.schoolId}", 
          options: Options(headers: {"Token" : session?.xToken}));
      result = jsonDecode(response.data);
    }
    if (result["result"] == "success") {
      List<PaperClass> paperClassList = [];
      for (var element in jsonDecode(result["message"])) {
        paperClassList.add(PaperClass(
          absentCount: element["absentCount"],
          clazzId: element["clazzId"],
          clazzName: element["clazzName"],
          planNumber: element["planNumber"],
          scanCount: element["scanCount"],
        ));
      }
      return Result(state: true, result: paperClassList, message: "");
    } else {
      return Result(state: false, message: result["message"]);
    }
  }

  Future<Result<PaperData>> fetchPaperData(
      String examId, String paperId) async {
    Dio client = BaseSingleton.singleton.dio;

    if (session == null) {
      return Result(state: false, message: "未登录");
    }
    logger.d("fetchPaperData, xToken: ${session?.xToken}");
    Response response = await client
        .get("$zhixueChecksheetUrl?examId=$examId&paperId=$paperId");
    logger.d("paperData: ${response.data}");
    Map<String, dynamic> json = jsonDecode(response.data);
    logger.d("paperData: $json");
    if (json["errorCode"] != 0) {
      logger.d("paperData: failed");
      return Result(state: false, message: json["errorInfo"]);
    }

    List<dynamic> sheetImagesDynamic =
        jsonDecode(json["result"]["sheetImages"]);
    List<dynamic> cutBlockDetail = jsonDecode(json["result"]["cutBlockDetail"]);
    List<String> sheetImages = [];
    for (var element in sheetImagesDynamic) {
      sheetImages.add(element);
    }
    List<Question> questions = [];
    List<Marker> markers = [];
    Map<int, List<Map>> cutBlocksPosition = {};
    String sheetQuestions = json["result"]["sheetDatas"];
    List<dynamic> sheetQuestionsDynamic =
        jsonDecode(sheetQuestions)["userAnswerRecordDTO"]
            ["answerRecordDetails"];
    for (var subCutBlockDetail in cutBlockDetail) {
      for (var cutBlocks in subCutBlockDetail["cutBlocks"]) {
        if (cutBlocksPosition[cutBlocks["topicStartNum"]] == null) {
          cutBlocksPosition[cutBlocks["topicStartNum"]] = [];
        }
        try {
          cutBlocksPosition[cutBlocks["topicStartNum"]]?.add({
            "position": jsonDecode(cutBlocks["position"]),
            "positionPercent": jsonDecode(cutBlocks["positionPercent"]),
            "dispTopic": cutBlocks["dispTopic"],
            "topicNumStr": cutBlocks["topicNumStr"],
            "topicStartNum": cutBlocks["topicStartNum"],
            "crossSection":
                jsonDecode(cutBlocks["coordinate"] ?? "[]").length > 1,
          });
        } catch (_) {}
      }
    }
    for (var element in sheetQuestionsDynamic) {
      String? selectedAnswer;
      bool isSubjective = true;
      List<dynamic> subTopicMap = [];
      try {
        if (element["subTopics"] != null) {
          Map<String, double> subStandradScore = {};
          for (var subCutBlockDetail in cutBlockDetail) {
            if (subCutBlockDetail["topicNumber"].toString() ==
                element["dispTitle"]) {
              for (var cutBlocks in subCutBlockDetail["cutBlocks"]) {
                subStandradScore[cutBlocks["topicNumStr"]] =
                    cutBlocks["subTopicScore"] as double;
              }
            }
          }
          for (var subTopicElement in element["subTopics"]) {
            var subQuestionId =
                "${element["dispTitle"]},${subTopicElement["subTopicIndex"]}";
            subTopicElement["subQuestionId"] =
                subTopicElement["subTopicIndex"] != -1
                    ? subQuestionId
                    : element["dispTitle"].toString();
            subTopicElement["standradScore"] =
                subStandradScore[subQuestionId] ??
                    element["standardScore"] as double;
          }
          subTopicMap = element["subTopics"];
        }
      } catch (e) {
        logger.e("fetchPaperData: $e");
      }
      if (element["answerType"] == "s01Text") {
        selectedAnswer = element["answer"];
        isSubjective = false;
      }
      List<QuestionSubTopic> subTopic = [];
      double subStandradScoreSum = 0;
      for (var subTopicElement in subTopicMap) {
        List<TeacherMarking> teacherMarkingList = [];
        if (subTopicElement.containsKey("teacherMarkingRecords")) {
          for (var teacherMarkingRecordsElement
              in subTopicElement["teacherMarkingRecords"]) {
            teacherMarkingList.add(TeacherMarking(
                role: teacherMarkingRecordsElement["role"],
                score: teacherMarkingRecordsElement["score"],
                teacherId: teacherMarkingRecordsElement["teacherId"],
                teacherName: teacherMarkingRecordsElement["teacherName"]));
          }
        }
        if (subTopicElement["stepRecords"] != null && subTopicMap.length == 1) {
          for (var subTopicElement in subTopicMap) {
            for (var stepRecordElement in subTopicElement["stepRecords"]) {
              subTopic.add(QuestionSubTopic(
                  score: stepRecordElement["score"],
                  standradScore: null,
                  scoreSource: subTopicElement["scoreSource"],
                  subQuestionId: stepRecordElement["stepTitle"],
                  teacherMarkingRecords: teacherMarkingList));
            }
          }
        } else {
          subTopic.add(QuestionSubTopic(
              score: subTopicElement["score"],
              standradScore: subTopicElement["standradScore"],
              scoreSource: subTopicElement["scoreSource"],
              subQuestionId: subTopicElement["subQuestionId"],
              teacherMarkingRecords: teacherMarkingList));
          subStandradScoreSum += subTopicElement["standradScore"] as double;
        }
      }
      if (subStandradScoreSum != (element["standardScore"] as double)) {
        //TODO
        for (QuestionSubTopic subTopicElement in subTopic) {
          subTopicElement.standradScore = null;
        }
      }
      List<MapEntry<String, double>> stepRecords = [];
      try {
        if (element["subTopics"] != null) {
          List<dynamic> subTopics = element["subTopics"];
          logger.d("subTopics: $subTopics");
          if (subTopics.length != 1) {
            for (var subTopic in subTopics) {
              stepRecords.add(
                  MapEntry("${subTopic["subTopicIndex"]}", subTopic["score"]));
            }
          } else {
            for (var subTopic in subTopics) {
              if (subTopic["stepRecords"] != null) {
                for (var stepRecord in subTopic["stepRecords"]) {
                  stepRecords.add(
                      MapEntry(stepRecord["stepTitle"], stepRecord["score"]));
                }
              }
            }
          }
        }
      } catch (e) {
        logger.e("fetchPaperData: $e");
      }
      questions.add(Question(
        questionId: element["dispTitle"],
        topicNumber: element["topicNumber"],
        fullScore: element["standardScore"],
        userScore: element["score"],
        subTopic: subTopic,
        isSelected: (element as Map<String, dynamic>).containsKey("isSelected")
            ? element["isSelected"]
            : true,
        isSubjective: isSubjective,
        selectedAnswer: selectedAnswer,
        stepRecords: stepRecords,
        markingContentsExist: element["markingContents"] != null,
      ));
    }

    if ((jsonDecode(sheetQuestions) as Map<String, dynamic>)
        .containsKey("answerSheetLocationDTO")) {
      List sheetMarkersSheets =
          jsonDecode(sheetQuestions)["answerSheetLocationDTO"]["pageSheets"];

      logger.d("sheetMarkersSheets, start: $sheetMarkersSheets");
      try {
        Result parseResult =
            parseMarkers(sheetMarkersSheets, questions, cutBlocksPosition);
        if (parseResult.state) {
          markers = parseResult.result;
          logger.d("parseMarkers, success: $markers");
        } else {
          logger.e("parseMarkers, fail end: ${parseResult.message}");
        }
      } on Exception catch (e) {
        logger.e("parseMarkers: $e");
      }
    }

    try {
      Result transcriptResult =
          await fetchTranscriptData("00", examId, paperId, questions);
      if (transcriptResult.state) {
        questions = transcriptResult.result;
        logger.d("fetchTranscriptData, success: $questions");
      } else {
        logger.e("fetchTranscriptData, fail end: ${transcriptResult.message}");
      }
    } catch (e) {
      logger.e("fetchTranscriptData: $e");
    }

    logger.d("paperData: success, $sheetImages");
    PaperData paperData = PaperData(
      examId: examId,
      paperId: paperId,
      sheetImages: sheetImages,
      questions: questions,
      markers: markers,
    );

    logger.d("paperData: success, ${json["result"]["sheetImages"]}");
    return Result(state: true, message: "", result: paperData);
  }

  int findMaxOverlap(List<double> lengths, double startPercentage,
      double endPercentage, String message) {
    double totalLength = 0;
    for (int i = 0; i < lengths.length; i++) {
      totalLength += lengths[i];
    }
    double start = totalLength * startPercentage;
    double end = totalLength * endPercentage;
    double maxOverlap = -1;
    int maxIndex = 0;
    double currentStart = 0;
    double currentEnd = 0;
    for (int i = 0; i < lengths.length; i++) {
      currentEnd += lengths[i];
      List points = <double>[start, end, currentStart, currentEnd];
      points.sort();
      double overlap = points[2] - points[1];
      if (end < currentStart || start > currentEnd) {
        overlap = 0;
      }
      if (overlap > maxOverlap) {
        maxOverlap = overlap;
        maxIndex = i;
      }
      currentStart = currentEnd;
    }
    return maxIndex;
  }

  Result<List<Marker>> parseMarkers(List sheetMarkersSheets,
      List<Question> questions, Map<int, List<Map>> cutBlocksPosition) {
    logger.d("parseMarkers: $sheetMarkersSheets");
    List<Marker> markers = [];
    List<int> parsedQuestionIds = [];
    Map<int, List<double>> questionSectionHeight = {};
    Map<int, double> questionSectionCount = {};

    try {
      for (var sheetId = 0; sheetId < sheetMarkersSheets.length; sheetId++) {
        //统计每大题 Section 高度
        Map sheet = sheetMarkersSheets[sheetId];
        for (var section in sheet["sections"]) {
          if (section["type"] == "AnswerQuestion") {
            for (var branchElement in section["contents"]["branch"]) {
              if (questionSectionHeight[branchElement["num"].toInt()] == null) {
                questionSectionHeight[branchElement["num"].toInt()] = [];
              }
              questionSectionHeight[branchElement["num"].toInt()]
                  ?.add(branchElement["position"]["height"].toDouble());
            }
          }
        }
      }
    } catch (_) {}
    for (var sheetId = 0; sheetId < sheetMarkersSheets.length; sheetId++) {
      Map sheet = sheetMarkersSheets[sheetId];
      for (var section in sheet["sections"]) {
        logger.d("section parse, start, $section");
        if (section["enabled"] || true) {
          double fullScore = 0;
          double userScore = 0;

          List<MapEntry> stepRecords = [];
          switch (section["type"]) {
            case "SingleChoice":
              for (var branch in section["contents"]["branch"]) {
                logger.d("branch parse, start, $branch");
                List choices = branch["chooses"];
                List numList = branch["ixList"];
                double top = branch["position"]["top"].toDouble() +
                    (branch["position"]["top"].toDouble() == 0
                        ? section["contents"]["position"]["top"].toDouble()
                        : 0);
                double left = branch["position"]["left"].toDouble() +
                    (branch["position"]["top"].toDouble() == 0
                        ? section["contents"]["position"]["left"].toDouble()
                        : 0);
                double topOffset =
                    (branch["firstOption"]["top"] + 3).toDouble();
                double leftOffset =
                    (branch["firstOption"]["left"] + 3).toDouble();
                double width = branch["firstOption"]["width"].toDouble();
                double height = branch["firstOption"]["height"].toDouble();
                double colOffset = (branch["colOffset"] + 2).toDouble();
                double rowOffset = (branch["rowOffset"] + 2).toDouble();
                logger.d("branch parse, start");
                for (var i = 0; i < numList.length; i++) {
                  int qid = numList[i];
                  late Question question;
                  try {
                    question = questions
                        .firstWhere((element) => element.topicNumber == qid);
                  } catch (e) {
                    logger.e("parseMarkers: $e");
                    continue;
                  }
                  if (question.selectedAnswer != null) {
                    if (!parsedQuestionIds.contains(qid)) {
                      parsedQuestionIds.add(qid);
                      if (question.isSelected) {
                        fullScore += question.fullScore;
                        userScore += question.userScore;
                      }
                    }

                    int ix = choices.indexOf(question.selectedAnswer!);
                    if (ix != -1) {
                      if (question.topicNumber == 1) {
                        logger.d(
                            "branch parse, $qid, $ix, $top, $left, $topOffset, $leftOffset, $width, $height, $colOffset, $rowOffset");
                      }

                      markers.add(Marker(
                        type: MarkerType.singleChoice,
                        sheetId: sheetId,
                        top: top,
                        left: left,
                        topOffset: topOffset + rowOffset * i,
                        leftOffset: leftOffset + colOffset * ix,
                        width: width,
                        height: height,
                        color: question.userScore == question.fullScore
                            ? Colors.green.withOpacity(0.75)
                            : Colors.red.withOpacity(0.75),
                        message: "",
                      ));
                    }
                  }
                }
              }
              break;
            case "Object":
              for (var branch in section["contents"]["branch"]) {
                List choices = branch["chooses"];
                List numList = branch["ixList"];
                double top = branch["position"]["top"].toDouble();
                double left = branch["position"]["left"].toDouble();
                double topOffset =
                    (branch["firstOption"]["top"] + 3).toDouble();
                double leftOffset =
                    (branch["firstOption"]["left"] + 3).toDouble();
                double width = branch["firstOption"]["width"].toDouble();
                double height = branch["firstOption"]["height"].toDouble();
                double colOffset = (branch["colOffset"] + 2).toDouble();
                double rowOffset = (branch["rowOffset"] + 2).toDouble();
                logger.d("branch parse, start");
                for (var i = 0; i < numList.length; i++) {
                  int qid = numList[i];
                  late Question question;
                  try {
                    question = questions
                        .firstWhere((element) => element.topicNumber == qid);
                  } catch (e) {
                    logger.e("parseMarkers: $e");
                    continue;
                  }
                  if (question.selectedAnswer != null) {
                    if (!parsedQuestionIds.contains(qid)) {
                      parsedQuestionIds.add(qid);
                      if (question.isSelected) {
                        fullScore += question.fullScore;
                        userScore += question.userScore;
                      }
                    }

                    for (var singleAnswer
                        in question.selectedAnswer!.split('')) {
                      int ix = choices.indexOf(singleAnswer);
                      if (ix != -1) {
                        markers.add(Marker(
                          type: MarkerType.multipleChoice,
                          sheetId: sheetId,
                          top: top,
                          left: left,
                          topOffset: topOffset + rowOffset * i,
                          leftOffset: leftOffset + colOffset * ix,
                          width: width,
                          height: height,
                          color: question.userScore == question.fullScore
                              ? Colors.green.withOpacity(0.75)
                              : question.userScore < question.fullScore
                                  ? Colors.deepOrange.withOpacity(0.75)
                                  : Colors.red.withOpacity(0.75),
                          message: "",
                        ));
                      }
                    }
                  }
                }
              }
              break;
            case "AnswerQuestion":
              for (var branch in section["contents"]["branch"]) {
                List numList = branch["ixList"];
                for (var i = 0; i < numList.length; i++) {
                  int qid = numList[i];
                  late Question question;
                  try {
                    question = questions
                        .firstWhere((element) => element.topicNumber == qid);
                  } catch (e) {
                    logger.e("parseMarkers: $e");
                    continue;
                  }
                  if (!parsedQuestionIds.contains(qid)) {
                    parsedQuestionIds.add(qid);
                    if (question.isSelected) {
                      fullScore += question.fullScore;
                      userScore += question.userScore;
                      stepRecords.addAll(question.stepRecords
                          .map((e) => MapEntry("$qid(${e.key})", e.value))
                          .toList());
                    }
                  }
                }
              }
              break;
          }
          double top = section["contents"]["position"]["top"].toDouble();
          double left = section["contents"]["position"]["left"].toDouble();
          double width = section["contents"]["position"]["width"].toDouble();
          double height = section["contents"]["position"]["height"].toDouble();
          try {
            for (var branchElement in section["contents"]["branch"]) {
              var cutBlockList =
                  cutBlocksPosition[branchElement["num"].toInt()];
              questionSectionCount[branchElement["num"].toInt()] =
                  (questionSectionCount[branchElement["num"].toInt()] ?? 0) + 1;
              if (cutBlockList != null) {
                var count = 1;
                for (var cutBlock in cutBlockList) {
                  double preHeight = 0;
                  int sectionIndex = 0;
                  if (cutBlock["crossSection"] == true) {
                    sectionIndex = findMaxOverlap(
                        questionSectionHeight[branchElement["num"].toInt()] ??
                            <double>[1000],
                        cutBlock["positionPercent"]["top"].toDouble(),
                        (cutBlock["positionPercent"]["top"] +
                                cutBlock["positionPercent"]["height"])
                            .toDouble(),
                        branchElement["num"].toString());
                    if (sectionIndex + 1 !=
                        (questionSectionCount[branchElement["num"].toInt()] ??
                            0)) {
                      //CutBlock 不属于该 Section
                      continue;
                    }
                    for (int i = 0; i < sectionIndex; i++) {
                      preHeight +=
                          questionSectionHeight[branchElement["num"].toInt()]
                                  ?[i] ??
                              0;
                    }
                  }
                  if ((branchElement["numList"] ?? []).length > 1) {
                    //TODO
                    continue;
                  }
                  markers.add(Marker(
                    type: MarkerType.cutBlock,
                    sheetId: sheetId,
                    top: branchElement["position"]["top"].toDouble() -
                            preHeight ??
                        0,
                    left: branchElement["position"]["left"].toDouble(),
                    topOffset: cutBlock["position"]["top"].toDouble(),
                    leftOffset: cutBlock["position"]["left"].toDouble(),
                    width: cutBlock["position"]["width"].toDouble(),
                    height: cutBlock["position"]["height"].toDouble(),
                    color: count % 2 == 0
                        ? Colors.yellow.shade800
                        : Colors.blue.shade400,
                    message:
                        " ${cutBlock["dispTopic"] ?? cutBlock["topicNumStr"] ?? ""}",
                  ));
                  count += 1;
                }
              }
              //break;
            }
          } catch (_) {}
          if (userScore != fullScore) {
            markers.add(Marker(
              type: MarkerType.sectionEnd,
              sheetId: sheetId,
              top: top,
              left: left + width,
              topOffset: 0,
              leftOffset: -100,
              width: 0,
              height: 0,
              color: Colors.red.shade700,
              message: "-${fullScore - userScore}",
            ));
          }
          if (stepRecords.isNotEmpty) {
            markers.add(Marker(
              type: MarkerType.detailScoreEnd,
              sheetId: sheetId,
              top: top,
              left: left + width,
              topOffset: 60,
              leftOffset: -300,
              width: 0,
              height: 0,
              color: Colors.red.shade700,
              message:
                  stepRecords.map((e) => "${e.key}: ${e.value}").join("\n"),
            ));
          }
          if (!["SingleChoice", "Object"].contains(section["type"]) &&
              fullScore != 0) {
            logger.d("section parse, start, $userScore, $fullScore");
            markers.add(Marker(
                type: MarkerType.svgPicture,
                sheetId: sheetId,
                top: top + height,
                left: left + width,
                topOffset: -60,
                leftOffset: -100,
                width: 0,
                height: 0,
                color: Colors.red.shade700,
                message: userScore == 0.0
                    ? "wrong"
                    : userScore < fullScore
                        ? "half"
                        : "correct"));
          }
        }
      }
    }
    logger.d("question parse");
    return Result(state: true, message: "", result: markers);
  }

  // fetch paper actual percentile
  Future<Result<PaperPercentile>> fetchPaperOfficialPercentile(
      String examId, String paperId) async {
    Dio client = BaseSingleton.singleton.dio;

    if (session == null) {
      return Result(state: false, message: "未登录");
    }
    logger.d("fetchPaperPercentile, xToken: ${session?.xToken}");
    Response response =
        await client.get("$zhixueTrendUrl?examId=$examId&paperId=$paperId");
    logger.d("paperPercentile: ${response.data}");
    Map<String, dynamic> json = jsonDecode(response.data);
    logger.d("paperPercentile: $json");
    if (json["errorCode"] != 0) {
      logger.d("paperPercentile: failed");
      return Result(state: false, message: json["errorInfo"]);
    }

    try {
      Map<String, dynamic> data = json["result"]["list"][0];
      Map<String, dynamic> improveBar = data["improveBar"];

      String scale = improveBar["levelScale"];
      int offset = improveBar["offset"];

      String tagCode = data["tag"]["code"];
      int count = data["statTotalNum"];

      if (scale.startsWith("G") && tagCode == "grade") {
        int numeralScale = (int.parse(scale.substring(1)) - 1);

        double percentile = numeralScale * 10 + (offset / 10);
        percentile = 1 - percentile / 100;

        logger.d("paperPercentile: success, $percentile");
        return Result(
            state: true,
            message: "",
            result: PaperPercentile(
                percentile: percentile,
                count: count,
                version: 0,
                official: true));
      } else {
        logger.d("paperPercentile: success, no data");
        return Result(state: false, message: "无数据");
      }
    } catch (e) {
      logger.e("paperPercentile: $e");
      return Result(state: false, message: "获取失败");
    }
  }

  Future<Result<PaperPercentile>> fetchPaperPercentile(
      String examId, String paperId, double score) async {
    Result<PaperPercentile> officialResult =
        await fetchPaperOfficialPercentile(examId, paperId);
    if (officialResult.state) {
      return officialResult;
    } else {
      Result<List<dynamic>> pred = await fetchPaperPredict(paperId, score);
      if (pred.state) {
        return Result(
            state: true,
            message: "",
            result: PaperPercentile(
                percentile: pred.result![1],
                count: 1,
                version: pred.result![0],
                official: false));
      } else {
        return Result(state: false, message: pred.message);
      }
    }
  }

  Future<Result<String>> uploadPaperData(Paper paper) async {
    await fetchBasicInfo();
    if (paper.source == Source.preview) {
      logger.d("uploadPaperData 不允许上传预览分数 $paper");
      return Result(state: true, message: "不允许上传预览分数");
    }
    SharedPreferences shared = await SharedPreferences.getInstance();
    bool? allowed = shared.getBool("allowTelemetry");
    if (allowed == null || !allowed) {
      logger.d("uploadPaperData 不允许数据上传 $paper");
      return Result(state: true, message: "不允许数据上传");
    }

    Dio client = BaseSingleton.singleton.dio;

    logger.d("uploadPaperData: start, data: ${{
      "user_id": basicInfo?.id,
      "exam_id": paper.examId,
      "paper_id": paper.paperId,
      "subject_id": paper.subjectId,
      "subject_name": paper.name,
      "standard_score": paper.fullScore,
      "user_score": paper.userScore,
      "diagnostic_score": paper.diagnosticScore,
    }}");

    //String rawData =
    //    "user_id=${basicInfo?.id}&exam_id=${paper.examId}&paper_id=${paper.paperId}&subject_id=${paper.subjectId}&subject_name=${paper.name}&standard_score=${paper.fullScore}&user_score=${paper.userScore}&diagnostic_score=${paper.diagnosticScore}";
    Response response = await client.post(
      '$telemetryBaseUrl/exam/submit',
      data: {
        "user_id": basicInfo?.id,
        "exam_id": paper.examId,
        "paper_id": paper.paperId,
        "subject_id": paper.subjectId,
        "subject_name": paper.name,
        "standard_score": paper.fullScore,
        "user_score": paper.userScore,
        "diagnostic_score": paper.diagnosticScore,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer ${session?.serverToken}',
          //'Signature': Hmac(sha256, utf8.encode(uploadKey)).convert(utf8.encode(rawData))
        },
        contentType: Headers.jsonContentType,
      ),
    );

    logger.d("uploadPaperData: response: ${response.data}");
    return Result(state: true, message: "成功哒！", result: response.data);
  }

  Future<Result<String>> uploadPaperClassData(
      List<PaperClass> paperClassList, String paperId) async {
    SharedPreferences shared = await SharedPreferences.getInstance();
    bool? allowed = shared.getBool("allowTelemetry");
    if (allowed == null || !allowed) {
      logger.d("uploadPaperClassData 不允许数据上传");
      return Result(state: true, message: "不允许数据上传");
    }

    Dio client = BaseSingleton.singleton.dio;
    List<Map<String, dynamic>> mapList =
        paperClassList
        .where((element) => element.scanCount != 0)
        .map((element) => element.toMap()).toList();
    if (mapList.isEmpty) {
      logger.d("uploadPaperClassData: 无数据");
      return Result(state: false, message: "无数据");
    }
    logger.d("uploadPaperClassData: start, data: ${{
      "paper_id": paperId,
      "data": mapList,
    }}");
    //String rawData =
    //    "user_id=${basicInfo?.id}&exam_id=${paper.examId}&paper_id=${paper.paperId}&subject_id=${paper.subjectId}&subject_name=${paper.name}&standard_score=${paper.fullScore}&user_score=${paper.userScore}&diagnostic_score=${paper.diagnosticScore}";
    Response response = await client.post(
      '$telemetryBaseUrl/exam/submit/exam_data',
      data: {
        "paper_id": paperId,
        "data": mapList,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer ${session?.serverToken}',
          //'Signature': Hmac(sha256, utf8.encode(uploadKey)).convert(utf8.encode(rawData))
        },
        contentType: Headers.jsonContentType,
      ),
    );

    logger.d("uploadPaperClassData: response: ${response.data}");
    return Result(state: true, message: "成功哒！", result: response.data);
  }

  Future<Result<double>> fetchExamPredict(String examId, double score) async {
    Dio client = BaseSingleton.singleton.dio;

    Response response =
        await client.get('$telemetryExamPredictUrl/$examId/$score');
    logger.d("fetchExamPredict: cronet, response: $response.data");

    Map<String, dynamic> result = jsonDecode(response.data);
    logger.d("fetchExamPredict: end, $result");
    if (result["code"] == 0) {
      return Result(state: true, message: "成功哒！", result: result["percent"]);
    } else {
      return Result(state: false, message: result["code"].toString());
    }
  }

  Future<Result<List<dynamic>>> fetchPaperPredict(
      String paperId, double score) async {
    Dio client = BaseSingleton.singleton.dio;

    Response response =
        await client.get('$telemetryPaperPredictUrl/$paperId/$score');
    logger.d("fetchPaperPredict: cronet, response: ${response.data}");

    Map<String, dynamic> result = jsonDecode(response.data);
    if (result["code"] == 0) {
      return Result(
          state: true,
          message: "成功哒！",
          result: [result["version"], result["percent"]]);
    } else {
      return Result(state: false, message: result["code"].toString());
    }
  }

  Future<Result<ScoreInfo>> fetchExamScoreInfo(String examId) async {
    Dio client = BaseSingleton.singleton.dio;

    logger.d("fetchExamScoreInfo: start, $examId");
    Response response = await client.get('$telemetryExamScoreInfoUrl/$examId');
    Map<String, dynamic> result = jsonDecode(response.data);
    logger.d("fetchExamScoreInfo: end, $result");

    if (result["code"] == 0) {
      ScoreInfo scoreInfo = ScoreInfo(
          max: result["data"]["max"],
          min: result["data"]["min"],
          avg: result["data"]["avg"],
          med: result["data"]["med"]);

      return Result(state: true, message: "成功哒！", result: scoreInfo);
    } else {
      return Result(state: false, message: result["code"].toString());
    }
  }

  Future<Result<ScoreInfo>> fetchPaperScoreInfo(String paperId) async {
    Dio client = BaseSingleton.singleton.dio;

    logger.d("fetchPaperScoreInfo: start, $paperId");
    Response response =
        await client.get('$telemetryPaperScoreInfoUrl/$paperId');
    Map<String, dynamic> result = jsonDecode(response.data);
    logger.d("fetchPaperScoreInfo: end, $result");
    if (result["code"] == 0) {
      ScoreInfo scoreInfo = ScoreInfo(
          max: result["data"]["max"],
          min: result["data"]["min"],
          avg: result["data"]["avg"],
          med: result["data"]["med"]);

      return Result(state: true, message: "成功哒！", result: scoreInfo);
    } else {
      return Result(state: false, message: result["code"]);
    }
  }

  Future<Result<List<ClassInfo>>> fetchExamClassInfo(String examId) async {
    Dio client = BaseSingleton.singleton.dio;

    logger.d("fetchExamClassInfo: start, $examId");
    Response response = await client.get('$telemetryExamClassInfoUrl/$examId');
    Map<String, dynamic> result = jsonDecode(response.data);

    logger.d("fetchExamClassInfo: end, $result");
    if (result["code"] == 0) {
      List<ClassInfo> classesInfo = [];
      for (Map<String, dynamic> item in result["data"]) {
        ClassInfo classInfo = ClassInfo(
            classId: item["class_id"],
            className: item["class_name"],
            count: item["count"],
            max: item["max"],
            min: item["min"],
            avg: item["avg"],
            med: item["med"]);
        classesInfo.add(classInfo);
      }

      return Result(state: true, message: "成功哒！", result: classesInfo);
    } else {
      return Result(state: false, message: result["code"].toString());
    }
  }

  Future<Result<List<ClassInfo>>> fetchPaperClassInfo(String examId) async {
    Dio client = BaseSingleton.singleton.dio;

    logger.d("fetchPaperClassInfo: start, $examId");
    Response response = await client.get('$telemetryPaperClassInfoUrl/$examId');
    Map<String, dynamic> result = jsonDecode(response.data);

    logger.d("fetchPaperClassInfo: end, $result");
    if (result["code"] == 0 && result["data"] != null) {
      List<ClassInfo> classesInfo = [];
      for (Map<String, dynamic> item in result["data"]) {
        ClassInfo classInfo = ClassInfo(
            classId: item["class_id"],
            className: item["class_name"],
            count: item["count"],
            max: item["max"],
            min: item["min"],
            avg: item["avg"],
            med: item["med"]);
        classesInfo.add(classInfo);
      }

      return Result(state: true, message: "成功哒！", result: classesInfo);
    } else {
      return Result(state: false, message: result["code"].toString());
    }
  }
}

double getAssignScoreFromLevel(String level) {
  if (level == "A1") {
    return 100;
  } else if (level == "A2") {
    return 97;
  } else if (level == "A3") {
    return 94;
  } else if (level == "A4") {
    return 91;
  } else if (level == "A5") {
    return 88;
  } else if (level == "B1") {
    return 85;
  } else if (level == "B2") {
    return 82;
  } else if (level == "B3") {
    return 79;
  } else if (level == "B4") {
    return 76;
  } else if (level == "B5") {
    return 73;
  } else if (level == "C1") {
    return 70;
  } else if (level == "C2") {
    return 67;
  } else if (level == "C3") {
    return 64;
  } else if (level == "C4") {
    return 61;
  } else if (level == "C5") {
    return 58;
  } else if (level == "D1") {
    return 55;
  } else if (level == "D2") {
    return 52;
  } else if (level == "D3") {
    return 49;
  } else if (level == "D4") {
    return 46;
  } else if (level == "D5") {
    return 43;
  } else if (level == "E") {
    return 40;
  } else {
    return -1;
  }
}

double getScoringResult(double percentage) {
  if (percentage <= 0.01 && percentage >= 0) {
    return 100;
  } else if (percentage <= 0.03) {
    return 97;
  } else if (percentage <= 0.06) {
    return 94;
  } else if (percentage <= 0.1) {
    return 91;
  } else if (percentage <= 0.15) {
    return 88;
  } else if (percentage <= 0.21) {
    return 85;
  } else if (percentage <= 0.28) {
    return 82;
  } else if (percentage <= 0.36) {
    return 79;
  } else if (percentage <= 0.43) {
    return 76;
  } else if (percentage <= 0.50) {
    return 73;
  } else if (percentage <= 0.57) {
    return 70;
  } else if (percentage <= 0.64) {
    return 67;
  } else if (percentage <= 0.71) {
    return 64;
  } else if (percentage <= 0.78) {
    return 61;
  } else if (percentage <= 0.84) {
    return 58;
  } else if (percentage <= 0.89) {
    return 55;
  } else if (percentage <= 0.93) {
    return 52;
  } else if (percentage <= 0.96) {
    return 49;
  } else if (percentage <= 0.98) {
    return 46;
  } else if (percentage <= 0.99) {
    return 43;
  } else if (percentage > 1 || percentage < 0) {
    return -1;
  } else {
    return 40;
  }
}
