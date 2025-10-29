import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:quran_hadith/services/reading_mode_service.dart';

/// Bottom sheet widget for reading mode controls
class ReadingModeSheet extends StatefulWidget {
  const ReadingModeSheet({super.key});

  @override
  State<ReadingModeSheet> createState() => _ReadingModeSheetState();
}

class _ReadingModeSheetState extends State<ReadingModeSheet> {
  final ReadingModeService _readingMode = ReadingModeService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Row(
            children: [
              Icon(
                FontAwesomeIcons.bookOpen,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text(
                'Reading Modes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Focus Mode
          _buildModeCard(
            icon: FontAwesomeIcons.eye,
            title: 'Focus Mode',
            subtitle: 'Hide UI, show only ayah text',
            value: _readingMode.focusMode,
            onChanged: (_) => _readingMode.toggleFocusMode(),
            color: theme.colorScheme.primary,
            keyboardHint: 'F',
          ),
          const SizedBox(height: 12),

          // Night Mode
          _buildModeCard(
            icon: FontAwesomeIcons.moon,
            title: 'Night Mode',
            subtitle: 'OLED-black background for dark reading',
            value: _readingMode.nightMode,
            onChanged: (_) => _readingMode.toggleNightMode(),
            color: theme.colorScheme.secondary,
            keyboardHint: 'N',
          ),
          const SizedBox(height: 12),

          // Auto Night Mode
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text(
                'Auto Night Mode',
                style: TextStyle(fontSize: 14),
              ),
              subtitle: const Text(
                'Enable automatically from 8 PM to 6 AM',
                style: TextStyle(fontSize: 12),
              ),
              value: _readingMode.autoNightMode,
              onChanged: (_) => _readingMode.toggleAutoNightMode(),
            ),
          ),
          const SizedBox(height: 12),

          // Dyslexia Mode
          _buildModeCard(
            icon: FontAwesomeIcons.font,
            title: 'Dyslexia-Friendly Mode',
            subtitle: 'Enhanced spacing and font for easier reading',
            value: _readingMode.dyslexiaMode,
            onChanged: (_) => _readingMode.toggleDyslexiaMode(),
            color: theme.colorScheme.tertiary,
            keyboardHint: null,
          ),
          const SizedBox(height: 20),

          // Blue Light Filter
          const Text(
            'Blue Light Filter',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Reduce eye strain in low light conditions',
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                FontAwesomeIcons.sun,
                size: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              Expanded(
                child: Slider(
                  value: _readingMode.blueLight,
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  label:
                      '${(_readingMode.blueLight * 100).toStringAsFixed(0)}%',
                  onChanged: (value) {
                    setState(() {
                      _readingMode.setBlueLight(value);
                    });
                  },
                ),
              ),
              Icon(
                FontAwesomeIcons.moon,
                size: 16,
                color: Colors.orange.withOpacity(0.8),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Keyboard shortcuts info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      FontAwesomeIcons.keyboard,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Keyboard Shortcuts',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildShortcutRow('F11', 'Toggle fullscreen'),
                _buildShortcutRow('F', 'Toggle focus mode'),
                _buildShortcutRow('N', 'Toggle night mode'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Close button
          Center(
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color color,
    String? keyboardHint,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: value ? color : Colors.transparent,
          width: 2,
        ),
      ),
      color: value
          ? color.withOpacity(0.1)
          : Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withOpacity(0.3),
      child: SwitchListTile(
        secondary: Icon(icon, color: color, size: 20),
        title: Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (keyboardHint != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: color.withOpacity(0.5)),
                ),
                child: Text(
                  keyboardHint,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeThumbColor: color,
      ),
    );
  }

  Widget _buildShortcutRow(String key, String action) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: Theme.of(context).dividerColor,
              ),
            ),
            child: Text(
              key,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              action,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
