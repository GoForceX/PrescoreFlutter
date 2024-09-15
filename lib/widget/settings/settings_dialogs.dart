import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:prescore_flutter/constants.dart';
import 'package:prescore_flutter/main.dart';
import 'package:prescore_flutter/model/login_model.dart';
import 'package:prescore_flutter/util/user_util/user_util.dart';
import 'package:prescore_flutter/widget/component.dart';
import 'package:provider/provider.dart';

class SelectClassCountDialog extends StatefulWidget {
  const SelectClassCountDialog({super.key});

  @override
  SelectClassCountDialogState createState() => SelectClassCountDialogState();
}

class SelectClassCountDialogState extends State<SelectClassCountDialog> {
  final classCountController = TextEditingController();
  Map<String, TextEditingController> secondClassesCountCtr = {};
  @override
  void initState() {
    super.initState();
    classCountController.text =
        (BaseSingleton.singleton.sharedPreferences.getInt('classCount') ?? 45)
            .toString();
    jsonDecode(BaseSingleton.singleton.sharedPreferences
                .getString('secondClassesCount') ??
            "{}")
        .forEach((key, value) {
      secondClassesCountCtr[key] = TextEditingController();
      secondClassesCountCtr[key]?.text = value.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    LoginModel model = Provider.of<LoginModel>(context, listen: false);
    List<Widget> numberPickerList = [];
    secondClassesCountCtr.forEach((key, value) {
      numberPickerList.add(ClipRect(
        child: Dismissible(
          direction: DismissDirection.startToEnd,
          key: ValueKey(key),
          onDismissed: (direction) {
            setState(() {
              secondClassesCountCtr.remove(key);
            });
          },
          background: Container(
              margin: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.all(Radius.circular(6))),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 12),
              child: const Icon(Icons.delete)),
          child: NumberPicker(controller: value, labelText: "$key (滑动以删除)"),
        ),
      ));
    });
    return AlertDialog(
      title: const Text('你的班级有多少人？'),
      content: SingleChildScrollView(
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            NumberPicker(
                controller: classCountController, labelText: "行政(默认值)"),
            ...numberPickerList,
            const SizedBox(height: 8),
            FutureBuilder(
              future: model.user.fetchClassmate(),
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (snapshot.hasData) {
                  return Row(children: [
                    const Icon(Icons.people, size: 18),
                    Text(
                        " ${model.user.studentInfo?.gradeName}${model.user.studentInfo?.className}: ",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(" ${snapshot.data.length} 人")
                  ]);
                } else {
                  return const Text("");
                }
              },
            )
          ])),
      actions: <Widget>[
        PopupMenuButton(
          itemBuilder: (BuildContext context) {
            List<String> secondSubjects = ["物理", "化学", "生物", "历史", "地理", "政治"];
            secondClassesCountCtr
                .forEach((key, value) => secondSubjects.remove(key));
            return secondSubjects
                .map((subject) => PopupMenuItem(
                      value: subject,
                      child: Text(subject),
                    ))
                .toList();
          },
          onSelected: (String value) {
            setState(() {
              secondClassesCountCtr[value] = TextEditingController();
              secondClassesCountCtr[value]?.text = "45";
            });
          },
          child: Text("添加选科班",
              style: TextStyle(color: Theme.of(context).colorScheme.primary)),
        ),
        TextButton(
          onPressed: () async {
            BaseSingleton.singleton.sharedPreferences.setInt(
                'classCount', int.tryParse(classCountController.text) ?? 45);
            BaseSingleton.singleton.sharedPreferences.setString(
                'secondClassesCount',
                jsonEncode(secondClassesCountCtr.map(
                    (key, value) => MapEntry(key, int.parse(value.text)))));
            setState(() {});
            Navigator.pop(context, '确定');
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}

class SelectColorDialog extends StatefulWidget {
  const SelectColorDialog({super.key});

  @override
  SelectColorDialogState createState() => SelectColorDialogState();
}

class SelectColorDialogState extends State<SelectColorDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择应用主题色'),
      content: Wrap(
          alignment: WrapAlignment.center,
          children: brandColorMap.entries.map((entry) {
            return Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: entry.value.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  width: 2,
                  color: BaseSingleton.singleton.sharedPreferences
                              .getString("brandColor") ==
                          entry.key
                      ? Colors.black
                      : entry.value.withOpacity(0.8),
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                child: AnimatedOpacity(
                  opacity: BaseSingleton.singleton.sharedPreferences
                              .getString("brandColor") ==
                          entry.key
                      ? 1
                      : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.done,
                    color: Colors.black,
                    size: 20,
                  ),
                ),
                onTap: () {
                  setState(() {
                    BaseSingleton.singleton.sharedPreferences
                        .setString("brandColor", entry.key);
                    WidgetsFlutterBinding.ensureInitialized()
                        .performReassemble();
                  });
                },
              ),
            );
          }).toList()),
      actions: <Widget>[
        TextButton(
          onPressed: () async {
            Navigator.pop(context, '确定');
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}
