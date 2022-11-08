import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:prescore_flutter/assets/draw_icons.dart';
import 'package:prescore_flutter/main.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';

import '../../model/paper_model.dart';
import '../../util/struct.dart';

class PaperPhoto extends StatefulWidget {
  final String examId;
  final String paperId;
  const PaperPhoto({Key? key, required this.paperId, required this.examId})
      : super(key: key);

  @override
  State<PaperPhoto> createState() => _PaperPhotoState();
}

class _PaperPhotoState extends State<PaperPhoto> {
  @override
  Widget build(BuildContext context) {
    Widget main = Container();

    logger.d("exam id: ${widget.examId}");

    if (Provider.of<PaperModel>(context, listen: false).isDataLoaded) {
      List<Widget> photos = [];

      photos.add(const ExperimentalDrawTips());
      photos.add(const SizedBox(
        height: 16,
      ));

      List<Marker>? markers =
          Provider.of<PaperModel>(context, listen: false).paperData?.markers;
      markers ??= [];
      for (var i = 0;
          i <
              Provider.of<PaperModel>(context, listen: false)
                  .paperData!
                  .sheetImages
                  .length;
          i++) {
        photos.add(PaperPhotoWidget(
          sheetId: i,
          url: Provider.of<PaperModel>(context, listen: false)
              .paperData!
              .sheetImages[i],
          tag: const Uuid().v4(),
          markers: markers,
        ));
      }

      return ListView(
        children: photos,
      );
    } else {
      main = FutureBuilder(
        future: Provider.of<PaperModel>(context, listen: false)
            .user
            .fetchPaperData(widget.examId, widget.paperId),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data.state) {
              List<Widget> photos = [];

              photos.add(const ExperimentalDrawTips());
              photos.add(const SizedBox(
                height: 16,
              ));

              for (var i = 0;
                  i < snapshot.data.result.sheetImages.length;
                  i++) {
                photos.add(PaperPhotoWidget(
                  sheetId: i,
                  url: snapshot.data.result.sheetImages[i],
                  tag: const Uuid().v4(),
                  markers: snapshot.data.result.markers,
                ));
              }

              return ListView(
                children: photos,
              );
            } else {
              return Container();
            }
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      );
    }

    return Center(child: Column(children: [Expanded(child: main)]));
  }
}

class PaperPhotoWidget extends StatefulWidget {
  final int sheetId;
  final String url;
  final String tag;
  final List<Marker> markers;
  const PaperPhotoWidget(
      {Key? key,
      required this.sheetId,
      required this.url,
      required this.tag,
      required this.markers})
      : super(key: key);

  @override
  State<PaperPhotoWidget> createState() => _PaperPhotoWidgetState();
}

class _PaperPhotoWidgetState extends State<PaperPhotoWidget> {
  Future<Uint8List?> markerPainter(
      List<Marker> markers, Uint8List originalImage) async {
    if (BaseSingleton.singleton.sharedPreferences
            .getBool("useExperimentalDraw") !=
        null) {
      if (!BaseSingleton.singleton.sharedPreferences
          .getBool("useExperimentalDraw")!) {
        return originalImage;
      }
    }

    /*
    img.Image? originalImg = img.decodeImage(originalImage);
    if (originalImg == null) {
      return originalImage;
    }
     */

    var pictureRecorder = ui.PictureRecorder();
    var canvas = Canvas(pictureRecorder);

    Paint linePaint = Paint();

    ui.Codec codec = await ui.instantiateImageCodec(originalImage);
    ui.FrameInfo frameInfo = await codec.getNextFrame();

    canvas.drawImage(frameInfo.image, const Offset(0, 0), linePaint);

    double widthRate = 420 / frameInfo.image.width;
    double heightRate = 297 / frameInfo.image.height;

    for (var marker in markers) {
      if (marker.sheetId == widget.sheetId) {
        switch (marker.type) {
          case MarkerType.singleChoice:
          case MarkerType.multipleChoice:
            linePaint.color = marker.color;
            linePaint.strokeWidth = 5;
            linePaint.style = PaintingStyle.fill;

            canvas.drawRect(
                Rect.fromLTWH(
                    marker.left / widthRate + marker.leftOffset,
                    marker.top / heightRate + marker.topOffset,
                    marker.width,
                    marker.height),
                linePaint);
            break;
          case MarkerType.shortAnswer:
            break;
          case MarkerType.sectionEnd:
            ui.ParagraphBuilder pb = ui.ParagraphBuilder(ui.ParagraphStyle(
                textAlign: TextAlign.left,
                fontWeight: FontWeight.w800,
                fontStyle: FontStyle.normal,
                fontSize: 64.0));
            pb.pushStyle(ui.TextStyle(color: marker.color));
            pb.addText(marker.message);
            ui.ParagraphConstraints pc =
                const ui.ParagraphConstraints(width: 200);
            ui.Paragraph paragraph = pb.build()..layout(pc);
            canvas.drawParagraph(
                paragraph,
                Offset(marker.left / widthRate + marker.leftOffset,
                    marker.top / heightRate + marker.topOffset));
            break;
          case MarkerType.svgPicture:
            logger.d("svg: ${marker.type}, ${marker.message}");
            switch (marker.message) {
              case "wrong":
                drawWrong(
                    canvas,
                    100,
                    100,
                    marker.top / heightRate + marker.topOffset,
                    marker.left / widthRate + marker.leftOffset,
                    marker.color);
                break;
              case "half":
                drawHalfCorrect(
                    canvas,
                    100,
                    100,
                    marker.top / heightRate + marker.topOffset,
                    marker.left / widthRate + marker.leftOffset,
                    marker.color);
                break;
              case "correct":
                drawCorrect(
                    canvas,
                    100,
                    100,
                    marker.top / heightRate + marker.topOffset,
                    marker.left / widthRate + marker.leftOffset,
                    marker.color);
                break;
            }
            break;
        }
      }
    }

    var picture = await pictureRecorder
        .endRecording()
        .toImage(frameInfo.image.width, frameInfo.image.height);

    var pngImageBytes =
        await picture.toByteData(format: ui.ImageByteFormat.png);

    if (pngImageBytes == null) {
      return originalImage;
    }
    Uint8List pngBytes = Uint8List.view(pngImageBytes.buffer);

    try {
      const platform = MethodChannel('com.bjbybbs.prescore_flutter/opencv');
      pngBytes = await platform.invokeMethod('edgeDetect', {
        "src": pngBytes,
        "code": 7,
        "t1": 30.0,
        "t2": 120.0,
        "blurSize": 5.0,
        "dilateSize": 3.0,
      });
    } catch (e) {
      logger.e("e");
    }

    return pngBytes;
  }

  @override
  Widget build(BuildContext context) {
    Uint8List? memoryImage;
    Dio dio = BaseSingleton.singleton.dio;
    logger.d(widget.url);
    return FutureBuilder(
        future: dio.get(widget.url,
            options: Options(responseType: ResponseType.bytes)),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            memoryImage = Uint8List.fromList(snapshot.data.data);

            return FutureBuilder(
                future: markerPainter(widget.markers, memoryImage!),
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  if (snapshot.hasData) {
                    memoryImage = snapshot.data;

                    return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (subContext) => GestureDetector(
                                    onTap: () {
                                      Navigator.pop(subContext);
                                    },
                                    child: PaperPhotoEnlarged(
                                      memoryImage: memoryImage!,
                                      tag: widget.tag,
                                    ))),
                          );
                        },
                        child: Hero(
                          tag: widget.tag,
                          child: RepaintBoundary(
                            child: Image.memory(
                              memoryImage!,
                              width: 350.0,
                            ),
                          ),
                        ));
                  } else {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                });
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        });
  }
}

class PaperPhotoEnlarged extends StatefulWidget {
  final Uint8List? memoryImage;
  final String tag;
  const PaperPhotoEnlarged(
      {Key? key, required this.memoryImage, required this.tag})
      : super(key: key);

  @override
  State<PaperPhotoEnlarged> createState() => _PaperPhotoEnlargedState();
}

class _PaperPhotoEnlargedState extends State<PaperPhotoEnlarged> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (Platform.isAndroid) {
            PermissionStatus storageStatus = await Permission.storage.status;
            if (!storageStatus.isGranted) {
              await Permission.storage.request();
            }

            storageStatus = await Permission.storage.status;
            if (storageStatus.isGranted) {
              final result = await ImageGallerySaver.saveImage(
                  widget.memoryImage!,
                  name:
                      "prescore_${(DateTime.now().millisecondsSinceEpoch / 100).round()}");
              if (mounted) {
                if (result["isSuccess"]) {
                  SnackBar snackBar = SnackBar(
                    content: const Text('保存大成功！'),
                    backgroundColor: Colors.grey.withOpacity(0.5),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                } else {
                  SnackBar snackBar = SnackBar(
                    content: Text('呜呜呜，失败了……\n失败原因：${result["errorMessage"]}'),
                    backgroundColor: Colors.grey.withOpacity(0.5),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                }
              }
            } else {
              if (mounted) {
                SnackBar snackBar = SnackBar(
                  content: const Text('呜呜呜，失败了……\n失败原因：无保存权限……'),
                  backgroundColor: Colors.grey.withOpacity(0.5),
                );
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
              }
            }
          } else {
            SnackBar snackBar = SnackBar(
              content: const Text('呜呜呜，失败了……\n还不支持其他系统保存图片哦……'),
              backgroundColor: Colors.grey.withOpacity(0.5),
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          }
        },
        child: const Icon(Icons.save_alt_rounded),
      ),
      body: PhotoView(
        imageProvider: MemoryImage(
          widget.memoryImage!,
        ),
        heroAttributes: PhotoViewHeroAttributes(tag: widget.tag),
      ),
    );
  }
}

class ExperimentalDrawTips extends StatelessWidget {
  const ExperimentalDrawTips({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (BaseSingleton.singleton.sharedPreferences
            .getBool("useExperimentalDraw") !=
        null) {
      if (!BaseSingleton.singleton.sharedPreferences
          .getBool("useExperimentalDraw")!) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Card(
              elevation: 4,
              child: Container(
                  padding: const EdgeInsets.all(16),
                  child: const Text(
                      "现在可以像智学网原版一样在原卷上绘制扣分信息啦（虽然可能有bug），为什么不去试试呢？就在主页侧边栏设置里啦！",
                      style: TextStyle(fontSize: 16)))),
        );
      } else {
        return Container();
      }
    } else {
      return Container();
    }
  }
}
