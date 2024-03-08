import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../model/exam_model.dart';
import '../../util/struct.dart';
import 'detail_card.dart';
import '../../main.dart';

class ExamDetail extends StatefulWidget {
  final String examId;
  const ExamDetail({Key? key, required this.examId}) : super(key: key);

  @override
  State<ExamDetail> createState() => _ExamDetailState();
}

class _ExamDetailState extends State<ExamDetail> {
  Map<String, bool> selectedSubject = {};
  @override
  Widget build(BuildContext context) {
    if (Provider.of<ExamModel>(context, listen: false).isPaperLoaded) {
      List<Widget> children = [];
      List<Paper> papers =
          Provider.of<ExamModel>(context, listen: false).papers;
      List<Widget> subjectList = [];
      for (Paper element in papers) {
        subjectList.add(const SizedBox(width: 6));
        subjectList.add(ChoiceChip(
          label: Text(element.name),
          selected: selectedSubject[element.subjectId] ??
              BaseSingleton.singleton.sharedPreferences
                  .getBool("defaultShowAllSubject") ??
              false,
          onSelected: (bool selected) {
            setState(() {
              selectedSubject[element.subjectId] = selected;
            });
          },
        ));
      }
      subjectList.add(const SizedBox(width: 6));
      for (Paper element in papers) {
        Widget chart = Visibility(
            visible: selectedSubject[element.subjectId] ??
                (BaseSingleton.singleton.sharedPreferences
                        .getBool("defaultShowAllSubject") ??
                    false),
            child: DetailCard(paper: element, examId: widget.examId));
        children.add(chart);
      }

      return Stack(children: [
        ListView(
          padding: const EdgeInsets.all(8),
          shrinkWrap: false,
          children: children,
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Card(
              margin: const EdgeInsets.all(7),
              child: Row(children: subjectList),
            )
          ),
        ),
      ]);
    } else {
      FutureBuilder futureBuilder = FutureBuilder(
        future: Provider.of<ExamModel>(context, listen: false)
            .user
            .fetchPaper(widget.examId),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data.state) {
              List<Widget> children = [];
              Provider.of<ExamModel>(context, listen: false)
                  .setPapers(snapshot.data.result[0]);
              Provider.of<ExamModel>(context, listen: false)
                  .setAbsentPapers(snapshot.data.result[1]);
              Provider.of<ExamModel>(context, listen: false)
                  .setPaperLoaded(true);

              List<Paper> papers = snapshot.data.result[0];
              // List<Paper> absentPapers = snapshot.data.result[1];

              List<Widget> subjectList = [];
              for (Paper element in papers) {
                subjectList.add(const SizedBox(width: 6));
                subjectList.add(ChoiceChip(
                  label: Text(element.name),
                  selected: selectedSubject[element.subjectId] ??
                      BaseSingleton.singleton.sharedPreferences
                          .getBool("defaultShowAllSubject") ??
                      false,
                  onSelected: (bool selected) {
                    setState(() {
                      selectedSubject[element.subjectId] = selected;
                    });
                  },
                ));
              }
              subjectList.add(const SizedBox(width: 6));
              for (Paper element in papers) {
                Widget chart = Visibility(
                    visible: selectedSubject[element.subjectId] ??
                        (BaseSingleton.singleton.sharedPreferences
                                .getBool("defaultShowAllSubject") ??
                            false),
                    child: DetailCard(paper: element, examId: widget.examId));
                children.add(chart);
              }
              return Stack(children: [
                ListView(
                  padding: const EdgeInsets.all(8),
                  shrinkWrap: false,
                  children: children,
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Card(
                      child: Row(children: subjectList),
                    )
                  ),
                ),
              ]);
            } else {
              return Container();
            }
          } else {
            return Center(
                child: Container(
                    margin: const EdgeInsets.all(10),
                    child: const CircularProgressIndicator()));
          }
        },
      );
      return futureBuilder;
    }
  }
}
