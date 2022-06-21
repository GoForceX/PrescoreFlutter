import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:prescore_flutter/main.dart';
import 'package:prescore_flutter/util/rsa.dart';
import 'package:prescore_flutter/util/struct.dart';

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

  void logoff() async {
    session = null;
    basicInfo = null;
    isLoading = false;
    isBasicInfoLoaded = false;

    Directory dataDir = await getApplicationDocumentsDirectory();
    String dataPath = dataDir.path;
    PersistCookieJar cookieJar = PersistCookieJar(
        storage: FileStorage(
          dataPath,
        ),
        ignoreExpires: true);
    cookieJar.delete(Uri.parse("https://www.zhixue.com/"));
    cookieJar.delete(Uri.parse("https://open.changyan.com/"));
  }

  String getEncryptedPassword(String password) {
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

  String getParsedParams(
      String lt, String execution, String username, String password) {
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
    params.addEntries({
      "lt": lt,
      "execution": execution,
      "username": username,
      "password": getEncryptedPassword(password),
    }.entries);

    String parsedParams = "";
    params.forEach((key, value) {
      parsedParams += "$key=$value&";
    });
    return parsedParams.substring(0, parsedParams.length - 1);
  }

  Future<Session?> getSessionFromSt(String st) async {
    Directory dataDir = await getApplicationDocumentsDirectory();
    String dataPath = dataDir.path;
    PersistCookieJar cookieJar = PersistCookieJar(
        storage: FileStorage(
          dataPath,
        ),
        ignoreExpires: true);
    Dio client = BaseDio().dio;

    logger.d("st: $st");
    Response loginResponse = await client.post(
      "https://www.zhixue.com/ssoservice.jsp",
      data: {
        "action": "login",
        "ticket": st,
      },
      queryParameters: {
        "User-Agent":
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.5005.124 Safari/537.36 Edg/102.0.1245.41",
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    logger.d("loginResponse: ${loginResponse.data}");
    logger.d("loginResponse: ${loginResponse.headers}");

    List<Cookie> cookies =
        await cookieJar.loadForRequest(Uri.parse("https://www.zhixue.com/"));
    logger.d("cookies: $cookies");
    for (var element in cookies) {
      if (element.name == "tlsysSessionId") {
        Response tokenResponse = await client.get(
            "https://www.zhixue.com/addon/error/book/index",
            queryParameters: {
              "User-Agent":
                  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.5005.124 Safari/537.36 Edg/102.0.1245.41",
            });
        logger.d("tokenResponse: ${tokenResponse.data}");
        Map<String, dynamic> json = jsonDecode(tokenResponse.data);
        String xToken = json["result"];
        Session currSession = Session(st, element.value, xToken);
        session = currSession;
        logger.d(currSession.toString());
        client.options.headers["XToken"] = currSession.xToken;
        return currSession;
      }
    }
    return null;
  }

  Future<BasicInfo?> fetchBasicInfo(
      {bool force = false, Function? callback}) async {
    Dio client = BaseDio().dio;
    logger.d("fetchBasicInfo, callback: $callback");

    if (isBasicInfoLoaded && !force) {
      if (callback != null) {
        callback(this.basicInfo);
      }
      logger.d("basicInfo: loaded, ${this.basicInfo}");
      return this.basicInfo;
    }
    Response response =
        await client.get("https://www.zhixue.com/container/getCurrentUser");
    logger.d("basicInfo: ${response.data}");
    Map<String, dynamic> json = jsonDecode(response.data);
    logger.d("basicInfo: $json");
    if (json["errorCode"] != 200) {
      logger.d("basicInfo: failed");
      return null;
    }
    BasicInfo basicInfo = BasicInfo(
      json["result"]["id"],
      json["result"]["loginName"],
      json["result"]["name"],
      json["result"]["role"],
      json["result"]["avatar"],
    );
    this.basicInfo = basicInfo;
    isBasicInfoLoaded = true;
    if (callback != null) {
      logger.d("callback");
      callback(basicInfo);
    }
    logger.d("basicInfo: success,  $basicInfo");
    return basicInfo;
  }

  Future<Map<String, dynamic>> fetchExams() async {
    Dio client = BaseDio().dio;

    if (session == null) {
      return {"state": false, "message": "未登录", "result": null};
    }
    logger.d("fetchExams, xToken: ${session?.xToken}");
    Response response = await client.get(
        "https://www.zhixue.com/zhixuebao/report/exam/getUserExamList",
        queryParameters: {
          "User-Agent":
              "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.5005.124 Safari/537.36 Edg/102.0.1245.41"
        });
    logger.d("exams: ${response.data}");
    Map<String, dynamic> json = jsonDecode(response.data);
    logger.d("exams: $json");
    if (json["errorCode"] != 0) {
      logger.d("exams: failed");
      return {"state": false, "message": json["errorInfo"], "result": null};
    }
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
    return {"state": true, "message": "", "result": exams};
  }

  Future<Map<String, dynamic>> fetchPaper(String examId) async {
    Dio client = BaseDio().dio;

    if (session == null) {
      return {"state": false, "message": "未登录", "result": null};
    }
    logger.d("fetchPaper, xToken: ${session?.xToken}");
    Response response = await client.get(
        "https://www.zhixue.com/zhixuebao/report/exam/getReportMain?examId=$examId");
    logger.d("paper: ${response.data}");
    Map<String, dynamic> json = jsonDecode(response.data);
    logger.d("paper: $json");
    if (json["errorCode"] != 0) {
      logger.d("paper: failed");
      return {"state": false, "message": json["errorInfo"], "result": null};
    }

    List<Paper> papers = [];
    json["result"]["paperList"].forEach((element) {
      papers.add(Paper(
          paperId: element["paperId"],
          name: element["subjectName"],
          subjectId: element["subjectCode"],
          userScore: element["userScore"],
          fullScore: element["standardScore"]));
    });
    logger.d("paper: success, $papers");
    return {"state": true, "message": "", "result": papers};
  }

  Future<Map<String, dynamic>> fetchPaperDiagnosis(String examId) async {
    Dio client = BaseDio().dio;

    if (session == null) {
      return {"state": false, "message": "未登录", "result": null};
    }
    logger.d("fetchPaperDiagnosis, xToken: ${session?.xToken}");
    Response diagResponse = await client.get(
        "https://www.zhixue.com/zhixuebao/report/exam/getSubjectDiagnosis?examId=$examId");
    logger.d("diag: ${diagResponse.data}");
    Map<String, dynamic> diagJson = jsonDecode(diagResponse.data);
    logger.d("diag: $diagJson");
    if (diagJson["errorCode"] != 0) {
      logger.d("diag: failed");
      return {"state": false, "message": diagJson["errorInfo"], "result": null};
    }

    List<PaperDiagnosis> diags = [];
    diagJson["result"]["list"].forEach((element) {
      return diags.add(PaperDiagnosis(
          subjectId: element["subjectCode"],
          subjectName: element["subjectName"],
          diagnosticScore: element["myRank"]));
    });
    logger.d("diag: success, $diags");
    return {"state": true, "message": "", "result": diags};
  }

  Future<Map<String, dynamic>> fetchPaperData(
      String examId, String paperId) async {
    Dio client = BaseDio().dio;

    if (session == null) {
      return {"state": false, "message": "未登录", "result": null};
    }
    logger.d("fetchPaperData, xToken: ${session?.xToken}");
    Response response = await client.get(
        "https://www.zhixue.com/zhixuebao/report/checksheet/?examId=$examId&paperId=$paperId");
    logger.d("paperData: ${response.data}");
    Map<String, dynamic> json = jsonDecode(response.data);
    logger.d("paperData: $json");
    if (json["errorCode"] != 0) {
      logger.d("paperData: failed");
      return {"state": false, "message": json["errorInfo"], "result": null};
    }

    List<dynamic> sheetImagesDynamic =
        jsonDecode(json["result"]["sheetImages"]);
    List<String> sheetImages = [];
    for (var element in sheetImagesDynamic) {
      sheetImages.add(element);
    }
    List<Question> questions = [];
    String sheetQuestions = json["result"]["sheetDatas"];
    logger.d("sheetQuestions: $sheetQuestions");
    List<dynamic> sheetQuestionsDynamic =
        jsonDecode(sheetQuestions)["userAnswerRecordDTO"]
            ["answerRecordDetails"];
    logger.d("sheetQuestionsDynamic: $sheetQuestionsDynamic");
    for (var element in sheetQuestionsDynamic) {
      questions.add(Question(
        questionId: element["dispTitle"],
        fullScore: element["standardScore"],
        userScore: element["score"],
      ));
    }
    logger.d("paperData: success, $sheetImages");
    PaperData paperData = PaperData(
        examId: examId,
        paperId: paperId,
        sheetImages: sheetImages,
        questions: questions);

    logger.d("paperData: success, ${json["result"]["sheetImages"]}");
    return {"state": true, "message": "", "result": paperData};
  }

  Future<Map<String, dynamic>> login(String username, String password,
      {bool ignoreLoading = true,
      bool force = true,
      Function? callback,
      BuildContext? context}) async {
    if (isLoading & !ignoreLoading) {
      return {"status": false, "message": "正在登录中，请稍后再试"};
    }
    if (!force) {
      if (isLoggedIn()) {
        if (callback != null) {
          callback();
        }
        return {"status": true, "message": "已登录"};
      }
    }

    isLoading = true;

    /*
    Directory dataDir = await getApplicationDocumentsDirectory();
    String dataPath = dataDir.path;
    PersistCookieJar cookieJar = PersistCookieJar(
        storage: FileStorage(
          dataPath,
        ),
        ignoreExpires: true);
    Dio client = Dio()..interceptors.add(CookieManager(cookieJar));
    dio = client;

     */

    Dio client = BaseDio().dio;
    Directory dataDir = await getApplicationDocumentsDirectory();
    String dataPath = dataDir.path;
    PersistCookieJar cookieJar = PersistCookieJar(
        storage: FileStorage(
          dataPath,
        ),
        ignoreExpires: true);
    /*
      ..httpClientAdapter = Http2Adapter(
        ConnectionManager(
          idleTimeout: 10000,
          // Ignore bad certificate
          onClientCreate: (_, config) => config.onBadCertificate = (_) => true,
        ),
      );
       */

    Response preload = await client.get(
        "https://open.changyan.com/sso/login?sso_from=zhixuesso&service=https%3A%2F%2Fwww.zhixue.com:443%2Fssoservice.jsp",
        queryParameters: {
          "User-Agent":
              "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.5005.124 Safari/537.36 Edg/102.0.1245.41",
        });
    String preloadBody = preload.data;
    preloadBody = preloadBody.trim();
    logger.d("loginPreloadBody: $preloadBody");
    preloadBody = preloadBody.replaceAll('\\', '').replaceAll('\'', '');
    preloadBody = preloadBody.replaceAll('(', '').replaceAll(')', '');

    Map<String, dynamic> preloadParsed = jsonDecode(preloadBody);
    if (preloadParsed['code'] != 1000) {
      if (preloadParsed['code'] == 1001) {
        session = await getSessionFromSt(preloadParsed['data']['st']);
        if (session == null) {
          isLoading = false;
          return {"status": false, "message": "登录失败"};
        }
        if (callback != null) {
          callback();
        }
        isLoading = false;
        return {"status": true, "message": "已登录"};
      }
      isLoading = false;
      return {"status": false, "message": preloadParsed['data']};
    }
    String lt = preloadParsed['data']['lt'];
    String execution = preloadParsed['data']['execution'];

    logger.d(
        "loginUri: https://open.changyan.com/sso/login?sso_from=zhixuesso&service=https%3A%2F%2Fwww.zhixue.com%2Fssoservice.jsp&${getParsedParams(lt, execution, username, password)}");
    Response response = await client.get(
        "https://open.changyan.com/sso/login?sso_from=zhixuesso&${getParsedParams(lt, execution, username, password)}",
        queryParameters: {
          "User-Agent":
              "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.5005.124 Safari/537.36 Edg/102.0.1245.41",
        });
    String body = response.data;
    body = body.trim();
    logger.d("cookies: ${cookieJar.domainCookies}");
    logger.d("loginBody: $body");
    body = body.replaceAll('\\', '').replaceAll('\'', '');
    body = body.replaceAll('(', '').replaceAll(')', '');

    Map<String, dynamic> parsed = jsonDecode(body);
    if (parsed['code'] != 1001) {
      isLoading = false;
      return {"status": false, "message": parsed['data']};
    }
    session = await getSessionFromSt(parsed['data']['st']);
    if (session == null) {
      isLoading = false;
      return {"status": false, "message": "登录失败"};
    }

    if (callback != null) {
      callback();
    }
    isLoading = false;
    return {"status": true, "message": "登录成功"};
  }
}
