import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:prescore_flutter/util/struct.dart';
import 'package:prescore_flutter/util/user_util/user_util.dart';
import 'package:provider/provider.dart';
import 'package:scrollview_observer/scrollview_observer.dart';

import '../../model/paper_model.dart';

class PaperMarking extends StatefulWidget {
  final String examId;
  final String paperId;
  const PaperMarking({Key? key, required this.examId, required this.paperId})
      : super(key: key);

  @override
  State<PaperMarking> createState() => _PaperMarkingState();
}

class _PaperMarkingState extends State<PaperMarking>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  late ScrollController scrollController;
  late AnimationController fabAnimationController;
  late ListObserverController observerController;
  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    scrollController = ScrollController();
    observerController = ListObserverController(controller: scrollController);
    fabAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    scrollController.addListener(() {
      if (scrollController.offset <= MediaQuery.of(context).size.height * 0.4 &&
          fabAnimationController.status == AnimationStatus.completed) {
        fabAnimationController.reverse();
      } else if (scrollController.offset >
              MediaQuery.of(context).size.height * 0.4 &&
          fabAnimationController.status == AnimationStatus.dismissed) {
        fabAnimationController.forward();
      }
    });
    future = Provider.of<PaperModel>(context, listen: false)
        .user
        .fetchMarkingProgress(widget.paperId);
    super.initState();
  }

  late Future future;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    Widget main = FutureBuilder(
        future: future,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data.state) {
              List<Widget> questionCards = [];
              List<Widget> questionIndicators = [];

              snapshot.data.result.forEach((element) {
                (element as QuestionProgress);
                questionCards.add(QuestionProgressCard(question: element));
                Color indicatorColor = Colors.grey;
                if ((element).realCompleteCount / (element).allCount == 1) {
                  indicatorColor = Colors.lightGreen;
                } else if ((element).realCompleteCount / (element).allCount >
                    0) {
                  indicatorColor = Colors.yellowAccent;
                } else {
                  indicatorColor = Colors.redAccent;
                }
                var currentIndex = questionIndicators.length;
                questionIndicators.add(
                  InkWell(
                    borderRadius: BorderRadius.circular(4.0),
                    onTap: () {
                      observerController.animateTo(
                        index: currentIndex,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.ease,
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: indicatorColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: FittedBox(
                          child: Text(
                            element.dispTitle,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              });
              return ListViewObserver(
                controller: observerController,
                child: CustomScrollView(
                  slivers: [
                    SliverGrid.extent(
                      maxCrossAxisExtent: 72,
                      children: questionIndicators,
                    ),
                    SliverList(
                      delegate: SliverChildListDelegate(questionCards),
                    ),
                  ],
                  controller: scrollController,
                ),
              );
            } else {
              return Container();
            }
          } else {
            return Center(
                child: Container(
                    margin: const EdgeInsets.all(10),
                    child: const CircularProgressIndicator()));
          }
        });
    return Stack(children: [
      RefreshIndicator(
          onRefresh: () {
            setState(() {
              future = Provider.of<PaperModel>(context, listen: false)
                  .user
                  .fetchMarkingProgress(widget.paperId);
            });
            return future;
          },
          child: main),
      Positioned(
        bottom: 20,
        right: 20,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 2),
            end: const Offset(0, 0),
          ).animate(CurvedAnimation(
            parent: fabAnimationController,
            curve: Curves.easeInOut,
          )),
          child: FloatingActionButton(
            onPressed: () {
              scrollController.animateTo(0.0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.ease);
            },
            child: const Icon(Icons.arrow_upward),
          ),
        ),
      )
    ]);
  }
}

class QuestionProgressCard extends StatefulWidget {
  final QuestionProgress question;
  const QuestionProgressCard({Key? key, required this.question})
      : super(key: key);
  @override
  QuestionProgressCardState createState() => QuestionProgressCardState();
}

class QuestionProgressCardState extends State<QuestionProgressCard>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    Widget body = Container(
        padding: const EdgeInsets.all(12.0),
        alignment: AlignmentDirectional.topStart,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: FittedBox(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            "${widget.question.dispTitle}：",
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(
                            height: 12,
                          )
                        ],
                      ),
                      Text(
                        "${widget.question.realCompleteCount}",
                        style: const TextStyle(fontSize: 48),
                      ),
                      const SizedBox(
                        width: 16,
                      ),
                      const Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            "/",
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(
                            height: 12,
                          )
                        ],
                      ),
                      const SizedBox(
                        width: 16,
                      ),
                      Text(
                        "${widget.question.allCount}",
                        style: const TextStyle(fontSize: 48),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 4),
            LinearPercentIndicator(
              lineHeight: 8.0,
              percent:
                  widget.question.realCompleteCount / widget.question.allCount,
              backgroundColor: Colors.grey,
              linearGradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.6)
                  ]),
              barRadius: const Radius.circular(4),
            ),
          ],
        ));
    return Card.filled(margin: const EdgeInsets.all(8.0), child: body);
  }
}
