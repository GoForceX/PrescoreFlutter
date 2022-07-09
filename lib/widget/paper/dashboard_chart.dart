import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../util/struct.dart';

class DashboardChart extends StatelessWidget {
  final List<PaperDiagnosis> diagnoses;
  const DashboardChart({Key? key, required this.diagnoses}) : super(key: key);

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
                        entryRadius: 3,
                        dataEntries: diagnoses
                            .map((e) => RadarEntry(value: e.diagnosticScore))
                            .toList(),
                      ),
                      RadarDataSet(
                        entryRadius: 0,
                        dataEntries: List.filled(
                            diagnoses.length, const RadarEntry(value: 100)),
                        fillColor: Colors.transparent,
                        borderColor: Colors.transparent,
                      )
                    ],
                    tickCount: 3,
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
                    radarShape: RadarShape.polygon,
                    getTitle: (index, angle) {
                      return RadarChartTitle(
                          text: diagnoses[index].subjectName);
                    },
                  ),
                  swapAnimationDuration: const Duration(milliseconds: 150),
                  swapAnimationCurve: Curves.linear,
                ),
              ),
              const Text("这么巨！", style: TextStyle(fontSize: 16)),
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
