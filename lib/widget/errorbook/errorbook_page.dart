import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:prescore_flutter/model/login_model.dart';
import 'package:prescore_flutter/widget/drawer.dart';
import 'package:provider/provider.dart';

import '../../model/errorbook_model.dart';
import '../../util/struct.dart';
import 'question_card.dart';

@RoutePage()
class ErrorBookPage extends StatelessWidget {
  const ErrorBookPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('错题集'),
        titleSpacing: 0,
      ),
      body: ChangeNotifierProvider(
          create: (_) => ErrorBookModel(),
          builder: (BuildContext context, Widget? child) {
            ErrorBookModel model =
                Provider.of<ErrorBookModel>(context, listen: false);
            model.user = Provider.of<LoginModel>(context, listen: false).user;
            model.onChange = () async {
              String subjectCode = model.selectedSubjectCode!;
              int pageIndex = model.selectedPageIndex;
              DateTime? beginTime = model.beginTime;
              beginTime?.copyWith(hour: 0, minute: 0, second: 0);
              DateTime? endTime = model.endTime;
              endTime?.copyWith(hour: 23, minute: 59, second: 59);
              Result<ErrorBookData> result = await model.user
                  .fetchErrorbookList(
                      subjectCode: subjectCode,
                      pageIndex: pageIndex,
                      beginTime: beginTime,
                      endTime: endTime);
              if (result.state) {
                model.setErrorBookData(result.result, cleanTotalPage: false);
              }
            };
            model.user.fetchErrorbookSubjectList().then((value) {
              if (value.state) {
                Provider.of<ErrorBookModel>(context, listen: false)
                    .setSubjectCodeList(value.result!);
              }
            });
            return Consumer<ErrorBookModel>(
              builder: (context, model, widget) {
                int? totalPage = Provider.of<ErrorBookModel>(context, listen: false).totalPage;
                ErrorBookData? errorBookData =
                    Provider.of<ErrorBookModel>(context, listen: false)
                        .errorBookData;
                return CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: SubjectFilter(
                            subjectList: Provider.of<ErrorBookModel>(context, listen: false).subjectCodeList ?? [],
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: DateChooser()
                        ),
                        if (errorBookData != null)
                          SliverToBoxAdapter(
                            child: Row(children: [
                              const SizedBox(width: 8),
                              const Icon(Icons.format_list_numbered_rounded, size: 18),
                              Text(
                                  " 共 ${errorBookData.totalQuestion} 道, ${errorBookData.totalPage} 页",
                                  style: const TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.bold))
                            ]),
                          ),
                        if (errorBookData != null)
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              childCount: Provider.of<ErrorBookModel>(context, listen: false).totalPage ?? 0,
                              (context, index) => ErrorQuestionCard(errorQuestion: errorBookData.errorQuestions[index]),
                              
                            ),
                          ),
                        if (errorBookData == null)
                          const SliverToBoxAdapter(child: 
                            Center(child: CircularProgressIndicator()),
                          ),
                        if (totalPage != null)
                          SliverToBoxAdapter(child: 
                            Center(child: PageChooser(totalPage: totalPage)),
                          ),
                      ],
                    );
              },
            );
          }),
      drawer: const MainDrawer(),
    );
  }
}

class SubjectFilter extends StatelessWidget {
  final List<Subject> subjectList;
  const SubjectFilter({required this.subjectList, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> cards = [];
    cards.add(const Text(" 学科 ",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)));
    for (int i = 0; i < subjectList.length; i++) {
      cards.add(Card(
        elevation: 0,
        color: Provider.of<ErrorBookModel>(context, listen: false)
                    .selectedSubjectCode ==
                subjectList[i].code
            ? Theme.of(context).colorScheme.secondaryContainer
            : Theme.of(context).colorScheme.onPrimary,
        margin: const EdgeInsets.all(4.0),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          onTap: () {
            Provider.of<ErrorBookModel>(context, listen: false)
                .setSubjectCode(subjectList[i].code);
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Text(" ${subjectList[i].name} "),
          ),
        ),
      ));
    }
    return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          margin: const EdgeInsets.only(left: 7),
          child: Row(children: cards),
        ));
  }
}

class PageChooser extends StatelessWidget {
  final int totalPage;
  const PageChooser({required this.totalPage, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> cards = [];
    for (int i = 1; i <= totalPage; i++) {
      cards.add(Card(
        elevation: 0,
        color: Provider.of<ErrorBookModel>(context, listen: false)
                    .selectedPageIndex ==
                i
            ? Theme.of(context).colorScheme.secondaryContainer
            : Theme.of(context).colorScheme.onPrimary,
        margin: const EdgeInsets.all(4.0),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          onTap: () {
            Provider.of<ErrorBookModel>(context, listen: false).setPageIndex(i);
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(" $i "),
          ),
        ),
      ));
    }
    return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          margin: const EdgeInsets.all(7),
          child: Row(children: cards),
        ));
  }
}

class DateChooser extends StatelessWidget {
  const DateChooser({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ErrorBookModel>(builder: (context, model, widget) {
      ErrorBookModel model =
          Provider.of<ErrorBookModel>(context, listen: false);
      return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            margin: const EdgeInsets.only(left: 7, bottom: 4),
            child: Row(children: [
              const Text(" 日期  ",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ActionChip(
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                ),
                backgroundColor: model.beginTime != null
                    ? Theme.of(context).colorScheme.secondaryContainer
                    : Theme.of(context).colorScheme.onPrimary,
                label: model.beginTime != null
                    ? Text(
                        "${model.beginTime?.year}-${model.beginTime?.month}-${model.beginTime?.day}")
                    : const Text("默认"),
                avatar: const Icon(Icons.event),
                onPressed: () async {
                  DateTime? date = await showDatePicker(
                    context: context,
                    initialDate: model.beginTime ?? DateTime.now(),
                    firstDate: DateTime(1970),
                    lastDate: DateTime.now(),
                    helpText: "选择起始日期",
                  );
                  model.setFromDate(date);
                },
              ),
              const Text("  至  ",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ActionChip(
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                ),
                backgroundColor: model.endTime != null
                    ? Theme.of(context).colorScheme.secondaryContainer
                    : Theme.of(context).colorScheme.onPrimary,
                label: model.endTime != null
                    ? Text(
                        "${model.endTime?.year}-${model.endTime?.month}-${model.endTime?.day}")
                    : const Text("默认"),
                avatar: const Icon(Icons.event),
                onPressed: () async {
                  DateTime? date = await showDatePicker(
                    context: context,
                    initialDate: model.endTime ?? DateTime.now(),
                    firstDate: DateTime(1970),
                    lastDate: DateTime.now(),
                    helpText: "选择终止日期",
                  );
                  model.setToDate(date);
                },
              ),
            ]),
          ));
    });
  }
}
