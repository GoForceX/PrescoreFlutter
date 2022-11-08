import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../main.dart';

class ScanProcessPage extends StatefulWidget {
  final XFile image;
  const ScanProcessPage({Key? key, required this.image}) : super(key: key);

  @override
  State<ScanProcessPage> createState() => _ScanProcessPageState();
}

class _ScanProcessPageState extends State<ScanProcessPage> {
  static const platform = MethodChannel('com.bjbybbs.prescore_flutter/opencv');

  @override
  Widget build(BuildContext context) {
    logger.d("Building ScanProcessPage");

    return Scaffold(
      appBar: AppBar(
        title: const Text('图片处理'),
      ),
      body: FutureBuilder(
        future: widget.image.readAsBytes(),
        builder: (BuildContext ct, AsyncSnapshot snapshot) {
          logger.d("img proc, future1");
          if (snapshot.hasData) {
            logger.d("img proc, future1, fin");
            return FutureBuilder(
              future: platform.invokeMethod('edgeDetect', {
                "src": snapshot.data,
                "code": 7,
                "t1": 50.0,
                "t2": 150.0,
                "blurSize": 5.0,
                "dilateSize": 5.0,
              }),
              builder: (BuildContext ct, AsyncSnapshot snapshot) {
                logger.d("img proc, future2");
                if (snapshot.hasData) {
                  logger.d("img proc, future2, fin");
                  return Image.memory(snapshot.data);
                } else {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
              },
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}
