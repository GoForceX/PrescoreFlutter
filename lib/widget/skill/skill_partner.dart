import 'package:flutter/material.dart';
import 'package:prescore_flutter/widget/skill/skill_header.dart';
import 'package:provider/provider.dart';

import '../../model/skill_model.dart';
import '../../util/user_util.dart';

class SkillPartner extends StatefulWidget {
  const SkillPartner({super.key});

  @override
  State<SkillPartner> createState() => _SkillPartnerState();
}

class _SkillPartnerState extends State<SkillPartner> {
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
              SizedBox(
                height: 20,
              ),
              SkillMatch()
            ],
          ),
        )
      ],
    );
  }
}

class SkillMatch extends StatefulWidget {
  const SkillMatch({super.key});

  @override
  State<SkillMatch> createState() => _SkillMatchState();
}

class _SkillMatchState extends State<SkillMatch> {
  @override
  Widget build(BuildContext context) {
    return Flex(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      mainAxisSize: MainAxisSize.max,
      direction: Axis.horizontal,
      children: [
        Flex(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.vertical,
          children: [
            const Text("比赛"),
            const Text("0"),
          ],
        ),
        Expanded(child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
          ),
        )),
        Flex(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.vertical,
          children: [
            const Text("比赛"),
            const Text("0"),
          ],
        ),
      ],
    );
  }
}
