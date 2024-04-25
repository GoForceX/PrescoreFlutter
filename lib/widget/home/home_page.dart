import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:prescore_flutter/main.dart';
import 'package:prescore_flutter/model/login_model.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrader/upgrader.dart';
import 'package:version/version.dart';
import 'package:r_upgrade/r_upgrade.dart';
import 'package:prescore_flutter/widget/drawer.dart';
import 'exams.dart';
import 'login.dart';

@RoutePage()
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  HomePageState({Key? key}) : super();
  bool isLoggedIn = false;
  bool isUpgradeAlertDialogShown = false;
  bool isRequestDialogShown = false;

  void setLoggedIn(bool value) {
    setState(() => isLoggedIn = value);
  }

  Future<void> showUpgradeInfo(BuildContext context) async {
    if (BaseSingleton.singleton.sharedPreferences.getBool('checkUpdate') ==
        false) {
      return;
    }
    String appcastURL = 'https://matrix.bjbybbs.com/appcast.xml';
    final appcast = Appcast();
    await appcast.parseAppcastItemsFromUri(appcastURL);
    AppcastItem? item = appcast.bestItem();
    if (item != null) {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      if (context.mounted) {
        String? versionString = item.versionString;
        if (versionString != null) {
          if (Version.parse(packageInfo.version) <
              Version.parse(versionString)) {
            logger.i("got update: ${item.fileURL!}");
            if (isUpgradeAlertDialogShown) {
              return;
            }
            isUpgradeAlertDialogShown = true;
            await showDialog<String>(
              context: context,
              builder: (BuildContext dialogContext) => AlertDialog(
                title: const Text('现在要更新吗？'),
                content: Text(
                    '获取到最新版本$versionString，然而当前版本是${packageInfo.version}\n\n你需要更新吗？\n\n更新日志：\n${item.itemDescription}'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext, '但是我拒绝');
                    },
                    child: const Text('但是我拒绝'),
                  ),
                  TextButton(
                    onPressed: () async {
                      int? update = await RUpgrade.upgrade(item.fileURL!,
                          fileName: 'app-release.apk',
                          installType: RUpgradeInstallType.normal);
                      if (update != null) {
                        bool? isSuccess = await RUpgrade.install(update);
                        if (isSuccess != true) {
                          if (mounted) {
                            await showDialog<String>(
                                context: context,
                                builder: (BuildContext dialogContext) =>
                                    AlertDialog(
                                      title: const Text('更新失败'),
                                      content: const Text('新版本更新失败，或许可以再试一次？'),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () async {
                                            Navigator.pop(dialogContext, '好哦');
                                          },
                                          child: const Text('好哦'),
                                        ),
                                      ],
                                    ));
                          }
                        }
                      } else {
                        if (mounted) {
                          await showDialog<String>(
                              context: context,
                              builder: (BuildContext dialogContext) =>
                                  AlertDialog(
                                    title: const Text('更新失败'),
                                    content: const Text('新版本更新失败，或许可以再试一次？'),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () async {
                                          Navigator.pop(dialogContext, '好哦');
                                        },
                                        child: const Text('好哦'),
                                      ),
                                    ],
                                  ));
                        }
                      }
                      if (mounted) {
                        Navigator.pop(dialogContext, '当然是更新啦');
                      }
                    },
                    child: const Text('当然是更新啦'),
                  ),
                ],
              ),
            );
          }
        }
      }
    }
  }

  Future<void> showRequestDialog(BuildContext context) async {
    SharedPreferences? shared = BaseSingleton.singleton.sharedPreferences;
    bool? allowed = shared.getBool("allowTelemetry");
    bool? requested = shared.getBool("telemetryRequested");
    logger.d("allowed: $allowed, requested: $requested");
    allowed ??= false;
    requested ??= false;
    if (!allowed && !requested) {
      shared.setBool("telemetryRequested", true);
      logger.d("show request dialog");
      if (isRequestDialogShown) {
        return;
      }
      isRequestDialogShown = true;
      await showDialog<String>(
          context: context,
          builder: (BuildContext dialogContext) => AlertDialog(
                title: const Text('授权向服务器上传数据'),
                content: const Text(
                    '点击确定\n即为您自愿授权将已获取的分数自动同步到本软件服务器\n同意本软件在境外服务器存储您的成绩信息\n点击取消仍可使用本App基本功能。\n\n选项可在设置中进行修改。'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      SnackBar snackBar = const SnackBar(
                          content: Text('拒绝之后小部分功能可能无法使用哦，在侧边栏设置中可以手动授权！'));
                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      Navigator.pop(dialogContext, '不要');
                    },
                    child: const Text('不要'),
                  ),
                  TextButton(
                    onPressed: () async {
                      shared.setBool("allowTelemetry", true);
                      Navigator.pop(dialogContext, '同意');
                    },
                    child: const Text('同意'),
                  ),
                ],
              ));
    }
  }

  @override
  Widget build(BuildContext context) {
    Future.microtask(() {
      showRequestDialog(context);
      showUpgradeInfo(context);
    });
    return Consumer<LoginModel>(builder: (context, model, child) {
      return Scaffold(
          /*appBar: AppBar(
                title: const Text('出分啦'),
                actions: [
                  IconButton(
                      onPressed: onNavigatingForum,
                      icon: const Icon(Icons.insert_comment))
                ],
              ),*/
          body: Builder(builder: (BuildContext context) {
            if (!(model.isLoggedIn)) {
              return const Center(child: LoginWidget());
            } else {
              return const Exams();
            }
          }),
          drawer: model.isLoggedIn ? const MainDrawer() : null);
    });
  }
}