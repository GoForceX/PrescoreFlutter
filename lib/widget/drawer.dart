import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prescore_flutter/model/login_model.dart';
import 'package:prescore_flutter/widget/user_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prescore_flutter/main.dart';
import '../../util/user_util.dart';
import 'package:prescore_flutter/service.dart' show refreshService;

import '../main.gr.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;

late Database database;
const String tableName = "userSession";

Future<void> initDataBase() async {
  database = await openDatabase(
    path.join(await getDatabasesPath(), 'UserSession.db'),
    onCreate: (db, version) async {
      var tableExists = await db
          .rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='$tableName'");
      if (tableExists.isEmpty) {
        logger.d("tableNotExists, CREATE TABLE $tableName");
        db.execute(
          'CREATE TABLE $tableName (userId TEXT, st TEXT, sessionId TEXT, xToken TEXT PRIMARY KEY, serverToken TEXT)',
        );
      }
    },
    version: 1,
  );
}


class MainDrawer extends StatefulWidget {
  const MainDrawer({super.key});

  @override
  State<MainDrawer> createState() => _MainDrawerState();
}

class Destination {
  const Destination(this.label, this.icon, this.selectedIcon, this.router, this.enabled);

  final String label;
  final Widget icon;
  final Widget selectedIcon;
  final PageRouteInfo router;
  final bool enabled;
}

class _MainDrawerState extends State<MainDrawer> {
  SharedPreferences sharedPrefs = BaseSingleton.singleton.sharedPreferences;
  int get currentIndex {
    for (int i = 0; i < destinations.length; i++) {
      if (destinations[i].router.routeName ==
          ModalRoute.of(context)?.settings.name) {
        return i;
      }
    }
    return 0;
  }
  List<dynamic> destinations = [
    const Destination('考试列表', Icon(Icons.home_outlined), Icon(Icons.home), HomeRoute(), true),
    const Destination(
        '设置', Icon(Icons.settings_applications_outlined), Icon(Icons.settings_applications), SettingsRoute(), true),
    const Destination(
        '错题集', Icon(Icons.book_outlined), Icon(Icons.book_rounded), ErrorBookRoute(), true),
  ];

  void logout(context) async {
    await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('你要退出账号吗？'),
        content: const Text('退出现在的账号，你要这么做吗？'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, '我点错了'),
            child: const Text('我点错了'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext, '果断退出');
              Navigator.pop(context);
              Provider.of<LoginModel>(context, listen: false)
                  .setLoggedIn(false);
              Provider.of<LoginModel>(context, listen: false).setLoading(false);
              Provider.of<LoginModel>(context, listen: false).user.logoff();
              Provider.of<LoginModel>(context, listen: false).setUser(User());
              dialogContext.router.replaceAll([const HomeRoute()]);
              //MethodChannel channel = const MethodChannel('MainActivity');
              //channel.invokeMethod('stopService');
              refreshService();
            },
            child: const Text('果断退出'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        NavigationDrawer(
          onDestinationSelected: (selectedIndex) {
            setState(() {
              //currentIndex = selectedIndex;
              if(selectedIndex == destinations.length) {
                logout(context);
                return;
              }
              Navigator.pop(context);
              context.router.replace(destinations[selectedIndex].router);
            });
          },
          selectedIndex: currentIndex,
          children: [
            const SizedBox(height: 30),
            const MainAppbarWidget(),
            const Divider(indent: 36, endIndent: 36, height: 55),
            ...destinations.map((destination) {
              if(destination.runtimeType != Destination) {
                return destination;
              } 
              return NavigationDrawerDestination(
                label: Text(destination.label, style: const TextStyle(fontSize: 18)),
                icon: destination.icon,
                selectedIcon: destination.selectedIcon,
                enabled: destination.enabled || sharedPrefs.getBool("developMode") == true,
              );
            }),
            const Divider(indent: 36, endIndent: 36),
            const NavigationDrawerDestination(
              label: Text("登出", style: TextStyle(fontSize: 18)),
              icon: Icon(Icons.logout)
            )
            //const Divider(indent: 36, endIndent: 36),
          ],
        ),
        /*Positioned(
          bottom: 24,
          right: 24,
          child: FilledButton.tonal(
            onPressed: () => logout(context),
            child: const Row(children: [Icon(Icons.logout), SizedBox(width: 5), Text(' 登出', style: TextStyle(fontSize: 18))])
          ),
        ),*/
      ],
    );
  }
}
