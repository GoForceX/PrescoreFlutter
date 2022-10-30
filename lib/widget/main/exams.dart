import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:prescore_flutter/main.dart';
import 'package:prescore_flutter/model/login_model.dart';
import 'package:provider/provider.dart';

import '../../util/struct.dart';
import 'exam_card.dart';

List<ExamCard> generateCardsFromExams(BuildContext context, List<Exam> exams) {
  List<ExamCard> cards = [];
  for (Exam exam in exams) {
    cards.add(ExamCard(
      user: Provider.of<LoginModel>(context, listen: false).user,
      uuid: exam.uuid,
      examName: exam.examName,
      examType: exam.examType,
      examTime: exam.examTime,
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

class ExamsState extends State<Exams> {
  int pageIndex = 1;
  bool lastFetched = false;
  bool isLoading = false;
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
    result = (await model.user.fetchExams(1)).result;
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
    List<Exam>? newResult = ((await model.user.fetchExams(pageIndex)).result);
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

    if (result != null) {
      return SliverList(
          delegate: SliverChildListDelegate(
              generateCardsFromExams(context, result!)));
    }

    LoginModel model = Provider.of<LoginModel>(context, listen: false);
    model.user.fetchExams(1).then((value) {
      result = value.result;
      setState(() {});
    });
    return const SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
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
                backgroundColor: Colors.grey.withOpacity(0.5),
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
                child: CircularProgressIndicator(),
              ),
            );
          }
        });
  }
}
