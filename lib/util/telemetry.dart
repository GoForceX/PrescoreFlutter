import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:prescore_flutter/util/struct.dart';

import '../main.dart';

class Telemetry {
  Future<Map<String, dynamic>> login(
      Session session, BasicInfo basicInfo) async {
    Dio client = BaseSingleton().dio;

    try {
      Response response = await client.post(
        'https://matrix.bjbybbs.com/api/login',
        data: {
          'username': basicInfo.id,
          'password': session.sessionId,
        },
      );
      logger.d('serverLogin response: ${response.data}');
      // session.serverToken = response.data['access_token'];
      return {"state": true, "message": "成功哒！", "result": response.data['access_token']};
    } catch (e) {
      logger.e(e);
      return {"state": false, "message": e.toString(), "data": null};
    }
  }

  Future<Map<String, dynamic>> uploadPaperData(
      Paper paper, Session session, BasicInfo basicInfo) async {
    Dio client = BaseSingleton().dio;

    try {
      Response response = await client.post(
        'https://matrix.bjbybbs.com/api/exam/submit',
        data: {
          "user_id": basicInfo.id,
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
            'Authorization': 'Bearer ${session.serverToken}',
          },
          contentType: Headers.jsonContentType,
        ),
      );
      return {"state": true, "message": "成功哒！", "result": response.data};
    } catch (e) {
      logger.e(e);
      return {"state": false, "message": e.toString(), "data": null};
    }
  }

  Future<Map<String, dynamic>> fetchExamPredict(
      String examId, double score) async {
    Dio client = BaseSingleton().dio;

    try {
      Response response = await client
          .get('https://matrix.bjbybbs.com/api/exam/predict/$examId/$score');
      Map<String, dynamic> result = jsonDecode(response.data);
      if (result["code"] == 0) {
        return {"state": true, "message": "成功哒！", "result": result["percent"]};
      } else {
        return {"state": false, "message": result["code"], "data": null};
      }
    } catch (e) {
      logger.e(e);
      return {"state": false, "message": e.toString(), "data": null};
    }
  }

  Future<Map<String, dynamic>> fetchPaperPredict(
      String paperId, double score) async {
    Dio client = BaseSingleton().dio;

    try {
      Response response = await client
          .get('https://matrix.bjbybbs.com/api/paper/predict/$paperId/$score');
      Map<String, dynamic> result = jsonDecode(response.data);
      if (result["code"] == 0) {
        return {"state": true, "message": "成功哒！", "result": result["percent"]};
      } else {
        return {"state": false, "message": result["code"], "data": null};
      }
    } catch (e) {
      logger.e(e);
      return {"state": false, "message": e.toString(), "data": null};
    }
  }
}
