import 'package:flutter/material.dart';

class FancyButton extends StatelessWidget {
  final List<Color> gradients;
  final Function() callback;
  final String text;
  const FancyButton(
      {Key? key,
        required this.gradients,
        required this.callback,
        required this.text})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradients,
                ),
              ),
            ),
          ),
          FittedBox(
            child: TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    vertical: 20.0, horizontal: 32.0),
                primary: Colors.white,
                textStyle: const TextStyle(fontSize: 20),
              ),
              onPressed: callback,
              child: const Text('登录'),
            ),
          ),
        ],
      ),
    );
  }
}
