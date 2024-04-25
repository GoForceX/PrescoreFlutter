//import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prescore_flutter/widget/exam/exam_page.dart';
import 'package:prescore_flutter/widget/open_container.dart';

//import '../../main.gr.dart';
import '../../util/user_util.dart';

class ExamCard extends StatelessWidget {
  const ExamCard(
      {Key? key,
      required this.user,
      required this.uuid,
      required this.examName,
      required this.examType,
      required this.examTime,
      required this.isFinal})
      : super(key: key);

  final User user;
  final String uuid;
  final String examName;
  final String examType;
  final DateTime examTime;
  final bool isFinal;

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
          Row(children: [
            Text(
              DateFormat('yyyy-MM-dd').format(examTime),
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            Expanded(child: Container()),
            Icon(isFinal ? Icons.public_off : Icons.public, size: 10),
            Text(isFinal ? " 已结束" : " 正在进行",
                style: const TextStyle(
                  fontSize: 10,
                )),
            const SizedBox(width: 6)
          ])
        ],
      ),
    );
    /*return Card(
      elevation: 2,
      margin: const EdgeInsets.all(8.0),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: InkWell(
          borderRadius:BorderRadius.circular(12.0),
          onTap: () {
            context.router.navigate(ExamRoute(uuid: uuid, user: user));
          },
          child: cardMain),
    );*/
    ExamPage examPage = ExamPage(
      uuid: uuid,
      user: user,
    );
    return OpenContainer(
      openColor: Colors.transparent,
      closedColor: Colors.transparent,
      closedElevation: 0,
      openElevation: 0,
      transitionDuration: const Duration(milliseconds: 300),
      tappable: false,
      clipBehavior: Clip.none,
      transitionType: ContainerTransitionType.fade,
      openBuilder: (BuildContext buildContext, __) {
        return examPage;
      },
      closedBuilder: (BuildContext buildContext, openContainer) {
        return Card(
          elevation: 2,
          margin: const EdgeInsets.all(8.0),
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: Theme.of(buildContext).colorScheme.outlineVariant,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
          child: InkWell(
              borderRadius: BorderRadius.circular(12.0),
              onTap: openContainer,
              child: cardMain),
        );
      },
    );
  }
}
