const Map<String, String> commonHeaders = {
  "User-Agent":
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.5005.124 Safari/537.36 Edg/102.0.1245.41",
};

const String changyanSSOUrl =
    "https://open.changyan.com/sso/login?sso_from=zhixuesso&service=https%3A%2F%2Fwww.zhixue.com:443%2Fssoservice.jsp";

const String zhixueBaseUrl = "https://www.zhixue.com";

const String zhixueLoginUrl = "$zhixueBaseUrl/ssoservice.jsp";
const String zhixueXTokenUrl = "$zhixueBaseUrl/addon/error/book/index";
const String zhixueInfoUrl = "$zhixueBaseUrl/container/getCurrentUser";

const String zhixueServiceUrl = "$zhixueBaseUrl/zhixuebao";
const String zhixueExamListUrl =
    "$zhixueServiceUrl/report/exam/getUserExamList";
const String zhixueReportUrl = "$zhixueServiceUrl/report/exam/getReportMain";
const String zhixueDiagnosisUrl =
    "$zhixueServiceUrl/report/exam/getSubjectDiagnosis";
const String zhixueChecksheetUrl = "$zhixueServiceUrl/report/checksheet/";

const String telemetryBaseUrl = "https://matrix.bjbybbs.com/api";

const String telemetryLoginUrl = "$telemetryBaseUrl/token";
const String telemetrySubmitUrl = "$telemetryBaseUrl/exam/submit";
const String telemetryExamPredictUrl = "$telemetryBaseUrl/exam/predict";
const String telemetryPaperPredictUrl = "$telemetryBaseUrl/paper/predict";
const String telemetryExamScoreInfoUrl = "$telemetryBaseUrl/exam/score_info";
const String telemetryPaperScoreInfoUrl = "$telemetryBaseUrl/paper/score_info";
const String telemetryExamClassInfoUrl = "$telemetryBaseUrl/exam/class_info";
const String telemetryPaperClassInfoUrl = "$telemetryBaseUrl/paper/class_info";