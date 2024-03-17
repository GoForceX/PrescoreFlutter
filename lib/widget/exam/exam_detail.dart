import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../model/exam_model.dart';
import '../../util/struct.dart';
import 'detail_card.dart';
import '../../main.dart';
import 'detail_util.dart';

class ExamDetail extends StatefulWidget {
  final String examId;
  const ExamDetail({Key? key, required this.examId}) : super(key: key);

  @override
  State<ExamDetail> createState() => _ExamDetailState();
}

class _ExamDetailState extends State<ExamDetail> {
  Map<String, bool> selectedSubject = {};
  @override
  void initState() {
    setUploadListener(context);
    fetchData(context, widget.examId);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExamModel>(
      builder:
          (BuildContext consumerContext, ExamModel examModel, Widget? child) {
        if (examModel.isPaperLoaded || examModel.isPreviewPaperLoaded) {
          List<Widget> children = [];
          List<Paper> papers = examModel.papers;
          // List<Paper> absentPapers = examModel.absentPapers;

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
                  )),
            ),
          ]);
        } else {
          return Center(
              child: Container(
                  margin: const EdgeInsets.all(10),
                  child: const CircularProgressIndicator()));
        }
      },
    );
  }
}
