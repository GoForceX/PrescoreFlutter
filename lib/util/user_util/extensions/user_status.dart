import 'package:dio/dio.dart';
import 'package:prescore_flutter/util/struct.dart';

class User {
  Session? session;
  BasicInfo? basicInfo;
  StudentInfo? studentInfo;
  bool isBasicInfoLoaded = false;
  bool isStudentInfoLoaded = false;
  bool keepLocalSession = false;
  bool autoLogout = true;
  Dio dio = Dio();
  Function reLoginFailedCallback = () {};

  User({this.session});
}
