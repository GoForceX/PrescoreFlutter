import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:prescore_flutter/util/struct.dart';

import '../assets/draw_icons.dart';
import '../main.dart';

Future<Uint8List?> markerPainter(
    List<Marker> markers, Uint8List originalImage, int sheetId) async {
  var pictureRecorder = PictureRecorder();
  var canvas = Canvas(pictureRecorder);

  Paint linePaint = Paint();

  Codec codec = await instantiateImageCodec(originalImage);
  FrameInfo frameInfo = await codec.getNextFrame();

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
          ParagraphBuilder pb = ParagraphBuilder(ParagraphStyle(
              textAlign: TextAlign.left,
              fontWeight: FontWeight.w800,
              fontStyle: FontStyle.normal,
              fontSize: 64.0));
          pb.pushStyle(TextStyle(color: marker.color));
          pb.addText(marker.message);
          ParagraphConstraints pc =
          const ParagraphConstraints(width: 200);
          Paragraph paragraph = pb.build()..layout(pc);
          canvas.drawParagraph(
              paragraph,
              Offset(marker.left / widthRate + marker.leftOffset,
                  marker.top / heightRate + marker.topOffset));
          break;
        case MarkerType.detailScoreEnd:
          ParagraphBuilder pb = ParagraphBuilder(ParagraphStyle(
              textAlign: TextAlign.right,
              fontWeight: FontWeight.w400,
              fontStyle: FontStyle.normal,
              fontSize: 40.0));
          pb.pushStyle(TextStyle(color: marker.color));
          pb.addText(marker.message);
          ParagraphConstraints pc =
          const ParagraphConstraints(width: 300);
          Paragraph paragraph = pb.build()..layout(pc);
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
          ParagraphBuilder pb = ParagraphBuilder(ParagraphStyle(
              textAlign: TextAlign.left,
              fontWeight: FontWeight.w800,
              fontStyle: FontStyle.normal,
              fontSize: 32.0));
          pb.pushStyle(TextStyle(color: marker.color));
          pb.addText(marker.message);
          ParagraphConstraints pc =
          const ParagraphConstraints(width: 200);
          Paragraph paragraph = pb.build()..layout(pc);
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


  var pngImageBytes = await picture.toByteData(format: ImageByteFormat.png);

  if (pngImageBytes == null) {
    return originalImage;
  }
  Uint8List pngBytes = Uint8List.view(pngImageBytes.buffer);

  return pngBytes;
}

Future<Uint8List?> fetchImage(String url) async {
  Dio dio = BaseSingleton.singleton.dio;
  var image = await dio.get(url, options: Options(responseType: ResponseType.bytes));
  logger.d("fetchImage: ${image.data.length}, fin");
  return image.data;
}

Future<Uint8List?> fetchImageAndDrawMarker(
    List<Marker> markers, String url, int sheetId) async {
  Uint8List? result;
  try {
    var image = await fetchImage(url);
    logger.d("fetchImage: ${image?.length}, fin");
    result = await markerPainter(markers, image!, sheetId);
  } catch (e) {
    logger.e("fetchImageAndDrawMarker: $e");
  }
  return result;
}

Future<List<Uint8List?>> fetchImageListAndDrawMarker(
    List<Marker> markers, List<String> urls) async {
  List<Uint8List?> images = [];

  images = await Future.wait(urls.asMap().entries.map((e) => fetchImageAndDrawMarker(markers, e.value, e.key)));
  logger.d("fetchImageListAndDrawMarker: ${images.map((element) => element?.length).join(',')}, finish");
  return images;
}

Future<List<Uint8List?>> fetchImageList(List<String> urls) async {
  List<Uint8List?> images = [];

  images = await Future.wait(urls.map((url) => fetchImage(url)));
  logger.d("fetchImage: ${images.map((element) => element?.length).join(',')}, fin");
  return images;
}