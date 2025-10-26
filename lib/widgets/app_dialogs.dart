import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:quran_hadith/services/native_desktop_service.dart';
import 'package:quran_hadith/utils/shared_p.dart';

/// Centralized, consistent dialogs for the app
class AppDialogs {
  AppDialogs._();

  /// Handle exit flow with optional confirmation and minimize-to-tray choice.
  /// Returns true if the app was closed, false if cancelled, null if minimized.
  static Future<bool?> handleExit(BuildContext context) async {
    final bool confirm = appSP.getBool('confirm_on_exit', defaultValue: true);
    final String preferred =
        appSP.getString('preferred_exit_action', defaultValue: 'ask');

    // If user chose not to confirm, act on preferred choice
    if (!confirm && preferred != 'ask') {
      return _performExitAction(context, preferred);
    }

    return showDialog<bool?>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final theme = Theme.of(context);
        bool dontAskAgain = !confirm;
        String selected = 'exit';
        final bool supportsTray = !kIsWeb &&
            (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            icon: const FaIcon(FontAwesomeIcons.solidCircleQuestion),
            title: const Text('Exit Qur’ān Hadith?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  supportsTray
                      ? 'You can minimize to the tray to keep audio playing in the background.'
                      : 'You can cancel if you exited by mistake.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                if (supportsTray)
                  RadioListTile<String>(
                    value: 'minimize',
                    groupValue: selected,
                    dense: true,
                    title: const Text('Minimize to tray'),
                    secondary: const Icon(Icons.keyboard_arrow_down_rounded),
                    onChanged: (v) => setState(() => selected = v ?? 'exit'),
                  ),
                RadioListTile<String>(
                  value: 'exit',
                  groupValue: selected,
                  dense: true,
                  title: const Text('Exit the app'),
                  secondary: const Icon(Icons.power_settings_new_rounded),
                  onChanged: (v) => setState(() => selected = v ?? 'exit'),
                ),
                const SizedBox(height: 4),
                CheckboxListTile(
                  value: dontAskAgain,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (v) => setState(() => dontAskAgain = v ?? false),
                  title: const Text("Don't ask again"),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton.tonal(
                onPressed: () async {
                  // Persist preference if requested
                  if (dontAskAgain) {
                    await appSP.setBool('confirm_on_exit', false);
                    await appSP.setString('preferred_exit_action', selected);
                  }
                  final result = await _performExitAction(context, selected);
                  Navigator.of(context).pop(result);
                },
                child: Text(supportsTray && selected == 'minimize'
                    ? 'Minimize'
                    : 'Exit'),
              ),
            ],
          );
        });
      },
    );
  }

  /// Execute exit or minimize action; returns true if closed, null if minimized, false if cancelled.
  static Future<bool?> _performExitAction(
      BuildContext context, String action) async {
    if (action == 'minimize') {
      // Attempt minimize to tray (or taskbar fallback)
      await nativeDesktop.minimizeToTray();
      return null;
    }
    // Exit application
    try {
      await SystemNavigator.pop(animated: true);
      return true;
    } catch (_) {
      // Fallback if pop is not supported
      SystemNavigator.pop();
      return true;
    }
  }
}
