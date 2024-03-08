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

class LoginCredential {
  String? userName;
  String? password;

  LoginCredential(this.userName, this.password);

  @override
  String toString() {
    return 'LoginCredential{userName: $userName, password: $password';
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

  StudentInfo(this.id, this.loginName, this.name, this.role, this.avatar, this.studentNo, this.gradeName, this.className, this.classId, this.schoolName);

  @override
  String toString() {
    return 'StudentInfo{id: $id, loginName: $loginName, name: $name, role: $role, avatar: $avatar, studentNo: $studentNo, gradeName: $gradeName, className: $className, classId: $classId, schoolName: $schoolName}';
  }
}

class Classmate {
  String name = "";
  String id = "";
  String code = "";
  String gender = "";
  String mobile = "";

  Classmate(this.name, this.id, this.code, this.gender, this.mobile);

  @override
  String toString() {
    return 'StudentInfo{name: $name, id: $id, code: $code, gender: $gender, mobile: $mobile}';
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
  Map<String, dynamic> toMap() {
    return {
      "examId": examId,
      "paperId": paperId,
      "name": name,
      "subjectId": subjectId,
      "userScore": userScore,
      "fullScore": fullScore,
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
  String role;
  double score;
  String teacherId;
  String teacherName;
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
    return 'teacherMarking{score: $score, standradScore: $standradScore, scoreSource: $scoreSource, subQuestionId: $subQuestionId, teacherMarkingRecords: $teacherMarkingRecords}';
  }

  Map<String, dynamic> toMap() {
    List<Map<String, dynamic>> teacherMarkingRecordsJsonList = teacherMarkingRecords.map((element) => element.toMap()).toList();
    return {
      "score": score,
      "standradScore": standradScore,
      "scoreSource": scoreSource,
      "subQuestionId": subQuestionId,
      "teacherMarkingRecords": teacherMarkingRecordsJsonList,
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
  String? selectedAnswer;
  List<QuestionSubTopic> subTopic;
  double? classScoreRate;
  List<MapEntry<String, double>> stepRecords;

  Question({
    required this.questionId,
    required this.topicNumber,
    required this.userScore,
    required this.fullScore,
    required this.isSelected,
    required this.isSubjective,
    required this.subTopic,
    this.selectedAnswer,
    this.classScoreRate,
    required this.stepRecords,
  });

  @override
  String toString() {
    return 'Question{questionId: $questionId, userScore: $userScore, fullScore: $fullScore, isSelected: $isSelected, selectedAnswer: $selectedAnswer, isSubjective: $isSubjective, subTopic: $subTopic, classScoreRate: $classScoreRate, stepRecords: $stepRecords}';
  }
  Map<String, dynamic> toMap() {
    List<Map<String, dynamic>> subTopicJsonList = subTopic.map((element) => element.toMap()).toList();

    return {
      "questionId": questionId,
      "userScore": userScore,
      "fullScore": fullScore,
      "isSubjective" : isSubjective ? "true" : "false",
      "selectedAnswer" : selectedAnswer,
      "subTopic" : subTopicJsonList,
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
  dynamic data;
  ErrorQuestion({
    required this.data
  });
  @override
  String toString() {
    return 'ErrorQuestion{data: $data}';
  }
}

class ErrorBookData {
  String subjectCode;
  int currentPageIndex;
  int totalPage;
  int totalQuestion;
  List<ErrorQuestion> errorQuestion;
  ErrorBookData({
    required this.subjectCode,
    required this.currentPageIndex,
    required this.totalPage,
    required this.totalQuestion,
    required this.errorQuestion
  });
  @override
  String toString() {
    return 'ErrorBookData{subjectCode: $subjectCode, currentPageIndex: $currentPageIndex, totalPage: $totalPage, totalQuestion: $totalQuestion, errorQuestion: $errorQuestion}';
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
    List<Map<String, dynamic>> jsonList = questions.map((element) => element.toMap()).toList();
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
      {required this.percentile,
        required this.count,
        required this.official});

  @override
  String toString() {
    return 'ExamPercentile{percentile: $percentile, count: $count, official: $official}';
  }
}
