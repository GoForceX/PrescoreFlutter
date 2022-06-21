import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../model/exam_model.dart';
import '../../util/struct.dart';

class DashboardCard extends StatefulWidget {
  final String examId;
  const DashboardCard({Key? key, required this.examId}) : super(key: key);

  @override
  State<DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<DashboardCard> {
  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];

    Provider.of<ExamModel>(context, listen: false).addListener(() {
      logger.d(
          "DashboardInfo: ${Provider.of<ExamModel>(context, listen: false).isPaperLoaded} ${Provider.of<ExamModel>(context, listen: false).isDiagFetched}");
      if (Provider.of<ExamModel>(context, listen: false).isPaperLoaded &&
          Provider.of<ExamModel>(context, listen: false).isDiagFetched) {
        for (var paper
            in Provider.of<ExamModel>(context, listen: false).papers) {
          try {
            logger.d("DashboardInfo: ${paper.name}");
            Provider.of<ExamModel>(context, listen: false)
                .user
                .uploadPaperData(paper);
          } catch (e) {
            logger.e(e);
          }
        }
      }
    });

    if (Provider.of<ExamModel>(context, listen: false).isPaperLoaded) {
      List<Paper> papers =
          Provider.of<ExamModel>(context, listen: false).papers;
      double userScore = 0;
      for (var element in papers) {
        userScore += element.userScore;
      }

      double fullScore = 0;
      for (var element in papers) {
        fullScore += element.fullScore;
      }
      Widget chart = DashboardInfo(userScore: userScore, fullScore: fullScore);
      children.add(chart);
    } else {
      FutureBuilder futureBuilder = FutureBuilder(
        future: Provider.of<ExamModel>(context, listen: false)
            .user
            .fetchPaper(widget.examId),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data["state"]) {
              Future.delayed(Duration.zero, () {
                Provider.of<ExamModel>(context, listen: false)
                    .setPapers(snapshot.data["result"]);
                Provider.of<ExamModel>(context, listen: false)
                    .setPaperLoaded(true);
              });
              double userScore = 0;
              for (var element in snapshot.data["result"]) {
                userScore += element.userScore;
              }

              double fullScore = 0;
              for (var element in snapshot.data["result"]) {
                fullScore += element.fullScore;
              }
              Widget chart =
                  DashboardInfo(userScore: userScore, fullScore: fullScore);
              return chart;
            } else {
              return Container();
            }
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      );

      children.add(futureBuilder);
    }

    children.add(Consumer(builder:
        (BuildContext consumerContext, ExamModel examModel, Widget? child) {
      if (examModel.isPaperLoaded) {
        double userScore = 0;
        for (var element in examModel.papers) {
          userScore += element.userScore;
        }

        return FutureBuilder(
          future: Provider.of<ExamModel>(context, listen: false)
              .user
              .fetchExamPredict(widget.examId, userScore),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            logger.d("DashboardPredict: ${snapshot.data}");
            if (snapshot.hasData) {
              if (snapshot.data["state"]) {
                if (snapshot.data["result"] < 0) {
                  Widget predict = const DashboardPredict(percentage: 0);
                  return predict;
                } else if (snapshot.data["result"] > 1) {
                  Widget predict = const DashboardPredict(percentage: 1);
                  return predict;
                } else {
                  Widget predict =
                      DashboardPredict(percentage: snapshot.data["result"]);
                  return predict;
                }
              } else {
                return Container();
              }
            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        );
      } else {
        return Container();
      }
    }));

    if (Provider.of<ExamModel>(context, listen: false).isDiagLoaded) {
      Widget chart = DashboardChart(
          diagnoses: Provider.of<ExamModel>(context, listen: false).diagnoses);
      children.add(chart);
    } else {
      FutureBuilder futureBuilder = FutureBuilder(
        future: Provider.of<ExamModel>(context, listen: false)
            .user
            .fetchPaperDiagnosis(widget.examId),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data["state"]) {
              Future.delayed(Duration.zero, () {
                Provider.of<ExamModel>(context, listen: false)
                    .setDiagnoses(snapshot.data["result"]);
                Provider.of<ExamModel>(context, listen: false)
                    .setDiagFetched(true);
                Provider.of<ExamModel>(context, listen: false)
                    .setDiagLoaded(true);
              });
              return DashboardChart(diagnoses: snapshot.data["result"]);
            } else {
              Future.delayed(Duration.zero, () {
                Provider.of<ExamModel>(context, listen: false)
                    .setDiagFetched(true);
              });
              return Container();
            }
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      );

      children.add(futureBuilder);
    }

    ListView listView = ListView(
      padding: const EdgeInsets.all(8),
      shrinkWrap: false,
      children: children,
    );

    return Expanded(child: listView);
  }
}

class DashboardInfo extends StatelessWidget {
  final double userScore;
  final double fullScore;
  const DashboardInfo(
      {Key? key, required this.userScore, required this.fullScore})
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: const [
                          Text(
                            "得分：",
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(
                            height: 12,
                          )
                        ],
                      ),
                      Text(
                        "$userScore",
                        style: const TextStyle(fontSize: 48),
                      ),
                      const SizedBox(
                        width: 16,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: const [
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
                        "$fullScore",
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
              percent: userScore / fullScore,
              backgroundColor: Colors.grey,
              linearGradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Colors.lightBlueAccent, Colors.lightBlue, Colors.blue],
              ),
              barRadius: const Radius.circular(4),
            ),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: const [
                          Text(
                            "预测年排百分比：",
                            style: TextStyle(fontSize: 24),
                          ),
                          SizedBox(
                            height: 12,
                          )
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
                          SizedBox(
                            height: 12,
                          )
                        ],
                      ),
                    ],
                  ),
                )),
            const SizedBox(
              height: 16,
            ),
            LinearPercentIndicator(
              lineHeight: 8.0,
              percent: percentage,
              backgroundColor: Colors.grey,
              linearGradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Colors.lightBlueAccent, Colors.lightBlue, Colors.blue],
              ),
              barRadius: const Radius.circular(4),
            ),
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

/*
class DashboardCard extends StatelessWidget {
  final double fullScore;
  final double userScore;
  final List<Paper> papers;
  final List<PaperDiagnosis> diagnoses;

  const DashboardCard(
      {Key? key,
      required this.fullScore,
      required this.userScore,
      required this.papers,
      required this.diagnoses})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
  }
}
 */
