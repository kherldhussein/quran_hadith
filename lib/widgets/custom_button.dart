import 'package:flutter/material.dart';
import 'package:popover/popover.dart';
import 'package:quran_hadith/layout/adaptive.dart';

import 'menu_list_items.dart';

class RoundCustomButton extends StatelessWidget {
  final IconData? icon;
  final List<Widget>? children;

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
        child: Popover(
          backgroundColor: Color(0xffeef2f5),
          bodyBuilder: (BuildContext context) => ListItems(children: children),
          child: IconButton(
              onPressed: () {},
              splashRadius: 10,
              icon: Icon(icon),
              color: Colors.black),
        ),
      ),
    );
  }
}
