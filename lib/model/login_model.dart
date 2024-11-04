import 'package:flutter/material.dart';
import 'package:prescore_flutter/util/user_util/extensions/user_status.dart';

import '../util/struct.dart';

class LoginModel extends ChangeNotifier {
  bool isLoggedIn = false;
  bool isLoading = false;
  bool isAutoLogging = false;
  User user = User();
  BasicInfo basicInfo = BasicInfo("", "", "", "", "");

  void setAutoLogging(bool value) {
    isAutoLogging = value;
    notifyListeners();
  }

  void setLoggedIn(bool value) {
    isLoggedIn = value;
    notifyListeners();
  }

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void setUser(User value) {
    user = value;
    notifyListeners();
  }
}
