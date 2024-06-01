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

  bool isLoaded = false;

  SharedPreferences sharedPrefs = BaseSingleton.singleton.sharedPreferences;
  Widget webviewCard = Container();
  webview.InAppWebViewController? inAppWebViewController;

  @override
  void reassemble() {
    super.reassemble();
    changeStyle();
  }

  Future<void> changeStyle() async {
    String backgroundColor =
        "#${(Theme.of(context).colorScheme.surfaceContainerLow.value).toRadixString(16).substring(2)}";
    String buttonColor =
        "#${Theme.of(context).colorScheme.primaryContainer.value.toRadixString(16).substring(2)}";
    String focusColor =
        "#${Theme.of(context).colorScheme.primaryFixedDim.value.toRadixString(16).substring(2)}";
    String inputColor =
        "#${Theme.of(context).colorScheme.surfaceContainerHighest.value.toRadixString(16).substring(2)}";
    String textColor =
        "#${Theme.of(context).colorScheme.onSurface.value.toRadixString(16).substring(2)}";
    await inAppWebViewController?.callAsyncJavaScript(functionBody: """
      styleElement = document.createElement('style');
      styleElement.innerHTML = 
      '.w_body { margin: 0px 0px 0px 0px; }'+
      '.w_login_warp { background: $backgroundColor; padding: 15px 15px 15px 15px; }'+
      '.w_head { display: none; }'+
      '.help_box { display: none; }'+
      '.login_btn a { background: $buttonColor; color: $textColor; border-radius: 5px; }'+
      '.user_box input { background-color: $inputColor; color: $textColor; border-radius: 5px; }'+
      '.user_box input:focus { border-bottom: 2px solid $focusColor; }'+
      '.user_box span.close { margin-right: 10px; }'
      ;
      document.body.append(styleElement);
      return;
    """);
    return;
  }

  void setPasswordListener() {
    inAppWebViewController?.addJavaScriptHandler(
        handlerName: 'username',
        callback: (username) {
          sharedPrefs.setString("username", username[0]);
          debugPrint(username.toString());
        });
    inAppWebViewController?.addJavaScriptHandler(
        handlerName: 'password',
        callback: (password) {
          sharedPrefs.setString("password", password[0]);
          debugPrint(password.toString());
        });
    inAppWebViewController?.evaluateJavascript(source: """
            var user = document.getElementById("txtUserName");
            var password = document.getElementById("txtPassword");
            user.value = "${sharedPrefs.getString("username") ?? ""}";
            password.value = "${sharedPrefs.getString("password") ?? ""}";
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
          setPasswordListener();
          await changeStyle();
          setState(() {
            isLoaded = true;
          });
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
    changeStyle();
    return Container(
        constraints: const BoxConstraints(
          maxHeight: 226,
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
            clipBehavior: Clip.antiAliasWithSaveLayer,
            child: Stack(
              children: [
                webviewCard,
                if (!isLoaded)
                  Container(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      child: Center(
                          child: Container(
                              margin: const EdgeInsets.all(10),
                              child: const CircularProgressIndicator())))
              ],
            )));
  }
}
