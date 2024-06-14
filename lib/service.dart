import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:prescore_flutter/main.dart';
import 'package:prescore_flutter/util/struct.dart';
import 'package:prescore_flutter/util/user_util.dart';
import 'package:collection/collection.dart';
//import './util/flutter_log_local/flutter_log_local.dart';

void refreshService() {
  //供主程序调用以刷新服务状态
  var sharedPreferences = BaseSingleton.singleton.sharedPreferences;
  var channelMainActivity = const MethodChannel("MainActivity");
  if (sharedPreferences.getBool("localSessionExist") ?? false) {
    if (sharedPreferences.getBool("enableWearService")! ||
        sharedPreferences.getBool("checkExams")!) {
      channelMainActivity.invokeMethod("startService", {
        "checkExams": sharedPreferences.getBool("checkExams") ?? false,
        "checkExamsInterval":
            sharedPreferences.getInt("checkExamsInterval") ?? 6,
        "selectedWearDeviceUUID":
            sharedPreferences.getString("selectedWearDeviceUUID") ?? "",
        "enableWearService":
            sharedPreferences.getBool("enableWearService") ?? "",
        "showMoreSubject": sharedPreferences.getBool("showMoreSubject") ?? "",
      });
    } else {
      channelMainActivity.invokeMethod('stopService');
    }
  } else {
    channelMainActivity.invokeMethod('stopService');
  }
}

User user = User();
MethodChannel channel = const MethodChannel("PrescoreService");
late Database database;
const String tableName = "ExamList";
const delayFinalTime = 10e6 * 60 * 60 * 24 * 5;
const maxExamCount = 10;
bool showMoreSubject = false;

Logger logger = Logger(
    printer: PrettyPrinter(
        methodCount: 5,
        // number of method calls to be displayed
        errorMethodCount: 8,
        // number of method calls if stacktrace is provided
        lineLength: 120,
        // width of the output
        colors: true,
        // Colorful log messages
        printEmojis: true,
        // Print an emoji for each log message
        printTime: true // Should each log print contain a timestamp
        ));

Future<void> initDataBase() async {
  database = await openDatabase(
    join(await getDatabasesPath(), 'ExamList.db'),
    onCreate: (db, version) async {
      var tableExists = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='$tableName'");
      if (tableExists.isEmpty) {
        logger.d("tableNotExists, CREATE TABLE $tableName");
        db.execute(
          'CREATE TABLE $tableName (id TEXT PRIMARY KEY, subjectList TEXT, isFinal TEXT, finalTime INTEGER)',
        );
      }
    },
    version: 1,
  );
}

Future<void> login({bool force = true}) async {
  //String username = BaseSingleton.singleton.sharedPreferences.getString("username") ?? "";
  //String password = BaseSingleton.singleton.sharedPreferences.getString("password") ?? "";
  //Result result = await user.login(username, password, force: force);
  Result result = await user.loginFromLocal(force: force);
  if (result.state) {
    user.reLoginFailedCallback = () {
      channel.invokeMethod('stopService');
    };
    logger.d(user.session?.xToken);
    if (user.isBasicInfoLoaded) {
      await channel.invokeMethod(
          'setupForeground', '${user.basicInfo?.name} 已登录');
    } else {
      await channel.invokeMethod(
          'setupForeground', '${user.loginCredential.userName} 已登录');
    }
    return;
  } else {
    throw Exception(result.message);
  }
}

Future<Result<String>> fetchSubjectList(
    {int retry = 0, String examId = ""}) async {
  late Result result;
  if (showMoreSubject) {
    result = await user.fetchPreviewPaper(examId, requestScore: false);
  } else {
    result = await user.fetchPaper(examId);
  }

  List subjectList = [];
  if (result.state) {
    for (Paper subject in result.result[0]) {
      if (!showMoreSubject) {
        subjectList.add(subject.name);
      } else if (subject.markingStatus == MarkingStatus.m4CompleteMarking) {
        subjectList.add(subject.name);
      }
    }
    subjectList.sort();
    return Result(state: true, message: "", result: subjectList.toString());
  } else {
    if (retry <= 0) {
      return Result(state: false, message: result.message);
    }
    return fetchSubjectList(retry: retry - 1, examId: examId);
  }
}

Future<Result> checkExams(
    {int retry = 0, bool firstRun = false, Result? errMsg}) async {
  if (retry <= -1) {
    logger.e(errMsg);
    return errMsg ?? Result(state: false, message: "");
  }
  if (!user.isLoggedIn()) {
    try {
      await login(force: false);
    } catch (_) {}
  }
  Result result = Result(state: false, message: "");
  try {
    result = await user.fetchExams(1);
  } catch (e) {
    result = Result(state: false, message: e.toString());
  }
  if (result.state) {
    var trackExamCount = 0;
    for (Exam examRemote in result.result) {
      logger.d("checkExams examRemote : $examRemote");
      List<Map<String, dynamic>> examLocal = await database.query(
        tableName,
        where: 'id = ?',
        whereArgs: [examRemote.uuid],
      );
      logger.d("checkExams examLocal ($database): $examLocal");
      bool newExam = false;
      if (examLocal.isEmpty) {
        //新的考试
        await database.insert(tableName, {
          "id": examRemote.uuid,
          "subjectList": "[]",
          "isFinal": "false",
          "finalTime": -1
        });
        examLocal = await database.query(
          tableName,
          where: 'id = ?',
          whereArgs: [examRemote.uuid],
        );
        if (firstRun == false) {
          channel.invokeMethod(
              "sendNotification", {"text": "考试 ${examRemote.examName} 发布了"});
        }
        newExam = true;
      }
      logger.d(
          "checkExams DelayTime: ${DateTime.now().microsecondsSinceEpoch - examLocal[0]["finalTime"]}");
      if (examLocal[0]["isFinal"] == "false" ||
          (DateTime.now().microsecondsSinceEpoch - examLocal[0]["finalTime"]) <
              delayFinalTime) {
        //本地未标记为关闭的考试
        if (trackExamCount > maxExamCount) {
          //LocalLogger.write("checkExams $trackExamCount 个", isError: false);
          return Result(state: true, message: "Warning：活动考试数量超过限制");
        }
        Result remoteSubjectList =
            await fetchSubjectList(retry: 0, examId: examRemote.uuid);
        trackExamCount += 1;
        if (remoteSubjectList.state) {
          if (remoteSubjectList.result != examLocal[0]["subjectList"] &&
              !newExam &&
              firstRun == false) {
            //科目变动
            channel.invokeMethod("sendNotification", {
              "text": showMoreSubject
                  ? "考试 ${examRemote.examName} 新的科目完成判卷"
                  : "考试 ${examRemote.examName} 发布了新的科目"
            });
          }
          if (remoteSubjectList.result != examLocal[0]["subjectList"] ||
              examRemote.isFinal) {
            //科目变动或远程变更为已关闭
            var finalTime = examLocal[0]["finalTime"];
            if (examRemote.isFinal && firstRun == false && finalTime == -1) {
              finalTime = DateTime.now().microsecondsSinceEpoch;
            }
            await database.update(
                tableName,
                {
                  "id": examRemote.uuid,
                  "subjectList": remoteSubjectList.result,
                  "isFinal": examRemote.isFinal.toString(),
                  "finalTime": finalTime
                },
                where: 'id = ?',
                whereArgs: [examRemote.uuid]);
          }
        } else if (firstRun) {
          return checkExams(
              retry: retry - 1, firstRun: firstRun, errMsg: remoteSubjectList);
        } else {
          logger.e(remoteSubjectList);
        }
        sleep(const Duration(milliseconds: 100));
      }
    }
    //LocalLogger.write("checkExams $trackExamCount 个", isError: false);
    return Result(state: true, message: "");
  } else {
    try {
      //LocalLogger.write("examCheck failed $result", isError: true);
      //if(result.message.contains("oken")) {
    } catch (_) {}
    return checkExams(retry: retry - 1, firstRun: firstRun, errMsg: result);
  }
}

Future<void> serviceMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BaseSingleton.singleton.init();
  await initDataBase();
  Timer? checkExamsTimer;
  user.autoLogout = false;
  if (!user.isLoggedIn()) {
    try {
      await login(force: false);
    } catch (_) {}
  }
  channel.setMethodCallHandler((call) async {
    if (call.method == "changeServiceStatus") {
      showMoreSubject = call.arguments["showMoreSubject"];
      if (call.arguments["checkExams"]) {
        bool isLock = false;
        checkExamsTimer = Timer.periodic(
            Duration(minutes: call.arguments["checkExamsInterval"]),
            (timer) async {
          if (isLock) return;
          isLock = true;
          try {
            await checkExams(retry: 0);
          } finally {
            isLock = false;
          }
        });
      } else {
        if (checkExamsTimer != null) {
          checkExamsTimer?.cancel();
        }
      }
      //LocalLogger.write("changeServiceStatus active: ${checkExamsTimer?.isActive}, interval ${call.arguments["checkExamsInterval"]}", isError: false);
      return Future.value();
    }
    if (call.method != "login" && !user.isLoggedIn()) {
      await login(force: false);
    }
    logger.d("Call arguments: ${call.arguments.toString()}");
    logger.d("Call method : ${call.method}");
    int retry = 2;
    while (retry >= 0) {
      try {
        switch (call.method) {
          case "login":
            {
              login(force: true);
              return Future.value();
            }
          case "fetchExams":
            {
              Result result = await user.fetchExams(1);
              if (result.state) {
                List<Map<String, dynamic>> examJsonList =
                    (result.result as List<Exam>)
                        .map((exam) => exam.toMap())
                        .toList();
                return Future.value(jsonEncode(examJsonList));
              } else {
                throw Exception(result.message);
              }
            }
          case "fetchPaper":
            {
              Future normalPaper = user.fetchPaper(call.arguments["examId"]);
              Future<Result> previewPaper = Future.value(Result(state: true, result: [[], []], message: ''));
              if (showMoreSubject) {
                bool previewScore = BaseSingleton.singleton.sharedPreferences
                        .getBool('tryPreviewScore') ==
                    true;
                previewPaper = user.fetchPreviewPaper(call.arguments["examId"],
                    requestScore: previewScore);
              }
              List<Paper> papers = [];
              List result = await Future.wait([normalPaper, previewPaper]);
              for (Result resultElement in result) {
                if (resultElement.state) {
                  for (Paper paperElement in resultElement.result[0]) {
                    Paper? currentSamePaper = papers.firstWhereOrNull(
                        (item) => item.paperId == paperElement.paperId);
                    if (currentSamePaper != null) {
                      if (currentSamePaper.source != Source.common) {
                        int index = papers.indexOf(currentSamePaper);
                        papers.remove(currentSamePaper);
                        papers.insert(index, paperElement);
                      }
                    } else {
                      papers.add(paperElement);
                    }
                  }
                }
              }
              if (result[0].state) {
                List<Map<String, dynamic>> paperJsonList =
                    papers.map((paper) => paper.toMap()).toList();
                return Future.value(jsonEncode(paperJsonList));
              } else {
                throw Exception(result[0].message);
              }
            }
          case "fetchPaperPercentile":
            {
              Result result = await user.fetchPaperPercentile(
                  call.arguments["examId"],
                  call.arguments["paperId"],
                  double.parse(call.arguments["score"]));
              if (result.state) {
                return Future.value(jsonEncode(result.result
                    .toMap(extraMap: {"paperId": call.arguments["paperId"]})));
              } else {
                throw Exception(result.message);
              }
            }
          case "fetchPaperClassInfo":
            {
              Result result =
                  await user.fetchPaperClassInfo(call.arguments["paperId"]);
              if (result.state) {
                List<Map<String, dynamic>> jsonList =
                    (result.result as List<ClassInfo>)
                        .map((element) => element.toMap())
                        .toList();
                return Future.value(jsonEncode(jsonList));
              } else {
                throw Exception(result.message);
              }
            }
          case "fetchPaperData":
            {
              Result result = await user.fetchPaperData(
                  call.arguments["examId"], call.arguments["paperId"]);
              if (result.state) {
                var jsonList = result.result.toMap();
                for (var element in jsonList["questions"]) {
                  for (var subTopicElement in element["subTopic"]) {
                    try {
                      var subTeacherName = "";
                      for (var name
                          in subTopicElement["teacherMarkingRecords"]) {
                        subTeacherName += (name["teacherName"] + " ");
                      }
                      subTopicElement["subTeacherName"] = subTeacherName;
                      subTopicElement.remove("teacherMarkingRecords");
                    } catch (_) {}
                  }
                }
                return Future.value(jsonEncode(jsonList));
              } else {
                throw Exception(result.message);
              }
            }
          case "fetchMarkingProgress":
            {
              Result result =
                  await user.fetchMarkingProgress(call.arguments["paperId"]);
              if (result.state) {
                List<Map<String, dynamic>> jsonList =
                    (result.result as List<QuestionProgress>)
                        .map((element) => element.toMap())
                        .toList();
                return Future.value(jsonEncode(jsonList));
              } else {
                throw Exception(result.message);
              }
            }
        }
      } catch (e) {
        retry -= 1;
        //LocalLogger.write("wearMethod failed $e", isError: true);
        //await login(force: true);
        if (retry <= 0) {
          rethrow;
        }
      }
    }
    return Future.value(null);
  });
}
