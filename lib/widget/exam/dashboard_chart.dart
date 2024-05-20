import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../util/struct.dart';

class DashboardChart extends StatefulWidget {
  final List<PaperDiagnosis> diagnoses;
  final String tips;
  final String subTips;

  const DashboardChart(
      {Key? key,
      required this.diagnoses,
      required this.tips,
      required this.subTips})
      : super(key: key);

  @override
  State<DashboardChart> createState() => _DashboardChartState();
}

class _DashboardChartState extends State<DashboardChart> {
  bool officialStyle = false;
  List<PaperDiagnosis> parsedDiagnoses = [];

  void onChanged(bool state) {
    setState(() {
      officialStyle = state;
      if (officialStyle) {
        parsedDiagnoses = widget.diagnoses.map((e) {
          return PaperDiagnosis(
            subjectName: e.subjectName,
            diagnosticScore: 100 - e.diagnosticScore,
            subjectId: e.subjectId,
          );
        }).toList();
      } else {
        parsedDiagnoses = widget.diagnoses;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (parsedDiagnoses.isEmpty) {
      parsedDiagnoses = widget.diagnoses;
    }
    if (widget.diagnoses.length >= 3) {
      Container chartCard = Container(
          padding: const EdgeInsets.all(12.0),
          alignment: AlignmentDirectional.center,
          height: 300,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: RadarChart(
                  RadarChartData(
                    dataSets: [
                      RadarDataSet(
                        fillColor: Colors.blueAccent.withOpacity(0.45),
                        // Set the color inside the data
                        borderColor: Colors.blue,
                        entryRadius: 0,
                        borderWidth: 2,
                        dataEntries: parsedDiagnoses
                            .map((e) => RadarEntry(value: e.diagnosticScore))
                            .toList(),
                      ),
                      RadarDataSet(
                        entryRadius: 0,
                        borderWidth: 2,
                        dataEntries: List.filled(parsedDiagnoses.length,
                            const RadarEntry(value: 125)),
                        fillColor: Colors.transparent,
                        borderColor: Colors.transparent,
                      ),
                      RadarDataSet(
                        entryRadius: 0,
                        borderWidth: 2,
                        dataEntries: List.filled(parsedDiagnoses.length,
                            const RadarEntry(value: 0)),
                        fillColor: Colors.transparent,
                        borderColor: Colors.transparent,
                      )
                    ],
                    tickCount: 5,
                    radarBorderData: BorderSide(
                      color: ThemeMode.system == ThemeMode.dark
                          ? Colors.grey.shade900
                          : Colors.grey.shade500,
                      width: 1,
                    ),
                    tickBorderData: BorderSide(
                      color: ThemeMode.system == ThemeMode.dark
                          ? Colors.grey.shade900
                          : Colors.grey.shade500,
                      width: 1,
                    ),
                    gridBorderData: BorderSide(
                      color: ThemeMode.system == ThemeMode.dark
                          ? Colors.grey.shade900
                          : Colors.grey.shade500,
                      width: 1,
                    ),
                    titlePositionPercentageOffset: 0.1,
                    radarBackgroundColor: Colors.transparent,
                    radarShape: RadarShape.circle,
                    getTitle: (index, angle) {
                      return RadarChartTitle(
                          text: parsedDiagnoses[index].subjectName);
                    },
                  ),
                  swapAnimationDuration: const Duration(milliseconds: 150),
                  swapAnimationCurve: Curves.linear,
                ),
              ),
              const SizedBox(height: 8),
              Text(widget.tips, style: const TextStyle(fontSize: 16)),
              Text(widget.subTips, style: const TextStyle(fontSize: 12)),
            ],
          ));

      return Card.filled(
        //elevation: 2,
        margin: const EdgeInsets.all(8.0),
        /*shape: RoundedRectangleBorder(
          side: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),*/
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('智学网风格的雷达图', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Switch(value: officialStyle, onChanged: onChanged)
              ],
            ),
            chartCard
          ],
        ),
      );
    } else {
      return Container();
    }
  }
}
