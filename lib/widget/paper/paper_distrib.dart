import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:prescore_flutter/main.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';

class PaperDistributionPhoto extends StatefulWidget {
  final String examId;
  final String paperId;
  const PaperDistributionPhoto(
      {Key? key, required this.paperId, required this.examId})
      : super(key: key);

  @override
  State<PaperDistributionPhoto> createState() => _PaperDistributionPhotoState();
}

class _PaperDistributionPhotoState extends State<PaperDistributionPhoto>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  List<Widget> photos = [];

  @override
  void initState() {
    super.initState();
    photos.add(const SizedBox(
      height: 20,
    ));
    photos.add(const Center(
      child: Text("加载可能需要较长时间，请耐心等待~"),
    ));
    photos.add(const SizedBox(
      height: 20,
    ));
    photos.add(PaperDistributionPhotoWidget(
        url:
            "https://matrix.bjbybbs.com/api/img/paper/triple/${widget.paperId}",
        tag: const Uuid().v4()));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView(
      children: photos,
    );
  }
}

class PaperDistributionPhotoWidget extends StatefulWidget {
  final String url;
  final String tag;
  const PaperDistributionPhotoWidget(
      {Key? key, required this.url, required this.tag})
      : super(key: key);

  @override
  State<PaperDistributionPhotoWidget> createState() =>
      _PaperDistributionPhotoWidgetState();
}

class _PaperDistributionPhotoWidgetState
    extends State<PaperDistributionPhotoWidget> {
  @override
  Widget build(BuildContext context) {
    GlobalKey globalKey = GlobalKey();
    return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (subContext) => GestureDetector(
                      onTap: () {
                        Navigator.pop(subContext);
                      },
                      child: Scaffold(
                        floatingActionButton: FloatingActionButton(
                          onPressed: () async {
                            if (Platform.isAndroid) {
                              PermissionStatus storageStatus =
                                  await Permission.storage.status;
                              PermissionStatus photoStatus =
                                  await Permission.photos.status;
                              if (!storageStatus.isGranted |
                                  !photoStatus.isGranted) {
                                logger.d('req');
                                await Permission.storage.request();
                                await Permission.photos.request();
                              }

                              storageStatus = await Permission.storage.status;
                              photoStatus = await Permission.photos.status;
                              logger.d([storageStatus, photoStatus]);

                              if (storageStatus.isGranted |
                                  photoStatus.isGranted) {
                                Dio dio = BaseSingleton.singleton.dio;
                                dio
                                    .get(widget.url,
                                        options: Options(
                                            responseType: ResponseType.bytes))
                                    .then((value) async {
                                  final result = await ImageGallerySaver.saveImage(
                                      Uint8List.fromList(value.data),
                                      name:
                                          "prescore_${(DateTime.now().millisecondsSinceEpoch / 100).round()}");
                                  if (mounted) {
                                    if (result["isSuccess"]) {
                                      SnackBar snackBar = SnackBar(
                                        content: const Text('保存大成功！'),
                                        backgroundColor:
                                            ThemeMode.system == ThemeMode.dark
                                                ? Colors.grey[900]
                                                : Colors.grey[200],
                                      );
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(snackBar);
                                    } else {
                                      SnackBar snackBar = SnackBar(
                                        content: Text(
                                            '呜呜呜，失败了……\n失败原因：${result["errorMessage"]}'),
                                        backgroundColor:
                                            ThemeMode.system == ThemeMode.dark
                                                ? Colors.grey[900]
                                                : Colors.grey[200],
                                      );
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(snackBar);
                                    }
                                  }
                                });
                              } else {
                                SnackBar snackBar = SnackBar(
                                  content:
                                      const Text('呜呜呜，失败了……\n失败原因：无保存权限……'),
                                  backgroundColor:
                                      ThemeMode.system == ThemeMode.dark
                                          ? Colors.grey[900]
                                          : Colors.grey[200],
                                );
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(snackBar);
                              }
                            } else {
                              SnackBar snackBar = SnackBar(
                                content:
                                    const Text('呜呜呜，失败了……\n还不支持其他系统保存图片哦……'),
                                backgroundColor:
                                    ThemeMode.system == ThemeMode.dark
                                        ? Colors.grey[900]
                                        : Colors.grey[200],
                              );
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(snackBar);
                            }
                          },
                          child: const Icon(Icons.save_alt_rounded),
                        ),
                        body: PhotoView(
                          imageProvider: NetworkImage(
                            widget.url,
                          ),
                          heroAttributes:
                              PhotoViewHeroAttributes(tag: widget.tag),
                        ),
                      ),
                    )),
          );
        },
        child: Hero(
          tag: widget.tag,
          child: RepaintBoundary(
            key: globalKey,
            child: Stack(
              children: <Widget>[
                const Center(
                    child: Column(
                  children: [
                    SizedBox(
                      height: 20,
                    ),
                    CircularProgressIndicator(),
                    SizedBox(
                      height: 20,
                    ),
                  ],
                )),
                Image.network(
                  widget.url,
                ),
              ],
            ),
          ),
        ));
  }
}
