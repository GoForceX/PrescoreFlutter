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

class NormalLoginCard extends StatefulWidget {
  const NormalLoginCard({
    required this.model,
    required this.usernameController,
    required this.passwordController,
    Key? key,
  }) : super(key: key);

  final LoginModel model;
  final TextEditingController usernameController;
  final TextEditingController passwordController;

  @override
  State<NormalLoginCard> createState() => _NormalLoginCardState();
}

class _NormalLoginCardState extends State<NormalLoginCard> {
  void login({useLocalSession = false, keepLocalSession = false}) async {
    LoginModel model = Provider.of<LoginModel>(context, listen: false);
    if (useLocalSession) {
      model.setAutoLogging(true);
    }
    model.setLoading(true);
    final username = widget.usernameController.text;
    final password = widget.passwordController.text;

    sharedPrefs.setString("username", username);
    sharedPrefs.setString("password", password);

    Result result;
    try {
      result = await model.user.login(username, password,
          useLocalSession: useLocalSession, keepLocalSession: keepLocalSession);
    } catch (e) {
      SnackBar snackBar = SnackBar(
          content: Text('呜呜呜，登录失败了……\n失败原因：${(e as DioException).error}'));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        model.setLoading(false);
        model.setAutoLogging(false);
      }
      return;
    }
    if (mounted) {
      if (result.state) {
        model.user.telemetryLogin();
        model.setLoggedIn(true);
        model.setAutoLogging(false);
        model.setLoading(false);
        logger.d("session ${model.user.session}");
        refreshService();

        model.user.reLoginFailedCallback = () {
          model.setLoggedIn(false);
          model.setLoading(false);
          model.setUser(User());
          Navigator.of(context, rootNavigator: true)
              .pushReplacementNamed(HomeRoute.name);
        };
      } else {
        SnackBar snackBar =
            SnackBar(content: Text('呜呜呜，登录失败了……\n失败原因：${result.message}'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        model.setLoading(false);
        model.setAutoLogging(false);
      }
    }
  }

  bool _isObscured = true;
  SharedPreferences sharedPrefs = BaseSingleton.singleton.sharedPreferences;

  void saveAccount() {
    final username = widget.usernameController.text;
    final password = widget.passwordController.text;

    sharedPrefs.setString("username", username);
    sharedPrefs.setString("password", password);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 220,
        constraints: const BoxConstraints(
          maxWidth: 400,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 32),
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
                        controller: widget.usernameController,
                        decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.account_box),
                            suffixIcon: ClearButton(
                                controller: widget.usernameController),
                            labelText: '用户名',
                            floatingLabelBehavior: FloatingLabelBehavior.auto,
                            hintText: '请输入用户名',
                            filled: true,
                            enabled: !widget.model.isLoading),
                        onChanged: (text) {
                          saveAccount();
                        },
                        autofillHints: !widget.model.isLoading
                            ? const [AutofillHints.username]
                            : null,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: TextField(
                        controller: widget.passwordController,
                        obscureText: _isObscured,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.password),
                          suffixIcon: IconButton(
                            icon: _isObscured
                                ? const Icon(Icons.visibility_off)
                                : const Icon(Icons.visibility),
                            onPressed: () =>
                                setState(() => _isObscured = !_isObscured),
                          ),
                          labelText: '密码',
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                          hintText: '请输入密码',
                          filled: true,
                          enabled: !widget.model.isLoading,
                        ),
                        autofillHints: !widget.model.isLoading
                            ? const [AutofillHints.password]
                            : null,
                        onChanged: (text) {
                          saveAccount();
                        },
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 16),
                      child: FilterChip(
                        label: const Text('保持登录'),
                        selected: sharedPrefs.getBool("keepLogin") ?? true,
                        onSelected: widget.model.isLoading
                            ? null
                            : (bool selected) => setState(() {
                                  if (!selected) {
                                    if (sharedPrefs
                                                .getBool("enableWearService") ==
                                            true ||
                                        sharedPrefs.getBool("checkExams") ==
                                            true) {
                                      SnackBar snackBar = const SnackBar(
                                          content: Text('注意：启用后台服务必须保持登录'));
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(snackBar);
                                      //sharedPrefs.setBool("keepLogin", true);
                                      //return;
                                    }
                                  }
                                  sharedPrefs.setBool("keepLogin", selected);
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
                onPressed: widget.model.isLoading
                    ? null
                    : () {
                        login(
                            useLocalSession: false,
                            keepLocalSession:
                                sharedPrefs.getBool("keepLogin") ?? true);
                        TextInput.finishAutofillContext();
                      },
                icon: widget.model.isLoading
                    ? Container(
                        height: 10,
                        width: 10,
                        margin: const EdgeInsets.all(4),
                        child: const CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.login, size: 18),
                label: const Text("登录"),
              ))
        ]));
  }
}
