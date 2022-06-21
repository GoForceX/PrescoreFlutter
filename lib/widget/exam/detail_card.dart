import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
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
                      Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: const [
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
              linearGradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Colors.lightBlueAccent, Colors.lightBlue, Colors.blue],
              ),
              barRadius: const Radius.circular(4),
            ),
            const SizedBox(
              height: 16,
            ),
            FutureBuilder(
              future: Provider.of<ExamModel>(context, listen: false)
                  .user
                  .fetchPaperPredict(paper.paperId, paper.userScore),
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                logger.d("DetailPredict: ${snapshot.data}");
                if (snapshot.hasData) {
                  if (snapshot.data["state"]) {
                    if (snapshot.data["result"] < 0) {
                      Widget predict = const DetailPredict(percentage: 0);
                      return predict;
                    } else if (snapshot.data["result"] > 1) {
                      Widget predict = const DetailPredict(percentage: 1);
                      return predict;
                    } else {
                      Widget predict =
                          DetailPredict(percentage: snapshot.data["result"]);
                      return predict;
                    }
                  } else {
                    return Container();
                  }
                } else {
                  return const DetailPredict(percentage: -1);
                }
              },
            ),
          ],
        ));

    return Card(
      margin: const EdgeInsets.all(12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 8,
      child: InkWell(
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
  final double percentage;
  const DetailPredict({Key? key, required this.percentage}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: FittedBox(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Text(
                    "预测年排百分比：",
                    style: TextStyle(fontSize: 24),
                  ),
                  SizedBox(
                    height: 12,
                  )
                ],
              ),
              Text(
                percentage != -1 ?(percentage * 100).toStringAsFixed(2) : "-",
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(
                width: 16,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Text(
                    "%",
                    style: TextStyle(fontSize: 24),
                  ),
                  SizedBox(
                    height: 12,
                  )
                ],
              ),
            ],
          ),
        ));
  }
}
