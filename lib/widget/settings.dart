import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import 'drawer.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

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
