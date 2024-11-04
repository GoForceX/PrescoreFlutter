import 'dart:convert';

//import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:prescore_flutter/main.dart';
import 'package:prescore_flutter/util/struct.dart';
import '../user_util.dart';
import 'package:prescore_flutter/constants.dart';

extension ExamUtil on User {
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
    /*if (json["errorCode"] != 0 && json["errorInfo"].contains("Token")) {
      await updateLoginStatus(force: true);
      Response response = await client.get(url);
      json = jsonDecode(response.data);
    }*/
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
          /*if (requestScore) {
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
          }*/
        } catch (_) {}
        try {
          MarkingStatus status = MarkingStatus.noMarkingStatus;
          try {
            status = subject["markingStatus"] == "m4CompleteMarking"
                ? MarkingStatus.m4CompleteMarking
                : subject["markingStatus"] == "m3marking"
                    ? MarkingStatus.m3marking
                    : MarkingStatus.unknown;
          } catch (_) {}
          return Paper(
              examId: subject["examId"],
              paperId: subject["markingPaperId"],
              id: subject["id"],
              answerSheet: subject["dispName"],
              name: subject["subjectName"],
              subjectId: subject["subjectCode"],
              userScore: userScore,
              fullScore: standardScore,
              source: Source.preview,
              markingStatus: status);
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
}
