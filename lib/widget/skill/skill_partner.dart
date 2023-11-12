import 'package:flutter/material.dart';
import 'package:prescore_flutter/widget/skill/skill_detail.dart';
import 'package:prescore_flutter/widget/skill/skill_header.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../model/skill_model.dart';
import '../../util/user_util.dart';

class SkillPartner extends StatefulWidget {
  const SkillPartner({super.key});

  @override
  State<SkillPartner> createState() => _SkillPartnerState();
}

class _SkillPartnerState extends State<SkillPartner> {
  @override
  Widget build(BuildContext context) {
    User user = Provider.of<SkillModel>(context, listen: false).user;

    return Flex(
      direction: Axis.vertical,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(8),
            shrinkWrap: false,
            children: const [SkillMatch()],
          ),
        )
      ],
    );
  }
}

class SkillMatch extends StatefulWidget {
  const SkillMatch({super.key});

  @override
  State<SkillMatch> createState() => _SkillMatchState();
}

class _SkillMatchState extends State<SkillMatch> {
  List<ChartData> p1 = [
    ChartData("语文", -3.055),
    ChartData("数学", 2.325),
    ChartData("英语", -3.417),
    ChartData("物理", -2.773),
    ChartData("化学", 4.125),
    ChartData("生物", 1.844)
  ];
  List<ChartData> p2 = [
    ChartData("语文", 2.055),
    ChartData("数学", 7.325),
    ChartData("英语", -1.841),
    ChartData("物理", 2.483),
    ChartData("化学", -4.125),
    ChartData("生物", 1.844)
  ];

  @override
  Widget build(BuildContext context) {
    return Flex(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      direction: Axis.horizontal,
      children: [
        Expanded(
          child: Column(
            children: [
              const Text("你的能力"),
              const SizedBox(
                height: 8,
              ),
              const CircleAvatar(
                radius: 40,
                backgroundImage: AssetImage('assets/akarin.webp'),
              ),
              const SizedBox(
                height: 8,
              ),
              const Text("P1"),
              SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                series: <ChartSeries>[
                  BarSeries<ChartData, String>(
                    dataSource: p1,
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.y,
                    pointColorMapper: (ChartData data, int index) =>
                        p1[index].y > p2[index].y
                            ? Colors.yellow
                            : Colors.blueGrey,
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                  )
                ],
              )
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              const Text("对方能力"),
              const SizedBox(
                height: 8,
              ),
              const CircleAvatar(
                radius: 40,
                backgroundImage: AssetImage('assets/akarin.webp'),
              ),
              const SizedBox(
                height: 8,
              ),
              const Text("P2"),
              SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                series: <ChartSeries>[
                  BarSeries<ChartData, String>(
                    dataSource: p2,
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.y,
                    pointColorMapper: (ChartData data, int index) =>
                        p2[index].y > p1[index].y
                            ? Colors.yellow
                            : Colors.blueGrey,
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                  )
                ],
              )
            ],
          ),
        ),
      ],
    );
  }
}
