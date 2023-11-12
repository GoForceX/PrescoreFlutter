import 'dart:ui';

class Session {
  String st;
  String sessionId;
  String xToken;
  String userId;
  String? serverToken;

  Session(this.st, this.sessionId, this.xToken, this.userId,
      {this.serverToken});

  @override
  String toString() {
    return 'Session{st: $st, sessionId: $sessionId, xToken: $xToken, userId: $userId, serverToken: $serverToken}';
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

class Exam {
  final String uuid;
  final String examName;
  final String examType;
  final DateTime examTime;

  Exam(
      {required this.uuid,
      required this.examName,
      required this.examType,
      required this.examTime});

  @override
  String toString() {
    return 'Exam{uuid: $uuid, examName: $examName, examType: $examType, examTime: $examTime}';
  }
}

class Paper {
  String examId;
  String paperId;
  String name;
  String subjectId;
  double userScore;
  double fullScore;
  double? assignScore;
  double? diagnosticScore;

  Paper({
    required this.examId,
    required this.paperId,
    required this.name,
    required this.subjectId,
    required this.userScore,
    required this.fullScore,
    this.assignScore,
    this.diagnosticScore,
  });

  @override
  String toString() {
    return 'Paper{examId: $examId, paperId: $paperId, name: $name, subjectId: $subjectId, userScore: $userScore, fullScore: $fullScore, assignScore: $assignScore, diagnosticScore: $diagnosticScore}';
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

class Question {
  String questionId;
  int topicNumber;
  double userScore;
  double fullScore;
  bool isSelected;
  String? selectedAnswer;

  Question({
    required this.questionId,
    required this.topicNumber,
    required this.userScore,
    required this.fullScore,
    required this.isSelected,
    this.selectedAnswer,
  });

  @override
  String toString() {
    return 'Question{questionId: $questionId, userScore: $userScore, fullScore: $fullScore, isSelected: $isSelected, selectedAnswer: $selectedAnswer}';
  }
}

enum MarkerType {
  singleChoice,
  multipleChoice,
  shortAnswer,
  sectionEnd,
  svgPicture,
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
}
