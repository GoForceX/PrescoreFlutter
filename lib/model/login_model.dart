import 'package:flutter/material.dart';
import 'package:prescore_flutter/util/user_util.dart';

import '../util/struct.dart';

class LoginModel extends ChangeNotifier {
  bool isLoggedIn = false;
  bool isLoading = false;
  bool isLoggedOff = false;
  String username = "";
  String password = "";
  User user = User();
  BasicInfo basicInfo = BasicInfo("", "", "", "", "");

  void setLoggedIn(bool value) {
    isLoggedIn = value;
    notifyListeners();
  }

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void setLoggedOff(bool value) {
    isLoggedOff = value;
    notifyListeners();
  }

  void setUsername(String value) {
    username = value;
    notifyListeners();
  }

  void setPassword(String value) {
    password = value;
    notifyListeners();
  }

  void setUser(User value) {
    user = value;
    notifyListeners();
  }
}
