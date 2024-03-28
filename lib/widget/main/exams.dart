import 'package:dio/dio.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:prescore_flutter/main.dart';
import 'package:prescore_flutter/model/login_model.dart';
import 'package:provider/provider.dart';

import '../../util/struct.dart';
import 'exam_card.dart';

List<Widget> generateCardsFromExams(BuildContext context, List<Exam> exams) {
  List<Widget> cards = [];
  for (Exam exam in exams) {
    cards.add(ExamCard(
      user: Provider.of<LoginModel>(context, listen: false).user,
      uuid: exam.uuid,
      examName: exam.examName,
      examType: exam.examType,
      examTime: exam.examTime,
      isFinal: exam.isFinal,
    ));
  }
  return cards;
}

class Exams extends StatefulWidget {
  final EasyRefreshController controller;
  const Exams({Key? key, required this.controller}) : super(key: key);

  @override
  State<StatefulWidget> createState() => ExamsState();
}

enum PageType { exam, homework }

class ExamsState extends State<Exams> {
  int pageIndex = 1;
  int retry = 4;
  bool lastFetched = false;
  bool isLoading = false;
  PageType pageType = PageType.exam;
  List<Exam>? result;

  bool isLoaded() {
    final result = this.result;
    if (result != null) {
      return result.isNotEmpty;
    }
    return false;
  }

  Future<bool> refresh() async {
    isLoading = true;
    LoginModel model = Provider.of<LoginModel>(context, listen: false);
    try {
      result = (await model.user
              .fetchExams(1, homework: pageType == PageType.homework))
          .result;
    } catch (e) {
      widget.controller.finishRefresh(IndicatorResult.fail);
      widget.controller.resetHeader();
      widget.controller.resetFooter();
      return true;
    }
    pageIndex = 1;
    lastFetched = false;
    setState(() {});
    widget.controller.finishRefresh();
    widget.controller.resetHeader();
    widget.controller.resetFooter();
    isLoading = true;
    return true;
  }

  Future<bool> load() async {
    isLoading = true;
    LoginModel model = Provider.of<LoginModel>(context, listen: false);
    pageIndex += 1;
    List<Exam>? newResult;
    try {
      newResult = ((await model.user
              .fetchExams(pageIndex, homework: pageType == PageType.homework))
          .result);
    } catch (e) {
      widget.controller.finishLoad(IndicatorResult.fail);
      return true;
    }
    if (newResult == null) {
      widget.controller.finishLoad(IndicatorResult.fail);
      return true;
    }
    if (newResult.length < 10) {
      lastFetched = true;
    }
    for (var element in newResult) {
      result?.add(element);
    }

    setState(() {});
    if (lastFetched) {
      widget.controller.finishLoad(IndicatorResult.noMore);
    } else {
      widget.controller.finishLoad();
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    logger.d("Rebuild!");
    Widget segmentedButton = Container(
        padding: const EdgeInsets.all(8),
        child: SegmentedButton<PageType>(
          style: ButtonStyle(
            side: MaterialStateProperty.all(BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            )),
            shape: MaterialStateProperty.all(RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0))),
            elevation: MaterialStateProperty.all(2),
          ),
          segments: const <ButtonSegment<PageType>>[
            ButtonSegment<PageType>(
                value: PageType.exam,
                label: Text('考试报告'),
                icon: Icon(Icons.history_edu)),
            ButtonSegment<PageType>(
                value: PageType.homework,
                label: Text('练习报告'),
                icon: Icon(Icons.home_work_outlined)),
          ],
          selected: <PageType>{pageType},
          onSelectionChanged: (newSelection) {
            setState(() {
              pageType = newSelection.first;
              result = null;
              isLoading = true;
              //refresh();
            });
          },
        ));
    if (result != null) {
      List<Widget> pageList = [const SizedBox(height: 8), segmentedButton];
      pageList.addAll(generateCardsFromExams(context, result!));
      return SliverList(delegate: SliverChildListDelegate(pageList));
    }

    LoginModel model = Provider.of<LoginModel>(context, listen: false);
    model.user
        .fetchExams(1, homework: pageType == PageType.homework)
        .then((value) {
      setState(() {
        result = value.result;
        retry--;
        if (retry <= 0) {
          result ??= [];
          if (!value.state) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(value.message)));
          }
        }
      });
    }).catchError((e) {
      (e as DioException);
      setState(() {
        retry--;
        if (retry <= 0) {
          result ??= [];
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.error.toString())));
        }
      });
    });
    return SliverList(
        delegate: SliverChildListDelegate([
      const SizedBox(height: 8),
      segmentedButton,
      Center(
          child: Container(
              margin: const EdgeInsets.all(10),
              child: const CircularProgressIndicator()))
    ]));
  }
}

class ExamsBuilder extends StatelessWidget {
  final Future future;
  const ExamsBuilder({Key? key, required this.future}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: future,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          logger.d("snapshot.data: ${snapshot.data}");
          if (snapshot.connectionState == ConnectionState.done) {
            if (!snapshot.data.state) {
              SnackBar snackBar = SnackBar(
                content: Text('呜呜呜，考试数据获取失败了……\n失败原因：${snapshot.data.message}'),
                //backgroundColor: Colors.grey.withOpacity(0.5),
              );
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
              return SliverList(
                  delegate: SliverChildListDelegate(
                      generateCardsFromExams(context, [])));
            }
            return SliverList(
                delegate: SliverChildListDelegate(
                    generateCardsFromExams(context, snapshot.data.result)));
          } else {
            return const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                  child: SizedBox(
                height: 40,
                width: 40,
                child: CircularProgressIndicator(),
              )),
            );
          }
        });
  }
}
