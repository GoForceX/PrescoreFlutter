import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:prescore_flutter/main.dart';

import '../main.gr.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.lightBlueAccent, Colors.lightBlue, Colors.blue],
              ),
            ),
            child: Text('出分啦！'),
          ),
          ListTile(
            title: const Text('主页'),
            onTap: () {
              Navigator.pop(context);
              context.router.navigateNamed("/");
            },
          ),
          ListTile(
            title: const Text('能力'),
            onTap: () {
              Navigator.pop(context);
              context.router.navigate(SkillRoute(user: BaseSingleton.singleton.currentUser));
            },
          ),
          ListTile(
            title: const Text('设置'),
            onTap: () {
              Navigator.pop(context);
              context.router.navigate(const SettingsRoute());
            },
          ),
        ],
      ),
    );
  }
}
