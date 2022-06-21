import 'package:flutter/material.dart';
import 'package:prescore_flutter/util/login.dart';

import '../util/struct.dart';

class ExamModel extends ChangeNotifier {
  User user = User();

  bool isDiagFetched = false;
  bool isDiagLoaded = false;
  List<PaperDiagnosis> diagnoses = [];

  bool isPaperLoaded = false;
  List<Paper> papers = [];

  void setUser(User value) {
    user = value;
    notifyListeners();
  }

  void setDiagFetched(bool value) {
    isDiagFetched = value;
    notifyListeners();
  }

  void setDiagLoaded(bool value) {
    isDiagLoaded = value;
    notifyListeners();
  }

  void setDiagnoses(List<PaperDiagnosis> value) {
    diagnoses = value;
    notifyListeners();
  }

  void setPaperLoaded(bool value) {
    isPaperLoaded = value;
    notifyListeners();
  }

  void setPapers(List<Paper> value) {
    papers = value;
    notifyListeners();
  }
}
