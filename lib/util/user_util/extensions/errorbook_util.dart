import 'dart:convert';

//import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:prescore_flutter/main.dart';
import 'package:prescore_flutter/util/struct.dart';
import '../user_util.dart';
import '../../../constants.dart';

extension UserErrorbookUtil on User {
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
}
