import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../model/exam_model.dart';
import '../../util/struct.dart';
import 'detail_card.dart';

class ExamDetail extends StatefulWidget {
  final String examId;
  const ExamDetail({Key? key, required this.examId}) : super(key: key);

  @override
  State<ExamDetail> createState() => _ExamDetailState();
}

class _ExamDetailState extends State<ExamDetail> {
  @override
  Widget build(BuildContext context) {
    ListView listView;

    if (Provider.of<ExamModel>(context, listen: false).isPaperLoaded) {
      List<Widget> children = [];
      List<Paper> papers =
          Provider.of<ExamModel>(context, listen: false).papers;

      for (var element in papers) {
        Widget chart = DetailCard(paper: element, examId: widget.examId,);
        children.add(chart);
      }

      return Column(children: [
        Expanded(
            child: ListView(
          padding: const EdgeInsets.all(8),
          shrinkWrap: false,
          children: children,
        ))
      ]);
    } else {
      FutureBuilder futureBuilder = FutureBuilder(
        future: Provider.of<ExamModel>(context, listen: false)
            .user
            .fetchPaper(widget.examId),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data["state"]) {
              List<Widget> children = [];
              Provider.of<ExamModel>(context, listen: false)
                  .setPapers(snapshot.data["result"]);
              Provider.of<ExamModel>(context, listen: false)
                  .setPaperLoaded(true);

              for (var element in snapshot.data["result"]) {
                Widget chart = DetailCard(examId: widget.examId, paper: element);
                children.add(chart);
              }

              ListView listView = ListView(
                padding: const EdgeInsets.all(8),
                shrinkWrap: false,
                children: children,
              );

              return listView;
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
      return Column(children: [
        Expanded(
          child: futureBuilder,
        )
      ]);
    }
  }
}
