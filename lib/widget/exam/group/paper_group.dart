import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:prescore_flutter/main.dart';
import 'package:prescore_flutter/util/paper_group_db.dart';
import 'package:prescore_flutter/widget/exam/group/detail_card_group.dart';
import 'package:provider/provider.dart';

import '../../../model/exam_model.dart';
import '../../../util/struct.dart';

class PaperGroup extends StatefulWidget {
  final String examId;
  const PaperGroup({Key? key, required this.examId}) : super(key: key);

  @override
  State<PaperGroup> createState() => _PaperGroupState();
}

class _PaperGroupState extends State<PaperGroup>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  List<List<Paper>> papersGroupList = [];

  Future<void> updateLocalDb() async {
    await deletePapersGroups(widget.examId);
    await savePapersGroups(papersGroupList);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<ExamModel>(
      builder:
          (BuildContext consumerContext, ExamModel examModel, Widget? child) {
        List<Paper> papers = [];
        if (examModel.isPaperLoaded) {
          List<String> absentPaperIds =
              examModel.absentPapers.map((paper) => paper.paperId!).toList();
          papers = examModel.papers
              .where((paper) =>
                  !absentPaperIds.contains(paper.paperId) &&
                  paper.source == Source.common)
              .toList();
          readPaperGroups(widget.examId)
              .then((List<List<String>> papersGroups) {
            logger.d("readPaperGroups $papersGroups");
            if (papersGroupList.isNotEmpty) {
              return;
            }
            for (List<String> idGroup in papersGroups) {
              List<Paper> papersGroup = [];
              for (String paperId in idGroup) {
                List fetchRes =
                    papers.where((paper) => paper.paperId == paperId).toList();
                if (fetchRes.isNotEmpty) {
                  papersGroup.add(fetchRes[0]);
                }
              }
              papersGroupList.add(papersGroup);
            }
            setState(() {});
          });
        } else {
          return Center(
              child: Container(
                  margin: const EdgeInsets.all(10),
                  child: const CircularProgressIndicator()));
        }
        return Stack(children: [
          if (papersGroupList.isNotEmpty)
            ListView.builder(
              padding: const EdgeInsets.all(8),
              shrinkWrap: false,
              itemCount: papersGroupList.length,
              itemBuilder: (BuildContext context, int index) {
                return DetailCardGroup(
                    paperGroups: papersGroupList[index],
                    examId: widget.examId,
                    deleteCallback: () {
                      papersGroupList.remove(papersGroupList[index]);
                      updateLocalDb();
                      setState(() {});
                    });
              },
            )
          else
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                children: [
                  SizedBox(
                    height: 180,
                    child: SvgPicture.asset("assets/add_files.svg",
                        colorFilter: ColorFilter.mode(
                            Theme.of(context).colorScheme.primaryContainer,
                            BlendMode.modulate), //modulate overlay
                        semanticsLabel: 'A red up arrow'),
                  ),
                  Text("\n暂无科目组",
                      style: Theme.of(context).textTheme.labelMedium)
                ],
              ),
            ),
          Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton.extended(
                heroTag: null,
                onPressed: papers.isNotEmpty
                    ? () {
                        showDialog(
                            context: context,
                            builder: (context) {
                              return AddGroupDialog(
                                  papers: papers,
                                  callback: (result) {
                                    setState(() {
                                      papersGroupList.add(result);
                                      updateLocalDb();
                                    });
                                  });
                            });
                      }
                    : null,
                icon: const Icon(Icons.add),
                label: const Text("科目组"),
              ))
        ]);
      },
    );
  }
}

class AddGroupDialog extends StatefulWidget {
  final List<Paper> papers;
  final Function(List<Paper> result) callback;
  const AddGroupDialog(
      {required this.papers, required this.callback, super.key});

  @override
  AddGroupDialogState createState() => AddGroupDialogState();
}

class AddGroupDialogState extends State<AddGroupDialog> {
  Set<String> selectedPaper = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择成组科目'),
      content: Wrap(
          alignment: WrapAlignment.center,
          children: widget.papers.map((Paper entry) {
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
              child: FilterChip(
                label: Text(entry.name),
                selected: selectedPaper.contains(entry.paperId),
                onSelected: (bool value) {
                  if (value) {
                    selectedPaper.add(entry.paperId!);
                  } else {
                    selectedPaper.remove(entry.paperId);
                  }
                  setState(() {});
                },
              ),
            );
          }).toList()),
      actions: <Widget>[
        TextButton(
          onPressed: () async {
            if (selectedPaper.isNotEmpty) {
              List<Paper> result = selectedPaper
                  .map((paperId) => widget.papers
                      .where((paper) => paper.paperId == paperId)
                      .first)
                  .toList();
              widget.callback(result);
            }
            Navigator.pop(context, '确定');
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}
