import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:r_upgrade/r_upgrade.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:upgrader/upgrader.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version/version.dart';

import '../main.dart';
import 'drawer.dart';

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
                  BaseSingleton.singleton
                      .sharedPreferences
                      .setBool('allowTelemetry', value);
                  setState(() {});
                },
                initialValue:
                BaseSingleton.singleton.sharedPreferences.getBool('allowTelemetry'),
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