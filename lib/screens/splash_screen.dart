import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:quran_hadith/screens/home_screen.dart';

import '../theme/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const HomeScreen(),
        WindowTitleBarBox(
          child: Row(
            children: [Expanded(child: MoveWindow()), const WindowButtons()],
          ),
        ),
      ],
    );
  }
}

class WindowButtons extends StatelessWidget {
  const WindowButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = kDarkSecondaryColor;
    return Row(
      children: [
        MinimizeWindowButton(
          colors: WindowButtonColors(
            iconMouseDown: Get.theme.colorScheme.background,
            iconNormal: theme.withOpacity(.5),
            mouseOver: theme.withOpacity(.5),
            mouseDown: theme.withOpacity(.5),
            iconMouseOver: Colors.white,
          ),
        ),
        MaximizeWindowButton(
          colors: WindowButtonColors(
            iconMouseDown: Get.theme.colorScheme.background,
            iconNormal: theme.withOpacity(.5),
            mouseOver: theme.withOpacity(.5),
            mouseDown: theme.withOpacity(.5),
            iconMouseOver: Colors.white,
          ),
        ),
        CloseWindowButton(
          colors: WindowButtonColors(
            mouseOver: const Color(0xFFD32F2F).withOpacity(.5),
            mouseDown: const Color(0xFFB71C1C).withOpacity(.5),
            iconNormal: theme.withOpacity(.5),
            iconMouseOver: Colors.white,
          ),
          onPressed: () {
            SystemSound.play(SystemSoundType.alert);
            Get.dialog(
              AlertDialog(
                title: Text('Are you sure you want to exit?'),
                content: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => SystemNavigator.pop(),
                      child: Text('Exit'),
                    ),
                    TextButton(
                      onPressed: () => Get.back(),
                      child: Text('Cancel'),
                    )
                  ],
                ),
                iconColor: theme.withOpacity(.5),
                icon: FaIcon(FontAwesomeIcons.solidCircleQuestion),
              ),
              name: 'Exit Dialog',
            );
          },
        ),
      ],
    );
  }
}
