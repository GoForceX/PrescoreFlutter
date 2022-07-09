import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../model/exam_model.dart';
import '../../util/struct.dart';
import '../paper/dashboard_chart.dart';
import '../paper/dashboard_info.dart';
import '../paper/dashboard_predict.dart';
import '../paper/dashboard_ranking.dart';

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

      Widget ranking = DashboardRanking(
          diagnoses: Provider.of<ExamModel>(context, listen: false).diagnoses);
      children.add(ranking);
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
              return Column(
                children: [
                  DashboardChart(diagnoses: snapshot.data["result"]),
                  DashboardRanking(diagnoses: snapshot.data["result"])
                ],
              );
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
