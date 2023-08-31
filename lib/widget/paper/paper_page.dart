import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:prescore_flutter/widget/paper/paper_detail.dart';
import 'package:prescore_flutter/widget/paper/paper_distrib.dart';
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
  const PaperPage(
      {Key? key,
      required this.user,
      required this.examId,
      required this.paperId})
      : super(key: key);

  @override
  State<PaperPage> createState() => _PaperPageState();
}

class _PaperPageState extends State<PaperPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    logger.d("exam session: ${widget.user.session}");

    return Scaffold(
      appBar: AppBar(
        title: const Text('出分啦'),
      ),
      body: ChangeNotifierProvider(
        create: (_) => PaperModel(),
        builder: (BuildContext context, Widget? child) {
          PaperModel model = Provider.of<PaperModel>(context, listen: false);
          model.user = widget.user;
          Widget chosenWidget = Container();
          switch (_selectedIndex) {
            case 0:
              chosenWidget = PaperPhoto(
                examId: widget.examId,
                paperId: widget.paperId,
              );
              break;
            case 1:
              chosenWidget =
                  PaperDetail(examId: widget.examId, paperId: widget.paperId);
              break;
            case 2:
              chosenWidget =
                  PaperDistributionPhoto(examId: widget.examId, paperId: widget.paperId);
              break;
            default:
              chosenWidget = Container();
          }
          return Center(
            child: chosenWidget,
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_album),
            label: '原卷',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_rounded),
            label: '小分',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.line_axis),
            label: '分布',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
