import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../model/exam_model.dart';
import '../../util/login.dart';
import 'exam_dashboard.dart';

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

  @override
  Widget build(BuildContext context) {
    logger.d(
        "exam session: ${widget.user.session}");

    return Scaffold(
      appBar: AppBar(
        title: const Text('出分啦'),
      ),
      body: ChangeNotifierProvider(
        create: (_) => ExamModel(),
        builder: (BuildContext context, Widget? child) {
          ExamModel model = Provider.of<ExamModel>(context, listen: false);
          model.user = widget.user;
          return Center(
            child: FutureBuilder(
                future: Provider.of<ExamModel>(context, listen: false)
                    .user
                    .fetchPaper(widget.uuid),
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  if (snapshot.hasData) {
                    switch (_selectedIndex) {
                      case 0:
                        if (!snapshot.data["state"]) {
                          Future.delayed(Duration.zero, () {
                            SnackBar snackBar = SnackBar(
                              content: Text(
                                  '呜呜呜，数据获取失败了……\n失败原因：${snapshot.data["message"]}'),
                              backgroundColor:
                                  ThemeMode.system == ThemeMode.dark
                                      ? Colors.grey[900]
                                      : Colors.grey[200],
                            );
                            ScaffoldMessenger.of(context)
                                .showSnackBar(snackBar);
                          });
                          return const Center(
                            child: Icon(Icons.error),
                          );
                        } else {
                          return ExamDashboard(
                            examId: widget.uuid,
                            papers: snapshot.data["result"],
                          );
                        }
                      case 1:
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      default:
                        return Center(
                          child: Container(),
                        );
                    }
                  } else {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                }), //New
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: '全科预览',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books_rounded),
            label: '单科查看',
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
