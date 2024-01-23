import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../main.gr.dart';
import '../../util/user_util.dart';

class ExamCard extends StatelessWidget {
  const ExamCard(
      {Key? key,
      required this.user,
      required this.uuid,
      required this.examName,
      required this.examType,
      required this.examTime})
      : super(key: key);

  final User user;
  final String uuid;
  final String examName;
  final String examType;
  final DateTime examTime;

  @override
  Widget build(BuildContext context) {
    Color indicatorColor() {
      switch (examType) {
        case "weeklyExam":
          return Colors.green;
        case "monthlyExam":
          return Colors.yellow;
        case "midtermExam":
          return Colors.purpleAccent;
        case "terminalExam":
          return Colors.red;
        default:
          return Colors.grey;
      }
    }

    Row nameRow = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
            flex: 0,
            child: SizedBox(
              width: 8,
              height: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(color: indicatorColor()),
              ),
            )),
        const SizedBox(
          width: 12,
        ),
        Expanded(
            flex: 1,
            child: Container(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Text(
                  examName,
                  style: const TextStyle(
                    fontSize: 24,
                  ),
                ))),
      ],
    );

    Container cardMain = Container(
      padding: const EdgeInsets.all(12.0),
      alignment: AlignmentDirectional.topStart,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IntrinsicHeight(
            child: nameRow,
          ),
          const SizedBox(
            height: 8,
          ),
          Text(
            DateFormat('yyyy-MM-dd').format(examTime),
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ],
      ),
    );

    return Card(
      margin: const EdgeInsets.all(12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 4,
      child: InkWell(
          onTap: () {
            context.router.navigate(ExamRoute(uuid: uuid, user: user));
          },
          child: cardMain),
    );
  }
}
