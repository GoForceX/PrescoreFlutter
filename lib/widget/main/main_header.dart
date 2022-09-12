import 'dart:math';

import 'package:flutter/material.dart';
import 'package:prescore_flutter/main.dart';
import 'package:prescore_flutter/model/login_model.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../util/struct.dart';
import '../../util/user_util.dart';
import '../fancy_button.dart';

class SliverHeader extends StatelessWidget {
  const SliverHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      delegate: MySliverAppBar(
        expandedHeight: 150,
      ),
    );
  }
}

class MySliverAppBar extends SliverPersistentHeaderDelegate {
  final double expandedHeight;

  MySliverAppBar({required this.expandedHeight});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        Center(
            child: Opacity(
                opacity: 1 - sqrt(shrinkOffset / expandedHeight),
                child: Consumer<LoginModel>(builder: (context, model, widget) {
                  if (model.isLoggedIn) {
                    return const MainAppbarWidget();
                  } else {
                    return const FallbackAppbarWidget();
                  }
                }))),
      ],
    );
  }

  @override
  double get maxExtent => expandedHeight;

  @override
  double get minExtent => kToolbarHeight;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) => true;
}

class MainAppbarRowWidget extends StatelessWidget {
  final Widget image;
  final String title;
  final String subtitle;
  const MainAppbarRowWidget(
      {Key? key,
      required this.image,
      required this.title,
      required this.subtitle})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 24,
          height: 132,
        ),
        CircleAvatar(
          radius: 50,
          child: ClipOval(child: image),
        ),
        const SizedBox(
          width: 30,
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 32),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(
          width: 24,
          height: 132,
        )
      ],
    );
  }
}

class MainAppbarWidget extends StatelessWidget {
  const MainAppbarWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: Card(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        elevation: 8,
        child: InkWell(onLongPress: () async {
          await showDialog<String>(
            context: context,
            builder: (BuildContext dialogContext) => AlertDialog(
              title: const Text('你要退出账号吗？'),
              content: const Text('众所周知长按就可以退出现在的账号，你要这么做吗？'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, '我点错了'),
                  child: const Text('我点错了'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext, '果断退出');
                    Provider.of<LoginModel>(context, listen: false)
                        .setLoggedIn(false);
                    Provider.of<LoginModel>(context, listen: false)
                        .setLoggedOff(true);
                    Provider.of<LoginModel>(context, listen: false)
                        .setLoading(false);
                    Provider.of<LoginModel>(context, listen: false)
                        .user
                        .logoff();
                    Provider.of<LoginModel>(context, listen: false)
                        .setUser(User());
                  },
                  child: const Text('果断退出'),
                ),
              ],
            ),
          );
        }, child: Consumer<LoginModel>(
            builder: (BuildContext context, LoginModel value, Widget? child) {
          return FutureBuilder(
              future: value.user.fetchBasicInfo(),
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                Widget image = Image.asset('assets/akarin.webp');
                String title = "";
                String subtitle = "";
                if (snapshot.hasData) {
                  logger.d("basicInfo: ${snapshot.data}");
                  if (snapshot.data.avatar != "") {
                    image = FadeInImage.assetNetwork(
                        image: snapshot.data.avatar,
                        placeholder: 'assets/akarin.webp');
                  }
                  if (snapshot.data.name != "") {
                    title = snapshot.data.name;
                  }
                  if (snapshot.data.loginName != "") {
                    subtitle = snapshot.data.loginName;
                  }
                }
                return MainAppbarRowWidget(
                  image: image,
                  title: title,
                  subtitle: subtitle,
                );
              });
        })),
      ),
    );
  }
}

class FallbackAppbarWidget extends StatefulWidget {
  const FallbackAppbarWidget({Key? key}) : super(key: key);

  @override
  State<FallbackAppbarWidget> createState() => _FallbackAppbarWidgetState();
}

class _FallbackAppbarWidgetState extends State<FallbackAppbarWidget> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  bool _isObscured = true;

  void callback() {
    logger.d("get callback");
    Provider.of<LoginModel>(context, listen: false).setLoggedIn(true);
    Provider.of<LoginModel>(context, listen: false).user.telemetryLogin();
  }

  @override
  Widget build(BuildContext context) {
    SharedPreferences? sharedPrefs = BaseSingleton.singleton.sharedPreferences;
    String? prefUsername = sharedPrefs.getString('username');
    String? prefPassword = sharedPrefs.getString('password');

    logger.d("try login");
    if (!Provider.of<LoginModel>(context, listen: false).isLoggedOff) {
      Provider.of<LoginModel>(context).user.login(
          usernameController.text, passwordController.text,
          force: false, ignoreLoading: false, callback: callback);
    }

    if (prefUsername != null) {
      usernameController.text = prefUsername;
    }
    if (prefPassword != null) {
      passwordController.text = prefPassword;
    }

    return Consumer<LoginModel>(
      builder: (context, model, widget) {
        if (!model.isLoading) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 150,
                width: 200,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      height: 12,
                    ),
                    Expanded(
                        child: TextField(
                      obscureText: false,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '账号',
                      ),
                      controller: usernameController,
                    )),
                    Expanded(
                        child: TextField(
                      obscureText: _isObscured,
                      decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: '密码',
                          suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _isObscured = !_isObscured;
                                });
                              },
                              icon: Icon(_isObscured
                                  ? Icons.visibility_off
                                  : Icons.visibility))),
                      controller: passwordController,
                    )),
                  ],
                ),
              ),
              const SizedBox(
                width: 20,
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    height: 12,
                  ),
                  Flexible(
                      child: FancyButton(
                          gradients: const [
                        Color(0xFFFF7200),
                        Color(0xFFF65E0A),
                        Color(0xFFEC3355),
                      ],
                          callback: () async {
                            Provider.of<LoginModel>(context, listen: false)
                                .setLoggedOff(false);
                            Provider.of<LoginModel>(context, listen: false)
                                .setLoading(true);
                            final username = usernameController.text;
                            final password = passwordController.text;

                            sharedPrefs.setString("username", username);
                            sharedPrefs.setString("password", password);

                            User user = User();
                            Provider.of<LoginModel>(context, listen: false)
                                .setUser(user);
                            Result result =
                                await user.login(username, password);
                            if (mounted) {
                              if (result.state) {
                                Provider.of<LoginModel>(context, listen: false)
                                    .setLoggedIn(true);
                                logger.d(user.session?.xToken);
                                /*
                                Provider.of<LoginModel>(context, listen: false)
                                    .user
                                    .telemetryLogin();
                                 */
                              } else {
                                SnackBar snackBar = SnackBar(
                                  content: Text(
                                      '呜呜呜，登录失败了……\n失败原因：${result.message}'),
                                  backgroundColor:
                                      ThemeMode.system == ThemeMode.dark
                                          ? Colors.grey[900]
                                          : Colors.grey[200],
                                );
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(snackBar);
                                Provider.of<LoginModel>(context, listen: false)
                                    .setLoading(false);
                              }
                            }
                            /*
                            Future.delayed(
                                const Duration(seconds: 2),
                                () => Provider.of<LoginModel>(context,
                                        listen: false)
                                    .setLoggedIn(true));
                             */
                            // setLoggedIn(true);
                          },
                          text: '登录')),
                ],
              )
            ],
          );
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }
}
