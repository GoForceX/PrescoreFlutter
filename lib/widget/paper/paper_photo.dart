import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
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
  final bool showNonFinalAlert;
  const PaperPhoto(
      {Key? key,
      required this.paperId,
      required this.examId,
      this.showNonFinalAlert = false})
      : super(key: key);

  @override
  State<PaperPhoto> createState() => _PaperPhotoState();
}

class _PaperPhotoState extends State<PaperPhoto>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  ListView? markedphotos;
  ListView? unMarkedphotos;

  @override
  void initState() {
    super.initState();
    if (!Provider.of<PaperModel>(context, listen: false).isDataLoaded) {
      Provider.of<PaperModel>(context, listen: false)
          .user
          .fetchPaperData(widget.examId, widget.paperId)
          .then((value) {
        if (value.state) {
          Provider.of<PaperModel>(context, listen: false)
              .setPaperData(value.result);
          Provider.of<PaperModel>(context, listen: false).setDataLoaded(true);
        } else {
          Provider.of<PaperModel>(context, listen: false)
              .setErrMsg(value.message);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    logger.d("exam id: ${widget.examId}");
    return Consumer<PaperModel>(builder:
        (BuildContext consumerContext, PaperModel examModel, Widget? child) {
      if (examModel.errMsg != null) {
        return Center(child: Text(examModel.errMsg ?? ""));
      }
      if (examModel.paperData == null) {
        return Center(
            child: Container(
                margin: const EdgeInsets.all(10),
                child: const CircularProgressIndicator()));
      }
      if (BaseSingleton.singleton.sharedPreferences
                  .getBool("useExperimentalDraw") ==
              true &&
          markedphotos == null) {
        List<Marker> markers = examModel.paperData?.markers ?? [];
        List<Widget> photos = [];
        for (var i = 0; i < examModel.paperData!.sheetImages.length; i++) {
          photos.add(PaperPhotoWidget(
              sheetId: i,
              url: examModel.paperData!.sheetImages[i],
              tag: const Uuid().v4(),
              markers: markers,
              mark: true));
        }
        markedphotos = ListView(
          children: photos,
        );
      }
      if (BaseSingleton.singleton.sharedPreferences
                  .getBool("useExperimentalDraw") ==
              false &&
          unMarkedphotos == null) {
        List<Marker> markers = examModel.paperData?.markers ?? [];
        List<Widget> photos = [];
        for (var i = 0; i < examModel.paperData!.sheetImages.length; i++) {
          photos.add(PaperPhotoWidget(
              sheetId: i,
              url: examModel.paperData!.sheetImages[i],
              tag: const Uuid().v4(),
              markers: markers,
              mark: false));
        }
        unMarkedphotos = ListView(
          children: photos,
        );
      }

      return Stack(children: [
        Center(
            child: Column(children: [
          if (widget.showNonFinalAlert)
            Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: const Row(children: [
                  SizedBox(width: 20),
                  Icon(Icons.warning_amber_rounded,
                      size: 16, color: Colors.red),
                  Text(" 判卷可能未完成，不代表最终成绩")
                ])),
          Expanded(
              child: Visibility(
            visible: BaseSingleton.singleton.sharedPreferences
                    .getBool("useExperimentalDraw") ==
                true,
            maintainState: true,
            child: markedphotos ?? Container(),
          )),
        ])),
        Center(
            child: Column(children: [
          Expanded(
              child: Visibility(
            visible: BaseSingleton.singleton.sharedPreferences
                    .getBool("useExperimentalDraw") ==
                false,
            maintainState: true,
            child: unMarkedphotos ?? Container(),
          ))
        ])),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton.extended(
            onPressed: () {
              bool useExperimentalDraw = BaseSingleton
                  .singleton.sharedPreferences
                  .getBool("useExperimentalDraw")!;
              setState(() {
                BaseSingleton.singleton.sharedPreferences
                    .setBool("useExperimentalDraw", !useExperimentalDraw);
              });
            },
            icon: BaseSingleton.singleton.sharedPreferences
                    .getBool("useExperimentalDraw")!
                ? const Icon(Icons.brush)
                : const Icon(Icons.brush_outlined),
            label: Text(BaseSingleton.singleton.sharedPreferences
                    .getBool("useExperimentalDraw")!
                ? "已启用"
                : "已禁用"),
          ),
        ),
      ]);
    });
  }
}

class PaperPhotoWidget extends StatelessWidget {
  final int sheetId;
  final String url;
  final String tag;
  final List<Marker> markers;
  final bool mark;
  const PaperPhotoWidget(
      {Key? key,
      required this.sheetId,
      required this.url,
      required this.tag,
      required this.markers,
      required this.mark})
      : super(key: key);

  Future<Uint8List?> markerPainter(
      List<Marker> markers, Uint8List originalImage) async {
    if (!mark) {
      return originalImage;
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
      if (marker.left > 420) {
        widthRate = 1;
        heightRate = 1;
      }
    }

    for (var marker in markers) {
      if (marker.sheetId == sheetId) {
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
          case MarkerType.detailScoreEnd:
            ui.ParagraphBuilder pb = ui.ParagraphBuilder(ui.ParagraphStyle(
                textAlign: TextAlign.right,
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.normal,
                fontSize: 40.0));
            pb.pushStyle(ui.TextStyle(color: marker.color));
            pb.addText(marker.message);
            ui.ParagraphConstraints pc =
                const ui.ParagraphConstraints(width: 300);
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
          case MarkerType.cutBlock:
            linePaint.color = marker.color.withOpacity(0.1);
            linePaint.style = PaintingStyle.fill;
            canvas.drawRRect(
                RRect.fromLTRBR(
                    marker.left / widthRate + marker.leftOffset,
                    marker.top / heightRate + marker.topOffset,
                    marker.left / widthRate + marker.leftOffset + marker.width,
                    marker.top / heightRate + marker.topOffset + marker.height,
                    const Radius.circular(16)),
                linePaint);
            linePaint.color = marker.color.withOpacity(0.8);
            linePaint.strokeWidth = 2;
            linePaint.style = PaintingStyle.stroke;
            canvas.drawRRect(
                RRect.fromLTRBR(
                    marker.left / widthRate + marker.leftOffset,
                    marker.top / heightRate + marker.topOffset,
                    marker.left / widthRate + marker.leftOffset + marker.width,
                    marker.top / heightRate + marker.topOffset + marker.height,
                    const Radius.circular(16)),
                linePaint);
            ui.ParagraphBuilder pb = ui.ParagraphBuilder(ui.ParagraphStyle(
                textAlign: TextAlign.left,
                fontWeight: FontWeight.w800,
                fontStyle: FontStyle.normal,
                fontSize: 32.0));
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

    return pngBytes;
  }

  @override
  Widget build(BuildContext context) {
    Uint8List? memoryImage;
    Dio dio = BaseSingleton.singleton.dio;
    logger.d(url);
    return FutureBuilder(
        future:
            dio.get(url, options: Options(responseType: ResponseType.bytes)),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            memoryImage = Uint8List.fromList(snapshot.data.data);

            return FutureBuilder(
                future: markerPainter(markers, memoryImage!),
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
                                      tag: tag,
                                    ))),
                          );
                        },
                        child: Hero(
                          tag: tag,
                          child: RepaintBoundary(
                            child: Image.memory(
                              memoryImage!,
                              width: 350.0,
                            ),
                          ),
                        ));
                  } else {
                    return Center(
                      child: Container(
                          margin: const EdgeInsets.all(10),
                          child: const CircularProgressIndicator()),
                    );
                  }
                });
          } else {
            return Center(
              child: Container(
                  margin: const EdgeInsets.all(10),
                  child: const CircularProgressIndicator()),
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
            PermissionStatus photoStatus = await Permission.photos.status;
            if (!storageStatus.isGranted | !photoStatus.isGranted) {
              logger.d('req');
              await Permission.storage.request();
              await Permission.photos.request();
            }

            storageStatus = await Permission.storage.status;
            photoStatus = await Permission.photos.status;
            logger.d([storageStatus, photoStatus]);

            if (storageStatus.isGranted | photoStatus.isGranted) {
              final result = await ImageGallerySaver.saveImage(
                  widget.memoryImage!,
                  name:
                      "prescore_${(DateTime.now().millisecondsSinceEpoch / 100).round()}");
              if (mounted) {
                if (result["isSuccess"]) {
                  SnackBar snackBar = const SnackBar(
                    content: Text('保存大成功！'),
                    //backgroundColor: Colors.grey.withOpacity(0.5),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                } else {
                  SnackBar snackBar = SnackBar(
                    content: Text('呜呜呜，失败了……\n失败原因：${result["errorMessage"]}'),
                    //backgroundColor: Colors.grey.withOpacity(0.5),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                }
              }
            } else {
              if (mounted) {
                SnackBar snackBar = const SnackBar(
                  content: Text('呜呜呜，失败了……\n失败原因：无保存权限……'),
                  //backgroundColor: Colors.grey.withOpacity(0.5),
                );
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
              }
            }
          } else {
            SnackBar snackBar = const SnackBar(
              content: Text('呜呜呜，失败了……\n还不支持其他系统保存图片哦……'),
              //backgroundColor: Colors.grey.withOpacity(0.5),
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
