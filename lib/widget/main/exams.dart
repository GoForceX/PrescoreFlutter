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
  const Exams({Key? key}) : super(key: key);

  @override
  State<Exams> createState() => _ExamsState();
}

class _ExamsState extends State<Exams> {
  @override
  Widget build(BuildContext context) {
    LoginModel model = Provider.of<LoginModel>(context, listen: false);
    return FutureBuilder(
        future: model.user.fetchExams(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          logger.d("snapshot.data: ${snapshot.data}");
          if (snapshot.hasData) {
            if (!snapshot.data.state) {
              SnackBar snackBar = SnackBar(
                content:
                    Text('呜呜呜，考试数据获取失败了……\n失败原因：${snapshot.data.message}'),
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
