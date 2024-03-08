import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:prescore_flutter/model/login_model.dart';
import 'package:prescore_flutter/widget/drawer.dart';
import 'package:provider/provider.dart';

import '../../model/errorbook_model.dart';
import '../../util/struct.dart';

@RoutePage()
class ErrorBookPage extends StatefulWidget {
  const ErrorBookPage(
      {Key? key})
      : super(key: key);

  @override
  State<ErrorBookPage> createState() => _ErrorBookPageState();
}

class _ErrorBookPageState extends State<ErrorBookPage> {

  @override
  void initState() {
    super.initState();
  }

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
          ErrorBookModel model = Provider.of<ErrorBookModel>(context, listen: false);
          model.user = Provider.of<LoginModel>(context, listen: false).user;
          model.user.fetchErrorbookSubjectList().then((value) {
            if(value.state) {
              Provider.of<ErrorBookModel>(context, listen: false).setSubjectCodeList(value.result!);
            }
          });
          return Consumer<ErrorBookModel>(
            builder: (context, model, widget) {
              if(model.selectedSubjectCode != null) {
                FutureBuilder futureBuilder = FutureBuilder(
                  future: model.user.fetchErrorbookList(
                    subjectCode: model.selectedSubjectCode!,
                    pageIndex: model.selectedPageIndex!),
                  builder: (BuildContext context, AsyncSnapshot snapshot) {
                    if (snapshot.hasData) {
                      if(snapshot.connectionState == ConnectionState.waiting) {
                        if(snapshot.data.result.subjectCode != model.selectedSubjectCode) {
                          return Center(child: Container(margin: const EdgeInsets.all(10) ,child: const CircularProgressIndicator()));
                        }
                      }
                      if (snapshot.data.state) {
                        List<Widget> questions = [];
                        questions.add(Row(children: [const SizedBox(width: 8), const Icon(Icons.format_list_numbered_rounded, size: 18), Text(" 共 ${snapshot.data.result.totalQuestion} 道, ${snapshot.data.result.totalPage} 页", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))]));
                        if(snapshot.connectionState != ConnectionState.waiting) {
                          for(int i = 0; i < snapshot.data.result.errorQuestion.length; i++) {
                            questions.add(ErrorQuestionCard(errorQuestion: snapshot.data.result.errorQuestion[i]));
                          }
                        } else {
                          questions.add(Container(margin: const EdgeInsets.all(10) ,child: const CircularProgressIndicator()));
                        }
                        questions.add(PageChooser(totalPage: snapshot.data.result.totalPage));
                        return Column(children: questions);
                      } else {
                        return Container();
                      }
                    } else {
                      return Center(child: Container(margin: const EdgeInsets.all(10) ,child: const CircularProgressIndicator()));
                    }
                });
                return ListView(children: [
                  SubjectFilter(subjectList: Provider.of<ErrorBookModel>(context, listen: false).subjectCodeList!),
                  futureBuilder,
                ]);
              } else {
                return Center(child: Container(margin: const EdgeInsets.all(10) ,child: const CircularProgressIndicator()));
              }
            },
          );
        }
      ),
      drawer: const MainDrawer(),
    );
  }
}

class SubjectFilter extends StatelessWidget {
  final List<Subject> subjectList;
  const SubjectFilter({
    required this.subjectList,
    Key? key
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> cards = [];
    cards.add(const Text(" 学科 ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)));
    for(int i = 0; i < subjectList.length; i++) {
      cards.add(
        Card(
          elevation: 0,
          color: Provider.of<ErrorBookModel>(context, listen: false).selectedSubjectCode == subjectList[i].code ? Theme.of(context).colorScheme.secondaryContainer : Theme.of(context).colorScheme.onPrimary,
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
              Provider.of<ErrorBookModel>(context, listen: false).setSubjectCode(subjectList[i].code);
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(" ${subjectList[i].name} "),
            ),
          ),
        )
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        margin: const EdgeInsets.all(7),
        child: Row(children: cards),
      )
    );
  }
}

class PageChooser extends StatelessWidget {
  final int totalPage;
  const PageChooser({
    required this.totalPage,
    Key? key
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> cards = [];
    for(int i = 1; i <= totalPage; i++) {
      cards.add(
        Card(
          elevation: 0,
          color: Provider.of<ErrorBookModel>(context, listen: false).selectedPageIndex == i ? Theme.of(context).colorScheme.secondaryContainer : Theme.of(context).colorScheme.onPrimary,
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
        )
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        margin: const EdgeInsets.all(7),
        child: Row(children: cards),
      )
    );
  }
}

class ErrorQuestionCard extends StatelessWidget {
  final ErrorQuestion errorQuestion;
  const ErrorQuestionCard({
    required this.errorQuestion,
    Key? key
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(8.0),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      //child: Text(errorQuestion.data.toString()),
      child: Html(
        data: errorQuestion.data["errorBookTopicDTO"]["contentHtml"].replaceAll("bdo","td"),
        extensions: [
          TagExtension(
            tagsToExtend: {"bdo"},
            builder: (extensionContext) {
              return const Text("bdo");
            },
          ),
        ],
      )
    );
  }
}