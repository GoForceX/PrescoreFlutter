import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:prescore_flutter/widget/paper/paper_detail.dart';
import 'package:prescore_flutter/widget/paper/paper_marking.dart';
import 'package:prescore_flutter/widget/paper/paper_photo.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../model/paper_model.dart';
import '../../util/user_util.dart';

@RoutePage()
class PaperPage extends StatefulWidget {
  final String examId;
  final String paperId;
  final User user;
  final bool preview;
  const PaperPage(
      {Key? key,
      required this.user,
      required this.examId,
      required this.paperId,
      required this.preview})
      : super(key: key);

  @override
  State<PaperPage> createState() => _PaperPageState();
}

class _PaperPageState extends State<PaperPage> {
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
        title: const Text('分数细则'),
        titleSpacing: 0,
      ),
      body: ChangeNotifierProvider(
        create: (_) => PaperModel(),
        builder: (BuildContext context, Widget? child) {
          PaperModel model = Provider.of<PaperModel>(context, listen: false);
          model.user = widget.user;
          if (!widget.preview) {
            return PageView(
              controller: _controller,
              children: [
                Center(
                  child: PaperPhoto(
                      examId: widget.examId, paperId: widget.paperId),
                ),
                Center(
                  child: PaperDetail(
                      examId: widget.examId, paperId: widget.paperId),
                ),
                // Center(
                //   child: PaperDistributionPhoto(
                //       examId: widget.examId, paperId: widget.paperId),
                // ),
              ],
              onPageChanged: (value) {
                setState(() {
                  _selectedIndex = value;
                });
              },
            );
          } else {
            return PageView(
              controller: _controller,
              children: [
                Center(
                  child: PaperMarking(
                      examId: widget.examId, paperId: widget.paperId),
                ),
                Center(
                  child: PaperPhoto(
                      examId: widget.examId, paperId: widget.paperId, showNonFinalAlert: true),
                ),
                Center(
                  child: PaperDetail(
                      examId: widget.examId, paperId: widget.paperId, nonFinalAlert: true),
                )
              ],
              onPageChanged: (value) {
                setState(() {
                  _selectedIndex = value;
                });
              },
            );
          }
        },
      ),
      bottomNavigationBar: widget.preview
          ? NavigationBar(
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.list_alt_rounded),
                  label: '判卷进度',
                ),
                NavigationDestination(
                  icon: Icon(Icons.photo_album_outlined),
                  selectedIcon: Icon(Icons.photo_album),
                  label: '原卷',
                ),
                NavigationDestination(
                  icon: Icon(Icons.list_alt_rounded),
                  label: '小分',
                ),
              ],
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedIndex = index;
                  _controller.jumpToPage(_selectedIndex);
                });
              },
            )
          : NavigationBar(
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.photo_album_outlined),
                  selectedIcon: Icon(Icons.photo_album),
                  label: '原卷',
                ),
                NavigationDestination(
                  icon: Icon(Icons.list_alt_rounded),
                  label: '小分',
                ),
                // NavigationDestination(
                //   icon: Icon(Icons.line_axis),
                //   label: '分布',
                // ),
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
