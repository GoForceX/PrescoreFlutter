import 'package:flutter/material.dart';

class DashboardScoreInfo extends StatelessWidget {
  final double minimum;
  final double maximum;
  final double avg;
  final double med;
  const DashboardScoreInfo(
      {Key? key,
      required this.minimum,
      required this.maximum,
      required this.avg,
      required this.med})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Container infoCard = Container(
        padding: const EdgeInsets.all(12.0),
        alignment: AlignmentDirectional.topStart,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Flexible(
                    child: FittedBox(
                  child: Column(
                    children: [
                      const Text(
                        "最低分",
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        minimum.toStringAsFixed(2),
                        style: const TextStyle(fontSize: 32),
                      ),
                    ],
                  ),
                )),
                Flexible(
                    child: FittedBox(
                  child: Column(
                    children: [
                      const Text(
                        "最高分",
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        maximum.toStringAsFixed(2),
                        style: const TextStyle(fontSize: 32),
                      ),
                    ],
                  ),
                )),
              ],
            ),
            const SizedBox(
              height: 16,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Flexible(
                    child: FittedBox(
                  child: Column(
                    children: [
                      const Text(
                        "平均分",
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        avg.toStringAsFixed(2),
                        style: const TextStyle(fontSize: 32),
                      ),
                    ],
                  ),
                )),
                Flexible(
                    child: FittedBox(
                  child: Column(
                    children: [
                      const Text(
                        "中位数",
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        med.toStringAsFixed(2),
                        style: const TextStyle(fontSize: 32),
                      ),
                    ],
                  ),
                )),
              ],
            )
          ],
        ));

    return Card(
      margin: const EdgeInsets.all(12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 8,
      child: infoCard,
    );
  }
}
