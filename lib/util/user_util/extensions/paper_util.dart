import 'dart:convert';

import '../user_util.dart';

import 'package:html/parser.dart';
import 'package:html/dom.dart' as dom;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:prescore_flutter/main.dart';
import 'package:prescore_flutter/util/struct.dart';
import 'package:prescore_flutter/constants.dart';

extension PaperUtil on User {
  /// Fetch exam report from [zhixueMarkingProgressUrl].
  Future<Result<List<QuestionProgress>>> fetchMarkingProgress(
      String paperId) async {
    Dio client = BaseSingleton.singleton.dio;

    if (session == null) {
      return Result(state: false, message: "未登录");
    }
    Response response =
        await client.get("$zhixueMarkingProgressUrl_2?markingPaperId=$paperId");
    logger.d("fetchMarkingProgress, data: ${response.data}");
    List<Map<String, dynamic>> json =
        (jsonDecode(response.data) as List<dynamic>).map((item) {
      return item as Map<String, dynamic>;
    }).toList();
    bool allZero = true;
    for (var element in json) {
      if (element["realCompleteCount"] != 0) {
        allZero = false;
        break;
      }
    }
    if (allZero) {
      Response response =
          await client.get("$zhixueMarkingProgressUrl?markingPaperId=$paperId");
      logger.d("fetchMarkingProgress, data: ${response.data}");
      json = (jsonDecode(response.data) as List<dynamic>).map((item) {
        return item as Map<String, dynamic>;
      }).toList();
    }

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
            question.standardAnswer = data["standardAnswer"];
            question.answerHtml = data["answerHtml"];
            question.userAnswer = data["userAnswer"];
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
    StudentInfo? stuInfo = await fetchStudentInfo();
    if (stuInfo == null) {
      return Result(state: false, message: "未登录");
    }

    Dio client = BaseSingleton.singleton.dio;
    if (session == null) {
      return Result(state: false, message: "未登录");
    }

    Response response = await client.get(
        "$zhixuePaperClassList?markingPaperId=$paperId&isViewUser=false&schoolId=${stuInfo.schoolId}",
        options: Options(headers: {"Token": session?.xToken}));
    Map<String, dynamic> result = jsonDecode(response.data);
    bool validData = false;
    if (result["result"] == "success") {
      for (var element in jsonDecode(result["message"])) {
        if (element["scanCount"] != 0) {
          validData = true;
        }
      }
    }
    if (!validData) {
      response = await client.get(
          "$zhixuePaperClassList_2?mdarkingPaperId=$paperId&isViewUser=false&schoolId=${stuInfo.schoolId}",
          options: Options(headers: {"Token": session?.xToken}));
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
    Map<String, dynamic> json;
    if (response.data == "") {
      return Result(state: false, message: "无数据");
    }
    try {
      json = jsonDecode(response.data);
    } catch (_) {
      return Result(state: false, message: "数据解析失败");
    }
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

  Future<Result<PaperPercentile>> fetchPapersPercentile(
      List<String> paperIds, double score) async {
    Result<List<dynamic>> pred = await fetchPapersPredict(paperIds, score);
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
