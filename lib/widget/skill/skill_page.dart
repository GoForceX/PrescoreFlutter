import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:prescore_flutter/model/skill_model.dart';
import 'package:prescore_flutter/widget/skill/skill_detail.dart';
import 'package:prescore_flutter/widget/skill/skill_partner.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../util/user_util.dart';
import '../drawer.dart';

@RoutePage()
class SkillPage extends StatefulWidget {
  final User? user;
  const SkillPage({super.key, required this.user});

  @override
  State<SkillPage> createState() => _SkillPageState();
}

class _SkillPageState extends State<SkillPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    logger.d("skill system: init");

    if (widget.user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('出分啦'),
        ),
        drawer: const MainDrawer(),
        body: const Center(
          child: Text(
            '请先在主页登录哦~',
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('出分啦'),
      ),
      drawer: const MainDrawer(),
      body: ChangeNotifierProvider(
        create: (_) => SkillModel(),
        builder: (BuildContext context, Widget? child) {
          SkillModel model = Provider.of<SkillModel>(context, listen: false);
          model.user = widget.user!;
          Widget chosenWidget = Container();
          switch (_selectedIndex) {
            case 0:
              chosenWidget = const SkillDetail();
              break;
            case 1:
              chosenWidget = const SkillPartner();
              break;
            default:
              chosenWidget = Container();
          }
          return Center(
            child: Container(
              padding: const EdgeInsets.all(8),
              child: chosenWidget,
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.self_improvement),
            label: '我的',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_outlined),
            label: '伴学',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
