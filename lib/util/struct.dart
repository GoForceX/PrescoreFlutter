class Session {
  final String st;
  final String sessionId;
  final String xToken;

  Session(this.st, this.sessionId, this.xToken);

  @override
  String toString() {
    return 'Session{st: $st, sessionId: $sessionId, xToken: $xToken}';
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
  String paperId;
  String name;
  String subjectId;
  double userScore;
  double fullScore;
  double? diagnosticScore;

  Paper({
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
  double diagnosticScore;

  PaperDiagnosis({
    required this.subjectId,
    required this.diagnosticScore,
  });

  @override
  String toString() {
    return 'PaperDiagnosis{subjectId: $subjectId, diagnosticScore: $diagnosticScore}';
  }
}