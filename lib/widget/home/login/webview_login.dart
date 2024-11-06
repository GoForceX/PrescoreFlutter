import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart' as webview;
import 'package:flutter/material.dart';
import 'package:prescore_flutter/constants.dart';
import 'package:prescore_flutter/main.dart';
import 'package:prescore_flutter/model/login_model.dart';
import 'package:prescore_flutter/util/user_util/user_util.dart';
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

  get useBackupLoginPage => Platform.isIOS;
  get initUrl =>
      Uri.parse(useBackupLoginPage ? loginNoThirdCookieUrl : wapLoginUrl);

  SharedPreferences sharedPrefs = BaseSingleton.singleton.sharedPreferences;
  Widget webviewCard = Container();
  webview.InAppWebViewController? inAppWebViewController;
  webview.CookieManager cookieManager = webview.CookieManager.instance();

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
    if (!useBackupLoginPage) {
      await inAppWebViewController?.callAsyncJavaScript(functionBody: """
      styleElement = document.createElement('style');
      styleElement.innerHTML = 
      'body { background: $backgroundColor; }'+
      '.w_body { margin: 0px 0px 0px 0px; }'+
      '.w_login_warp { background: $backgroundColor; padding: 15px 15px 15px 15px; }'+
      '.w_head { display: none; }'+
      '.help_box { display: none; }'+
      '.login_btn a { background: $buttonColor; color: $textColor; border-radius: 5px; }'+
      '.user_box input { background-color: $inputColor; color: $textColor; border-radius: 5px; }'+
      '.user_box input:focus { border-bottom: 2px solid $focusColor; }'+
      '.user_box span.close { margin-right: 10px; }'+
      '.geetest_wrap { background: $backgroundColor; }'+
      '.geetest_header { background: $backgroundColor; }'+
      '.geetest_footer { background: $backgroundColor; }'+
      '.geetest_box { background: $backgroundColor; }';
      document.body.append(styleElement);
      return;
    """);
    } else {
      await inAppWebViewController?.callAsyncJavaScript(functionBody: """
      var targetElement = document.querySelector('.cl_login_box');
      function hideElementsExcept(element) {
          var parent = element.parentElement;
          while (parent && !parent.classList.contains(targetElement.className)) {
              var siblings = parent.children;
              for (var i = 0; i < siblings.length; i++) {
                  if (siblings[i] !== element) {
                      siblings[i].style.display = 'none';
                  }
              }
              element = parent;
              parent = parent.parentElement;
          }
      }
      hideElementsExcept(targetElement);

      styleElement = document.createElement('style');
      styleElement.innerHTML = 
      '.cl_login_box { all: unset; }'+
      '.cl_login_fill > input, .verified_name > input { width: 100%; }'+
      '.cl_banner { min-height: 30px; }'+
      '.pwd_remember { display: none; }'+
      '.note_msg { display: none; }'+
      '.cl_login_head { display: none; }';
      document.body.append(styleElement);
    """);
    }
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

  void login(webview.WebUri url) async {
    LoginModel model = Provider.of<LoginModel>(context, listen: false);
    List<webview.Cookie> cookies = await cookieManager.getCookies(url: url);
    BaseSingleton.singleton.cookieJar.saveFromResponse(
        url, cookies.map((e) => Cookie(e.name, e.value)).toList());
    String? tlsysSessionId;
    for (var element in cookies) {
      if (element.name == "tlsysSessionId") {
        tlsysSessionId = element.value;
        debugPrint(element.toString());
      }
    }
    String getToken = """
          var request = new Promise(function (resolve, reject) { 
            const Http = new XMLHttpRequest();
            Http.open("GET", "$zhixueXTokenUrl");
            Http.send();
            Http.onreadystatechange = (e) => {
              if (Http.readyState === 4 && Http.status === 200) {
                resolve(Http.responseText);
              }
            };
          });
          return await request;
        """;
    String response = (await inAppWebViewController?.callAsyncJavaScript(
            functionBody: getToken))
        ?.value;
    Map<String, dynamic> json = jsonDecode(response);
    String xToken = json["result"];
    if (json["errorCode"] == 0) {
      model.user.session = Session(
          sessionId: tlsysSessionId!,
          xToken: xToken,
          loginType: LoginType.webview);
      model.user.keepLocalSession = sharedPrefs.getBool("keepLogin") ?? true;
      BaseSingleton.singleton.dio.options.headers["XToken"] = xToken;
      if (sharedPrefs.getBool("keepLogin") ?? true) {
        model.user.saveLocalSession();
      }
      model.user.telemetryLogin();
      inAppWebViewController?.stopLoading();
      model.setLoggedIn(true);
    }
  }

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      webview.InAppWebViewController.setWebContentsDebuggingEnabled(
          !kReleaseMode);
    }

    webviewCard = webview.InAppWebView(
        initialUrlRequest: webview.URLRequest(url: webview.WebUri.uri(initUrl)),
        initialSettings: webview.InAppWebViewSettings(
          userAgent: userAgent,
          clearCache: sharedPrefs.getBool("keepLogin") == false,
          mixedContentMode: webview.MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
          isInspectable: !kReleaseMode,
        ),
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
          if (url!.path.contains('htm-vessel')) {
            login(url);
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    changeStyle();
    return Column(
      children: [
        Container(
            constraints: const BoxConstraints(
              //maxHeight: 226,
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
                child: Column(
                  children: [
                    ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12)),
                        child: SizedBox(
                            height: 218,
                            child: Stack(
                              children: [
                                webviewCard,
                                if (!isLoaded)
                                  Container(
                                      height: 218,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerLow,
                                      child: Center(
                                          child: Container(
                                              margin: const EdgeInsets.all(10),
                                              child:
                                                  const CircularProgressIndicator())))
                              ],
                            ))),
                    const Divider(height: 2),
                    Row(
                      children: [
                        Transform.scale(
                          scale: 0.75,
                          filterQuality: FilterQuality.high,
                          child: Checkbox(
                            value: sharedPrefs.getBool("keepLogin"),
                            //activeColor: Colors.red, //选中时的颜色
                            onChanged: (value) {
                              setState(() {
                                sharedPrefs.setBool("keepLogin", value!);
                              });
                            },
                          ),
                        ),
                        Text("保持登录",
                            style: Theme.of(context).textTheme.labelMedium),
                        const Expanded(child: SizedBox()),
                        GestureDetector(
                            child: Icon(Icons.refresh,
                                color: Theme.of(context).colorScheme.primary,
                                semanticLabel: "刷新",
                                size: 20),
                            onTap: () {
                              webview.InAppWebViewController.clearAllCache();
                              inAppWebViewController?.reload();
                              inAppWebViewController?.getUrl().then((url) {
                                login(url!);
                              });
                            }),
                        const SizedBox(width: 16)
                      ],
                    ),
                  ],
                ))),
      ],
    );
  }
}
