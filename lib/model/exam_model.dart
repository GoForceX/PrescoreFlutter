import 'package:flutter/material.dart';
import 'package:prescore_flutter/util/login.dart';

import '../util/struct.dart';

class ExamModel extends ChangeNotifier {
  User user = User();
  bool isDiagLoaded = false;
  List<PaperDiagnosis> diagnoses = [];

  void setUser(User value) {
    user = value;
    notifyListeners();
  }
}