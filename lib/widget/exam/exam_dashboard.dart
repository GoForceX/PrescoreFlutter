import 'package:flutter/material.dart';

import 'dashboard_card.dart';

class ExamDashboard extends StatelessWidget {
  final String examId;
  const ExamDashboard({Key? key, required this.examId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DashboardCard(examId: examId)
      ],
    );
  }
}
