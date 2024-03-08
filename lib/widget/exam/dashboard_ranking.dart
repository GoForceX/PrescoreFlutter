import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../main.dart';
import '../../util/struct.dart';

class DashboardRanking extends StatelessWidget {
  final List<PaperDiagnosis> diagnoses;
  const DashboardRanking({Key? key, required this.diagnoses}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int classCount =
        BaseSingleton.singleton.sharedPreferences.getInt("classCount") ?? 45;

    if (diagnoses.length >= 3) {
      Container chartCard = Container(
          padding: const EdgeInsets.all(12.0),
          alignment: AlignmentDirectional.center,
          height: 300,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text("设置中可以修改班级人数，获得更精准的计算。\n现在设置的班级人数是: $classCount",
                  style: const TextStyle(fontSize: 12)),
              const SizedBox(
                height: 16,
              ),
              Expanded(
                child: BarChart(
                  BarChartData(
                    barGroups: diagnoses
                        .asMap()
                        .entries
                        .map((item) => BarChartGroupData(
                              x: item.key,
                              barRods: [
                                BarChartRodData(
                                  toY: (item.value.diagnosticScore /
                                          100 *
                                          classCount)
                                      .roundToDouble(),
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary.withOpacity(0.6)]
                                  ),
                                )
                              ],
                              showingTooltipIndicators: [0],
                            ))
                        .toList(),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              space: 4.0,
                              child: Text(
                                diagnoses[value.toInt()].subjectName,
                                style: const TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: Colors.transparent,
                        tooltipPadding: const EdgeInsets.all(8),
                        fitInsideVertically: true,
                        tooltipMargin: 8,
                        getTooltipItem: (BarChartGroupData groupData,
                            int groupIndex,
                            BarChartRodData rodData,
                            int rodIndex) {
                          return BarTooltipItem(
                            rodData.toY.round().toString(),
                            const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  swapAnimationDuration: const Duration(milliseconds: 150),
                  swapAnimationCurve: Curves.linear,
                ),
              ),
            ],
          ));

      return Card(
        /*margin: const EdgeInsets.all(12.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        elevation: 8,*/
        elevation: 2,
        margin: const EdgeInsets.all(8.0),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: chartCard,
      );
    } else {
      return Container();
    }
  }
}
