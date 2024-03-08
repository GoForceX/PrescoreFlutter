import 'package:flutter/material.dart';
import 'package:prescore_flutter/util/user_util.dart';

import '../util/struct.dart';

class ErrorBookModel extends ChangeNotifier {
  User user = User();

  //filter
  DateTime? fromDate;
  DateTime? toTime;
  List<Subject>? subjectCodeList;
  String? selectedSubjectCode;
  int? selectedPageIndex;

  void setUser(User value) {
    user = value;
    notifyListeners();
  }

  void setSubjectCodeList(List<Subject> value) {
    subjectCodeList = value;
    setSubjectCode(value[0].code);
  }

  void setPageIndex(int value) {
    selectedPageIndex = value;
    notifyListeners();
  }

  void setSubjectCode(String value) {
    selectedSubjectCode = value;
    selectedPageIndex = 1;
    notifyListeners();
  }
}
