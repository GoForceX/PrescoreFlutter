import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:prescore_flutter/main.dart';
import 'package:prescore_flutter/util/struct.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prescore_flutter/constants.dart';
import '../user_util.dart';

extension TelemetryUtil on User {
  Future<Result<String>> uploadPaperClassData(
      List<PaperClass> paperClassList, String paperId) async {
    SharedPreferences shared = await SharedPreferences.getInstance();
    bool? allowed = shared.getBool("allowTelemetry");
    if (allowed == null || !allowed) {
      logger.d("uploadPaperClassData 不允许数据上传");
      return Result(state: true, message: "不允许数据上传");
    }

    Dio client = BaseSingleton.singleton.dio;
    List<Map<String, dynamic>> mapList = paperClassList
        .where((element) => element.scanCount != 0)
        .map((element) => element.toMap())
        .toList();
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

  Future<Result<List<dynamic>>> fetchPapersPredict(
      List<String> paperIds, double score) async {
    Dio client = BaseSingleton.singleton.dio;

    Response response = await client
        .post('$telemetryPaperPredictUrl/$score', data: {"paper_id": paperIds});
    logger.d("fetchPapersPredict: cronet, response: ${response.data}");

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

  Future<Result<DistributionData>> fetchPaperDistribution(
      {required String paperId, double step = 1}) async {
    Dio client = BaseSingleton.singleton.dio;

    Response response =
        await client.get('$telemetryPaperDistributionUrl/$paperId/$step');
    logger.d("fetchPaperDistribution: cronet, response: ${response.data}");

    Map<String, dynamic> result = jsonDecode(response.data);
    if (result["code"] == 0) {
      DistributionData paperDistribution = DistributionData();
      for (var element in result["data"]["distribute"]) {
        paperDistribution.distribute.add(DistributionScoreItem(
            score: element["score"], sum: element["sum"]));
      }
      for (var element in result["data"]["prefix"]) {
        paperDistribution.prefix.add(DistributionScoreItem(
            score: element["score"], sum: element["sum"]));
      }
      for (var element in result["data"]["suffix"]) {
        paperDistribution.suffix.add(DistributionScoreItem(
            score: element["score"], sum: element["sum"]));
      }
      return Result(state: true, message: "", result: paperDistribution);
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

  Future<Result<ScoreInfo>> fetchPapersScoreInfo(List<String> paperIds) async {
    Dio client = BaseSingleton.singleton.dio;

    logger.d("fetchPapersScoreInfo: start, $paperIds");
    Response response = await client
        .post(telemetryPaperScoreInfoUrl, data: {"paper_id": paperIds});
    logger.d("fetchPapersScoreInfo: e, ${response.data}");
    Map<String, dynamic> result = jsonDecode(response.data);
    logger.d("fetchPapersScoreInfo: end, $result");
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
}
