import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

import 'dart:math' as math;

class DashboardPredict extends StatelessWidget {
  final double percentage;
  const DashboardPredict({Key? key, required this.percentage})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Container infoCard = Container(
        padding: const EdgeInsets.all(12.0),
        alignment: AlignmentDirectional.topStart,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: FittedBox(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: const [
                              Text(
                                "预测年排百分比：",
                                style: TextStyle(fontSize: 24),
                              ),
                            ],
                          ),
                          Text(
                            (percentage * 100).toStringAsFixed(2),
                            style: const TextStyle(fontSize: 48),
                          ),
                          const SizedBox(
                            width: 16,
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: const [
                              Text(
                                "%",
                                style: TextStyle(fontSize: 24),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  )
                )),
            const SizedBox(
              height: 16,
            ),
            Align(
              alignment: Alignment((1 - percentage) * 2 - 1, 0),
              child: Column(
                children: [
                  Transform.rotate(
                    angle: ((1 - percentage) < 0.6) ? -math.pi / 5 : 0,
                    child: SvgPicture.asset(
                      "assets/running_person.svg",
                      height: 32,
                      color: Colors.lightBlueAccent,
                    ),
                  ),
                  SvgPicture.asset(
                    "assets/triangle_down_fill.svg",
                    height: 8,
                    color: Colors.lightBlueAccent,
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 20,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  LinearPercentIndicator(
                    lineHeight: 8.0,
                    percent: 1 - percentage,
                    backgroundColor: Colors.grey,
                    linearGradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.lightBlueAccent,
                        Colors.lightBlue,
                        Colors.blue
                      ],
                    ),
                    barRadius: const Radius.circular(4),
                  ),
                  const Align(
                    alignment: Alignment(0.7, 0),
                    child: VerticalDivider(
                      width: 4,
                      thickness: 4,
                      color: Colors.grey,
                    ),
                  ),
                  const Align(
                    alignment: Alignment(0.4, 0),
                    child: VerticalDivider(
                      width: 4,
                      thickness: 4,
                      color: Colors.grey,
                    ),
                  ),
                  const Align(
                    alignment: Alignment(0.2, 0),
                    child: VerticalDivider(
                      width: 4,
                      thickness: 4,
                      color: Colors.grey,
                    ),
                  ),
                  const Align(
                    alignment: Alignment(-0.2, 0),
                    child: VerticalDivider(
                      width: 4,
                      thickness: 4,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          ],
        ));

    return Card(
      margin: const EdgeInsets.all(12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 4,
      child: infoCard,
    );
  }
}
