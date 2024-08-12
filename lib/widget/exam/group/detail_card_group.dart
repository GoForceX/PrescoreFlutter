//import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:prescore_flutter/util/user_util.dart';
import 'package:prescore_flutter/widget/component.dart';
import 'package:provider/provider.dart';

import 'package:prescore_flutter/main.dart';

//import 'package:prescore_flutter/main.gr.dart';
import 'package:prescore_flutter/model/exam_model.dart';
import 'package:prescore_flutter/util/struct.dart';

extension PapersExtension on List<Paper> {
  double getFullScore() {
    return map((paper) => paper.fullScore!)
        .reduce((value, element) => value + element);
  }

  double getUserScore() {
    return map((paper) => paper.userScore!)
        .reduce((value, element) => value + element);
  }

  List<String> getPaperIdList() {
    return map((paper) => paper.paperId!).toList();
  }
}

class DetailCardGroup extends StatefulWidget {
  final String examId;
  final List<Paper> paperGroups;

  const DetailCardGroup(
      {Key? key, required this.paperGroups, required this.examId})
      : super(key: key);

  @override
  State<DetailCardGroup> createState() => _DetailCardGroupState();
}

class _DetailCardGroupState extends State<DetailCardGroup>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  bool detailExpanded = BaseSingleton.singleton.sharedPreferences
          .getBool("defaultShowAllSubject") ??
      false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 150),
        value: detailExpanded ? 1 : 0);
  }

  @override
  Widget build(BuildContext context) {
    Container infoCard;
    infoCard = Container(
        padding: const EdgeInsets.all(12.0),
        alignment: AlignmentDirectional.topStart,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Wrap(
                    alignment: WrapAlignment.center,
                    children: widget.paperGroups
                        .map((paper) => Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: 1, horizontal: 2),
                            child: TagCard(text: paper.name)))
                        .toList()),
              ],
            ),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: FittedBox(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      /*InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {},
                        child: Baseline(
                            baseline: 24,
                            baselineType: TextBaseline.alphabetic,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                const SizedBox(
                                  width: 4,
                                ),
                                const Icon(Icons.copy, size: 16),
                                Text(
                                  "${widget.paperGroups.length} 科",
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(
                                  width: 8,
                                ),
                              ],
                            )),
                      ),*/
                      const SizedBox(width: 12),
                      SizeTransition(
                          axisAlignment: 0.0,
                          sizeFactor: CurvedAnimation(
                              parent: Tween<double>(begin: 0, end: 1.0)
                                  .animate(_animationController),
                              curve: Curves.easeOut),
                          axis: Axis.horizontal,
                          child: Row(children: [
                            Text(
                              "${widget.paperGroups.getUserScore()}",
                              style: const TextStyle(fontSize: 40),
                            ),
                            const SizedBox(
                              width: 16,
                            ),
                          ])),
                      SizeTransition(
                          axisAlignment: 0.0,
                          sizeFactor: CurvedAnimation(
                              parent: Tween<double>(begin: 1.0, end: 0)
                                  .animate(_animationController),
                              curve: Curves.easeIn),
                          axis: Axis.horizontal,
                          child: Row(children: [
                            const Text(
                              "",
                              style: TextStyle(fontSize: 40),
                            ),
                            Icon(Icons.visibility_off_outlined,
                                size: 32,
                                color: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.color),
                            const SizedBox(
                              width: 16,
                            ),
                          ])),
                      const Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizedBox(
                            height: 4,
                          ),
                          Text(
                            "/",
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(
                        width: 16,
                      ),
                      Text(
                        "${widget.paperGroups.getFullScore()}",
                        style: const TextStyle(fontSize: 40),
                      ),
                    ],
                  ),
                )),
            SizeTransition(
                axisAlignment: 0.0,
                sizeFactor: CurvedAnimation(
                    parent: _animationController, curve: Curves.easeInOut),
                axis: Axis.vertical,
                child: Column(children: [
                  const SizedBox(
                    height: 8,
                  ),
                  LinearPercentIndicator(
                    lineHeight: 8.0,
                    percent: widget.paperGroups.getUserScore() /
                        widget.paperGroups.getFullScore(),
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
                  const SizedBox(
                    height: 8,
                  ),
                  PredictFutureBuilder(papers: widget.paperGroups),
                  ScoreInfoFutureBuilder(papers: widget.paperGroups),
                ])),
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
    return Card.filled(
      margin: const EdgeInsets.all(8.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        child: infoCard,
      ),
    );
  }
}

class PredictFutureBuilder extends StatefulWidget {
  final List<Paper> papers;

  const PredictFutureBuilder({Key? key, required this.papers})
      : super(key: key);

  @override
  State<PredictFutureBuilder> createState() => _PredictFutureBuilderState();
}

class _PredictFutureBuilderState extends State<PredictFutureBuilder> {
  Future<Result<PaperPercentile>>? future;

  @override
  Widget build(BuildContext context) {
    future ??= Provider.of<ExamModel>(context, listen: false)
        .user
        .fetchPapersPercentile(
            widget.papers.getPaperIdList(), widget.papers.getUserScore());
    return FutureBuilder(
      future: future,
      builder: (BuildContext context,
          AsyncSnapshot<Result<PaperPercentile>> snapshot) {
        logger.d("DetailPredict: ${snapshot.data}");
        if (snapshot.hasData) {
          if (snapshot.data!.state) {
            Widget predict = DetailPredictGroup(
                version: snapshot.data!.result!.version,
                percentage: snapshot.data!.result!.percentile,
                official: snapshot.data!.result!.official,
                count: snapshot.data!.result!.count);
            return predict;
          } else {
            return Container();
          }
        } else {
          return const DetailPredictGroup(
              version: -1, percentage: -1, official: false, count: -1);
        }
      },
    );
  }
}

class DetailPredictGroup extends StatelessWidget {
  final int version;
  final double percentage;
  final double? assignScore;
  final bool official;
  final int count;

  const DetailPredictGroup(
      {Key? key,
      required this.version,
      required this.percentage,
      required this.official,
      required this.count,
      this.assignScore})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          SizedBox(
            height: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Builder(builder: (BuildContext ct) {
                  if (version == -1) {
                    return Container();
                  }
                  return Row(
                    children: [
                      TagCard(
                        text: official
                            ? '${(percentage * count).ceil()} / $count'
                            : 'v$version',
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                    ],
                  );
                }),
                Flexible(
                    child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    children: [
                      Text(
                        official ? "实际年排：" : "预测年排：",
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        percentage != -1
                            ? (percentage * 100).toStringAsFixed(2)
                            : "-",
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(
                        width: 6,
                      ),
                      //const Column(
                      //  mainAxisAlignment: MainAxisAlignment.end,
                      //  children: [
                      const Text(
                        "%",
                        style: TextStyle(fontSize: 24),
                      ),
                      //   ],
                      //),
                    ],
                  ),
                ))
              ],
            ),
          ),
          Builder(builder: (BuildContext ct) {
            if (percentage == -1 || getScoringResult(percentage) == -1) {
              return Container();
            }
            if (assignScore == null) {
              return SizedBox(
                height: 40,
                child: Builder(builder: (BuildContext ct) {
                  if (version == -1) {
                    return Container();
                  }
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Builder(builder: (BuildContext ctx) {
                        if (official) {
                          return Container();
                        }
                        return Row(
                          children: [
                            TagCard(text: 'v$version'),
                            const SizedBox(
                              width: 8,
                            ),
                          ],
                        );
                      }),
                      Flexible(
                          child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "预测赋分：",
                              style: TextStyle(fontSize: 16),
                            ),
                            Text(
                              "${getScoringResult(percentage).toInt()}",
                              style: const TextStyle(fontSize: 32),
                            ),
                          ],
                        ),
                      ))
                    ],
                  );
                }),
              );
            } else {
              return SizedBox(
                height: 40,
                child: Builder(builder: (BuildContext ct) {
                  if (version == -1) {
                    return Container();
                  }
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                          child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "实际赋分：",
                              style: TextStyle(fontSize: 24),
                            ),
                            Text(
                              "$assignScore",
                              style: const TextStyle(fontSize: 32),
                            ),
                          ],
                        ),
                      ))
                    ],
                  );
                }),
              );
            }
          }),
        ],
      ),
    );
  }
}

class ScoreInfoFutureBuilder extends StatefulWidget {
  final List<Paper> papers;

  const ScoreInfoFutureBuilder({Key? key, required this.papers})
      : super(key: key);

  @override
  State<ScoreInfoFutureBuilder> createState() => _ScoreInfoFutureBuilderState();
}

class _ScoreInfoFutureBuilderState extends State<ScoreInfoFutureBuilder> {
  Future<Result<ScoreInfo>>? future;

  @override
  Widget build(BuildContext context) {
    future ??= Provider.of<ExamModel>(context, listen: false)
        .user
        .fetchPapersScoreInfo(
            widget.papers.map((paper) => paper.paperId!).toList());
    return FutureBuilder(
      future: future,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        logger.d("DetailScoreInfo: ${snapshot.data}");
        if (snapshot.hasData) {
          if (snapshot.data.state) {
            Widget scoreInfo = DetailScoreInfo(
                maximum: snapshot.data.result.max,
                minimum: snapshot.data.result.min,
                avg: snapshot.data.result.avg,
                med: snapshot.data.result.med);
            return scoreInfo;
          } else {
            return Container();
          }
        } else {
          return const DetailScoreInfo(
              maximum: -1, minimum: -1, avg: -1, med: -1);
        }
      },
    );
  }
}

class DetailScoreInfo extends StatefulWidget {
  final double minimum;
  final double maximum;
  final double avg;
  final double med;

  const DetailScoreInfo(
      {Key? key,
      required this.minimum,
      required this.maximum,
      required this.avg,
      required this.med})
      : super(key: key);

  @override
  State<DetailScoreInfo> createState() => _DetailScoreInfoState();
}

class _DetailScoreInfoState extends State<DetailScoreInfo> {
  String dropdownValue = "full";
  ClassInfo? chosenClass;
  num? classInfoNum;
  //late Future<Result<List<ClassInfo>>> future;

  @override
  void initState() {
    super.initState();
    /*future = Provider.of<ExamModel>(context, listen: false)
        .user
        .fetchPaperClassInfo(widget.paperId);*/
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /*FittedBox(
          child: FutureBuilder(
              future: future,
              builder: (BuildContext futureContext, AsyncSnapshot snapshot) {
                if (snapshot.hasData) {
                  if (snapshot.data.state == false) {
                    return const Text("全年级", style: TextStyle(fontSize: 16));
                  }
                  num tempClassInfoNum = 0;
                  for (var i in snapshot.data.result) {
                    tempClassInfoNum = tempClassInfoNum + (i.count ?? 0);
                  }
                  classInfoNum = tempClassInfoNum;
                  /*setState(() {
                  });*/
                  if (dropdownValue == "") {
                    dropdownValue = snapshot.data.result[0].classId;
                    chosenClass = snapshot.data.result[0];
                  }

                  List<DropdownMenuItem<String>> items = snapshot.data.result
                      .map<DropdownMenuItem<String>>((ClassInfo value) {
                    return DropdownMenuItem<String>(
                      value: value.classId,
                      child: Text(value.className),
                    );
                  }).toList();
                  items.insert(
                      0,
                      const DropdownMenuItem<String>(
                        value: "full",
                        child: Text("全年级"),
                      ));
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(
                        width: 16,
                      ),
                      /*const Text("当前选择的是："),
                      const SizedBox(
                        width: 16,
                      ),*/
                      DropdownButton<String>(
                        value: dropdownValue,
                        onChanged: (String? newValue) {
                          logger.d(newValue);
                          setState(() {
                            dropdownValue = newValue!;
                            if (dropdownValue == "full") {
                              chosenClass = null;
                            } else {
                              chosenClass = snapshot.data.result.firstWhere(
                                  (element) =>
                                      element.classId == dropdownValue);
                            }
                          });
                        },
                        items: items,
                      ),
                      Builder(builder: (BuildContext context) {
                        if (["", "full"].contains(dropdownValue)) {
                          //return Container();
                          return Row(children: [
                            const SizedBox(width: 8),
                            const Icon(Icons.people),
                            Text(" $classInfoNum 条",
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold))
                          ]);
                        } else {
                          return Row(children: [
                            const SizedBox(width: 8),
                            const Icon(Icons.people),
                            Text(" ${chosenClass?.count ?? 0} 条",
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold))
                          ]);
                        }
                      }),
                      const SizedBox(
                        width: 16,
                      ),
                    ],
                  );
                } else {
                  return const Text("全年级", style: TextStyle(fontSize: 16));
                }
              }),
        ),*/
        Builder(builder: (BuildContext bc) {
          if (["", "full"].contains(dropdownValue) || chosenClass == null) {
            return DetailScoreInfoData(
                minimum: widget.minimum,
                maximum: widget.maximum,
                avg: widget.avg,
                med: widget.med);
          } else {
            return DetailScoreInfoData(
                minimum: chosenClass!.min,
                maximum: chosenClass!.max,
                avg: chosenClass!.avg,
                med: chosenClass!.med);
          }
        })
      ],
    );
  }
}

class DetailScoreInfoData extends StatelessWidget {
  final double minimum;
  final double maximum;
  final double avg;
  final double med;

  const DetailScoreInfoData(
      {Key? key,
      required this.minimum,
      required this.maximum,
      required this.avg,
      required this.med})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Flexible(
            child: FittedBox(
          child: Column(
            children: [
              const Text(
                "最低分",
                style: TextStyle(fontSize: 12),
              ),
              Text(
                minimum != -1 ? minimum.toStringAsFixed(2) : "-",
                style: const TextStyle(fontSize: 20),
              ),
            ],
          ),
        )),
        Flexible(
            child: FittedBox(
          child: Column(
            children: [
              const Text(
                "最高分",
                style: TextStyle(fontSize: 12),
              ),
              Text(
                maximum != -1 ? maximum.toStringAsFixed(2) : "-",
                style: const TextStyle(fontSize: 20),
              ),
            ],
          ),
        )),
        Flexible(
            child: FittedBox(
          child: Column(
            children: [
              const Text(
                "平均分",
                style: TextStyle(fontSize: 12),
              ),
              Text(
                avg != -1 ? avg.toStringAsFixed(2) : "-",
                style: const TextStyle(fontSize: 20),
              ),
            ],
          ),
        )),
        Flexible(
            child: FittedBox(
          child: Column(
            children: [
              const Text(
                "中位数",
                style: TextStyle(fontSize: 12),
              ),
              Text(
                med != -1 ? med.toStringAsFixed(2) : "-",
                style: const TextStyle(fontSize: 20),
              ),
            ],
          ),
        )),
      ],
    );
  }
}
