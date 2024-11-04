import 'package:dio/dio.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:prescore_flutter/main.dart';
import 'package:prescore_flutter/model/login_model.dart';
import 'package:prescore_flutter/util/user_util/user_util.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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

class Exams extends StatelessWidget {
  const Exams({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> slivers = [];
    EasyRefreshController controller = EasyRefreshController(
      controlFinishRefresh: true,
      controlFinishLoad: true,
    );
    //slivers.add(const SliverHeader());
    slivers.add(SliverAppBar(
      //title: Text("考试列表"),
      forceElevated: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text("考试列表", style: Theme.of(context).textTheme.titleLarge),
        titlePadding: const EdgeInsetsDirectional.only(start: 56, bottom: 14),
        expandedTitleScale: 1.8,
      ),
      actions: [
        IconButton(
            onPressed: () =>
                launchUrl(Uri.parse("https://bjbybbs.com/t/Revealer")),
            icon: const Icon(Icons.insert_comment))
      ],
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      snap: false,
    ));
    slivers.add(const HeaderLocator.sliver());
    GlobalKey<ExamsListState> key = GlobalKey();
    ExamsList exams = ExamsList(key: key, controller: controller);
    slivers.add(exams);
    slivers.add(const FooterLocator.sliver());
    LoginModel model = Provider.of<LoginModel>(context, listen: false);
    return EasyRefresh.builder(
        controller: controller,
        header: const ClassicHeader(
          position: IndicatorPosition.locator,
          dragText: '下滑刷新 (´ρ`)',
          armedText: '松开刷新 (´ρ`)',
          readyText: '获取数据中... (›´ω`‹)',
          processingText: '获取数据中... (›´ω`‹)',
          processedText: '成功！(`ヮ´)',
          noMoreText: '太多啦 TwT',
          failedText: '失败了 TwT',
          messageText: '上次更新于 %T',
          hapticFeedback: true,
        ),
        footer: const ClassicFooter(
          infiniteOffset: 0,
          position: IndicatorPosition.locator,
          dragText: '下滑刷新 (´ρ`)',
          armedText: '松开刷新 (´ρ`)',
          readyText: '获取数据中... (›´ω`‹)',
          processingText: '获取数据中... (›´ω`‹)',
          processedText: '成功！(`ヮ´)',
          noMoreText: '我一点都没有了... TwT',
          failedText: '失败了 TwT',
          messageText: '上次更新于 %T',
        ),
        onRefresh: (model.isLoggedIn)
            ? () async {
                await key.currentState?.refresh();
              }
            : null,
        onLoad: (model.isLoggedIn)
            ? () async {
                await key.currentState?.load();
              }
            : null,
        childBuilder: (BuildContext ct, ScrollPhysics sp) => CustomScrollView(
              physics: sp,
              slivers: slivers,
            ));
  }
}

class ExamsList extends StatefulWidget {
  final EasyRefreshController controller;
  const ExamsList({Key? key, required this.controller}) : super(key: key);

  @override
  State<StatefulWidget> createState() => ExamsListState();
}

enum PageType { exam, homework }

class ExamsListState extends State<ExamsList> {
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
            side: WidgetStateProperty.all(BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            )),
            shape: WidgetStateProperty.all(RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0))),
            elevation: WidgetStateProperty.all(2),
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
              pageIndex = 1;
              result = null;
              lastFetched = false;
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
        if (result != null) {
          widget.controller.finishLoad();
        }
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
      setState(() {
        retry--;
        if (retry <= 0) {
          result ??= [];
          if (e is DioException) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(e.error.toString())));
          } else {
            throw e;
          }
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
