import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:prescore_flutter/constants.dart';
import 'package:prescore_flutter/model/login_model.dart';
import 'package:provider/provider.dart';
import 'package:r_upgrade/r_upgrade.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:upgrader/upgrader.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version/version.dart';

import '../main.dart';
import 'package:prescore_flutter/service.dart' as service;
import 'package:prescore_flutter/util/struct.dart';
import 'drawer.dart';

class SelectColorDialog extends StatefulWidget {
  const SelectColorDialog({super.key});

  @override
  SelectColorDialogState createState() => SelectColorDialogState();
}

class SelectColorDialogState extends State<SelectColorDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择应用主题色'),
      content: Wrap(
          alignment: WrapAlignment.center,
          children: brandColorMap.entries.map((entry) {
            return Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: entry.value.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  width: 2,
                  color: BaseSingleton.singleton.sharedPreferences
                              .getString("brandColor") ==
                          entry.key
                      ? Colors.black
                      : entry.value.withOpacity(0.8),
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                child: AnimatedOpacity(
                  opacity: BaseSingleton.singleton.sharedPreferences
                              .getString("brandColor") ==
                          entry.key
                      ? 1
                      : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.done,
                    color: Colors.black,
                    size: 20,
                  ),
                ),
                onTap: () {
                  setState(() {
                    BaseSingleton.singleton.sharedPreferences
                        .setString("brandColor", entry.key);
                    WidgetsFlutterBinding.ensureInitialized()
                        .performReassemble();
                  });
                },
              ),
            );
          }).toList()),
      actions: <Widget>[
        TextButton(
          onPressed: () async {
            Navigator.pop(context, '确定');
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}

@RoutePage()
class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String selectedDeviceName = BaseSingleton.singleton.sharedPreferences
          .getString('selectedWearDeviceName') ??
      "";
  bool huaweiHealthAvailable = false;
  String huaweiHealthErrMsg = "";
  MethodChannel channel = const MethodChannel('MainActivity');
  List<Map<String, String>> convertToMapList(List<dynamic> list) {
    return list.map((item) => Map<String, String>.from(item)).toList();
  }

  Future<List<Map<String, String>>?> getBoundDevices() async {
    final result = await channel.invokeMethod('getBoundDevices');
    return convertToMapList(result);
  }

  Widget chooseDeviceDialog(BuildContext context) {
    return AlertDialog(
      title: const Text('选择设备'),
      content: FutureBuilder<List<Map<String, String>>?>(
        future: getBoundDevices(),
        builder: (BuildContext context,
            AsyncSnapshot<List<Map<String, String>>?> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 40,
              width: 40,
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Text('${snapshot.error}');
          } else {
            if (snapshot.data != null) {
              return SizedBox(
                  height: 80,
                  child: ListView.separated(
                    itemCount: snapshot.data!.length,
                    separatorBuilder: (BuildContext context, int index) =>
                        const Divider(),
                    itemBuilder: (BuildContext context, int index) {
                      return ListTile(
                        title: Text(snapshot.data![index].values.join(" ")),
                        onTap: () {
                          BaseSingleton.singleton.sharedPreferences.setString(
                              'selectedWearDeviceName',
                              snapshot.data![index].values.join(" "));
                          BaseSingleton.singleton.sharedPreferences.setString(
                              'selectedWearDeviceUUID',
                              snapshot.data![index].keys.join(" "));
                          setState(() {
                            selectedDeviceName =
                                snapshot.data![index].values.join(" ");
                          });
                          service.refreshService();
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ));
            } else {
              return const Text("未发现设备");
            }
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () {
            BaseSingleton.singleton.sharedPreferences
                .setString('selectedWearDeviceName', '');
            BaseSingleton.singleton.sharedPreferences
                .setString('selectedWearDeviceUUID', '');
            setState(() {
              selectedDeviceName = "";
            });
            service.refreshService();
            Navigator.of(context).pop();
          },
          child: const Text('取消已选'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('关闭'),
        ),
      ],
    );
  }

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
                      RUpgrade.upgrade(
                        item.fileURL!,
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
    LoginModel model = Provider.of<LoginModel>(context, listen: false);

    showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('你的班级有多少人？'),
        content: SingleChildScrollView(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              TextField(
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
              const SizedBox(height: 8),
              FutureBuilder(
                future: model.user.fetchClassmate(),
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  if (snapshot.hasData) {
                    return Row(children: [
                      const Icon(Icons.people, size: 18),
                      Text(
                          " ${model.user.studentInfo?.gradeName}${model.user.studentInfo?.className}: ",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(" ${snapshot.data.length} 人")
                    ]);
                  } else {
                    return Container();
                  }
                },
              )
            ])),
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

  Future<void> showChangeTimerDialog(BuildContext context) async {
    final classCountController = TextEditingController();
    showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('后台轮询时间间隔'),
        content: TextField(
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'\d')),
            ],
            obscureText: false,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: '时间 (分钟)',
            ),
            controller: classCountController),
        actions: <Widget>[
          TextButton(
            onPressed: () async {
              int checkExamsInterval =
                  int.tryParse(classCountController.text) ?? 15;
              if (checkExamsInterval < 10) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('时间间隔不能小于10')));
                return;
              }
              BaseSingleton.singleton.sharedPreferences
                  .setInt('checkExamsInterval', checkExamsInterval);
              service.refreshService();
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
  void initState() {
    getBoundDevices().then(
      (value) {
        huaweiHealthErrMsg = "";
        huaweiHealthAvailable = true;
        setState(() {});
      },
    ).catchError((e) async {
      logger.e(e.message);
      if (e.message.contains("Scope unauthorized") ||
          e.message.contains("Health app not exist")) {
        huaweiHealthErrMsg = e.message;
        huaweiHealthAvailable = false;
        await BaseSingleton.singleton.sharedPreferences
            .setBool('enableWearService', false);
      } else {
        huaweiHealthErrMsg = "";
        huaweiHealthAvailable = true;
      }
      setState(() {});
    });
    super.initState();
  }
  int lastPress = 0;
  int pressCount = 0;
  @override
  Widget build(BuildContext context) {
    bool isPushEnabled =
        BaseSingleton.singleton.sharedPreferences.getBool('checkExams') ??
            false;
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: SettingsList(
        darkTheme: SettingsThemeData(
            settingsListBackground: Theme.of(context).colorScheme.surface),
        lightTheme: SettingsThemeData(
            settingsListBackground: Theme.of(context).colorScheme.surface),
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
                title: const Text('在原卷上绘制分数信息'),
                description: const Text('绘制扣分、小分、切题框等信息'),
              ),
              SettingsTile.switchTile(
                onToggle: (value) {
                  BaseSingleton.singleton.sharedPreferences
                      .setBool('defaultShowAllSubject', value);
                  setState(() {});
                },
                initialValue: BaseSingleton.singleton.sharedPreferences
                    .getBool('defaultShowAllSubject'),
                leading: const Icon(Icons.visibility),
                title: const Text('默认显示所有科目'),
                description: const Text('在单科查看页默认全选'),
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
              if (BaseSingleton.singleton.sharedPreferences
                      .getBool("developMode") ==
                  true)
                SettingsTile.switchTile(
                  onToggle: (value) {
                    BaseSingleton.singleton.sharedPreferences
                        .setBool('showMarkingRecords', value);
                    setState(() {});
                  },
                  initialValue: BaseSingleton.singleton.sharedPreferences
                      .getBool('showMarkingRecords'),
                  leading: const Icon(Icons.update),
                  title: const Text('显示判卷记录'),
                  description: const Text('在分数细则页显示判卷人'),
                ),
              if (BaseSingleton.singleton.sharedPreferences
                          .getBool("developMode") ==
                      true)
                SettingsTile.switchTile(
                  onToggle: (value) {
                    BaseSingleton.singleton.sharedPreferences
                        .setBool('showMoreSubject', value);
                    setState(() {});
                  },
                  initialValue: BaseSingleton.singleton.sharedPreferences
                      .getBool('showMoreSubject'),
                  leading: const Icon(Icons.more_horiz),
                  title: const Text('更多科目'),
                  description: const Text('在单科查看页包含判卷中和未参加的科目'),
                ),
              if (BaseSingleton.singleton.sharedPreferences
                          .getBool("developMode") ==
                      true &&
                  !kReleaseMode)
                SettingsTile.switchTile(
                  onToggle: (value) {
                    BaseSingleton.singleton.sharedPreferences
                        .setBool('tryPreviewScore', value);
                    setState(() {});
                  },
                  initialValue: BaseSingleton.singleton.sharedPreferences
                      .getBool('tryPreviewScore'),
                  leading: const Icon(Icons.preview),
                  title: const Text('提前查分(Beta)'),
                  description: const Text('提前查询正在阅卷中的分数，不代表最终分数，可能失效'),
                ),
              /*SettingsTile.switchTile(
                onToggle: (value) {
                  BaseSingleton.singleton.sharedPreferences
                      .setBool('checkUpdate', value);
                  setState(() {});
                },
                initialValue: BaseSingleton.singleton.sharedPreferences
                    .getBool('checkUpdate'),
                leading: const Icon(Icons.update),
                title: const Text('启动时检查更新'),
              ),*/
              SettingsTile.navigation(
                leading: const Icon(Icons.update),
                title: const Text('检查更新'),
                onPressed: (BuildContext context) {
                  showUpgradeAlert(context);
                },
              ),
            ],
          ),
          SettingsSection(title: const Text('外观样式'), tiles: [
            SettingsTile.switchTile(
              onToggle: (value) {
                BaseSingleton.singleton.sharedPreferences
                    .setBool('useDynamicColor', value);
                setState(() {});
              },
              description: const Text('动态提取壁纸主题色，支持Android 12+'),
              initialValue: BaseSingleton.singleton.sharedPreferences
                  .getBool('useDynamicColor'),
              leading: const Icon(Icons.colorize_outlined),
              title: const Text('动态取色'),
            ),
            SettingsTile.navigation(
              leading: const Icon(Icons.color_lens_outlined),
              title: const Text('主题色'),
              onPressed: (BuildContext context) {
                showDialog(
                    context: context,
                    builder: (BuildContext dialogContext) =>
                        const SelectColorDialog());
              },
              trailing: Container(
                width: 30,
                height: 30,
                margin: const EdgeInsets.only(right: 7),
                decoration: BoxDecoration(
                  color: (brandColorMap[BaseSingleton
                              .singleton.sharedPreferences
                              .getString("brandColor")] ??
                          Colors.blue)
                      .withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    width: 2,
                    color: (brandColorMap[BaseSingleton
                                .singleton.sharedPreferences
                                .getString("brandColor")] ??
                            Colors.blue)
                        .withOpacity(0.8),
                  ),
                ),
              ),
              description: Text(
                  "当前选择「${BaseSingleton.singleton.sharedPreferences.getString("brandColor")!}」"),
              enabled: BaseSingleton.singleton.sharedPreferences
                      .getBool('useDynamicColor') ==
                  false,
            ),
          ]),
          if (BaseSingleton.singleton.sharedPreferences
                  .getBool("developMode") ==
              true && Platform.isAndroid)
            SettingsSection(
              title: const Text('后台服务(Beta)'),
              tiles: [
                /*SettingsTile.switchTile(
                onToggle: (value) async {
                  await BaseSingleton.singleton.sharedPreferences
                      .setBool('useWakeLock', value);
                  refreshService();
                  setState(() {});
                },
                initialValue: BaseSingleton.singleton.sharedPreferences
                    .getBool('useWakeLock') ,
                leading: const Icon(Icons.lock),
                title: const Text('使用唤醒锁'),
                description: const Text('当出分啦在后台运行时，保持 CPU 唤醒状态'),
              ),*/
                if (!kReleaseMode)
                  SettingsTile.switchTile(
                    onToggle: (value) async {
                      if (value &&
                          BaseSingleton.singleton.sharedPreferences
                                  .getBool("keepLogin") ==
                              false) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('请启用"保持登录", 否则服务不会启动')));
                        return;
                      }
                      if (value) {
                        await service.initDataBase();
                        Result result =
                            await service.checkExams(firstRun: true);
                        if (!result.state) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('考试变动推送初始化失败，请检查凭证和网络')));
                          return;
                        }
                      }
                      await BaseSingleton.singleton.sharedPreferences
                          .setBool('checkExams', value);
                      service.refreshService();
                      setState(() {
                        isPushEnabled = value;
                      });
                    },
                    initialValue: BaseSingleton.singleton.sharedPreferences
                        .getBool('checkExams'),
                    leading: const Icon(Icons.notifications),
                    title: const Text('考试变动推送'),
                    description: const Text('当发布新的成绩时通知，需后台定期查询数据，可能造成异常！'),
                  ),
                if (!kReleaseMode)
                  SettingsTile.navigation(
                      leading: const Icon(Icons.timer),
                      title: const Text("后台轮询时间间隔"),
                      description: Text(
                          "${BaseSingleton.singleton.sharedPreferences.getInt("checkExamsInterval") ?? "Null"} 分钟"),
                      onPressed: (BuildContext context) {
                        showChangeTimerDialog(context);
                      },
                      enabled: isPushEnabled),
                SettingsTile.switchTile(
                  onToggle: (value) async {
                    if (value &&
                        BaseSingleton.singleton.sharedPreferences
                                .getBool("keepLogin") ==
                            false) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('请启用"保持登录", 否则服务不会启动')));
                      return;
                    }
                    await BaseSingleton.singleton.sharedPreferences
                        .setBool('enableWearService', value);
                    service.refreshService();
                    setState(() {});
                  },
                  initialValue: BaseSingleton.singleton.sharedPreferences
                      .getBool('enableWearService'),
                  leading: const Icon(Icons.upload),
                  title: const Text('启动穿戴推送'),
                  description: huaweiHealthAvailable
                      ? const Text('连接华为轻量手表端应用')
                      : const Text('连接华为轻量手表端应用(暂不可用)'),
                  enabled: huaweiHealthAvailable,
                ),
                SettingsTile.navigation(
                  leading: const Icon(Icons.watch),
                  title: const Text("选择设备"),
                  description: BaseSingleton.singleton.sharedPreferences
                                  .getString('selectedWearDeviceName') ==
                              null ||
                          BaseSingleton.singleton.sharedPreferences
                                  .getString('selectedWearDeviceName') ==
                              ""
                      ? const Text('目前未选择设备')
                      : Text('已选择 $selectedDeviceName'),
                  onPressed: (BuildContext context) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return chooseDeviceDialog(context);
                      },
                    );
                  },
                  enabled: huaweiHealthAvailable,
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
                onPressed: (context) {
                  ScaffoldMessenger.of(context).removeCurrentSnackBar();
                  if (BaseSingleton.singleton.sharedPreferences
                          .getBool("developMode") ==
                      true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('您已启用开发者模式')));
                    return;
                  }
                  if (DateTime.now().millisecondsSinceEpoch - lastPress > 500) {
                    pressCount = 0;
                  }
                  pressCount++;
                  lastPress = DateTime.now().millisecondsSinceEpoch;
                  if (pressCount >= 5) {
                    BaseSingleton.singleton.sharedPreferences
                        .setBool("developMode", true);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        showCloseIcon: true,
                        duration: Duration(seconds: 30),
                        content: Row(children: [
                          Icon(Icons.warning_amber, color: Colors.red),
                          SizedBox(width: 8),
                          Flexible(child: Text('开发者模式开启，启用了未完成或不稳定的功能，请谨慎使用'))
                        ])));
                    setState(() {});
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('再点击 ${5 - pressCount} 次启用开发者模式')));
                  }
                  return;
                },
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
