import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:prescore_flutter/main.dart';
import 'package:prescore_flutter/main.gr.dart';
import 'package:prescore_flutter/model/login_model.dart';
import 'package:prescore_flutter/widget/home/login/normal_login.dart';
import 'package:prescore_flutter/widget/home/login/webview_login.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:prescore_flutter/util/struct.dart';
import 'package:prescore_flutter/service.dart' show refreshService;
import 'package:prescore_flutter/util/user_util.dart';

class LoginWidget extends StatefulWidget {
  const LoginWidget({Key? key}) : super(key: key);

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  SharedPreferences sharedPrefs = BaseSingleton.singleton.sharedPreferences;
  final PageController controller = PageController();

  void login({useLocalSession = false, keepLocalSession = false}) async {
    if (useLocalSession) {
      Provider.of<LoginModel>(context, listen: false).setAutoLogging(true);
    }
    Provider.of<LoginModel>(context, listen: false).setLoading(true);
    final username = usernameController.text;
    final password = passwordController.text;

    sharedPrefs.setString("username", username);
    sharedPrefs.setString("password", password);

    User user = Provider.of<LoginModel>(context, listen: false).user;
    Result result;
    try {
      result = await user.login(username, password,
          useLocalSession: useLocalSession, keepLocalSession: keepLocalSession);
    } catch (e) {
      SnackBar snackBar = SnackBar(
          content: Text('呜呜呜，登录失败了……\n失败原因：${(e as DioException).error}'));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        Provider.of<LoginModel>(context, listen: false).setLoading(false);
        Provider.of<LoginModel>(context, listen: false).setAutoLogging(false);
      }
      return;
    }
    if (mounted) {
      if (result.state) {
        Provider.of<LoginModel>(context, listen: false).user.telemetryLogin();
        Provider.of<LoginModel>(context, listen: false).setLoggedIn(true);
        Provider.of<LoginModel>(context, listen: false).setAutoLogging(false);
        Provider.of<LoginModel>(context, listen: false).setLoading(false);
        logger.d("session ${user.session}");
        refreshService();
        LoginModel model = Provider.of<LoginModel>(context, listen: false);
        user.reLoginFailedCallback = () {
          model.setLoggedIn(false);
          model.setLoading(false);
          model.setUser(User());
          Navigator.of(context, rootNavigator: true)
              .pushReplacementNamed(HomeRoute.name); //TODO
        };
      } else {
        SnackBar snackBar =
            SnackBar(content: Text('呜呜呜，登录失败了……\n失败原因：${result.message}'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        Provider.of<LoginModel>(context, listen: false).setLoading(false);
        Provider.of<LoginModel>(context, listen: false).setAutoLogging(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String? prefUsername = sharedPrefs.getString('username');
    String? prefPassword = sharedPrefs.getString('password');

    if (prefUsername != null) {
      usernameController.text = prefUsername;
    } else {
      usernameController.text = "";
    }
    if (prefPassword != null) {
      passwordController.text = prefPassword;
    } else {
      usernameController.text = "";
    }
    if (sharedPrefs.getBool('localSessionExist') == true) {
      Future.microtask(() {
        login(useLocalSession: true, keepLocalSession: true);
      });
    }
    final textTheme = Theme.of(context)
        .textTheme
        .apply(displayColor: Theme.of(context).colorScheme.onSurface);
    return Consumer<LoginModel>(
      builder: (context, model, widget) {
        if (model.isAutoLogging) {
          return Center(
              child: Container(
                  margin: const EdgeInsets.all(10),
                  child: const CircularProgressIndicator()));
        }

        return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                stops: const [0.1, 0.8],
                colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context).colorScheme.onPrimary,
                ],
              ),
            ),
            child: PageView(
              physics: const NeverScrollableScrollPhysics(),
              controller: controller,
              children: [
                Column(children: [
                  Expanded(
                      flex: 3,
                      child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Container(
                              margin: const EdgeInsets.all(32),
                              child: Text("  登入",
                                  style: textTheme.displayMedium)))),
                  Expanded(
                      flex: 5,
                      child: Column(
                        children: [
                          NormalLoginCard(
                              model: model,
                              usernameController: usernameController,
                              passwordController: passwordController),
                          TextButton(
                            child: Text("备用登录方式 >",
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                        color: Theme.of(context).hintColor)),
                            onPressed: () {
                              controller.animateToPage(1,
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeOut);
                            },
                          ),
                        ],
                      )),
                  const Text("© GoForceX | 2021 - 2024",
                      style: TextStyle(color: Colors.grey, fontSize: 10)),
                  const Text("© 北京市八一学校 NPC 信息社 | 2023 - 2024",
                      style: TextStyle(color: Colors.grey, fontSize: 10)),
                  const SizedBox(height: 10),
                ]),
                Column(children: [
                  Expanded(
                      flex: 1,
                      child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Container(
                              margin: const EdgeInsets.all(32),
                              child: Text("  网页登入",
                                  style: textTheme.displayMedium)))),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        WebviewLoginCard(model: model),
                        TextButton(
                          child: Text("< 返回",
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                      color: Theme.of(context).hintColor)),
                          onPressed: () {
                            controller.animateToPage(0,
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut);
                          },
                        ),
                      ],
                    ),
                  ),
                ]),
              ],
            ));
      },
    );
  }
}
