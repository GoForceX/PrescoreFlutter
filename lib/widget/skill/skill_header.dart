import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../model/skill_model.dart';
import '../../util/user_util.dart';
import '../main/main_header.dart';

class SkillHeader extends StatefulWidget {
  const SkillHeader({super.key});

  @override
  State<SkillHeader> createState() => _SkillHeaderState();
}

class _SkillHeaderState extends State<SkillHeader> {
  @override
  Widget build(BuildContext context) {
    User user = Provider.of<SkillModel>(context, listen: false).user;

    return Container(
        height: 120,
        child: FittedBox(
            child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0)),
                elevation: 8,
                child: InkWell(
                  child: FutureBuilder(
                      future: user.fetchBasicInfo(),
                      builder: (BuildContext context, AsyncSnapshot snapshot) {
                        Widget image = Image.asset('assets/akarin.webp');
                        String title = "";
                        String subtitle = "";
                        if (snapshot.hasData) {
                          if (snapshot.data.avatar != "") {
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
                        return MainAppbarRowWidget(
                          image: image,
                          title: title,
                          subtitle: subtitle,
                          showTip: false,
                        );
                      }),
                ))));
  }
}
