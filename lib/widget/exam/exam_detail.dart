import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../model/exam_model.dart';
import '../../util/struct.dart';
import 'detail_card.dart';
import 'detail_util.dart';

class ExamDetail extends StatefulWidget {
  final String examId;
  const ExamDetail({Key? key, required this.examId}) : super(key: key);

  @override
  State<ExamDetail> createState() => _ExamDetailState();
}

class _ExamDetailState extends State<ExamDetail>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    setUploadListener(context);
    fetchData(context, widget.examId);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<ExamModel>(
      builder:
          (BuildContext consumerContext, ExamModel examModel, Widget? child) {
        if ((examModel.isPaperLoaded || examModel.isPreviewPaperLoaded) &&
            examModel.pageAnimationComplete) {
          List<Paper> papers = examModel.papers;
          List<Paper> absentPapers = examModel.absentPapers;
          List<String> absentPaperIds =
              absentPapers.map((paper) => paper.paperId).toList();
          List<Paper> presentPapers = papers
              .where((paper) => !absentPaperIds.contains(paper.paperId))
              .toList();
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            shrinkWrap: false,
            itemCount: presentPapers.length,
            itemBuilder: (BuildContext context, int index) {
              return DetailCard(
                  paper: presentPapers[index], examId: widget.examId);
            },
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
