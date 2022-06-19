import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

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
              color: Colors.blue,
            ),
            child: Text('头部'),
          ),
          ListTile(
            title: const Text('主页'),
            onTap: () {
              Navigator.pop(context);
              context.router.navigateNamed("/");
            },
          ),
        ],
      ),
    );
  }
}
