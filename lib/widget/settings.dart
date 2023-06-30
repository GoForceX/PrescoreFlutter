import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:r_upgrade/r_upgrade.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:upgrader/upgrader.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version/version.dart';

import '../main.dart';
import 'drawer.dart';

@RoutePage()
class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Future<void> showUpgradeAlert(BuildContext context) async {
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
            showDialog<String>(
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
                      RUpgrade.upgrade(item.fileURL!,
                          fileName: 'app-release.apk',
                      );
                      Navigator.pop(dialogContext, '当然是更新啦');
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

  Future<void> showChangeCountDialog(BuildContext context) async {
    final classCountController = TextEditingController();
    showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('你所在的班级有多少人？'),
        content: TextField(
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'\d')),
            ],
            obscureText: false,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: '班级人数',
            ),
            controller: classCountController),
        actions: <Widget>[
          TextButton(
            onPressed: () async {
              BaseSingleton.singleton.sharedPreferences.setInt(
                  'classCount', int.tryParse(classCountController.text) ?? 45);
              setState(() {});
              Navigator.pop(dialogContext, '确定');
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: SettingsList(
        sections: [
          SettingsSection(
            title: const Text('基本设置'),
            tiles: [
              SettingsTile.navigation(
                leading: const Icon(Icons.numbers_rounded),
                title: const Text('班级人数'),
                description: Text(
                    "${BaseSingleton.singleton.sharedPreferences.getInt("classCount") ?? 45}"),
                onPressed: (BuildContext context) {
                  showChangeCountDialog(context);
                },
              ),
              SettingsTile.switchTile(
                onToggle: (value) {
                  BaseSingleton.singleton.sharedPreferences
                      .setBool('useExperimentalDraw', value);
                  setState(() {});
                },
                initialValue: BaseSingleton.singleton.sharedPreferences
                    .getBool('useExperimentalDraw'),
                leading: const Icon(Icons.brush),
                title: const Text('在原卷上绘制扣分等信息'),
                description:
                    const Text('实验性功能，可能会导致卡顿和图片无法加载，若遇到问题，请将此设置关闭并在论坛报告。'),
              ),
              SettingsTile.switchTile(
                onToggle: (value) {
                  BaseSingleton.singleton.sharedPreferences
                      .setBool('allowTelemetry', value);
                  setState(() {});
                },
                initialValue: BaseSingleton.singleton.sharedPreferences
                    .getBool('allowTelemetry'),
                leading: const Icon(Icons.cloud_upload),
                title: const Text('允许上传数据'),
                description: const Text('向服务器上传考试数据'),
              ),
              SettingsTile.navigation(
                leading: const Icon(Icons.update),
                title: const Text('检查更新'),
                onPressed: (BuildContext context) {
                  showUpgradeAlert(context);
                },
              ),
            ],
          ),
          SettingsSection(
            title: const Text('关于'),
            tiles: [
              SettingsTile.navigation(
                leading: const Icon(Icons.info),
                title: const Text("当前版本"),
                description: Text(BaseSingleton.singleton.packageInfo.version),
              ),
              SettingsTile.navigation(
                leading: const Icon(Icons.web),
                title: const Text("问题反馈"),
                onPressed: (_) {
                  launchUrl(Uri.parse("https://youtrack.bjbybbs.com/"),
                      mode: LaunchMode.externalApplication);
                },
              ),
              SettingsTile.navigation(
                leading: const Icon(Icons.web),
                title: const Text("支持一下？"),
                description: const Text("会非常感谢你的！"),
                onPressed: (_) {
                  launchUrl(Uri.parse("https://afdian.net/a/GoForceX"),
                      mode: LaunchMode.externalApplication);
                },
              ),
              SettingsTile.navigation(
                leading: const Icon(Icons.web),
                title: const Text("去论坛看看"),
                onPressed: (_) {
                  launchUrl(Uri.parse("https://bjbybbs.com/t/Revealer"),
                      mode: LaunchMode.externalApplication);
                },
              ),
              SettingsTile.navigation(
                leading: const Icon(Icons.web),
                title: const Text("去官网看看"),
                onPressed: (_) {
                  launchUrl(
                      Uri.parse("https://matrix.bjbybbs.com/docs/landing"),
                      mode: LaunchMode.externalApplication);
                },
              ),
            ],
          ),
        ],
      ),
      drawer: const MainDrawer(),
    );
  }
}

/*
class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  Future<void> showUpgradeAlert(BuildContext context) async {
    String appcastURL = 'https://matrix.bjbybbs.com/appcast.xml';
    final appcast = Appcast();
    await appcast.parseAppcastItemsFromUri(appcastURL);
    AppcastItem? item = appcast.bestItem();
    if (item != null) {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      if (Version.parse(packageInfo.version) < Version.parse(item.versionString)) {
        logger.i("got update: ${item.fileURL!}");
        showDialog<String>(
          context: context,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: const Text('现在要更新吗？'),
            content: Text(
                '获取到最新版本${item.versionString}，然而当前版本是${packageInfo.version}\n\n你需要更新吗？\n\n更新日志：\n${item.itemDescription}'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext, '但是我拒绝');
                },
                child: const Text('但是我拒绝'),
              ),
              TextButton(
                onPressed: () async {
                  RUpgrade.upgrade(
                      item.fileURL!, fileName: 'app-release.apk', isAutoRequestInstall: true);
                  Navigator.pop(dialogContext, '当然是更新啦');
                },
                child: const Text('当然是更新啦'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: SettingsList(
        sections: [
          SettingsSection(
            title: const Text('基本设置'),
            tiles: [
              SettingsTile.switchTile(
                onToggle: (value) {
                  BaseSingleton()
                      .sharedPreferences
                      .setBool('allowTelemetry', value);
                },
                initialValue:
                    BaseSingleton().sharedPreferences.getBool('allowTelemetry'),
                leading: const Icon(Icons.cloud_upload),
                title: const Text('允许上传数据'),
                description: const Text('向服务器上传考试数据'),
              ),
              SettingsTile.navigation(
                leading: const Icon(Icons.update),
                title: const Text('检查更新'),
                onPressed: (BuildContext context) {
                  showUpgradeAlert(context);
                },
              ),
            ],
          ),
          SettingsSection(
            title: const Text('关于'),
            tiles: [
              SettingsTile.navigation(
                leading: const Icon(Icons.info),
                title: const Text("当前版本"),
                description: Text(BaseSingleton().packageInfo.version),
              ),
              SettingsTile.navigation(
                leading: const Icon(Icons.web),
                title: const Text("去网页看看"),
                onPressed: (_) {
                  launchUrl(Uri.parse("https://matrix.bjbybbs.com/docs/landing"));
                },
              ),
            ],
          ),
        ],
      ),
      drawer: const MainDrawer(),
    );
  }
}
 */
