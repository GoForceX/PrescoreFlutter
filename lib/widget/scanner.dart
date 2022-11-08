import 'package:auto_route/auto_route.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:prescore_flutter/main.gr.dart';

import '../main.dart';
import 'drawer.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({Key? key}) : super(key: key);

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  late CameraController controller;

  @override
  void initState() {
    super.initState();
    controller = CameraController(
        BaseSingleton.singleton.cameras[0], ResolutionPreset.max);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            print('User denied camera access.');
            break;
          default:
            print('Handle other errors.');
            break;
        }
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('扫描'),
      ),
      floatingActionButton: FloatingActionButton(onPressed: () {
        controller.takePicture().then((picFile) {
          logger.d("Picture taken: ${picFile.path}");
          context.router.navigate(ScanProcessRoute(image: picFile));
          // picFile.readAsBytes().then((value) {
          //     logger.d("Picture taken, navigating");
          //     if (mounted) {
          //       context.router.navigate(ScanProcessRoute(image: value));
          //     }
          // });
        });
      }),
      body: Builder(
        builder: (BuildContext ct) {
          if (!controller.value.isInitialized) {
            return Container();
          }
          return ValueListenableBuilder<CameraValue>(
            valueListenable: controller,
            builder: (BuildContext context, Object? value, Widget? child) {
              return Stack(
                fit: StackFit.expand,
                children: <Widget>[controller.buildPreview()],
              );
            },
          );
        },
      ),
      drawer: const MainDrawer(),
    );
  }
}
