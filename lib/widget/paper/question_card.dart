import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:prescore_flutter/main.dart';
import '../../util/struct.dart';
import '../component.dart';

class QuestionCard extends StatefulWidget {
  final Question question;
  final bool nonFinalAlert;
  const QuestionCard(
      {Key? key, required this.question, this.nonFinalAlert = false})
      : super(key: key);
  @override
  QuestionCardState createState() => QuestionCardState();
}

class QuestionCardState extends State<QuestionCard>
    with TickerProviderStateMixin {
  bool detailExpanded = false;
  List<Widget> allTeachersWidget = [];
  List<Widget> subTopicWidget = [];
  Set<String> teachersName = {};
  bool complexMarking = false;
  late AnimationController _animationController;
  late CurvedAnimation animationCurve;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
    animationCurve =
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut);
    for (var subQuestion in widget.question.subTopic) {
      if (subQuestion.teacherMarkingRecords.length > 1) {
        complexMarking = true;
      }
      for (var teacher in subQuestion.teacherMarkingRecords) {
        teachersName.add(teacher.teacherName);
      }
    }
    if (teachersName.isNotEmpty) {
      allTeachersWidget.add(const SizedBox(width: 8));
      allTeachersWidget.add(const Icon(Icons.people, size: 18));
      for (var teacher in teachersName) {
        allTeachersWidget.add(Row(
          children: [
            Text(
              " $teacher",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ));
      }
    }
    for (QuestionSubTopic subQuestion in widget.question.subTopic) {
      //遍历该大题所有空
      if (widget.question.subTopic.length <= 1 && !complexMarking) {
        break;
      }
      double subStandradScore = subQuestion.standradScore ?? -1;
      double subStudentScore = subQuestion.score;
      Set<String> allTeachersName = {};
      List<Widget> subTeachersWidget = [];
      for (TeacherMarking teacher in subQuestion.teacherMarkingRecords) {
        //遍历该空所有判卷人
        allTeachersName.add(teacher.teacherName);
      }
      if (allTeachersName.isNotEmpty) {
        subTeachersWidget.add(const SizedBox(width: 8));
        subTeachersWidget.add(const Icon(Icons.people, size: 18));
        for (String teacher in allTeachersName) {
          subTeachersWidget.add(Row(
            children: [
              Text(
                " $teacher",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ));
        }
      }
      subTopicWidget.add(Row(
        children: [
          const SizedBox(
            width: 6,
          ),
          SizedBox(
            width: 4,
            height: 24,
            child: DecoratedBox(
              decoration: BoxDecoration(
                  color: subStandradScore == -1
                      ? Colors.grey
                      : subStudentScore == subStandradScore
                          ? Colors.green
                          : subStudentScore != 0
                              ? Colors.yellow
                              : Colors.red),
            ),
          ),
          if (BaseSingleton.singleton.sharedPreferences
                  .getBool("showMarkingRecords") ==
              true)
            Row(children: subTeachersWidget),
          Text(
            "  $subStudentScore",
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(
            width: 16,
          ),
          if (subStandradScore != -1)
            Row(children: [
              const Text(
                "/",
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(
                width: 16,
              ),
              Text(
                subStandradScore.toString(),
                style: const TextStyle(fontSize: 24),
              ),
            ])
        ],
      ));
      if (allTeachersName.length >= 2) {
        //多判子项
        for (TeacherMarking teacher in subQuestion.teacherMarkingRecords) {
          //遍历该空所有判卷人
          subTopicWidget.add(Row(
            children: [
              const SizedBox(width: 24),
              const Icon(Icons.people, size: 18),
              Text(
                " ${teacher.teacherName} (${teacher.role}): ${teacher.score}",
              ),
            ],
          ));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Container infoCard = Container(
        padding: const EdgeInsets.all(12.0),
        alignment: AlignmentDirectional.topStart,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              // tag
              children: [
                TagCard(text: widget.question.isSubjective ? "主观" : "选择"),
                if (widget.question.subTopic.length > 1)
                  const Row(
                      children: [SizedBox(width: 8), TagCard(text: "多空")]),
                if (complexMarking)
                  const Row(
                      children: [SizedBox(width: 8), TagCard(text: "多判")]),
                if ((!widget.question.markingContentsExist &&
                    widget.question.isSubjective &&
                    widget.nonFinalAlert))
                  const Row(
                      children: [SizedBox(width: 8), TagCard(text: "未云判卷")]),
              ],
            ),
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
                            "${widget.question.questionId}：",
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(
                            height: 12,
                          )
                        ],
                      ),
                      Text(
                        "${widget.question.userScore}",
                        style: TextStyle(
                            fontSize: 48,
                            decoration:
                                (!widget.question.markingContentsExist &&
                                        widget.question.isSubjective &&
                                        widget.nonFinalAlert)
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none),
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
                        "${widget.question.fullScore}",
                        style: const TextStyle(fontSize: 48),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 4),
            if (BaseSingleton.singleton.sharedPreferences
                    .getBool("showMarkingRecords") ==
                true)
              Row(
                children: allTeachersWidget,
              ),
            const SizedBox(
              height: 16,
            ),
            LinearPercentIndicator(
              lineHeight: 8.0,
              percent: widget.question.userScore / widget.question.fullScore,
              backgroundColor: Colors.grey,
              linearGradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.6)
                  ]),
              barRadius: const Radius.circular(4),
            ),
            Builder(builder: (BuildContext context) {
              if (widget.question.classScoreRate != null) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
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
                              ((widget.question.classScoreRate ?? 0) * 100)
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
                              ((widget.question.classScoreRate ?? 0) *
                                      widget.question.fullScore)
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
                              "${widget.question.fullScore}",
                              style: const TextStyle(fontSize: 48),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                return const SizedBox.shrink();
              }
            }),
            SizeTransition(
              axisAlignment: 0.0,
              sizeFactor: animationCurve,
              axis: Axis.vertical,
              child: Column(
                children: subTopicWidget,
              ),
            ),
            if (widget.question.subTopic.length > 1 || complexMarking)
            Row(
              children: [
                const Spacer(),
                InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () {
                      setState(() {
                        detailExpanded = !detailExpanded;
                        if (detailExpanded) {
                          _animationController.forward(from: 0);
                        } else {
                          _animationController.reverse(from: 1);
                        }
                      });
                    },
                    child: Container(
                        margin: const EdgeInsets.all(6),
                        child: Row(
                          children: [
                            RotationTransition(
                                turns: Tween<double>(begin: 0.5, end: 0)
                                    .animate(_animationController),
                                child: const Icon(Icons.keyboard_arrow_up,
                                    size: 20)),
                            Text(
                              detailExpanded ? "折叠 " : "展开 ",
                              style: const TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        )))
              ],
            )
          ],
        ));
    return Card(
        elevation: 2,
        margin: const EdgeInsets.all(8.0),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: infoCard);
  }
}
