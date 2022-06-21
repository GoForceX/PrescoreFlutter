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
  double? diagnosticScore;

  Paper({
    required this.examId,
    required this.paperId,
    required this.name,
    required this.subjectId,
    required this.userScore,
    required this.fullScore,
    this.diagnosticScore,
  });

  @override
  String toString() {
    return 'Paper{paperId: $paperId, name: $name, subjectId: $subjectId, userScore: $userScore, fullScore: $fullScore, diagnosticScore: $diagnosticScore}';
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

class Question {
  String questionId;
  double userScore;
  double fullScore;

  Question({
    required this.questionId,
    required this.userScore,
    required this.fullScore,
  });

  @override
  String toString() {
    return 'Question{questionId: $questionId, userScore: $userScore, fullScore: $fullScore}';
  }
}

class PaperData {
  String examId;
  String paperId;
  List<String> sheetImages;
  List<Question> questions;

  PaperData({
    required this.examId,
    required this.paperId,
    required this.sheetImages,
    required this.questions,
  });

  @override
  String toString() {
    return 'PaperData{examId: $examId, paperId: $paperId, sheetImages: $sheetImages, questions: $questions}';
  }
}
