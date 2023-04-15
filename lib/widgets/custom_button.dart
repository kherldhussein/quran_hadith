import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:popover/popover.dart';
import 'package:quran_hadith/layout/adaptive.dart';

import '../theme/app_theme.dart';
import 'menu_list_items.dart';

class RoundCustomButton extends StatelessWidget {
  final List<Widget>? children;
  final IconData? icon;

  const RoundCustomButton({Key? key, this.icon, this.children})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isSmall = isDisplayVerySmallDesktop(context);
    return Padding(
      padding: EdgeInsets.all(isSmall ? 4 : 8.0),
      child: Container(
        constraints: BoxConstraints(minWidth: 0),
        decoration: BoxDecoration(
          border: Border.all(color: Color(0xffeef2f5)),
          borderRadius: BorderRadius.circular(isSmall ? 30 : 50),
        ),
        child: IconButton(
            onPressed: () {
              showPopover(
                  width: 250,
                  height: 265,
                  context: context,
                  backgroundColor: Theme.of(context).canvasColor,
                  bodyBuilder: (context) => ListItems(children: children));
            },
            splashRadius: 1,
            icon: FaIcon(icon),
            color: Colors.black),
      ),
    );
  }
}

class RoundCustomButton2 extends StatelessWidget {
  final List<Widget>? children;
  final IconData? icon;

  const RoundCustomButton2({Key? key, this.icon, this.children})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isSmall = isDisplayVerySmallDesktop(context);
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Container(
        constraints: BoxConstraints(minWidth: 0),
        width: 80,
        decoration: BoxDecoration(
          // border: Border.all(color: Color(0xffeef2f5)),
          color: kDarkSecondaryColor,
          borderRadius: BorderRadius.circular(isSmall ? 30 : 50),
        ),
        child: IconButton(
            onPressed: () {
              showPopover(
                  width: 250,
                  height: 265,
                  context: context,
                  backgroundColor: Theme.of(context).canvasColor,
                  bodyBuilder: (context) => ListItems(children: children));
            },
            splashRadius: 1,
            icon: Text('Support'),
            color: Colors.black),
      ),
    );
  }
}
