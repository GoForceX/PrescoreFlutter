import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../util/struct.dart';

class DashboardChart extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (diagnoses.length >= 3) {
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
                        fillColor: Colors.blueAccent.withOpacity(0.45), // Set the color inside the data
                        borderColor: Colors.blue,
                        entryRadius: 0,
                        borderWidth: 2,
                        dataEntries: diagnoses
                            .map((e) => RadarEntry(value: e.diagnosticScore))
                            .toList(),
                      ),
                      RadarDataSet(
                        entryRadius: 0,
                        borderWidth: 2,
                        dataEntries: List.filled(
                            diagnoses.length, const RadarEntry(value: 125)),
                        fillColor: Colors.transparent,
                        borderColor: Colors.transparent,
                      ),
                      RadarDataSet(
                        entryRadius: 0,
                        borderWidth: 2,
                        dataEntries: List.filled(
                            diagnoses.length, const RadarEntry(value: 0)),
                        fillColor: Colors.transparent,
                        borderColor: Colors.transparent,
                      )
                    ],
                    tickCount: 5,
                    radarBorderData: const BorderSide(
                      color: Colors.black,
                      width: 1,
                    ),
                    tickBorderData: const BorderSide(
                      color: Colors.black,
                      width: 1,
                    ),
                    gridBorderData: const BorderSide(
                      color: Colors.black,
                      width: 1,
                    ),
                    titlePositionPercentageOffset: 0.1,
                    radarBackgroundColor: Colors.transparent,
                    radarShape: RadarShape.circle,
                    getTitle: (index, angle) {
                      return RadarChartTitle(
                          text: diagnoses[index].subjectName);
                    },
                  ),
                  swapAnimationDuration: const Duration(milliseconds: 150),
                  swapAnimationCurve: Curves.linear,
                ),
              ),
              Text(tips, style: const TextStyle(fontSize: 16)),
              Text(subTips, style: const TextStyle(fontSize: 12)),
            ],
          ));

      return Card(
        margin: const EdgeInsets.all(12.0),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        elevation: 8,
        child: chartCard,
      );
    } else {
      return Container();
    }
  }
}
