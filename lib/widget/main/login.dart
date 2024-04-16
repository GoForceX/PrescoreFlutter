import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prescore_flutter/main.dart';
import 'package:prescore_flutter/main.gr.dart';
import 'package:prescore_flutter/model/login_model.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:prescore_flutter/util/struct.dart';
import 'package:prescore_flutter/service.dart' show refreshService;
import 'package:prescore_flutter/util/user_util.dart';

class ClearButton extends StatelessWidget {
  const ClearButton({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => controller.clear(),
      );
}

class LoginWidget extends StatefulWidget {
  const LoginWidget({Key? key}) : super(key: key);

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  SharedPreferences sharedPrefs = BaseSingleton.singleton.sharedPreferences;

  bool _isObscured = true;

  void login({useLocalSession = false, keepLocalSession = false}) async {
    if (useLocalSession) {
      Provider.of<LoginModel>(context, listen: false).setAutoLogging(true);
    }
    Provider.of<LoginModel>(context, listen: false).setLoading(true);
    final username = usernameController.text;
    final password = passwordController.text;

    sharedPrefs.setString("username", username);
    sharedPrefs.setString("password", password);

    User user = User();
    Provider.of<LoginModel>(context, listen: false).setUser(user);
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

  void saveAccount() {
    final username = usernameController.text;
    final password = passwordController.text;

    sharedPrefs.setString("username", username);
    sharedPrefs.setString("password", password);
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
        if (!model.isAutoLogging) {
          Widget loginCard = Container(
              height: 235,
              constraints: const BoxConstraints(
                maxWidth: 400,
              ),
              margin: const EdgeInsets.all(32),
              child: Stack(children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                  ),
                  child: AutofillGroup(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: TextField(
                              controller: usernameController,
                              decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.account_box),
                                  suffixIcon: ClearButton(
                                      controller: usernameController),
                                  labelText: '用户名',
                                  hintText: '请输入用户名',
                                  filled: true,
                                  enabled: !model.isLoading),
                              onChanged: (text) {
                                saveAccount();
                              },
                              autofillHints: const [AutofillHints.username],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            child: TextField(
                              controller: passwordController,
                              obscureText: _isObscured,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.password),
                                suffixIcon: IconButton(
                                  icon: _isObscured
                                      ? const Icon(Icons.visibility_off)
                                      : const Icon(Icons.visibility),
                                  onPressed: () => setState(
                                      () => _isObscured = !_isObscured),
                                ),
                                labelText: '密码',
                                hintText: '请输入密码',
                                filled: true,
                                enabled: !model.isLoading,
                              ),
                              autofillHints: const [AutofillHints.password],
                              onChanged: (text) {
                                saveAccount();
                              },
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(left: 16),
                            child: FilterChip(
                              label: const Text('保持登录'),
                              selected:
                                  sharedPrefs.getBool("keepLogin") ?? true,
                              onSelected: model.isLoading
                                  ? null
                                  : (bool selected) => setState(() {
                                        if (!selected) {
                                          if (sharedPrefs.getBool(
                                                      "enableWearService") ==
                                                  true ||
                                              sharedPrefs
                                                      .getBool("checkExams") ==
                                                  true) {
                                            SnackBar snackBar = const SnackBar(
                                                content:
                                                    Text('注意：启用后台服务必须保持登录'));
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(snackBar);
                                            //sharedPrefs.setBool("keepLogin", true);
                                            //return;
                                          }
                                        }
                                        sharedPrefs.setBool(
                                            "keepLogin", selected);
                                      }),
                            ),
                          )
                        ]),
                  ),
                ),
                Positioned(
                    right: 0,
                    bottom: 0,
                    child: FloatingActionButton.extended(
                      onPressed: model.isLoading
                          ? null
                          : () {
                              login(
                                  useLocalSession: false,
                                  keepLocalSession:
                                      sharedPrefs.getBool("keepLogin") ?? true);
                              TextInput.finishAutofillContext();
                            },
                      icon: model.isLoading
                          ? Container(
                              height: 10,
                              width: 10,
                              margin: const EdgeInsets.all(4),
                              child: const CircularProgressIndicator(
                                  strokeWidth: 2))
                          : const Icon(Icons.login, size: 18),
                      label: const Text("登录"),
                    ))
              ]));
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
              child: Column(children: [
                Expanded(
                    flex: 1,
                    child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Container(
                            margin: const EdgeInsets.all(32),
                            child:
                                Text("  登入", style: textTheme.displayMedium)))),
                Expanded(
                    flex: 2,
                    child:
                        Align(alignment: Alignment.topLeft, child: loginCard)),
                const Text("© GoForceX | 2021 - 2024",
                    style: TextStyle(color: Colors.grey, fontSize: 10)),
                const Text("© 北京市八一学校 NPC 信息社 | 2023 - 2024",
                    style: TextStyle(color: Colors.grey, fontSize: 10)),
                const SizedBox(height: 10),
              ]));
        } else {
          return Center(
              child: Container(
                  margin: const EdgeInsets.all(10),
                  child: const CircularProgressIndicator()));
        }
      },
    );
  }
}
