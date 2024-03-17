import 'package:flutter/material.dart';

class TagCard extends StatelessWidget {
  final String text;
  const TagCard({Key? key, required this.text}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.start, children: [
      Container(
        height: 20,
        width: null,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outlineVariant,
          borderRadius: const BorderRadius.all(
            Radius.circular(4),
          ),
        ),
        child: Center(
          child: Text(
            ("  $text  "),
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
      )
    ]);
  }
}
