import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:prescore_flutter/util/flutter_log_local/flutter_log_local.dart';
import 'package:prescore_flutter/util/struct.dart';
import 'package:flutter_html_table/flutter_html_table.dart';

class ErrorQuestionCard extends StatefulWidget {
  final ErrorQuestion errorQuestion;
  const ErrorQuestionCard({required this.errorQuestion, Key? key})
      : super(key: key);

  @override
  State<ErrorQuestionCard> createState() => _ErrorQuestionCardState();
}

class _ErrorQuestionCardState extends State<ErrorQuestionCard>
    with TickerProviderStateMixin {
  bool detailExpanded = false;
  late AnimationController _animationController;
  late CurvedAnimation animationCurve;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    animationCurve =
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        margin: const EdgeInsets.all(8),
        child: InkWell(
            borderRadius: BorderRadius.circular(12.0),
            onTap: () {
              setState(() {
                detailExpanded = !detailExpanded;
                if (detailExpanded) {
                  _animationController.forward(from: 0);
                } else {
                  _animationController.reverse(from: 1);
                }
              });
            },
            child: Column(
                //crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(widget.errorQuestion.topicSourcePaperName ?? "",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                  Text(
                      "分数: ${widget.errorQuestion.userScore} / ${widget.errorQuestion.standardScore}  |  第 ${widget.errorQuestion.topicNumber} 题  |  难度: ${widget.errorQuestion.difficultyName}"),
                  const Divider(),
                  const Text("原始题目",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  HtmlWithExtension(data: widget.errorQuestion.contentHtml),
                  const Divider(),
                  if (widget.errorQuestion.userAnswer.runtimeType == String)
                    Text("你的答案: ${widget.errorQuestion.userAnswer}",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (widget.errorQuestion.userAnswer.runtimeType ==
                      List<dynamic>)
                    const Text("你的答案",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  if (widget.errorQuestion.userAnswer.runtimeType ==
                      List<dynamic>)
                    ...widget.errorQuestion.userAnswer.map((item) {
                      return Image.network(item);
                    }),
                  const SizedBox(height: 10),
                  SizeTransition(
                    axisAlignment: 0.0,
                    sizeFactor: animationCurve,
                    axis: Axis.vertical,
                    child: Column(
                      children: [
                        const Divider(),
                        const Text("参考答案",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        HtmlWithExtension(
                            data: widget.errorQuestion.analysisHtml),
                        const Text("考察知识点",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        ...(widget.errorQuestion.knowledgeNames ?? [])
                            .map((item) {
                          return Text(item, textAlign: TextAlign.center);
                        }),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ])));
  }
}

class HtmlWithExtension extends StatelessWidget {
  final String? data;
  const HtmlWithExtension({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String? htmlContext = data;
    htmlContext = htmlContext
        ?.replaceAll(RegExp(r"<p[^>]*>"), "")
        .replaceAll("</p>", "<br>");
    htmlContext = htmlContext?.replaceAllMapped(RegExp(r"<img[^>]*>\s*<br\s*/?>"), (match) {
      return match.group(0)?.replaceAll(RegExp(r"\s*<br\s*/?>"), "") ?? "";
    });
    htmlContext = htmlContext?.replaceAll(RegExp(r'style="[^>]*"'), "");
    htmlContext = htmlContext?.replaceAll("<td", "<td style='border: 0.5px solid grey;'");
    LocalLogger.write(htmlContext ?? "");
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      return Html(
        data: htmlContext,
        /*style: {
          "table": Style(
            fontWeight: FontWeight.bold,
          ),
        },*/
        extensions: [
          const TableHtmlExtension(),
          TagExtension(
            tagsToExtend: {"bdo"},
            builder: (ExtensionContext extensionContext) {
              return Text(extensionContext.element!.text,
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    decorationStyle: TextDecorationStyle.dotted,
                    fontWeight: extensionContext.style?.fontWeight,
                  ));
            },
          ),
          TagExtension(
            tagsToExtend: {"img"},
            builder: (ExtensionContext extensionContext) {
              Widget child = Container();
              if(extensionContext.attributes["data-latex"] != null) {
                //child = LaTexT(laTeXCode: Text(Uri.decodeFull(extensionContext.attributes["data-latex"] ?? "")));
                child = ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      MediaQuery.of(context).platformBrightness == Brightness.dark ? Colors.white : Colors.black,
                      BlendMode.srcIn,
                    ),
                    child: Image.network(extensionContext.attributes["src"] ?? ""));
              } else {
                child = Image.network(extensionContext.attributes["src"] ?? "");
              }
              return SizedBox(
                  height: extensionContext.attributes["height"] != null
                      ? double.parse(extensionContext.attributes["height"]!)
                      : null,
                  width: extensionContext.attributes["width"] != null
                      ? min(double.parse(extensionContext.attributes["width"]!),
                          constraints.maxWidth)
                      : null,
                  child:
                  child);
            },
          ),
        ],
      );
    });
  }
}
