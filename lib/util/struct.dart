import 'dart:math';
import 'dart:ui';

class SsoInfo {
  String tgt;
  String at;
  String userId;

  SsoInfo({required this.tgt, required this.at, required this.userId});

  @override
  String toString() {
    return 'SsoInfo{tgt: $tgt, at: $at, userId: $userId}';
  }
}

enum LoginType {
  webview,
  app,
  parWeakCheckLogin;

  static LoginType getTypeByName(String name) =>
      LoginType.values.firstWhere((type) => type.name == name);
}

class Session {
  String? loginName;
  String? password;
  String? tgt;
  String? st;
  String sessionId;
  String xToken;
  LoginType loginType;
  String? userId;
  String? serverToken;

  Session(
      {this.loginName,
      this.password,
      this.tgt,
      this.st,
      required this.sessionId,
      required this.xToken,
      required this.loginType,
      this.userId,
      this.serverToken});

  @override
  String toString() {
    return 'Session{loginName: $loginName, password:$password, tgt: $tgt, st: $st, sessionId: $sessionId, xToken: $xToken, userId: $userId, serverToken: $serverToken, loginType: $loginType}';
  }
}

class BasicInfo {
  String id = "";
  String loginName = "";
  String name = "";
  String role = "";
  String avatar = "";

  BasicInfo(this.id, this.loginName, this.name, this.role, this.avatar);

  @override
  String toString() {
    return 'BasicInfo{id: $id, loginName: $loginName, name: $name, role: $role, avatar: $avatar}';
  }
}

class StudentInfo {
  String id = "";
  String loginName = "";
  String name = "";
  String role = "";
  String avatar = "";
  String studentNo = "";
  String gradeName = "";
  String className = "";
  String classId = "";
  String schoolName = "";
  String schoolId = "";

  StudentInfo(
      {required this.id,
      required this.loginName,
      required this.name,
      required this.role,
      required this.avatar,
      required this.studentNo,
      required this.gradeName,
      required this.className,
      required this.classId,
      required this.schoolName,
      required this.schoolId});

  @override
  String toString() {
    return 'StudentInfo{id: $id, loginName: $loginName, name: $name, role: $role, avatar: $avatar, studentNo: $studentNo, gradeName: $gradeName, className: $className, classId: $classId, schoolName: $schoolName}';
  }
}

enum Gender {
  male,
  female,
}

class Classmate {
  String name = "";
  String id = "";
  String code = "";
  Gender gender;
  String mobile = "";

  Classmate(
      {required this.name,
      required this.id,
      required this.code,
      required this.gender,
      required this.mobile});

  @override
  String toString() {
    return 'Classmate{name: $name, id: $id, code: $code, gender: $gender, mobile: $mobile}';
  }
}

class Exam {
  final String uuid;
  final String examName;
  final String examType;
  final DateTime examTime;
  final bool isFinal;

  Exam(
      {required this.uuid,
      required this.examName,
      required this.examType,
      required this.examTime,
      required this.isFinal});

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'examName': examName,
      'examType': examType,
      'examTime': examTime.toString(),
      'isFinal': isFinal
    };
  }

  @override
  String toString() {
    return 'Exam{uuid: $uuid, examName: $examName, examType: $examType, examTime: $examTime, isFinal: $isFinal}';
  }
}

enum Source {
  common,
  preview,
}

enum MarkingStatus {
  unknown,
  m4CompleteMarking,
  m3marking,
  m2startScan,
  noMarkingStatus
}

class Paper {
  String examId;
  String? id;
  String? answerSheet;
  String? paperId;
  String name;
  String subjectId;
  double? userScore;
  double? fullScore;
  double? assignScore;
  double? diagnosticScore;
  MarkingStatus markingStatus = MarkingStatus.unknown;
  Source source;

  Paper(
      {required this.examId,
      required this.paperId,
      required this.name,
      required this.subjectId,
      required this.userScore,
      required this.fullScore,
      required this.source,
      this.assignScore,
      this.id,
      this.answerSheet,
      this.diagnosticScore,
      this.markingStatus = MarkingStatus.unknown});

  @override
  String toString() {
    return 'Paper{examId: $examId, id: $id, answerSheet: $answerSheet, paperId: $paperId, name: $name, subjectId: $subjectId, userScore: $userScore, fullScore: $fullScore, assignScore: $assignScore, diagnosticScore: $diagnosticScore, source: $source}';
  }

  Map<String, dynamic> toMap() {
    String sourceStr = "";
    if (source == Source.common) {
      sourceStr = "common";
    } else if (source == Source.preview) {
      sourceStr = "preview";
    }
    return {
      "examId": examId,
      "paperId": paperId,
      "name": name,
      "subjectId": subjectId,
      "userScore": userScore,
      "fullScore": fullScore,
      "source": sourceStr,
    };
  }
}

class QuestionProgress {
  String dispTitle;
  int allCount;
  int realCompleteCount;
  QuestionProgress({
    required this.dispTitle,
    required this.allCount,
    required this.realCompleteCount,
  });

  @override
  String toString() {
    return 'QuestionProgress{dispTitle: $dispTitle, allCount: $allCount, realCompleteCount: $realCompleteCount}';
  }

  Map<String, dynamic> toMap() {
    return {
      "dispTitle": dispTitle,
      "allCount": allCount,
      "realCompleteCount": realCompleteCount
    };
  }
}

class PaperDiagnosis {
  String subjectId;
  String subjectName;
  double diagnosticScore;

  PaperDiagnosis({
    required this.subjectId,
    required this.subjectName,
    required this.diagnosticScore,
  });

  @override
  String toString() {
    return 'PaperDiagnosis{subjectId: $subjectId, diagnosticScore: $diagnosticScore}';
  }
}

class ExamDiagnosis {
  String tips;
  String subTips;
  List<PaperDiagnosis> diagnoses;

  ExamDiagnosis({
    required this.tips,
    required this.subTips,
    required this.diagnoses,
  });

  @override
  String toString() {
    return 'ExamDiagnosis{tips: $tips, subTips: $subTips, diagnoses: $diagnoses}';
  }
}

class TeacherMarking {
  String? role;
  double score;
  String? teacherId;
  String? teacherName;
  TeacherMarking({
    required this.role,
    required this.score,
    required this.teacherId,
    required this.teacherName,
  });

  @override
  String toString() {
    return 'TeacherMarking{role: $role, score: $score, teacherId: $teacherId, teacherName: $teacherName}';
  }

  Map<String, dynamic> toMap() {
    return {
      "role": role,
      "score": score,
      "teacherId": teacherId,
      "teacherName": teacherName,
    };
  }
}

class QuestionSubTopic {
  double score;
  double? standradScore;
  String? scoreSource;
  String subQuestionId;
  List<TeacherMarking> teacherMarkingRecords;
  QuestionSubTopic({
    required this.score,
    required this.standradScore,
    required this.scoreSource,
    required this.subQuestionId,
    required this.teacherMarkingRecords,
  });

  @override
  String toString() {
    return 'QuestionSubTopic{score: $score, standradScore: $standradScore, scoreSource: $scoreSource, subQuestionId: $subQuestionId, teacherMarkingRecords: $teacherMarkingRecords}';
  }

  Map<String, dynamic> toMap() {
    List<Map<String, dynamic>> teacherMarkingRecordsJsonList =
        teacherMarkingRecords.map((element) => element.toMap()).toList();
    return {
      "score": score,
      "standradScore": standradScore,
      "scoreSource": scoreSource,
      "subQuestionId": subQuestionId,
      "teacherMarkingRecords": teacherMarkingRecordsJsonList,
    };
  }
}

class PaperClass {
  int? absentCount;
  String? clazzId;
  String? clazzName;
  int? planNumber;
  int? scanCount;

  PaperClass({
    this.absentCount,
    this.clazzId,
    this.clazzName,
    this.planNumber,
    this.scanCount,
  });

  @override
  String toString() {
    return 'PaperClass{absentCount: $absentCount, clazzId: $clazzId, clazzName: $clazzName, planNumber: $planNumber, scanCount: $scanCount}';
  }

  Map<String, dynamic> toMap() {
    return {
      "absentCount": absentCount,
      "clazzId": clazzId,
      "clazzName": clazzName,
      "planNumber": planNumber,
      "scanCount": scanCount,
    };
  }
}

class Question {
  String questionId;
  int topicNumber;
  double userScore;
  double fullScore;
  bool isSelected;
  bool isSubjective;
  bool markingContentsExist;
  String? selectedAnswer;
  List<QuestionSubTopic> subTopic;
  double? classScoreRate;
  String? userAnswer;
  String? standardAnswer;
  String? answerHtml;
  List<MapEntry<String, double>> stepRecords;

  Question({
    required this.questionId,
    required this.topicNumber,
    required this.userScore,
    required this.fullScore,
    required this.isSelected,
    required this.isSubjective,
    required this.subTopic,
    required this.markingContentsExist,
    this.selectedAnswer,
    this.userAnswer,
    this.standardAnswer,
    this.answerHtml,
    this.classScoreRate,
    required this.stepRecords,
  });

  @override
  String toString() {
    return 'Question{questionId: $questionId, userScore: $userScore, fullScore: $fullScore, isSelected: $isSelected, selectedAnswer: $selectedAnswer, isSubjective: $isSubjective, subTopic: $subTopic, classScoreRate: $classScoreRate, stepRecords: $stepRecords}';
  }

  Map<String, dynamic> toMap() {
    List<Map<String, dynamic>> subTopicJsonList =
        subTopic.map((element) => element.toMap()).toList();

    return {
      "questionId": questionId,
      "userScore": userScore,
      "fullScore": fullScore,
      "isSubjective": isSubjective ? "true" : "false",
      "selectedAnswer": selectedAnswer,
      "subTopic": subTopicJsonList,
    };
  }
}

enum MarkerType {
  singleChoice,
  multipleChoice,
  shortAnswer,
  sectionEnd,
  detailScoreEnd,
  svgPicture,
  cutBlock,
}

class Marker {
  MarkerType type;
  int sheetId;
  double top;
  double left;
  double topOffset;
  double leftOffset;
  double height;
  double width;
  Color color;
  String message;

  Marker({
    required this.type,
    required this.sheetId,
    required this.top,
    required this.left,
    required this.topOffset,
    required this.leftOffset,
    required this.height,
    required this.width,
    required this.color,
    required this.message,
  });

  @override
  String toString() {
    return 'Marker{type: $type, sheetId: $sheetId, top: $top, left: $left, topOffset: $topOffset, leftOffset: $leftOffset, height: $height, width: $width, color: $color, message: $message}';
  }
}

class Subject {
  String code;
  String name;
  Subject({
    required this.code,
    required this.name,
  });
  @override
  String toString() {
    return 'Subject{code: $code, name: $name}';
  }
}

class ErrorQuestion {
  int? topicNumber;
  String? contentHtml;
  String? analysisHtml;
  String? difficultyName;
  List<dynamic>? knowledgeNames;
  String? topicSourcePaperName;
  dynamic userAnswer;
  double? standardScore;
  double? userScore;

  ErrorQuestion(
      {required this.topicNumber,
      required this.analysisHtml,
      required this.contentHtml,
      required this.difficultyName,
      required this.knowledgeNames,
      required this.topicSourcePaperName,
      required this.userAnswer,
      required this.standardScore,
      required this.userScore});
  @override
  String toString() {
    return 'ErrorQuestion{TopicNumber: $topicNumber, analysisHtml: $analysisHtml, contentHtml: $contentHtml, difficultyName: $difficultyName, knowledgeNames: $knowledgeNames, topicSourcePaperName: $topicSourcePaperName, userAnswer: $userAnswer, standardScore: $standardScore, userScore: $userScore}';
  }
}

class ErrorBookData {
  String subjectCode;
  int currentPageIndex;
  int totalPage;
  int totalQuestion;
  List<ErrorQuestion> errorQuestions;
  ErrorBookData(
      {required this.subjectCode,
      required this.currentPageIndex,
      required this.totalPage,
      required this.totalQuestion,
      required this.errorQuestions});
  @override
  String toString() {
    return 'ErrorBookData{subjectCode: $subjectCode, currentPageIndex: $currentPageIndex, totalPage: $totalPage, totalQuestion: $totalQuestion, errorQuestion: $errorQuestions}';
  }
}

class PaperData {
  String examId;
  String paperId;
  List<String> sheetImages;
  List<Question> questions;
  List<Marker> markers;

  PaperData({
    required this.examId,
    required this.paperId,
    required this.sheetImages,
    required this.questions,
    required this.markers,
  });

  @override
  String toString() {
    return 'PaperData{examId: $examId, paperId: $paperId, sheetImages: $sheetImages, questions: $questions, markers: $markers}';
  }

  Map<String, dynamic> toMap() {
    List<Map<String, dynamic>> jsonList =
        questions.map((element) => element.toMap()).toList();
    return {
      "examId": examId,
      "paperId": paperId,
      "questions": jsonList,
    };
  }
}

class Result<T> {
  bool state;
  String message;
  T? result;

  Result({required this.state, required this.message, this.result});

  @override
  String toString() {
    return 'Result{state: $state, message: $message, result: $result}';
  }
}

class ScoreInfo {
  double max;
  double min;
  double avg;
  double med;

  ScoreInfo(
      {required this.max,
      required this.min,
      required this.avg,
      required this.med});

  @override
  String toString() {
    return 'ScoreInfo{max: $max, min: $min, avg: $avg, med: $med}';
  }
}

class ClassInfo {
  String classId;
  String className;
  int count;
  double max;
  double min;
  double avg;
  double med;

  ClassInfo(
      {required this.classId,
      required this.className,
      required this.count,
      required this.max,
      required this.min,
      required this.avg,
      required this.med});

  @override
  String toString() {
    return 'ClassInfo{classId: $classId, className: $className, count: $count, max: $max, min: $min, avg: $avg, med: $med}';
  }

  Map<String, dynamic> toMap() {
    return {
      "classId": classId,
      "className": className,
      "count": count,
      "max": max,
      "min": min,
      "avg": avg,
      "med": med,
    };
  }
}

class PaperPercentile {
  double percentile;
  int count;
  int version;
  bool official;

  PaperPercentile(
      {required this.percentile,
      required this.count,
      required this.version,
      required this.official});

  @override
  String toString() {
    return 'PaperPercentile{percentile: $percentile, count: $count, version: $version, official: $official}';
  }

  Map<String, dynamic> toMap({Map<String, dynamic> extraMap = const {}}) {
    Map<String, dynamic> originMap = {
      "percentile": percentile,
      "count": count,
      "version": version,
      "official": official
    };
    originMap.addAll(extraMap);
    return originMap;
  }
}

class ExamPercentile {
  double percentile;
  int count;
  bool official;

  ExamPercentile(
      {required this.percentile, required this.count, required this.official});

  @override
  String toString() {
    return 'ExamPercentile{percentile: $percentile, count: $count, official: $official}';
  }
}

class DistributionData {
  List<DistributionScoreItem> distribute;
  List<DistributionScoreItem> prefix;
  List<DistributionScoreItem> suffix;

  DistributionData(
      {List<DistributionScoreItem>? distribute,
      List<DistributionScoreItem>? prefix,
      List<DistributionScoreItem>? suffix})
      : distribute = distribute ?? [],
        prefix = prefix ?? [],
        suffix = suffix ?? [];

  @override
  String toString() {
    return 'PaperDistribution{distribute: $distribute, prefix: $prefix, suffix: $suffix}';
  }
}

extension DistributionScoreItemExtension on List<DistributionScoreItem> {
  List<DistributionScoreItem> withStep(int step) {
    Map<int, int> score = {};
    for (var element in this) {
      int index = element.score ~/ step;
      score[index] = (score[index] ?? 0) + element.sum;
    }
    List<DistributionScoreItem> res = [];
    score.forEach((key, value) {
      res.add(
          DistributionScoreItem(score: (key * step).toDouble(), sum: value));
    });
    res.sort((a, b) => a.score.compareTo(b.score));
    return res;
  }

  List<DistributionScoreItem> removeFrontZero() {
    bool allZero = true;
    List<DistributionScoreItem> res = [];
    for (var element in this) {
      if (element.sum == 0 && allZero) continue;
      allZero = false;
      res.add(element);
    }
    return res;
  }

  List<DistributionScoreItem> removeEndMax() {
    bool allMax = true;
    List<DistributionScoreItem> res = [];
    for (var i = length - 1; i >= 0; i--) {
      var element = this[i];
      if (element.sum == getMaxSum() && allMax) continue;
      allMax = false;
      res.add(element);
    }
    return res;
  }

  int getMaxSum() {
    int res = 0;
    for (var element in this) {
      res = max(res, element.sum);
    }
    return res;
  }

  int getTotalSum() {
    return fold(0, (sum, item) => sum + item.sum);
  }
}

class DistributionScoreItem {
  double score;
  int sum;

  DistributionScoreItem({required this.score, required this.sum});

  @override
  String toString() {
    return 'DistributionScoreItem{score: $score, sum: $sum}';
  }
}
