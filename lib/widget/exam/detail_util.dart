import 'package:prescore_flutter/main.dart';
import 'package:prescore_flutter/util/struct.dart';
import 'package:provider/provider.dart';

import '../../model/exam_model.dart';

void setUploadListener(context) {
  Provider.of<ExamModel>(context, listen: false).addListener(() {
    logger.d(
        "DashboardInfo: ${Provider.of<ExamModel>(context, listen: false).isPaperLoaded} ${Provider.of<ExamModel>(context, listen: false).isDiagFetched}");
    if (Provider.of<ExamModel>(context, listen: false).uploadStatus !=
        UploadStatus.incomplete) {
      return;
    }
    if (Provider.of<ExamModel>(context, listen: false).isPaperLoaded &&
        Provider.of<ExamModel>(context, listen: false).isDiagFetched) {
      Provider.of<ExamModel>(context, listen: false)
          .setUploadStatus(UploadStatus.uploading);
      for (var paper in Provider.of<ExamModel>(context, listen: false).papers) {
        if (paper.paperId == null) {
          continue;
        }
        try {
          logger.d("DashboardInfo: $paper");
          bool noDiag = false;
          if (Provider.of<ExamModel>(context, listen: false)
                  .diagnoses
                  .firstWhere((element) => element.subjectId == paper.subjectId,
                      orElse: () => PaperDiagnosis(
                          subjectId: '', subjectName: '', diagnosticScore: -1))
                  .diagnosticScore ==
              -1) {
            noDiag = true;
          }
          Paper processedPaper = Paper(
              examId: paper.examId,
              paperId: paper.paperId,
              name: paper.name,
              subjectId: paper.subjectId,
              userScore: paper.userScore,
              fullScore: paper.fullScore,
              source: paper.source,
              diagnosticScore: noDiag
                  ? null
                  : 100 -
                      Provider.of<ExamModel>(context, listen: false)
                          .diagnoses
                          .firstWhere(
                              (element) => element.subjectId == paper.subjectId)
                          .diagnosticScore);
          Provider.of<ExamModel>(context, listen: false)
              .user
              .uploadPaperData(processedPaper);
          Provider.of<ExamModel>(context, listen: false)
              .user
              .fetchPaperClassList(paper.paperId!)
              .then((value) {
            if (value.state && value.result != null) {
              Provider.of<ExamModel>(context, listen: false)
                  .user
                  .uploadPaperClassData(value.result!, paper.paperId!);
            }
          });
        } catch (e) {
          Provider.of<ExamModel>(context, listen: false)
              .setUploadStatus(UploadStatus.incomplete);
          logger.e(e);
        }
      }
      Provider.of<ExamModel>(context, listen: false)
          .setUploadStatus(UploadStatus.complete);
    }
  });
}

void fetchData(context, examId) {
  if (!Provider.of<ExamModel>(context, listen: false).isDiagLoaded) {
    Future.delayed(Duration.zero, () async {
      Result<ExamDiagnosis> result =
          await Provider.of<ExamModel>(context, listen: false)
              .user
              .fetchPaperDiagnosis(examId);

      if (result.state && context.mounted) {
        Provider.of<ExamModel>(context, listen: false)
            .setDiagnoses(result.result!.diagnoses);
        Provider.of<ExamModel>(context, listen: false)
            .setTips(result.result!.tips);
        Provider.of<ExamModel>(context, listen: false)
            .setSubTips(result.result!.subTips);
        Provider.of<ExamModel>(context, listen: false).setDiagFetched(true);
        Provider.of<ExamModel>(context, listen: false).setDiagLoaded(true);
      } else if (context.mounted) {
        Provider.of<ExamModel>(context, listen: false).setDiagFetched(true);
      }
    });
  }
  if (BaseSingleton.singleton.sharedPreferences.getBool("showMoreSubject") ==
          true &&
      !Provider.of<ExamModel>(context, listen: false).isPreviewPaperLoaded) {
    bool previewScore =
        BaseSingleton.singleton.sharedPreferences.getBool('tryPreviewScore') ==
            true;
    Provider.of<ExamModel>(context, listen: false)
        .user
        .fetchPreviewPaper(examId, requestScore: previewScore)
        .then((value) {
      if (value.state && context.mounted) {
        Provider.of<ExamModel>(context, listen: false)
            .addPapers(value.result![0]);
        Provider.of<ExamModel>(context, listen: false)
            .setPreviewPaperLoaded(true);
      }
    });
  }
  if (!Provider.of<ExamModel>(context, listen: false).isPaperLoaded) {
    Provider.of<ExamModel>(context, listen: false)
        .user
        .fetchPaper(examId)
        .then((value) {
      if (value.state && context.mounted) {
        Provider.of<ExamModel>(context, listen: false)
            .addPapers(value.result![0]);
        Provider.of<ExamModel>(context, listen: false)
            .setAbsentPapers(value.result![1]);
        Provider.of<ExamModel>(context, listen: false).setPaperLoaded(true);
      }
    });
  }
}
