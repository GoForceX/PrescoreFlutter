import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../model/exam_model.dart';
import '../../util/user_util.dart';
import 'exam_dashboard.dart';
import 'exam_detail.dart';

@RoutePage()
class ExamPage extends StatefulWidget {
  const ExamPage({Key? key, required this.uuid, required this.user})
      : super(key: key);
  final String uuid;
  final User user;

  @override
  State<ExamPage> createState() => _ExamPageState();
}

class _ExamPageState extends State<ExamPage> {
  int _selectedIndex = 0;
  late PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  Widget build(BuildContext context) {
    logger.d("exam session: ${widget.user.session}");

    return Scaffold(
      appBar: AppBar(
        title: const Text('考试细则'),
        titleSpacing: 0,
      ),
      body: ChangeNotifierProvider(
        create: (_) => ExamModel(),
        builder: (BuildContext context, Widget? child) {
          ExamModel model = Provider.of<ExamModel>(context, listen: false);
          model.user = widget.user;
          Future.delayed(const Duration(milliseconds: 300), () async {
            try {
              model.setPageAnimationComplete();
            } catch (_) {}
          });
          return PageView(
            controller: _controller,
            children: [
              Center(
                child: ExamDetail(examId: widget.uuid),
              ),
              Center(
                child: ExamDashboard(
                  examId: widget.uuid,
                ),
              )
            ],
            onPageChanged: (value) {
              setState(() {
                _selectedIndex = value;
              });
            },
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.library_books_outlined),
            selectedIcon: Icon(Icons.library_books_rounded),
            label: '单科查看',
          ),
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: '全科预览',
          ),
        ],
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
            _controller.jumpToPage(_selectedIndex);
          });
        },
      ),
    );
  }
}
