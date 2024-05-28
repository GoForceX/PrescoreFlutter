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
    required this.model,
    Key? key,
  }) : super(key: key);

  final LoginModel model;

  @override
  State<WebviewLoginCard> createState() => _WebviewLoginCardState();
}

class _WebviewLoginCardState extends State<WebviewLoginCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  SharedPreferences sharedPrefs = BaseSingleton.singleton.sharedPreferences;
  Widget webviewCard = Container();

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
        onLoadStop: (controller, url) async {
          controller.evaluateJavascript(source: """
                const div = document.querySelectorAll("div");
                div.forEach(function (element) {
                    if (element.className == "w_head") {
                        element.remove();
                    }
                });
                const a = document.querySelectorAll("a");
                a.forEach(function (element) {
                    if (element.className == "fl" || element.className == "fr") {
                        element.remove();
                    }
                });
          """);
          List<webview.Cookie> cookies =
              await cookieManager.getCookies(url: url!);
          BaseSingleton.singleton.cookieJar.saveFromResponse(
              url, cookies.map((e) => Cookie(e.name, e.value)).toList());
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
    return Container(
        constraints: const BoxConstraints(
          maxHeight: 340,
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
