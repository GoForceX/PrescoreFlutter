import 'package:flutter/material.dart';
import 'package:prescore_flutter/util/user_util/extensions/user_status.dart';

import '../util/struct.dart';

class PaperModel extends ChangeNotifier {
  User user = User();
  bool isDataLoaded = false;
  PaperData? paperData;
  String? errMsg;

  void setUser(User value) {
    user = value;
    notifyListeners();
  }

  void setErrMsg(String value) {
    errMsg = value;
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
