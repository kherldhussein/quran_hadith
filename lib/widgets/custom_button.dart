import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:popover/popover.dart';
import 'package:quran_hadith/layout/adaptive.dart';

import '../theme/app_theme.dart';
import 'menu_list_items.dart';

class RoundCustomButton extends StatelessWidget {
  final List<Widget>? children;
  final IconData? icon;
  final double popoverWidth;
  final double popoverHeight;

  const RoundCustomButton({
    super.key,
    this.icon,
    this.children,
    this.popoverWidth = 260,
    this.popoverHeight = 280,
  });

  @override
  Widget build(BuildContext context) {
    final isSmall = isDisplayVerySmallDesktop(context);
    return Padding(
      padding: EdgeInsets.all(isSmall ? 4 : 8.0),
      child: Container(
        constraints: const BoxConstraints(minWidth: 0),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).canvasColor),
          borderRadius: BorderRadius.circular(isSmall ? 30 : 20),
        ),
        child: IconButton(
          onPressed: () {
            showPopover(
                width: popoverWidth,
                height: popoverHeight,
                context: context,
                backgroundColor: Theme.of(context).canvasColor,
                bodyBuilder: (context) => ListItems(children: children));
          },
          splashRadius: 1,
          iconSize: 20,
          icon: FaIcon(icon),
          color: Colors.black,
        ),
      ),
    );
  }
}

class RoundCustomButton2 extends StatelessWidget {
  final List<Widget>? children;
  final IconData? icon;

  const RoundCustomButton2({super.key, this.icon, this.children});

  @override
  Widget build(BuildContext context) {
    final isSmall = isDisplayVerySmallDesktop(context);
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Container(
        constraints: const BoxConstraints(minWidth: 0),
        width: 80,
        decoration: BoxDecoration(
          color: Get.theme.brightness == Brightness.light
              ? kAccentColor
              : kDarkSecondaryColor,
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
          icon: const Text(
            'Support',
            style: TextStyle(color: kLightSecondaryColor),
          ),
        ),
      ),
    );
  }
}
