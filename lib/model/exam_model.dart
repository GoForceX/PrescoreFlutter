import 'package:flutter/material.dart';
import 'package:prescore_flutter/util/user_util.dart';

import '../util/struct.dart';

class ExamModel extends ChangeNotifier {
  User user = User();

  bool isDiagFetched = false;
  bool isDiagLoaded = false;
  List<PaperDiagnosis> diagnoses = [];
  String tips = "";
  String subTips = "";

  bool isPaperLoaded = false;
  List<Paper> papers = [];
  List<Paper> absentPapers = [];

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

  void setTips(String value) {
    tips = value;
    notifyListeners();
  }

  void setSubTips(String value) {
    subTips = value;
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

  void setAbsentPapers(List<Paper> value) {
    absentPapers = value;
    notifyListeners();
  }
}
