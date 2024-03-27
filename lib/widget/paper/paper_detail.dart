import 'package:flutter/material.dart';
import 'package:prescore_flutter/widget/paper/question_card.dart';
import 'package:provider/provider.dart';
import 'package:scrollview_observer/scrollview_observer.dart';

import '../../model/paper_model.dart';

class PaperDetail extends StatefulWidget {
  final String examId;
  final String paperId;
  const PaperDetail({Key? key, required this.examId, required this.paperId})
      : super(key: key);

  @override
  State<PaperDetail> createState() => _PaperDetailState();
}

class _PaperDetailState extends State<PaperDetail>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  late ScrollController scrollController;
  late ListObserverController observerController;
  late AnimationController fabAnimationController;
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
    if (!Provider.of<PaperModel>(context, listen: false).isDataLoaded) {
      Provider.of<PaperModel>(context, listen: false)
          .user
          .fetchPaperData(widget.examId, widget.paperId)
          .then((value) {
        if (value.state) {
          Provider.of<PaperModel>(context, listen: false)
              .setPaperData(value.result);
          Provider.of<PaperModel>(context, listen: false).setDataLoaded(true);
        }
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<PaperModel>(
      builder:
          (BuildContext consumerContext, PaperModel examModel, Widget? child) {
        if (examModel.paperData == null) {
          return Center(
              child: Container(
                  margin: const EdgeInsets.all(10),
                  child: const CircularProgressIndicator()));
        }
        List<Widget> questionCards = [];
        List<Widget> questionIndicators = [];

        examModel.paperData?.questions.forEach((element) {
          if (element.isSelected) {
            questionCards.add(QuestionCard(question: element));

            Color indicatorColor = Colors.grey;
            if ((element).userScore / (element).fullScore == 1) {
              indicatorColor = Colors.lightGreen;
            } else if ((element).userScore / (element).fullScore > 0) {
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
                        element.questionId,
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
          }
        });
        Widget list = ListViewObserver(
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
        return Stack(children: [
          list,
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
                heroTag: null,
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
      },
    );
  }
}
