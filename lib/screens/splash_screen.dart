import 'dart:io' show Platform;
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:quran_hadith/screens/home_screen.dart';
import 'package:quran_hadith/widgets/app_dialogs.dart';

import '../theme/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
    return Stack(
      children: [
        const HomeScreen(),
        if (isDesktop)
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
  const WindowButtons({super.key});

  @override
  Widget build(BuildContext context) {
    const theme = kDarkSecondaryColor;
    return Row(
      children: [
        MinimizeWindowButton(
          colors: WindowButtonColors(
            iconMouseDown: Get.theme.colorScheme.surface,
            iconNormal: theme.withOpacity(.5),
            mouseOver: theme.withOpacity(.5),
            mouseDown: theme.withOpacity(.5),
            iconMouseOver: Colors.white,
          ),
        ),
        MaximizeWindowButton(
          colors: WindowButtonColors(
            iconMouseDown: Get.theme.colorScheme.surface,
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
          onPressed: () async {
            SystemSound.play(SystemSoundType.alert);
            await AppDialogs.handleExit(context);
          },
        ),
      ],
    );
  }
}
