import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

import '../../util/struct.dart';

class QuestionCard extends StatelessWidget {
  final Question question;
  const QuestionCard({Key? key, required this.question}) : super(key: key);

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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            "${question.questionId}：",
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(
                            height: 12,
                          )
                        ],
                      ),
                      Text(
                        "${question.userScore}",
                        style: const TextStyle(fontSize: 48),
                      ),
                      const SizedBox(
                        width: 16,
                      ),
                      const Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            "/",
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(
                            height: 12,
                          )
                        ],
                      ),
                      const SizedBox(
                        width: 16,
                      ),
                      Text(
                        "${question.fullScore}",
                        style: const TextStyle(fontSize: 48),
                      ),
                    ],
                  ),
                )),
            const SizedBox(
              height: 16,
            ),
            LinearPercentIndicator(
              lineHeight: 8.0,
              percent: question.userScore / question.fullScore,
              backgroundColor: Colors.grey,
              linearGradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Colors.lightBlueAccent, Colors.lightBlue, Colors.blue],
              ),
              barRadius: const Radius.circular(4),
            ),
            Builder(builder: (BuildContext context) {
              if (question.classScoreRate != null) {
                return Container(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  "班级得分率：",
                                  style: TextStyle(fontSize: 16),
                                ),
                                SizedBox(
                                  height: 12,
                                )
                              ],
                            ),
                            Text(
                              ((question.classScoreRate ?? 0) * 100)
                                  .toStringAsFixed(2),
                              style: const TextStyle(fontSize: 48),
                            ),
                            const SizedBox(
                              width: 16,
                            ),
                            const Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  "%",
                                  style: TextStyle(fontSize: 16),
                                ),
                                SizedBox(
                                  height: 12,
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                      FittedBox(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  "班级平均分：",
                                  style: TextStyle(fontSize: 16),
                                ),
                                SizedBox(
                                  height: 12,
                                )
                              ],
                            ),
                            Text(
                              ((question.classScoreRate ?? 0) *
                                      question.fullScore)
                                  .toStringAsFixed(2),
                              style: const TextStyle(fontSize: 48),
                            ),
                            const SizedBox(
                              width: 16,
                            ),
                            const Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  "/",
                                  style: TextStyle(fontSize: 16),
                                ),
                                SizedBox(
                                  height: 12,
                                )
                              ],
                            ),
                            const SizedBox(
                              width: 16,
                            ),
                            Text(
                              "${question.fullScore}",
                              style: const TextStyle(fontSize: 48),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                    ],
                  ),
                );
              } else {
                return const SizedBox.shrink();
              }
            }),
            Builder(builder: (BuildContext context) {
              if (question.classScoreRate != null) {
                return LinearPercentIndicator(
                  lineHeight: 8.0,
                  percent: question.classScoreRate ?? 0,
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
                );
              } else {
                return const SizedBox.shrink();
              }
            }),
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
