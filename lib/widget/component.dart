import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

class NumberPicker extends StatefulWidget {
  final TextEditingController controller;
  final int step;
  final String labelText;
  final bool intrinsic;
  final int? min;
  final int? max;
  const NumberPicker(
      {Key? key,
      required this.controller,
      this.step = 1,
      this.labelText = "",
      this.intrinsic = false,
      this.min = 0,
      this.max})
      : super(key: key);

  @override
  State<NumberPicker> createState() => _NumberPickerState();
}

class _NumberPickerState extends State<NumberPicker> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    TextField textField = TextField(
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'\d')),
        ],
        obscureText: false,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          prefixIcon: InkWell(
              borderRadius: const BorderRadius.all(Radius.circular(36)),
              child: const Icon(Icons.arrow_left),
              onTap: () {
                setState(() {
                  if (int.parse(widget.controller.text) - widget.step < (widget.min ?? double.negativeInfinity)) {
                    return;
                  }
                  String newNum =
                      (int.parse(widget.controller.text) - widget.step)
                          .toString();
                  widget.controller.text = newNum;
                });
              }),
          suffixIcon: InkWell(
              borderRadius: const BorderRadius.all(Radius.circular(36)),
              child: const Icon(Icons.arrow_right),
              onTap: () {
                setState(() {
                  if (int.parse(widget.controller.text) + widget.step > (widget.max ?? double.infinity)) {
                    return;
                  }
                  String newNum =
                      (int.parse(widget.controller.text) + widget.step)
                          .toString();
                  
                  widget.controller.text = newNum;
                });
              }),
          labelText: widget.labelText,
        ),
        controller: widget.controller);
    if (widget.intrinsic) {
      return Container(
        margin: const EdgeInsets.all(5),
        child: IntrinsicWidth(
          stepWidth: 8,
          child: textField,
        ),
      );
    } else {
      return Container(margin: const EdgeInsets.all(5), child: textField);
    }
  }
}
