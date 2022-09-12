import 'package:flutter/material.dart';
import 'package:prescore_flutter/util/user_util.dart';

import '../util/struct.dart';

class PaperModel extends ChangeNotifier {
  User user = User();
  bool isDataLoaded = false;
  PaperData? paperData;

  void setUser(User value) {
    user = value;
    notifyListeners();
  }

  void setDataLoaded(bool value) {
    isDataLoaded = value;
    notifyListeners();
  }

  void setPaperData(PaperData? value) {
    paperData = value;
    notifyListeners();
  }
}
