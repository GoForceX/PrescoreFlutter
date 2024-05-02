import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:prescore_flutter/main.dart';
import 'package:prescore_flutter/util/paper_draw.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';

import '../../model/paper_model.dart';

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

  late final AsyncMemoizer<List<Uint8List?>> _fetchAndDraw;
  late final AsyncMemoizer<List<Uint8List?>> _fetch;

  @override
  void initState() {
    super.initState();
    PaperModel model = Provider.of<PaperModel>(context, listen: false);
    if (!model.isDataLoaded) {
      model.user.fetchPaperData(widget.examId, widget.paperId).then((value) {
        if (value.state) {
          model.setPaperData(value.result);
          model.setDataLoaded(true);
        } else {
          model.setErrMsg(value.message);
        }
      });
    }

    _fetchAndDraw = AsyncMemoizer();
    _fetch = AsyncMemoizer();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    //logger.d("exam id: ${widget.examId}");
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
      // if (BaseSingleton.singleton.sharedPreferences
      //             .getBool("useExperimentalDraw") ==
      //         true &&
      //     markedphotos == null) {
      //   List<Marker> markers = examModel.paperData?.markers ?? [];
      //   List<Widget> photos = [];
      //   for (var i = 0; i < examModel.paperData!.sheetImages.length; i++) {
      //     photos.add(PaperPhotoWidget(
      //         sheetId: i,
      //         url: examModel.paperData!.sheetImages[i],
      //         tag: const Uuid().v4(),
      //         markers: markers,
      //         mark: true));
      //   }
      //   markedphotos = ListView(
      //     children: photos +
      //         [const SizedBox(height: 84)], // to avoid FAB covering last item
      //   );
      // }
      // if (BaseSingleton.singleton.sharedPreferences
      //             .getBool("useExperimentalDraw") ==
      //         false &&
      //     unMarkedphotos == null) {
      //   List<Marker> markers = examModel.paperData?.markers ?? [];
      //   List<Widget> photos = [];
      //   for (var i = 0; i < examModel.paperData!.sheetImages.length; i++) {
      //     photos.add(PaperPhotoWidget(
      //         sheetId: i,
      //         url: examModel.paperData!.sheetImages[i],
      //         tag: const Uuid().v4(),));
      //   }
      //   unMarkedphotos = ListView(
      //     children: photos +
      //         [const SizedBox(height: 84)], // to avoid FAB covering last item
      //   );
      // }

      return Stack(children: [
        if (BaseSingleton.singleton.sharedPreferences
                .getBool("useExperimentalDraw") ==
            true)
          Center(
              child: Column(children: [
            if (widget.showNonFinalAlert)
              Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: const Row(children: [
                    SizedBox(width: 20),
                    Icon(Icons.warning_amber_rounded,
                        size: 16, color: Colors.red),
                    Text(" 判卷未完成，不代表最终成绩，可能误标零分")
                  ])),
            Expanded(
                child: Visibility(
              visible: BaseSingleton.singleton.sharedPreferences
                      .getBool("useExperimentalDraw") ==
                  true,
              maintainState: true,
              child: FutureBuilder(
                  future: _fetchAndDraw.runOnce(() =>
                      fetchImageListAndDrawMarker(
                          examModel.paperData?.markers ?? [],
                          examModel.paperData!.sheetImages)),
                  builder: (BuildContext context,
                      AsyncSnapshot<List<Uint8List?>> snapshot) {
                    if (snapshot.hasData) {
                      List<Uint8List?> memoryImages = snapshot.data!;
                      List<Widget> photos = [];
                      for (var i = 0; i < memoryImages.length; i++) {
                        var tag = const Uuid().v4();
                        if (memoryImages[i] != null) {
                          photos.add(PaperPhotoWidget(
                            sheetId: i,
                            data: memoryImages[i]!,
                            tag: tag,
                            galleryItems: memoryImages
                                .map((e) => GalleryItem(id: tag, data: e!))
                                .toList(),
                          ));
                        }
                      }
                      markedphotos = ListView(
                        children: photos +
                            [
                              const SizedBox(height: 84)
                            ], // to avoid FAB covering last item
                      );
                      return markedphotos ?? const CircularProgressIndicator();
                    } else {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 8),
                            Text(
                                "请稍等，正在加载图片……共 ${examModel.paperData!.sheetImages.length} 页"),
                            const Text("你知道吗？其实可以通过滑动切换到其他页")
                          ],
                        ),
                      );
                    }
                  }),
            ))
          ])),
        if (BaseSingleton.singleton.sharedPreferences
                .getBool("useExperimentalDraw") ==
            false)
          Center(
              child: Column(children: [
            Expanded(
                child: Visibility(
              visible: BaseSingleton.singleton.sharedPreferences
                      .getBool("useExperimentalDraw") ==
                  false,
              maintainState: true,
              child: FutureBuilder(
                  future: _fetch.runOnce(
                      () => fetchImageList(examModel.paperData!.sheetImages)),
                  builder: (BuildContext context,
                      AsyncSnapshot<List<Uint8List?>> snapshot) {
                    if (snapshot.hasData) {
                      List<Uint8List?> memoryImages = snapshot.data!;
                      List<Widget> photos = [];
                      logger.d(memoryImages.length);
                      for (var i = 0; i < memoryImages.length; i++) {
                        var tag = const Uuid().v4();
                        if (memoryImages[i] != null) {
                          photos.add(PaperPhotoWidget(
                            sheetId: i,
                            data: memoryImages[i]!,
                            tag: tag,
                            galleryItems: memoryImages
                                .map((e) => GalleryItem(id: tag, data: e!))
                                .toList(),
                          ));
                        }
                      }
                      unMarkedphotos = ListView(
                        children: photos +
                            [
                              const SizedBox(height: 84)
                            ], // to avoid FAB covering last item
                      );
                      return unMarkedphotos ??
                          const CircularProgressIndicator();
                    } else {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                  }),
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

class PaperPhotoWidget extends StatefulWidget {
  final int sheetId;
  final Uint8List data;
  final String tag;
  final List<GalleryItem> galleryItems;

  const PaperPhotoWidget(
      {Key? key,
      required this.sheetId,
      required this.data,
      required this.tag,
      required this.galleryItems})
      : super(key: key);

  @override
  State<PaperPhotoWidget> createState() => _PaperPhotoWidgetState();
}

class _PaperPhotoWidgetState extends State<PaperPhotoWidget> {
  Future<Response<dynamic>>? getImageFuture;
  Future<dynamic>? markerPainterFuture;

  @override
  Widget build(BuildContext context) {
    Uint8List memoryImage = widget.data;
    return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => GalleryPhotoViewWrapper(
                      galleryItems: widget.galleryItems,
                      backgroundDecoration: const BoxDecoration(
                        color: Colors.black,
                      ),
                      initialIndex: widget.sheetId,
                      scrollDirection: Axis.horizontal,
                    )),
            // builder: (subContext) => GestureDetector(
            //     onTap: () {
            //       Navigator.pop(subContext);
            //     },
            //     child: PaperPhotoEnlarged(
            //       memoryImage: memoryImage!,
            //       tag: widget.tag,
            //     ))),
          );
        },
        child: Hero(
          tag: widget.tag,
          child: RepaintBoundary(
            child: Image.memory(
              memoryImage,
              width: 350.0,
            ),
          ),
        ));
  }
}

class GalleryItem {
  GalleryItem({
    required this.id,
    required this.data,
  });

  final String id;
  final Uint8List data;
}

class GalleryPhotoViewWrapper extends StatefulWidget {
  GalleryPhotoViewWrapper({
    super.key,
    this.loadingBuilder,
    this.backgroundDecoration,
    this.minScale,
    this.maxScale,
    this.initialIndex = 0,
    required this.galleryItems,
    this.scrollDirection = Axis.horizontal,
  }) : pageController = PageController(initialPage: initialIndex);

  final LoadingBuilder? loadingBuilder;
  final BoxDecoration? backgroundDecoration;
  final dynamic minScale;
  final dynamic maxScale;
  final int initialIndex;
  final PageController pageController;
  final List<GalleryItem> galleryItems;
  final Axis scrollDirection;

  @override
  State<StatefulWidget> createState() {
    return _GalleryPhotoViewWrapperState();
  }
}

class _GalleryPhotoViewWrapperState extends State<GalleryPhotoViewWrapper> {
  late int currentIndex = widget.initialIndex;

  void onPageChanged(int index) {
    setState(() {
      currentIndex = index;
    });
  }

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
                  widget.galleryItems[currentIndex].data,
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
      body: Container(
        decoration: widget.backgroundDecoration,
        constraints: BoxConstraints.expand(
          height: MediaQuery.of(context).size.height,
        ),
        child: Stack(
          alignment: Alignment.bottomLeft,
          children: <Widget>[
            PhotoViewGallery.builder(
              scrollPhysics: const BouncingScrollPhysics(),
              builder: _buildItem,
              itemCount: widget.galleryItems.length,
              loadingBuilder: widget.loadingBuilder,
              backgroundDecoration: widget.backgroundDecoration,
              pageController: widget.pageController,
              onPageChanged: onPageChanged,
              scrollDirection: widget.scrollDirection,
            ),
            Container(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                "第 ${currentIndex + 1} 页",
                style: const TextStyle(
                  fontSize: 17.0,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  PhotoViewGalleryPageOptions _buildItem(BuildContext context, int index) {
    final GalleryItem item = widget.galleryItems[index];
    return PhotoViewGalleryPageOptions(
      imageProvider: MemoryImage(
        item.data,
      ),
      initialScale: PhotoViewComputedScale.contained,
      minScale: PhotoViewComputedScale.contained * (0.5 + index / 10),
      maxScale: PhotoViewComputedScale.covered * 4.1,
      heroAttributes: PhotoViewHeroAttributes(tag: item.id),
    );
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
