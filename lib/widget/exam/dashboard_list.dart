import 'package:flutter/material.dart';

import 'package:prescore_flutter/util/struct.dart';

class DashboardList extends StatefulWidget {
  final List<Paper> papers;

  const DashboardList({super.key, required this.papers});

  @override
  State<DashboardList> createState() => _DashboardListState();
}

class _DashboardListState extends State<DashboardList> {
  @override
  Widget build(BuildContext context) {
    List<Paper> papers = List<Paper>.from(widget.papers);
    papers.removeWhere((paper) => paper.source != Source.common);

    Widget listCard = DataTable(
      columns: const [
        DataColumn(
          label: Text(
            "科目",
            style: TextStyle(fontSize: 16),
          ),
        ),
        DataColumn(
            label: Text(
          "满分",
          style: TextStyle(fontSize: 16),
        )),
        DataColumn(
            label: Text(
          "得分",
          style: TextStyle(fontSize: 16),
        )),
      ],
      rows: papers
          .map((e) => DataRow(cells: [
                /*DataCell(Text(
                  (++count).toString(),
                  style: const TextStyle(fontSize: 16),
                )),*/
                DataCell(Text(
                  e.name,
                  style: const TextStyle(fontSize: 16),
                )),
                DataCell(Text(
                  e.fullScore.toString(),
                  style: const TextStyle(fontSize: 16),
                )),
                DataCell(Text(
                  e.userScore.toString(),
                  style: const TextStyle(fontSize: 16),
                ))
              ]))
          .toList(),
    );

    return Card.filled(
      margin: const EdgeInsets.all(8.0),
      child: listCard,
    );
  }
}
