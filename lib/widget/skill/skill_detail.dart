import 'package:flutter/material.dart';
import 'package:prescore_flutter/widget/skill/skill_header.dart';
import 'package:provider/provider.dart';

import '../../model/skill_model.dart';
import '../../util/user_util.dart';

class SkillDetail extends StatefulWidget {
  const SkillDetail({super.key});

  @override
  State<SkillDetail> createState() => _SkillDetailState();
}

class _SkillDetailState extends State<SkillDetail> {
  @override
  Widget build(BuildContext context) {
    User user = Provider.of<SkillModel>(context, listen: false).user;

    return Flex(
      direction: Axis.vertical,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(8),
            shrinkWrap: false,
            children: const [
              SkillHeader(),
            ],
          ),
        )
      ],
    );
  }
}
