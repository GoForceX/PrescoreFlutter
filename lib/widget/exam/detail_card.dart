import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:prescore_flutter/util/user_util.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../main.gr.dart';
import '../../model/exam_model.dart';
import '../../util/struct.dart';

class DetailCard extends StatelessWidget {
  final String examId;
  final Paper paper;
  const DetailCard({Key? key, required this.paper, required this.examId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Container infoCard = Container(
        padding: const EdgeInsets.all(12.0),
        alignment: AlignmentDirectional.topStart,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                            "${paper.name}：",
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(
                            height: 12,
                          )
                        ],
                      ),
                      Text(
                        "${paper.userScore}",
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
                        "${paper.fullScore}",
                        style: const TextStyle(fontSize: 48),
                      ),
                    ],
                  ),
                )),
            const SizedBox(
              height: 16,
            ),
            LinearPercentIndicator(
              lineHeight: 8.0,
              percent: paper.userScore / paper.fullScore,
              backgroundColor: Colors.grey,
              linearGradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                //colors: [Colors.lightBlueAccent, Colors.lightBlue, Colors.blue],
                colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary.withOpacity(0.6)]
              ),
              barRadius: const Radius.circular(4),
            ),
            const SizedBox(
              height: 16,
            ),
            FutureBuilder(
              future: Provider.of<ExamModel>(context, listen: false)
                  .user
                  .fetchPaperPercentile(
                      paper.examId, paper.paperId, paper.userScore),
              builder: (BuildContext context,
                  AsyncSnapshot<Result<PaperPercentile>> snapshot) {
                logger.d("DetailPredict: ${snapshot.data}");
                if (snapshot.hasData) {
                  if (snapshot.data!.state) {
                    Widget predict = DetailPredict(
                        subjectId: paper.subjectId,
                        subjectName: paper.name,
                        version: snapshot.data!.result!.version,
                        percentage: snapshot.data!.result!.percentile,
                        official: snapshot.data!.result!.official,
                        count: snapshot.data!.result!.count,
                        assignScore: paper.assignScore);
                    return predict;
                  } else {
                    return Container();
                  }
                } else {
                  return DetailPredict(
                      subjectId: paper.subjectId,
                      subjectName: paper.name,
                      version: -1,
                      percentage: -1,
                      official: false,
                      count: -1,
                      assignScore: paper.assignScore);
                }
              },
            ),
            FutureBuilder(
              future: Provider.of<ExamModel>(context, listen: false)
                  .user
                  .fetchPaperScoreInfo(paper.paperId),
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                logger.d("DetailScoreInfo: ${snapshot.data}");
                if (snapshot.hasData) {
                  if (snapshot.data.state) {
                    Widget scoreInfo = DetailScoreInfo(
                        paperId: paper.paperId,
                        maximum: snapshot.data.result.max,
                        minimum: snapshot.data.result.min,
                        avg: snapshot.data.result.avg,
                        med: snapshot.data.result.med);
                    return scoreInfo;
                  } else {
                    return Container();
                  }
                } else {
                  return DetailScoreInfo(
                      paperId: paper.paperId,
                      maximum: -1,
                      minimum: -1,
                      avg: -1,
                      med: -1);
                }
              },
            ),
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
      child: InkWell(
        borderRadius:BorderRadius.circular(12.0),
        onTap: () {
          context.router.navigate(PaperRoute(
              examId: examId,
              paperId: paper.paperId,
              user: Provider.of<ExamModel>(context, listen: false).user));
        },
        child: infoCard,
      ),
    );
  }
}

class DetailPredict extends StatelessWidget {
  final String subjectId;
  final String subjectName;
  final int version;
  final double percentage;
  final double? assignScore;
  final bool official;
  final int count;
  const DetailPredict(
      {Key? key,
      required this.subjectId,
      required this.subjectName,
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
                      Container(
                        height: 20,
                        width: official ? 56 : 32,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.5),
                          borderRadius: const BorderRadius.all(
                            Radius.circular(4),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Center(
                            child: FittedBox(
                          child: Text(
                            official
                                ? '${(percentage * count).ceil()} / $count'
                                : 'v$version',
                            style: const TextStyle(fontSize: 12),
                          ),
                        )),
                      ),
                      const SizedBox(
                        width: 16,
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
            if (['数学', '语文', '英语'].contains(subjectName)) {
              return Container();
            }
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
                            Container(
                              height: 20,
                              width: 32,
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.5),
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(4),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'v$version',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 16,
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

class DetailScoreInfo extends StatefulWidget {
  final String paperId;
  final double minimum;
  final double maximum;
  final double avg;
  final double med;
  const DetailScoreInfo(
      {Key? key,
      required this.paperId,
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FittedBox(
          child:
            FutureBuilder(
              future: Provider.of<ExamModel>(context, listen: false)
                  .user
                  .fetchPaperClassInfo(widget.paperId),
              builder:
                  (BuildContext futureContext, AsyncSnapshot snapshot) {
                if (snapshot.hasData) {
                  if (snapshot.data.state == false) {
                    return const Text("全年级",
                        style: TextStyle(fontSize: 16));
                  }
                  num tempClassInfoNum = 0;
                  for(var i in snapshot.data.result) {
                    tempClassInfoNum = tempClassInfoNum + (i.count ?? 0);
                  }
                  classInfoNum = tempClassInfoNum;
                  /*setState(() {
                  });*/
                  if (dropdownValue == "") {
                    dropdownValue = snapshot.data.result[0].classId;
                    chosenClass = snapshot.data.result[0];
                  }

                  List<DropdownMenuItem<String>> items = snapshot
                      .data.result
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
                        // elevation: 16,
                        underline: Container(
                          height: 2,
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
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
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
                          ]);
                        } else {
                          return Row(children: [
                            const SizedBox(width: 8),
                            const Icon(Icons.people),
                            Text(" ${chosenClass?.count ?? 0} 条",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
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
        ),
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
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Flexible(
                child: FittedBox(
              child: Column(
                children: [
                  const Text(
                    "最低分",
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    minimum != -1 ? minimum.toStringAsFixed(2) : "-",
                    style: const TextStyle(fontSize: 32),
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
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    maximum != -1 ? maximum.toStringAsFixed(2) : "-",
                    style: const TextStyle(fontSize: 32),
                  ),
                ],
              ),
            )),
          ],
        ),
        const SizedBox(
          height: 16,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Flexible(
                child: FittedBox(
              child: Column(
                children: [
                  const Text(
                    "平均分",
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    avg != -1 ? avg.toStringAsFixed(2) : "-",
                    style: const TextStyle(fontSize: 32),
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
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    med != -1 ? med.toStringAsFixed(2) : "-",
                    style: const TextStyle(fontSize: 32),
                  ),
                ],
              ),
            )),
          ],
        )
      ],
    );
  }
}
