import 'dart:convert';
import 'dart:io';
import 'package:flutter_inappwebview/flutter_inappwebview.dart' as webview;
import 'package:flutter/material.dart';
import 'package:prescore_flutter/constants.dart';
import 'package:prescore_flutter/main.dart';
import 'package:prescore_flutter/model/login_model.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:prescore_flutter/util/struct.dart';

class WebviewLoginCard extends StatefulWidget {
  const WebviewLoginCard({
    Key? key,
  }) : super(key: key);

  @override
  State<WebviewLoginCard> createState() => _WebviewLoginCardState();
}

class _WebviewLoginCardState extends State<WebviewLoginCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  SharedPreferences sharedPrefs = BaseSingleton.singleton.sharedPreferences;
  Widget webviewCard = Container();
  webview.InAppWebViewController? inAppWebViewController;

  void changeStyle() {
    inAppWebViewController?.evaluateJavascript(source: """
          const div = document.querySelectorAll("div");
          div.forEach(function (element) {
              if (element.className == "w_head") {
                  element.remove();
              }
              if (element.className == "w_login_warp") {
                  element.style.padding = "15px 10px 10px 10px";
                  //element.style.background = "#${(Theme.of(context).colorScheme.secondaryContainer.value).toRadixString(16).padLeft(8, '0')}";
              }
              if (element.className == "w_body") {
                  element.style.margin = "0px 0px 0px 0px";
              }
          });
          document.getElementById("helpBox").remove()
    """);
  }

  void setPasswordListener() {
      inAppWebViewController?.addJavaScriptHandler(handlerName: 'username', callback: (username) {
        sharedPrefs.setString("username", username[0]);
        debugPrint(username.toString());
      });
      inAppWebViewController?.addJavaScriptHandler(handlerName: 'password', callback: (password) {
        sharedPrefs.setString("password", password[0]);
        debugPrint(password.toString());
      });
      inAppWebViewController?.evaluateJavascript(source: """
            var user = document.getElementById("txtUserName");
            var password = document.getElementById("txtPassword");
            user.value = "${sharedPrefs.getString("username")}";
            password.value = "${sharedPrefs.getString("password")}";
            user.onchange = function () { window.flutter_inappwebview.callHandler("username", user.value) };
            password.onchange = function () { window.flutter_inappwebview.callHandler("password", password.value) };
      """);
  }

  @override
  void initState() {
    super.initState();
    webview.CookieManager cookieManager = webview.CookieManager.instance();
    LoginModel model = Provider.of<LoginModel>(context, listen: false);
    webviewCard = webview.InAppWebView(
        initialUrlRequest: webview.URLRequest(
            url: Uri.parse('https://www.zhixue.com/wap_login.html')),
        initialOptions: webview.InAppWebViewGroupOptions(
            crossPlatform: webview.InAppWebViewOptions(
                userAgent: userAgent, clearCache: false),
            android: webview.AndroidInAppWebViewOptions(
              mixedContentMode:
                  webview.AndroidMixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
              clearSessionCache: false,
            )),
        onWebViewCreated: (controller) => inAppWebViewController = controller,
        onLoadStop: (controller, url) async {
          List<webview.Cookie> cookies =
              await cookieManager.getCookies(url: url!);
          BaseSingleton.singleton.cookieJar.saveFromResponse(
              url, cookies.map((e) => Cookie(e.name, e.value)).toList());
          changeStyle();
          setPasswordListener();
        },
        onUpdateVisitedHistory: (controller, url, androidIsReload) async {
          List<webview.Cookie> cookies =
              await cookieManager.getCookies(url: url!);
          BaseSingleton.singleton.cookieJar.saveFromResponse(
              url, cookies.map((e) => Cookie(e.name, e.value)).toList());
          if (url.path.contains('htm-vessel')) {
            String? tlsysSessionId;
            for (var element in cookies) {
              if (element.name == "tlsysSessionId") {
                tlsysSessionId = element.value;
                debugPrint(element.toString());
              }
            }
            String getToken = """
                var request = new Promise(function (resolve, reject) {
                  \$.get("https://www.zhixue.com/addon/error/book/index",function(data, status) {resolve(data)})
                });
                await request;
                return request;
              """;
            String response =
                (await controller.callAsyncJavaScript(functionBody: getToken))
                    ?.value;
            Map<String, dynamic> json = jsonDecode(response);
            String xToken = json["result"];
            if (json["errorCode"] == 0) {
              model.user.session = Session(null, tlsysSessionId!, xToken, "");
              model.user.keepLocalSession =
                  sharedPrefs.getBool("keepLogin") ?? true;
              BaseSingleton.singleton.dio.options.headers["XToken"] = xToken;
              if (sharedPrefs.getBool("keepLogin") ?? true) {
                model.user.saveLocalSession();
              }
              model.user.telemetryLogin();
              controller.stopLoading();
              model.setLoggedIn(true);
            }
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    changeStyle();
    return Container(
        constraints: const BoxConstraints(
          maxHeight: 222,
          maxWidth: 400,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 32),
        child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: const BorderRadius.all(Radius.circular(12)),
            ),
            clipBehavior: Clip.antiAlias,
            child: webviewCard));
  }
}
