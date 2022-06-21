import 'package:flutter/material.dart';
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

              snapshot.data["result"].questions.forEach((element) {
                questionCards.add(
                    QuestionCard(question: element));
              });

              return ListView(
                children: questionCards,
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
