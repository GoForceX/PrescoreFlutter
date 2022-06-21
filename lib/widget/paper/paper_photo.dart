import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../model/paper_model.dart';

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

    if (Provider.of<PaperModel>(context, listen: false).isDataLoaded) {
      List<Widget> photos = [];

      Provider.of<PaperModel>(context, listen: false)
          .paperData
          ?.sheetImages
          .forEach((element) {
        photos.add(PaperPhotoWidget(url: element, tag: const Uuid().v4()));
      });

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
            if (snapshot.data["state"]) {
              List<Widget> photos = [];

              snapshot.data["result"].sheetImages.forEach((element) {
                photos.add(
                    PaperPhotoWidget(url: element, tag: const Uuid().v4()));
              });

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

    return Center(
        child: Column(children: [Expanded(child: main)]));
  }
}

class PaperPhotoWidget extends StatelessWidget {
  final String url;
  final String tag;
  const PaperPhotoWidget({Key? key, required this.url, required this.tag})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: PhotoView(
                      imageProvider: NetworkImage(
                        url,
                      ),
                      heroAttributes: PhotoViewHeroAttributes(tag: tag),
                    ),
                  )),
        );
      },
      child: Hero(
        tag: tag,
        child: Image.network(
          url,
          width: 350.0,
        ),
      ),
    );
  }
}
