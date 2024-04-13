import 'package:flutter/material.dart';

import 'dashboard_card.dart';

class ExamDashboard extends StatefulWidget {
  final String examId;
  const ExamDashboard({Key? key, required this.examId}) : super(key: key);

  @override
  State<ExamDashboard> createState() => _ExamDashboardState();
}

class _ExamDashboardState extends State<ExamDashboard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [DashboardCard(examId: widget.examId)],
    );
  }
}
