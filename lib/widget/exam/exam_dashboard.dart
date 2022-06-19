import 'package:flutter/material.dart';

import '../../util/struct.dart';
import 'dashboard_card.dart';

class ExamDashboard extends StatelessWidget {
  final String examId;
  final List<Paper> papers;
  const ExamDashboard({Key? key, required this.examId, required this.papers})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    double userScore = 0;
    for (var element in papers) {
      userScore += element.userScore;
    }

    double fullScore = 0;
    for (var element in papers) {
      fullScore += element.fullScore;
    }

    return Column(
      children: [
        /*
        FutureBuilder(
          future: Provider.of<ExamModel>(context, listen: false)
              .user
              .fetchPaperDiagnosis(examId),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.hasData) {
              if (snapshot.data["state"]) {
                return DashboardCard(
                  userScore: userScore,
                  fullScore: fullScore,
                  papers: papers,
                  diagnoses: snapshot.data["result"],
                  examId: examId,
                );
              } else {
                return DashboardCard(
                  examId: examId,
                  userScore: userScore,
                  fullScore: fullScore,
                  papers: papers,
                  diagnoses: const [],
                );
              }
            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        )
         */
        DashboardCard(
          examId: examId,
          userScore: userScore,
          fullScore: fullScore,
          papers: papers,
        )
      ],
    );
  }
}
