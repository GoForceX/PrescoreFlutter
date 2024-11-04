import 'dart:convert';
import 'dart:typed_data';

//import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';
import 'package:pointycastle/export.dart';
import 'package:prescore_flutter/main.dart';
import 'package:prescore_flutter/util/struct.dart';
import 'package:prescore_flutter/util/user_util/extensions/user_info_util.dart';
import 'package:prescore_flutter/util/user_util/extensions/user_status.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_rc4/simple_rc4.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:prescore_flutter/constants.dart';
import 'package:synchronized/synchronized.dart';

const String userSession = "userSession";
final Lock databaseLock = Lock();

Future<Database> initLocalSessionDataBase() async {
  return await openDatabase(
    path.join(await getDatabasesPath(), 'UserSessionV4.db'),
    onCreate: (db, version) async {
      var tableExists = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='$userSession'");
      if (tableExists.isEmpty) {
        logger.d("tableNotExists, CREATE TABLE $userSession");
        db.execute(
          'CREATE TABLE $userSession (loginName TEXT, password TEXT, userId TEXT, st TEXT, tgt TEXT, sessionId TEXT, xToken TEXT, loginType TEXT, serverToken TEXT, basicInfo_id TEXT, basicInfo_loginName TEXT, basicInfo_name TEXT, basicInfo_role TEXT, basicInfo_avatar TEXT)',
        );
      }
    },
    version: 1,
  );
}

extension LoginUtil on User {
  bool isLoggedIn() {
    if (session == null) {
      return false;
    }
    return true;
  }

  Future<Session> readLocalSession() async {
    SharedPreferences sharedPrefs = BaseSingleton.singleton.sharedPreferences;
    return await databaseLock.synchronized(() async {
      Database database = await initLocalSessionDataBase();
      List<Map<String, Object?>> list =
          await database.rawQuery('SELECT * FROM $userSession');
      if (list.length == 1) {
        sharedPrefs.setBool("localSessionExist", true);
        Session localSession = Session(
          password: list[0]['password'] as String?,
          loginName: list[0]['loginName'] as String?,
          tgt: list[0]['tgt'] as String?,
          loginType: LoginType.getTypeByName(list[0]['loginType'] as String),
          st: list[0]['st'] as String?,
          sessionId: list[0]['sessionId'] as String,
          xToken: list[0]['xToken'] as String,
          userId: list[0]['userId'] as String?,
          serverToken: list[0]['serverToken'] as String?,
        );
        await database.close();
        return localSession;
      } else {
        await database.close();
        throw Exception("Incorrect number of local session entries");
      }
    });
  }

  Future<BasicInfo?> readLocalBasicInfo() async {
    return await databaseLock.synchronized(() async {
      Database database = await initLocalSessionDataBase();
      List<Map<String, Object?>> list =
          await database.rawQuery('SELECT * FROM $userSession');
      if (list.length == 1) {
        BasicInfo? localBasicInfo;
        if (list[0]['basicInfo_id'] != null) {
          localBasicInfo = BasicInfo(
              list[0]['basicInfo_id'] as String,
              list[0]['basicInfo_loginName'] as String,
              list[0]['basicInfo_name'] as String,
              list[0]['basicInfo_role'] as String,
              list[0]['basicInfo_avatar'] as String);
        }
        await database.close();
        return localBasicInfo;
      } else {
        await database.close();
        throw Exception("Incorrect number of local session entries");
      }
    });
  }

  Future<void> saveLocalSession() async {
    SharedPreferences sharedPrefs = BaseSingleton.singleton.sharedPreferences;
    return await databaseLock.synchronized(() async {
      Database database = await initLocalSessionDataBase();
      await database.rawDelete('DELETE FROM $userSession');
      await database.insert(
        userSession,
        {
          "loginName": session?.loginName,
          "password": session?.password,
          "serverToken": session?.serverToken,
          "sessionId": session?.sessionId,
          "st": session?.st,
          "tgt": session?.tgt,
          "loginType": session?.loginType.name,
          "userId": session?.userId,
          "xToken": session?.xToken,
          "basicInfo_id": basicInfo?.id,
          "basicInfo_loginName": basicInfo?.loginName,
          "basicInfo_name": basicInfo?.name,
          "basicInfo_role": basicInfo?.role,
          "basicInfo_avatar": basicInfo?.avatar
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await database.close();
      sharedPrefs.setBool("localSessionExist", true);
    });
  }

  String getEncryptedPassword(String password, bool isRSA) {
    if (isRSA) {
      final modulus = BigInt.parse(zhixueRsaKeyModules, radix: 16);
      final publicExponent =
          BigInt.parse(zhixueRsaKeyPublicExponent, radix: 16);
      final rsaPublicKey = RSAPublicKey(modulus, publicExponent);
      final cipher = PKCS1Encoding(RSAEngine())
        ..init(true, PublicKeyParameter<RSAPublicKey>(rsaPublicKey));
      final encryptedBytes = cipher.process(
          Uint8List.fromList(utf8.encode(password.split('').reversed.join())));
      final encryptedHex = encryptedBytes
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join('');
      return encryptedHex;
    } else {
      String encrypted =
          (RC4("iflytek_pass_edp").encodeBytes(utf8.encode(password)))
              .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
              .join('');
      return encrypted;
    }
  }

  /// Get xToken from cookies.
  ///
  /// xToken is required to access some APIs.
  ///
  /// xToken is received from [zhixueXTokenUrl].
  Future<String> getXToken() async {
    Dio client = BaseSingleton.singleton.dio;
    Response tokenResponse = await client.get(zhixueXTokenUrl);
    logger.d("tokenResponse: ${tokenResponse.data}");
    Map<String, dynamic> json = jsonDecode(tokenResponse.data);
    String xToken = json["result"];
    return xToken;
  }

  Future<Result> casLoginWithTGT(
      {required String tgt,
      required String at,
      required String userId,
      required bool keepLocalSession}) async {
    Dio client = BaseSingleton.singleton.dio;
    Response casResponse = await client.post(zhixueCasLogin,
        data: {
          "at": at,
          "userId": userId,
          "tokenTimeout": 0,
          "autoLogin": true,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ));
    Map<String, dynamic> casResult = jsonDecode(casResponse.data);
    if (casResult["errorCode"] != 0) {
      return Result(
          state: false,
          message: casResult["errorInfo"],
          result: casResult["errorInfo"]);
    }
    List<Cookie> cookies = await BaseSingleton.singleton.cookieJar
        .loadForRequest(Uri.parse(zhixueContainerUrl));
    for (var element in cookies) {
      if (element.name == "tlsysSessionId") {
        String xToken = casResult["result"]["token"];
        basicInfo = BasicInfo(
            casResult["result"]["id"],
            casResult["result"]["userInfo"]["loginName"],
            casResult["result"]["name"],
            casResult["result"]["role"],
            casResult["result"]["userInfo"]["avatar"]);
        isBasicInfoLoaded = true;
        Session currSession = Session(
            loginName: userId,
            tgt: tgt,
            sessionId: element.value,
            xToken: xToken,
            userId: userId,
            loginType: LoginType.app);
        session = currSession;
        client.options.headers["XToken"] = currSession.xToken;
        client.options.headers["token"] = currSession.xToken;
        if (keepLocalSession) {
          await saveLocalSession();
        }
        return Result(state: true, message: casResult["errorInfo"]);
      }
    }
    return Result(state: false, message: casResult["errorInfo"]);
  }

  Future<Result> parWeakCheckLogin(String username, String password,
      {bool keepLocalSession = false}) async {
    Dio client = BaseSingleton.singleton.dio;
    Response ssoResponse = await client.post(zhixueParWeakCheckLogin,
        data: {
          "loginName": username,
          "password": getEncryptedPassword(password, false),
          "description": "{encrypt: [\"password\"]}"
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ));

    Map<String, dynamic> ssoResult = jsonDecode(ssoResponse.data);
    debugPrint(ssoResponse.data.toString());
    if (ssoResult["errorCode"] == 0) {
      List<Cookie> cookies = await BaseSingleton.singleton.cookieJar
          .loadForRequest(Uri.parse(zhixueContainerUrl));
      for (var element in cookies) {
        if (element.name == "tlsysSessionId") {
          String xToken = ssoResult["result"]["token"];
          basicInfo = BasicInfo(
              ssoResult["result"]["id"],
              ssoResult["result"]["userInfo"]["loginName"],
              ssoResult["result"]["name"],
              ssoResult["result"]["role"],
              ssoResult["result"]["userInfo"]["avatar"]);
          isBasicInfoLoaded = true;
          Session currSession = Session(
              loginName: username,
              password: password,
              sessionId: element.value,
              xToken: xToken,
              userId: ssoResult["result"]["id"],
              loginType: LoginType.parWeakCheckLogin);
          session = currSession;
          client.options.headers["XToken"] = currSession.xToken;
          client.options.headers["token"] = currSession.xToken;
          if (keepLocalSession) {
            await saveLocalSession();
          }
          return Result(state: true, message: ssoResult["errorInfo"]);
        }
      }
      return Result(state: false, message: ssoResult["errorInfo"]);
    } else {
      return Result(state: false, message: ssoResult["errorInfo"]);
    }
  }

  Future<Result> ssoLogin(String username, String password, String captcha,
      {bool keepLocalSession = false}) async {
    Dio client = BaseSingleton.singleton.dio;
    Response ssoResponse = await client.post(changyanSSOLoginUrl,
        data: {
          "username": username,
          "password": getEncryptedPassword(password, true),
          "thirdCaptchaParam": captcha,
          "appId": "zhixue_parent",
          "captchaType": "third",
          "client": "android",
          "encode": "true",
          "encodeType": "R2/P",
          "extInfo": "{\"deviceId\":\"0\"}",
          "key": "auto",
          "method": "sso.login.account.v3"
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ));

    Map<String, dynamic> ssoResult = jsonDecode(ssoResponse.data);
    if (ssoResult["code"] == "success") {
      SsoInfo info = SsoInfo(
        tgt: ssoResult["data"]["tgt"],
        at: ssoResult["data"]["at"],
        userId: ssoResult["data"]["userId"],
      );
      Result result = await casLoginWithTGT(
          tgt: info.tgt,
          at: info.at,
          userId: info.userId,
          keepLocalSession: keepLocalSession);
      return result;
    } else {
      return Result(
          state: false,
          message: ssoResult["message"],
          result: ssoResult["message"]);
    }
  }

  Future<Result> ssoLoginWithTGT(String tgt,
      {bool keepLocalSession = false}) async {
    Dio client = BaseSingleton.singleton.dio;
    Response ssoResponse = await client.post(changyanSSOLoginUrl,
        data: {
          "tgt": tgt,
          "appId": "zhixue_parent",
          "client": "android",
          "extInfo": "{\"deviceId\":\"0\"}",
          "method": "sso.extend.tgt"
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ));

    Map<String, dynamic> ssoResult = jsonDecode(ssoResponse.data);
    if (ssoResult["code"] == "success") {
      SsoInfo info = SsoInfo(
        tgt: ssoResult["data"]["tgt"],
        at: ssoResult["data"]["at"],
        userId: ssoResult["data"]["userId"],
      );
      Result result = await casLoginWithTGT(
          tgt: info.tgt,
          at: info.at,
          userId: info.userId,
          keepLocalSession: keepLocalSession);
      return result;
    } else {
      return Result(
          state: false,
          message: ssoResult["code"].toString(),
          result: ssoResult["message"]);
    }
  }

  /// Login to zhixue.com.
  ///
  /// [username] and [password] are from user input and is required.
  Future<Result> loginFromLocal(
      {bool force = true, bool keepLocalSession = false}) async {
    if (!force) {
      if (isLoggedIn()) {
        return Result(state: true, message: "已登录");
      }
    }
    Dio client = BaseSingleton.singleton.dio;
    try {
      Session localSession = await readLocalSession();
      if (localSession.loginType == LoginType.webview ||
          localSession.loginType == LoginType.parWeakCheckLogin) {
        this.keepLocalSession = keepLocalSession;
        BasicInfo? localBasicInfo = await readLocalBasicInfo();
        if (localBasicInfo != null) {
          isBasicInfoLoaded = true;
          basicInfo = localBasicInfo;
        }
        session = localSession;
        client.options.headers["XToken"] = session?.xToken;
        client.options.headers["Token"] = session?.xToken;
        try {
          await fetchBasicInfo();
        } catch (e) {
          logger.e("login: fetchBasicInfo error: $e");
        }
        return Result(state: true, message: "本地Session登录成功");
      } else if (localSession.loginType == LoginType.app) {
        autoLogout = false;
        this.keepLocalSession = keepLocalSession;
        return await ssoLoginWithTGT(localSession.tgt!,
            keepLocalSession: keepLocalSession);
      } else {
        return Result(state: false, message: "Unknown login type");
      }
    } catch (e) {
      return Result(state: false, message: e.toString());
    }
  }

  Future<void> updateLoginStatus() async {
    Dio client = BaseSingleton.singleton.dio;
    Response response = await client.get(zhixueLoginStatusUrl);
    Map<String, dynamic> json = jsonDecode(response.data);
    logger.d("updateLoginStatus $response");
    if (json["result"] != "success") {
      Result res = Result(state: false, message: "Unknown LoginType");
      try {
        if (session?.loginType == LoginType.parWeakCheckLogin) {
          res = await parWeakCheckLogin(session!.loginName!, session!.password!,
              keepLocalSession: keepLocalSession);
        } else if (session?.loginType == LoginType.app) {
          res = await ssoLoginWithTGT(session!.tgt!,
              keepLocalSession: keepLocalSession);
        } else if (session?.loginType == LoginType.webview) {
          res = Result(state: false, message: "Webview isn't support reLogin");
        }
      } catch (e) {
        if (autoLogout) {
          await logoff();
          reLoginFailedCallback();
        }
      }
      if (res.state != true && autoLogout) {
        await logoff();
        reLoginFailedCallback();
      }
    }
  }

  /// Remove **all** cookies and session data to logoff
  Future<bool> logoff() async {
    SharedPreferences sharedPrefs = BaseSingleton.singleton.sharedPreferences;
    session = null;
    basicInfo = null;
    studentInfo = null;
    isBasicInfoLoaded = false;
    keepLocalSession = false;
    BaseSingleton.singleton.dio.options.headers["XToken"] = null;

    // Remove all cookies from related sites.
    CookieJar cookieJar = BaseSingleton.singleton.cookieJar;
    try {
      cookieJar.deleteAll();
    } catch (_) {}
    cookieJar.delete(Uri.parse(zhixueBaseUrl));
    cookieJar.delete(Uri.parse(zhixueBaseUrl_2));
    cookieJar.delete(Uri.parse(changyanBaseUrl));

    return await databaseLock.synchronized(() async {
      Database database = await initLocalSessionDataBase();
      await database.rawDelete('DELETE FROM $userSession');
      await database.close();
      sharedPrefs.setBool("localSessionExist", false);
      return true;
    });
  }
}
