import 'package:flutter/material.dart';
import 'package:prescore_flutter/util/user_util/extensions/user_status.dart';

import '../util/struct.dart';

class ErrorBookModel extends ChangeNotifier {
  User user = User();
  ErrorBookData? errorBookData;

  DateTime? beginTime;
  DateTime? endTime;

  List<Subject>? subjectCodeList;
  String? selectedSubjectCode;

  int? totalPage;
  int selectedPageIndex = 1;

  Function onChange = () {};

  void setUser(User value) {
    user = value;
    notifyListeners();
  }

  void setSubjectCodeList(List<Subject> value) {
    subjectCodeList = value;
    setSubjectCode(value[0].code);
  }

  void setSubjectCode(String value) {
    selectedSubjectCode = value;
    setErrorBookData(null);
    onChange();
    notifyListeners();
  }

  void setPageIndex(int value) {
    selectedPageIndex = value;
    setErrorBookData(null, cleanTotalPage: false);
    onChange();
    notifyListeners();
  }

  void setFromDate(DateTime? value) {
    beginTime = value;
    setErrorBookData(null);
    onChange();
    notifyListeners();
  }

  void setToDate(DateTime? value) {
    endTime = value;
    setErrorBookData(null);
    onChange();
    notifyListeners();
  }

  void setErrorBookData(ErrorBookData? value, {bool cleanTotalPage = true}) {
    errorBookData = value;
    if (cleanTotalPage) {
      if (errorBookData == null) {
        totalPage = null;
      }
      selectedPageIndex = 1;
    }
    if (errorBookData != null) {
      totalPage = errorBookData?.totalPage;
    }
    notifyListeners();
  }
}
