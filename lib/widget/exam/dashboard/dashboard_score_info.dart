import 'package:flutter/material.dart';
import 'package:prescore_flutter/main.dart';
import 'package:prescore_flutter/util/struct.dart';
import 'package:prescore_flutter/util/user_util/extensions/telemetry_util.dart';
import 'package:provider/provider.dart';

import '../../../model/exam_model.dart';

class DashboardScoreInfo extends StatefulWidget {
  final String examId;
  final double minimum;
  final double maximum;
  final double avg;
  final double med;
  const DashboardScoreInfo(
      {Key? key,
      required this.examId,
      required this.minimum,
      required this.maximum,
      required this.avg,
      required this.med})
      : super(key: key);

  @override
  State<DashboardScoreInfo> createState() => _DashboardScoreInfoState();
}

class _DashboardScoreInfoState extends State<DashboardScoreInfo> {
  String dropdownValue = "full";
  ClassInfo? chosenClass;
  Future<Result<List<ClassInfo>>>? examClassInfoFuture;

  @override
  Widget build(BuildContext context) {
    examClassInfoFuture ??= Provider.of<ExamModel>(context, listen: false)
        .user
        .fetchExamClassInfo(widget.examId);
    return Card.filled(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          const SizedBox(
            height: 8,
          ),
          FittedBox(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const SizedBox(
                  width: 16,
                ),
                const Text(
                  "当前范围",
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(
                  width: 16,
                ),
                FutureBuilder(
                    future: examClassInfoFuture,
                    builder:
                        (BuildContext futureContext, AsyncSnapshot snapshot) {
                      if (snapshot.hasData) {
                        if (snapshot.data.state == false) {
                          return const Text("全年级",
                              style: TextStyle(fontSize: 16));
                        }

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
                          children: [
                            DropdownButton<String>(
                              value: dropdownValue,
                              // elevation: 16,
                              underline: Container(
                                height: 2,
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant,
                              ),
                              onChanged: (String? newValue) {
                                logger.d(newValue);
                                setState(() {
                                  dropdownValue = newValue!;
                                  if (dropdownValue == "full") {
                                    chosenClass = null;
                                  } else {
                                    chosenClass = snapshot.data.result
                                        .firstWhere((element) =>
                                            element.classId == dropdownValue);
                                  }
                                });
                              },
                              items: items,
                            ),
                          ],
                        );
                      } else {
                        return const Text("全年级",
                            style: TextStyle(fontSize: 16));
                      }
                    }),
                const SizedBox(
                  width: 16,
                ),
                Builder(builder: (BuildContext context) {
                  if (["", "full"].contains(dropdownValue)) {
                    return Container();
                  } else {
                    return Row(children: [
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
            ),
          ),
          Builder(builder: (BuildContext bc) {
            if (["", "full"].contains(dropdownValue) || chosenClass == null) {
              return DashboardScoreInfoData(
                  minimum: widget.minimum,
                  maximum: widget.maximum,
                  avg: widget.avg,
                  med: widget.med);
            } else {
              return DashboardScoreInfoData(
                  minimum: chosenClass!.min,
                  maximum: chosenClass!.max,
                  avg: chosenClass!.avg,
                  med: chosenClass!.med);
            }
          })
        ],
      ),
    );
  }
}

class DashboardScoreInfoData extends StatelessWidget {
  final double minimum;
  final double maximum;
  final double avg;
  final double med;
  const DashboardScoreInfoData(
      {Key? key,
      required this.minimum,
      required this.maximum,
      required this.avg,
      required this.med})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(12.0),
        alignment: AlignmentDirectional.topStart,
        child: Column(
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
                        minimum.toStringAsFixed(2),
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
                        maximum.toStringAsFixed(2),
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
                        avg.toStringAsFixed(2),
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
                        med.toStringAsFixed(2),
                        style: const TextStyle(fontSize: 32),
                      ),
                    ],
                  ),
                )),
              ],
            )
          ],
        ));
  }
}
