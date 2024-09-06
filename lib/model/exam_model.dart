import 'package:flutter/material.dart';
import 'package:prescore_flutter/util/user_util.dart';
import 'package:collection/collection.dart';

import '../util/struct.dart';

enum UploadStatus { uploading, complete, incomplete }

class ExamModel extends ChangeNotifier {
  User user = User();

  bool isDiagFetched = false;
  bool isDiagLoaded = false;
  List<PaperDiagnosis> diagnoses = [];
  String tips = "";
  String subTips = "";

  bool isPaperLoaded = false;
  bool isPreviewPaperLoaded = false;
  UploadStatus uploadStatus = UploadStatus.incomplete;

  bool pageAnimationComplete = false;
  List<Paper> papers = [];
  List<Paper> absentPapers = [];
  int getLength(Source paperSource) {
    int sum = 0;
    for (Paper element in papers) {
      if (element.source == paperSource) {
        sum++;
      }
    }
    return sum;
  }

  void setUser(User value) {
    user = value;
    notifyListeners();
  }

  void setDiagFetched(bool value) {
    isDiagFetched = value;
    notifyListeners();
  }

  void setDiagLoaded(bool value) {
    isDiagLoaded = value;
    notifyListeners();
  }

  void setUploadStatus(UploadStatus value) {
    uploadStatus = value;
  }

  void setDiagnoses(List<PaperDiagnosis> value) {
    diagnoses = value;
    notifyListeners();
  }

  void setPageAnimationComplete() {
    pageAnimationComplete = true;
    notifyListeners();
  }

  void setTips(String value) {
    tips = value;
    notifyListeners();
  }

  void setSubTips(String value) {
    subTips = value;
    notifyListeners();
  }

  void setPaperLoaded(bool value) {
    isPaperLoaded = value;
    notifyListeners();
  }

  void setPreviewPaperLoaded(bool value) {
    isPreviewPaperLoaded = value;
    notifyListeners();
  }

  void addPapers(List<Paper> value) {
    for (Paper paperElement in value) {
      Paper? currentSamePaper = papers
          .firstWhereOrNull((item) => item.subjectId == paperElement.subjectId);
      if (currentSamePaper != null) {
        if (currentSamePaper.source != Source.common) {
          int index = papers.indexOf(currentSamePaper);
          papers.remove(currentSamePaper);
          papers.insert(index, paperElement);
        } else {
          currentSamePaper.id ??= paperElement.id;
          currentSamePaper.answerSheet ??= paperElement.answerSheet;
        }
      } else {
        papers.add(paperElement);
      }
    }
  }

  void setPapers(List<Paper> value) {
    papers = value;
  }

  void setAbsentPapers(List<Paper> value) {
    absentPapers = value;
  }
}
