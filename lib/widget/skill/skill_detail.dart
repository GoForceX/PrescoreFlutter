import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:prescore_flutter/util/struct.dart';
import 'package:prescore_flutter/widget/skill/skill_header.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../model/skill_model.dart';
import '../../util/user_util.dart';

class SkillDetail extends StatefulWidget {
  const SkillDetail({super.key});

  @override
  State<SkillDetail> createState() => _SkillDetailState();
}

class _SkillDetailState extends State<SkillDetail> {
  @override
  Widget build(BuildContext context) {
    User user = Provider.of<SkillModel>(context, listen: false).user;

    final List<ChartData> chartData = [
      ChartData("语文", -3.055),
      ChartData("数学", 2.325),
      ChartData("英语", -3.417),
      ChartData("物理", -2.773),
      ChartData("化学", 4.125),
      ChartData("生物", 1.844)
    ];

    return Flex(
      direction: Axis.vertical,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(8),
            shrinkWrap: false,
            children: [
              const SkillHeader(),
              const SizedBox(
                height: 16,
              ),
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0)),
                elevation: 8,
                child: InkWell(
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    alignment: AlignmentDirectional.center,
                    height: 400,
                    child: Flex(
                      direction: Axis.vertical,
                      children: [
                        const Text("各科能力", style: TextStyle(fontSize: 18)),
                        const SizedBox(
                          height: 8,
                        ),
                        Expanded(
                          child: SfCartesianChart(
                            primaryXAxis: CategoryAxis(),
                            primaryYAxis: NumericAxis(plotBands: <PlotBand>[
                              PlotBand(
                                isVisible: true,
                                start: 0,
                                end: 0,
                                borderWidth: 2,
                                borderColor: ThemeMode.system == ThemeMode.dark
                                    ? Colors.blue[900]!
                                    : Colors.blue[200]!,
                              )
                            ], interval: 2, labelFormat: '{value}'),
                            series: <CartesianSeries>[
                              BarSeries<ChartData, String>(
                                  dataSource: chartData.reversed.toList(),
                                  xValueMapper: (ChartData data, _) => data.x,
                                  yValueMapper: (ChartData data, _) => data.y,
                                  dataLabelSettings:
                                      const DataLabelSettings(isVisible: true)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ChartData {
  ChartData(this.x, this.y);
  final String x;
  final double y;
}
