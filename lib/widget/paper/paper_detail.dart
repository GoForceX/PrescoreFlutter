import 'package:flutter/material.dart';
import 'package:prescore_flutter/util/struct.dart';
import 'package:prescore_flutter/widget/paper/question_card.dart';
import 'package:provider/provider.dart';

import '../../model/paper_model.dart';

class PaperDetail extends StatefulWidget {
  final String examId;
  final String paperId;
  const PaperDetail({Key? key, required this.examId, required this.paperId})
      : super(key: key);

  @override
  State<PaperDetail> createState() => _PaperDetailState();
}

class _PaperDetailState extends State<PaperDetail> {
  @override
  Widget build(BuildContext context) {
    Widget main = Container();

    if (Provider.of<PaperModel>(context, listen: false).isDataLoaded) {
      List<Widget> questionCards = [];

      Provider.of<PaperModel>(context, listen: false)
          .paperData
          ?.questions
          .forEach((element) {
        questionCards.add(QuestionCard(question: element));
      });

      main = ListView(
        children: questionCards,
      );
    } else {
      main = FutureBuilder(
        future: Provider.of<PaperModel>(context, listen: false)
            .user
            .fetchPaperData(widget.examId, widget.paperId),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data["state"]) {
              List<Widget> questionCards = [];
              List<Widget> questionIndicators = [];

              snapshot.data["result"].questions.forEach((element) {
                (element as Question);
                if (element.isSelected) {
                  questionCards.add(QuestionCard(question: element));

                  Color indicatorColor = Colors.grey;
                  if ((element).userScore / (element).fullScore == 1) {
                    indicatorColor = Colors.lightGreen;
                  } else if ((element).userScore / (element).fullScore > 0) {
                    indicatorColor = Colors.yellowAccent;
                  } else {
                    indicatorColor = Colors.redAccent;
                  }

                  questionIndicators.add(
                    Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: indicatorColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: FittedBox(
                          child: Text(
                            element.questionId,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }
              });

              return CustomScrollView(
                slivers: [
                  SliverGrid.extent(
                    maxCrossAxisExtent: 72,
                    children: questionIndicators,
                  ),
                  SliverList(
                    delegate: SliverChildListDelegate(questionCards),
                  ),
                ],
              );
            } else {
              return Container();
            }
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      );
    }

    return Column(children: [
      Expanded(
        child: main,
      )
    ]);
  }
}
