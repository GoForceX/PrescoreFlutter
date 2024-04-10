import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../model/exam_model.dart';
import '../../util/struct.dart';
import 'detail_card.dart';
import 'detail_util.dart';

class ExamDetail extends StatelessWidget {
  final String examId;
  const ExamDetail({Key? key, required this.examId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    setUploadListener(context);
    fetchData(context, examId);
    return Consumer<ExamModel>(
      builder:
          (BuildContext consumerContext, ExamModel examModel, Widget? child) {
        if (examModel.isPaperLoaded || examModel.isPreviewPaperLoaded) {
          List<Paper> papers = examModel.papers;
          // List<Paper> absentPapers = examModel.absentPapers;
          return ListView(
            padding: const EdgeInsets.all(8),
            shrinkWrap: false,
            children: papers.map((paper) => DetailCard(paper: paper, examId: examId)).toList(),
          );
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
