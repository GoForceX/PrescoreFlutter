import 'package:flutter/material.dart';
import 'package:prescore_flutter/widget/exam/dashboard_list.dart';
import 'package:prescore_flutter/widget/exam/dashboard_score_info.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../model/exam_model.dart';
import '../../util/struct.dart';
import 'dashboard_chart.dart';
import 'dashboard_info.dart';
import 'dashboard_predict.dart';
import 'dashboard_ranking.dart';

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
            logger.d("DashboardInfo: ${paper}");
            bool noDiag = false;
            if (Provider.of<ExamModel>(context, listen: false)
                    .diagnoses
                    .firstWhere(
                        (element) => element.subjectId == paper.subjectId,
                        orElse: () => PaperDiagnosis(
                            subjectId: '',
                            subjectName: '',
                            diagnosticScore: -1))
                    .diagnosticScore ==
                -1) {
              noDiag = true;
            }
            Paper processedPaper = Paper(
                examId: paper.examId,
                paperId: paper.paperId,
                name: paper.name,
                subjectId: paper.subjectId,
                userScore: paper.userScore,
                fullScore: paper.fullScore,
                diagnosticScore: noDiag
                    ? null
                    : 100 -
                        Provider.of<ExamModel>(context, listen: false)
                            .diagnoses
                            .firstWhere((element) =>
                                element.subjectId == paper.subjectId)
                            .diagnosticScore);
            Provider.of<ExamModel>(context, listen: false)
                .user
                .uploadPaperData(processedPaper);
          } catch (e) {
            logger.e(e);
          }
        }
      }
    });

    if (Provider.of<ExamModel>(context, listen: false).isPaperLoaded) {
      List<Paper> papers =
          Provider.of<ExamModel>(context, listen: false).papers;

      List<Widget> infoChildren = [];

      double userScore = 0;
      for (var element in papers) {
        userScore += element.userScore;
      }

      double assignScore = 0;
      int noAssignCount = 0;
      for (var element in papers) {
        if (element.assignScore == null) {
          noAssignCount += 1;
        }
        assignScore += element.assignScore ?? element.userScore;
      }

      double fullScore = 0;
      for (var element in papers) {
        fullScore += element.fullScore;
      }
      if (noAssignCount != papers.length) {
        Widget chart = DashboardInfo(
          userScore: userScore,
          fullScore: fullScore,
          assignScore: assignScore,
        );
        infoChildren.add(chart);
      } else {
        Widget chart = DashboardInfo(
          userScore: userScore,
          fullScore: fullScore,
        );
        infoChildren.add(chart);
      }

      Widget lst = DashboardList(papers: papers);
      infoChildren.add(lst);

      children.add(ListView(
        padding: const EdgeInsets.all(8),
        shrinkWrap: true,
        children: infoChildren,
      ));
    } else {
      FutureBuilder futureBuilder = FutureBuilder(
        future: Provider.of<ExamModel>(context, listen: false)
            .user
            .fetchPaper(widget.examId),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          List<Widget> infoChildren = [];

          if (snapshot.hasData) {
            if (snapshot.data.state) {
              Future.delayed(Duration.zero, () {
                Provider.of<ExamModel>(context, listen: false)
                    .setPapers(snapshot.data.result);
                Provider.of<ExamModel>(context, listen: false)
                    .setPaperLoaded(true);
              });
              double userScore = 0;
              for (var element in snapshot.data.result) {
                userScore += element.userScore;
              }

              double assignScore = 0;
              int noAssignCount = 0;
              for (var element in snapshot.data.result) {
                if (element.assignScore == null) {
                  noAssignCount += 1;
                }
                assignScore += element.assignScore ?? element.userScore;
              }

              double fullScore = 0;
              for (var element in snapshot.data.result) {
                fullScore += element.fullScore;
              }
              if (noAssignCount != snapshot.data.result.length) {
                Widget chart = DashboardInfo(
                  userScore: userScore,
                  fullScore: fullScore,
                  assignScore: assignScore,
                );
                children.insert(0, chart);
              } else {
                Widget chart = DashboardInfo(
                  userScore: userScore,
                  fullScore: fullScore,
                );
                infoChildren.add(chart);
              }

              Widget lst = DashboardList(papers: snapshot.data.result);
              infoChildren.add(lst);

              return ListView(
                padding: const EdgeInsets.all(8),
                shrinkWrap: true,
                children: infoChildren,
              );
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
              if (snapshot.data.state) {
                if (snapshot.data.result < 0) {
                  Widget predict = const DashboardPredict(percentage: 0);
                  return predict;
                } else if (snapshot.data.result > 1) {
                  Widget predict = const DashboardPredict(percentage: 1);
                  return predict;
                } else {
                  Widget predict =
                      DashboardPredict(percentage: snapshot.data.result);
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

    children.add(Consumer(builder:
        (BuildContext consumerContext, ExamModel examModel, Widget? child) {
      return FutureBuilder(
        future: Provider.of<ExamModel>(context, listen: false)
            .user
            .fetchExamScoreInfo(widget.examId),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          logger.d("DashboardScoreInfo: ${snapshot.data}");
          if (snapshot.hasData) {
            if (snapshot.data.state) {
              Widget scoreInfo = DashboardScoreInfo(
                examId: widget.examId,
                maximum: snapshot.data.result.max,
                minimum: snapshot.data.result.min,
                avg: snapshot.data.result.avg,
                med: snapshot.data.result.med,
              );
              return scoreInfo;
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
    }));

    if (Provider.of<ExamModel>(context, listen: false).isDiagLoaded) {
      Widget chart = DashboardChart(
        diagnoses: Provider.of<ExamModel>(context, listen: false).diagnoses,
        tips: Provider.of<ExamModel>(context, listen: false).tips,
        subTips: Provider.of<ExamModel>(context, listen: false).subTips,
      );
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
            if (snapshot.data.state) {
              Future.delayed(Duration.zero, () {
                Provider.of<ExamModel>(context, listen: false)
                    .setDiagnoses(snapshot.data.result.diagnoses);
                Provider.of<ExamModel>(context, listen: false)
                    .setTips(snapshot.data.result.tips);
                Provider.of<ExamModel>(context, listen: false)
                    .setSubTips(snapshot.data.result.subTips);
                Provider.of<ExamModel>(context, listen: false)
                    .setDiagFetched(true);
                Provider.of<ExamModel>(context, listen: false)
                    .setDiagLoaded(true);
              });
              return Column(
                children: [
                  DashboardChart(
                      diagnoses: snapshot.data.result.diagnoses,
                      tips: snapshot.data.result.tips,
                      subTips: snapshot.data.result.subTips),
                  DashboardRanking(diagnoses: snapshot.data.result.diagnoses),
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
