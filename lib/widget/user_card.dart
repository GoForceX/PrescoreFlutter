import 'package:flutter/material.dart';
import 'package:prescore_flutter/main.dart';
import 'package:prescore_flutter/model/login_model.dart';
import 'package:provider/provider.dart';

class MainAppbarWidget extends StatelessWidget {
  const MainAppbarWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<LoginModel>(
        builder: (BuildContext context, LoginModel value, Widget? child) {
      return FittedBox(
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(20)),
          ),
          color: Theme.of(context).colorScheme.onSecondary,
          margin: const EdgeInsets.only(left: 10, right: 10),
          child: Consumer<LoginModel>(
              builder: (BuildContext context, LoginModel value, Widget? child) {
            return FutureBuilder(
                future: value.user.fetchBasicInfo(),
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  Widget image = Image.asset('assets/akarin.webp');
                  String title = "";
                  String subtitle = "";
                  if (snapshot.hasData) {
                    logger.d("basicInfo: ${snapshot.data}");
                    if (snapshot.data.avatar != "" &&
                        !(snapshot.data.avatar as String).contains('default')) {
                      image = FadeInImage.assetNetwork(
                          image: snapshot.data.avatar,
                          placeholder: 'assets/akarin.webp');
                    }
                    if (snapshot.data.name != "") {
                      title = snapshot.data.name;
                    }
                    if (snapshot.data.loginName != "") {
                      subtitle = snapshot.data.loginName;
                    }
                  }
                  return Container(
                      margin: const EdgeInsets.all(15),
                      width: 180,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 26,
                            child: ClipOval(child: image),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(children: [
                                Text(
                                  title,
                                  style: const TextStyle(fontSize: 22),
                                )
                              ]),
                              Row(children: [
                                Text(
                                subtitle,
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey),
                              ),
                              ]),
                            ],
                          ),
                        ],
                      ));
                });
          }),
        ),
      );
    });
  }
}
