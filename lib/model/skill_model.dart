import 'package:flutter/material.dart';

import '../util/user_util.dart';

class SkillModel extends ChangeNotifier {
  late User user;

  void setUser(User value) {
    user = value;
    notifyListeners();
  }
}
