import 'dart:convert';

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

import '../constants.dart';

class User {
  Session? session;
  BasicInfo? basicInfo;
  bool isLoading = false;
  bool isBasicInfoLoaded = false;
  Dio dio = Dio();

  User({this.session});

  bool isLoggedIn() {
    if (session == null) {
      return false;
    }
    return true;
  }

  /// Remove **all** cookies and session data to logoff
  void logoff() async {
    session = null;
    basicInfo = null;
    isLoading = false;
    isBasicInfoLoaded = false;

    // Remove all cookies from related sites.
    CookieJar cookieJar = BaseSingleton.singleton.cookieJar;
    cookieJar.delete(Uri.parse("https://www.zhixue.com/"));
    cookieJar.delete(Uri.parse("https://open.changyan.com/"));
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
        await cookieJar.loadForRequest(Uri.parse("https://www.zhixue.com/"));
    logger.d("cookies: $cookies");
    for (var element in cookies) {
      if (element.name == "tlsysSessionId") {
        String xToken = await getXToken();
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
      BuildContext? context}) async {
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

    // Start login and set this flag to true to avoid multiple login requests.
    isLoading = true;

    Dio client = BaseSingleton.singleton.dio;

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
          return Result(state: false, message: "登录失败");
        }
        if (callback != null) {
          callback();
        }
        isLoading = false;
        return Result(state: true, message: "已登录");
      }
      isLoading = false;
      return Result(state: false, message: preloadParsed['data']);
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
      return Result(state: false, message: "登录失败");
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

    // Parse basic info.
    String? avatar = json["result"]["avatar"];
    avatar ??= "";
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
    logger.d("basicInfo: success,  $basicInfo");
    return basicInfo;
  }

  /// Fetch exam list from [zhixueExamListUrl]
  Future<Result<List<Exam>>> fetchExams(int pageIndex) async {
    Dio client = BaseSingleton.singleton.dio;

    // Reject if not logged in.
    if (session == null) {
      return Result(state: false, message: "未登录");
    }

    // Fetch exams.
    logger.d("fetchExams, xToken: ${session?.xToken}");
    Response response =
        await client.get("$zhixueExamListUrl?pageIndex=$pageIndex");
    logger.d("exams: ${response.data}");
    Map<String, dynamic> json = jsonDecode(response.data);
    logger.d("exams: $json");
    if (json["errorCode"] != 0) {
      logger.d("exams: failed");
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
          examTime: dateTime));
    });
    logger.d("exams: success, $exams");
    return Result(state: true, message: "", result: exams);
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
                assignScore: element["userScore"]));
          } else {
            absentPapers.add(Paper(
                examId: examId,
                paperId: element["paperId"],
                name: element["subjectName"],
                subjectId: element["subjectCode"],
                userScore: element["preAssignScore"],
                fullScore: element["standardScore"]));
          }
        } else {
          absentPapers.add(Paper(
              examId: examId,
              paperId: element["paperId"],
              name: element["subjectName"],
              subjectId: element["subjectCode"],
              userScore: element["userScore"],
              fullScore: element["standardScore"]));
        }
      } else {
        absentPapers.add(Paper(
            examId: examId,
            paperId: element["paperId"],
            name: element["subjectName"],
            subjectId: element["subjectCode"],
            userScore: 0,
            fullScore: element["standardScore"]));
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
                assignScore: element["userScore"]));
          } else {
            papers.add(Paper(
                examId: examId,
                paperId: element["paperId"],
                name: element["subjectName"],
                subjectId: element["subjectCode"],
                userScore: element["preAssignScore"],
                fullScore: element["standardScore"]));
          }
        } else {
          papers.add(Paper(
              examId: examId,
              paperId: element["paperId"],
              name: element["subjectName"],
              subjectId: element["subjectCode"],
              userScore: element["userScore"],
              fullScore: element["standardScore"]));
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
              fullScore: json["result"]["standardScore"]));
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
    List<String> sheetImages = [];
    for (var element in sheetImagesDynamic) {
      sheetImages.add(element);
    }
    List<Question> questions = [];
    List<Marker> markers = [];
    String sheetQuestions = json["result"]["sheetDatas"];
    logger.d("sheetQuestions: $sheetQuestions");
    List<dynamic> sheetQuestionsDynamic =
        jsonDecode(sheetQuestions)["userAnswerRecordDTO"]
            ["answerRecordDetails"];
    logger.d("sheetQuestionsDynamic: $sheetQuestionsDynamic");
    for (var element in sheetQuestionsDynamic) {
      String? selectedAnswer;
      if (element["answerType"] == "s01Text") {
        selectedAnswer = element["answer"];
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
        isSelected: (element as Map<String, dynamic>).containsKey("isSelected")
            ? element["isSelected"]
            : true,
        selectedAnswer: selectedAnswer,
        stepRecords: stepRecords,
      ));
    }

    if ((jsonDecode(sheetQuestions) as Map<String, dynamic>)
        .containsKey("answerSheetLocationDTO")) {
      List sheetMarkersSheets =
          jsonDecode(sheetQuestions)["answerSheetLocationDTO"]["pageSheets"];

      logger.d("sheetMarkersSheets, start: $sheetMarkersSheets");
      try {
        Result parseResult = parseMarkers(sheetMarkersSheets, questions);
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

  Result<List<Marker>> parseMarkers(
      List sheetMarkersSheets, List<Question> questions) {
    logger.d("parseMarkers: $sheetMarkersSheets");
    List<Marker> markers = [];
    List<int> parsedQuestionIds = [];
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
    SharedPreferences shared = await SharedPreferences.getInstance();
    bool? allowed = shared.getBool("allowTelemetry");
    if (allowed == null || !allowed) {
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

    Response response = await client.post(
      'https://matrix.bjbybbs.com/api/exam/submit',
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
        },
        contentType: Headers.jsonContentType,
      ),
    );

    logger.d("uploadPaperData: response: ${response.data}");
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
      return Result(state: false, message: result["code"]);
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
