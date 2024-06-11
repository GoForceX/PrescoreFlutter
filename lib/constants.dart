import 'package:flutter/material.dart';
import 'package:prescore_flutter/main.dart';

const Map<String, String> commonHeaders = {
  "user-agent":
      userAgent,
};
const String userAgent =
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.5005.124 Safari/537.36 Edg/102.0.1245.41";

const String changyanSSOUrl =
    "https://sso.zhixue.com/sso_alpha/login?service=https://www.zhixue.com:443/ssoservice.jsp";

const String zhixueBaseUrl = "https://www.zhixue.com";
const String zhixueBaseUrl_2 = "https://pt-ali-bj.zhixue.com";

const String wapLoginUrl = "$zhixueBaseUrl/wap_login.html";
const String loginNoThirdCookieUrl = "$zhixueBaseUrl/login_no_third_cookie.html";

const String zhixueLoginUrl = "$zhixueBaseUrl/ssoservice.jsp";
const String zhixueXTokenUrl = "$zhixueBaseUrl/addon/error/book/index";
const String zhixueInfoUrl = "$zhixueBaseUrl/container/getCurrentUser";
const String zhixueStudentAccountUrl = "$zhixueBaseUrl/container/container/student/account/";
const String zhixueLoginStatusUrl = "$zhixueBaseUrl/loginState/";
const String zhixueClassmatesUrl = "$zhixueBaseUrl/container/contact/student/students";

const String zhixueServiceUrl = "$zhixueBaseUrl/zhixuebao";
const String zhixueExamListUrl =
    "$zhixueServiceUrl/report/exam/getUserExamList";
const String zhixueNewExamAnswerSheetUrl = "$zhixueBaseUrl/exam/examcenter/getNewExamAnswerSheetList";
const String zhixueMarkingProgressUrl = "$zhixueBaseUrl/marking/marking/markingTopicProgress";
const String zhixueReportUrl = "$zhixueServiceUrl/report/exam/getReportMain";
const String zhixueDiagnosisUrl =
    "$zhixueServiceUrl/report/exam/getSubjectDiagnosis";
const String zhixueChecksheetUrl = "$zhixueServiceUrl/report/checksheet/";
const String zhixueTrendUrl = "$zhixueServiceUrl/report/paper/getLevelTrend";
const String zhixueTranscriptUrl = "$zhixueServiceUrl/zhixuebao/transcript/analysis/main/";
const String zhixuePaperClassList = "$zhixueBaseUrl/api-cloudmarking-scan/scanImageRecord/findPaperClassList/";
const String zhixuePaperClassList_2 = "$zhixueBaseUrl_2/api-cloudmarking-scan/scanImageRecord/findPaperClassList/";
const String zhixueSchoolListUrl = "$zhixueBaseUrl/api-cloudmarking-scan/common/findSchoolList/";
const String zhixueFriendManageUrl = "$zhixueServiceUrl/zhixuebao/friendmanage/";

const String zhixueErrorbookSubjectListUrl = "$zhixueBaseUrl/addon/app/errorbook/getSubjects";
const String zhixueErrorbookPapersListUrl = "$zhixueBaseUrl/addon/app/errorbook/getPapers";
const String zhixueErrorbookListUrl = "$zhixueBaseUrl/addon/app/errorbook/getErrorbookList";

//const String telemetryBaseUrl = "https://matrix.bjbybbs.com/api";
//const String telemetryBaseUrl = "https://matrix.npcstation.com/api";

String get telemetryBaseUrl => BaseSingleton.singleton.sharedPreferences.getString('telemetryBaseUrl') ?? "https://matrix.npcstation.com/api";

String get telemetryLoginUrl => "$telemetryBaseUrl/token";
String get telemetrySubmitUrl => "$telemetryBaseUrl/exam/submit";
String get telemetryExamPredictUrl => "$telemetryBaseUrl/exam/predict";
String get telemetryPaperPredictUrl => "$telemetryBaseUrl/paper/predict";
String get telemetryPaperDistributionUrl => "$telemetryBaseUrl/paper/distribute";
String get telemetryExamScoreInfoUrl => "$telemetryBaseUrl/exam/score_info";
String get telemetryPaperScoreInfoUrl => "$telemetryBaseUrl/paper/score_info";
String get telemetryExamClassInfoUrl => "$telemetryBaseUrl/exam/class_info";
String get telemetryPaperClassInfoUrl => "$telemetryBaseUrl/paper/class_info";

const Map<String, Color> brandColorMap = {
  "红粉色": Colors.pink,
  "赤红色": Colors.red,
  "橙黄色": Colors.orange,
  "琥珀橙": Colors.amber,
  "柠檬黄": Colors.yellow,
  "石灰黄": Colors.lime,
  "青绿色": Colors.lightGreen,
  "草绿色": Colors.green,
  "茶绿色": Colors.teal,
  "蓝绿色": Colors.cyan,
  "淡蓝色": Colors.lightBlue,
  "天蓝色": Colors.blue,
  "靛蓝色": Colors.indigo,
  "丁香紫": Colors.purple,
  "黛紫色": Colors.deepPurple,
  "灰蓝色": Colors.blueGrey,
  "赭褐色": Colors.brown,
  "苍灰色": Colors.grey,
};