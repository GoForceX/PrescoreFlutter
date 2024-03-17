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
import 'detail_util.dart';

class DashboardCard extends StatelessWidget {
  final String examId;
  const DashboardCard({Key? key, required this.examId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    setUploadListener(context);
    fetchData(context, examId);

    List<Widget> children = [];
    //总分
    Consumer totalCards = Consumer<ExamModel>(builder:
        (BuildContext consumerContext, ExamModel examModel, Widget? child) {
      List<Widget> infoChildren = [];
      if (examModel.isPaperLoaded || examModel.isPreviewPaperLoaded) {
        double userScore = 0;
        List<Paper> papers = examModel.papers;
        // List<Paper> absentPapers = examModel.absentPapers;

        for (var element in papers) {
          if (element.source != Source.common) {
            continue;
          }
          userScore += element.userScore;
        }

        double assignScore = 0;
        int noAssignCount = 0;
        for (var element in papers) {
          if (element.source != Source.common) {
            continue;
          }
          if (element.assignScore == null) {
            noAssignCount += 1;
          }
          assignScore += element.assignScore ?? element.userScore;
        }

        double fullScore = 0;
        for (var element in papers) {
          if (element.source != Source.common) {
            continue;
          }
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

        return ListView(
          padding: const EdgeInsets.all(0),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: infoChildren,
        );
      } else {
        return Center(
            child: Container(
                margin: const EdgeInsets.all(10),
                child: const CircularProgressIndicator()));
      }
    });
    children.add(totalCards);

    children.add(Consumer(builder:
        (BuildContext consumerContext, ExamModel examModel, Widget? child) {
      if (examModel.isPaperLoaded) {
        double userScore = 0;
        for (var element in examModel.papers) {
          if (element.source != Source.common) {
            continue;
          }
          userScore += element.userScore;
        }

        return FutureBuilder(
          future: Provider.of<ExamModel>(context, listen: false)
              .user
              .fetchExamPredict(examId, userScore),
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
              return Center(
                  child: Container(
                      margin: const EdgeInsets.all(10),
                      child: const CircularProgressIndicator()));
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
            .fetchExamScoreInfo(examId),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          logger.d("DashboardScoreInfo: ${snapshot.data}");
          if (snapshot.hasData) {
            if (snapshot.data.state) {
              Widget scoreInfo = DashboardScoreInfo(
                examId: examId,
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
            return Center(
                child: Container(
                    margin: const EdgeInsets.all(10),
                    child: const CircularProgressIndicator()));
          }
        },
      );
    }));

    children.add(Consumer(builder:
        (BuildContext consumerContext, ExamModel examModel, Widget? child) {
      if (examModel.isPaperLoaded && examModel.isDiagLoaded) {
        List<PaperDiagnosis> diagnoses = [];
        bool absentFlag = false;
        for (var element in examModel.diagnoses) {
          if (examModel.absentPapers
              .where((paper) => paper.subjectId == element.subjectId)
              .isEmpty) {
            diagnoses.add(element);
            absentFlag = true;
          }
        }

        String tips = examModel.tips;
        if (absentFlag) {
          String bestSubject = diagnoses
              .reduce((curr, next) =>
                  curr.diagnosticScore < next.diagnosticScore ? curr : next)
              .subjectName;
          double bestScore = diagnoses
              .reduce((curr, next) =>
                  curr.diagnosticScore < next.diagnosticScore ? curr : next)
              .diagnosticScore;
          String worstSubject = diagnoses
              .reduce((curr, next) =>
                  curr.diagnosticScore > next.diagnosticScore ? curr : next)
              .subjectName;
          double worstScore = diagnoses
              .reduce((curr, next) =>
                  curr.diagnosticScore > next.diagnosticScore ? curr : next)
              .diagnosticScore;
          if (worstScore - bestScore > 30) {
            tips = "尽管$bestSubject成绩不错，但$worstSubject有些偏科哦";
          } else {
            tips = "你的各科成绩相差不大，继续努力哦";
          }
        }

        return Column(
          children: [
            DashboardChart(
                diagnoses: diagnoses, tips: tips, subTips: examModel.subTips),
            DashboardRanking(diagnoses: diagnoses),
          ],
        );
      } else {
        return Container();
      }
    }));

    ListView listView = ListView(
      padding: const EdgeInsets.all(8),
      shrinkWrap: false,
      children: children,
    );

    return Expanded(child: listView);
  }
}
