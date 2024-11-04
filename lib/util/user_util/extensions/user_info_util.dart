import 'package:prescore_flutter/util/user_util/extensions/user_login_util.dart';
import 'package:prescore_flutter/util/user_util/extensions/user_status.dart';

import 'dart:convert';

//import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:prescore_flutter/main.dart';
import 'package:prescore_flutter/util/struct.dart';
import 'package:prescore_flutter/constants.dart';

extension UserInfoUtil on User {
  /// Get basic info from [zhixueBasicInfoUrl].
  Future<BasicInfo?> fetchBasicInfo(
      {bool force = false, Function? callback}) async {
    Dio client = BaseSingleton.singleton.dio;
    logger.d("fetchBasicInfo, callback: $callback");

    // Check if basic info is loaded.
    // Forcing this means to ignore previous fetched info and fetch again.
    if (isBasicInfoLoaded && !force) {
      if (callback != null) {
        callback(this.basicInfo);
      }
      logger.d("basicInfo: loaded, ${this.basicInfo}");
      return this.basicInfo;
    }

    // Fetch basic info.
    Response response = await client.get(zhixueInfoUrl);
    logger.d("basicInfo: ${response.data}");
    Map<String, dynamic> json = jsonDecode(response.data);
    logger.d("basicInfo: $json");
    if (json["errorCode"] != 200) {
      logger.d("basicInfo: failed");
      return null;
    }
    String avatar = json["result"]["avatar"] ?? "";
    // Parse basic info.
    BasicInfo basicInfo = BasicInfo(
      json["result"]["id"],
      json["result"]["loginName"],
      json["result"]["name"],
      json["result"]["role"],
      avatar,
    );
    this.basicInfo = basicInfo;
    logger.d("basicInfo: $basicInfo");

    // Set this flag so that we don't fetch again.
    isBasicInfoLoaded = true;
    if (callback != null) {
      logger.d("callback");
      callback(basicInfo);
    }
    if (keepLocalSession) {
      await saveLocalSession();
    }
    logger.d("basicInfo: success,  $basicInfo");
    return basicInfo;
  }

  Future<StudentInfo?> fetchStudentInfo(
      {bool force = false, Function? callback}) async {
    Dio client = BaseSingleton.singleton.dio;
    logger.d("fetchStudentInfo, callback: $callback");

    if (isStudentInfoLoaded && !force) {
      if (callback != null) {
        callback(this.studentInfo);
      }
      logger.d("fetchStudentInfo: loaded, ${this.studentInfo}");
      return this.studentInfo;
    }

    BasicInfo? basicInfo = await fetchBasicInfo();

    if (basicInfo != null && basicInfo.role == "parent") {
      Response response = await client.get(zhixueFriendManageUrl);
      logger.d("fetchStudentInfo: ${response.data}");
      Map<String, dynamic> json = jsonDecode(response.data);
      logger.d("fetchStudentInfo: $json");
      if (!json.containsKey("clazzs")) {
        logger.d("fetchStudentInfo: failed");
        return null;
      }

      StudentInfo studentInfo = StudentInfo(
        id: basicInfo.id,
        loginName: basicInfo.loginName,
        name: basicInfo.name,
        role: basicInfo.role,
        avatar: basicInfo.avatar,
        studentNo: "",
        gradeName: json["studentClazz"]["division"]["grade"]["name"],
        className: json["studentClazz"]["name"],
        classId: json["studentClazz"]["id"],
        schoolName: json["studentClazz"]["division"]["school"]["name"],
        schoolId: json["studentClazz"]["division"]["school"]["id"],
      );
      this.studentInfo = studentInfo;
      logger.d("fetchStudentInfo: $studentInfo");

      isStudentInfoLoaded = true;
      if (callback != null) {
        logger.d("callback");
        callback(studentInfo);
      }
      logger.d("fetchStudentInfo: success, $studentInfo");
      return studentInfo;
    }

    Response response = await client.get(zhixueStudentAccountUrl);
    logger.d("fetchStudentInfo: ${response.data}");
    Map<String, dynamic> json = jsonDecode(response.data);
    logger.d("fetchStudentInfo: $json");

    if (!json.containsKey("student")) {
      return null;
    }
    String avatar = json["student"]["avatar"] ?? "";

    StudentInfo studentInfo = StudentInfo(
      id: json["student"]["id"],
      loginName: json["student"]["loginName"],
      name: json["student"]["name"],
      role: json["student"]["roles"][0]["eName"],
      avatar: avatar,
      studentNo: json["student"]["studentNo"],
      gradeName: json["student"]["clazz"]["grade"]["name"],
      className: json["student"]["clazz"]["name"],
      classId: json["student"]["clazz"]["id"],
      schoolName: json["student"]["clazz"]["school"]["name"],
      schoolId: json["student"]["clazz"]["school"]["id"],
    );
    this.studentInfo = studentInfo;
    logger.d("fetchStudentInfo: $studentInfo");

    isStudentInfoLoaded = true;
    if (callback != null) {
      logger.d("callback");
      callback(studentInfo);
    }
    logger.d("fetchStudentInfo: success,  $studentInfo");
    return studentInfo;
  }

  Future<List<Classmate>> fetchClassmate() async {
    await fetchStudentInfo();
    Dio client = BaseSingleton.singleton.dio;
    Response response = await client.get(
        "$zhixueClassmatesUrl?r=${studentInfo?.id}student&clazzId=${studentInfo?.classId}");
    logger.d("fetchClassmate: ${response.data}");
    List<dynamic> json = jsonDecode(response.data);
    List<Classmate> classmates = [];
    for (var classmate in json) {
      classmates.add(Classmate(
        name: classmate["name"],
        id: classmate["id"],
        code: classmate["code"],
        gender: classmate["gender"] == 1 ? Gender.female : Gender.male,
        mobile: classmate["mobile"],
      ));
    }
    logger.d("fetchClassmate: $classmates");
    return classmates;
  }

  @Deprecated("Unstable API, use [studentInfo.schoolId] instead.")
  Future<Result<List<String>>> fetchSchoolList(String paperId) async {
    Dio client = BaseSingleton.singleton.dio;
    if (session == null) {
      return Result(state: false, message: "未登录");
    }

    Response response =
        await client.get("$zhixueSchoolListUrl?markingPaperId=$paperId");
    logger.d("fetchSchoolList: ${response.data}, $paperId");
    Map<String, dynamic> json = jsonDecode(response.data);
    if (json["result"] != "success") {
      return Result(state: false, message: json["message"]);
    }

    List<String> schoolList = [];
    for (var element in jsonDecode(json["message"])) {
      schoolList.add(element["schoolId"]);
    }

    return Result(state: true, result: schoolList, message: "");
  }
}
