import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:quran_hadith/services/gesture_service.dart';

/// Settings sheet for gesture customization
class GestureSettingsSheet extends StatelessWidget {
  final GestureService service;

  const GestureSettingsSheet({super.key, required this.service});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => GestureSettingsSheet(service: gestureService),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  _buildHeader(context, theme),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildMasterToggle(theme),
                        const SizedBox(height: 16),
                        _buildGestureToggles(theme),
                        const SizedBox(height: 16),
                        _buildSensitivitySliders(theme),
                        const SizedBox(height: 16),
                        _buildHapticToggle(theme),
                        const SizedBox(height: 16),
                        _buildGestureGuide(theme),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Row(
        children: [
          const FaIcon(FontAwesomeIcons.handPointer, size: 20),
          const SizedBox(width: 12),
          Text(
            'Gesture Settings',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterToggle(ThemeData theme) {
    return Card(
      child: SwitchListTile(
        title: const Text('Enable Gestures'),
        subtitle: Text(
          service.gesturesEnabled
              ? 'All gestures are active'
              : 'All gestures are disabled',
          style: theme.textTheme.bodySmall,
        ),
        secondary: FaIcon(
          service.gesturesEnabled
              ? FontAwesomeIcons.handPointer
              : FontAwesomeIcons.handBackFist,
          color: service.gesturesEnabled ? theme.colorScheme.primary : null,
        ),
        value: service.gesturesEnabled,
        onChanged: (_) => service.toggleGestures(),
      ),
    );
  }

  Widget _buildGestureToggles(ThemeData theme) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Gesture Types',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildGestureToggle(
            theme,
            'Horizontal Swipe',
            'Swipe left/right to navigate ayahs',
            FontAwesomeIcons.arrowsLeftRight,
            service.horizontalSwipeEnabled,
            () => service.toggleHorizontalSwipe(),
          ),
          _buildGestureToggle(
            theme,
            'Vertical Swipe',
            'Swipe up/down to scroll',
            FontAwesomeIcons.arrowsUpDown,
            service.verticalSwipeEnabled,
            () => service.toggleVerticalSwipe(),
          ),
          _buildGestureToggle(
            theme,
            'Double Tap',
            'Double tap to play/pause',
            FontAwesomeIcons.handPointer,
            service.doubleTapEnabled,
            () => service.toggleDoubleTap(),
          ),
          _buildGestureToggle(
            theme,
            'Long Press',
            'Long press for ayah options',
            FontAwesomeIcons.handFist,
            service.longPressEnabled,
            () => service.toggleLongPress(),
          ),
          _buildGestureToggle(
            theme,
            'Pinch',
            'Pinch to adjust font size',
            FontAwesomeIcons.magnifyingGlass,
            service.pinchEnabled,
            () => service.togglePinch(),
          ),
          _buildGestureToggle(
            theme,
            'Multi-Finger Gestures',
            '2/3-finger gestures for quick actions',
            FontAwesomeIcons.hand,
            service.multiFingerGesturesEnabled,
            () => service.toggleMultiFingerGestures(),
          ),
        ],
      ),
    );
  }

  Widget _buildGestureToggle(
    ThemeData theme,
    String title,
    String subtitle,
    IconData icon,
    bool value,
    VoidCallback onChanged,
  ) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
      secondary: FaIcon(icon, size: 16),
      value: value && service.gesturesEnabled,
      onChanged: service.gesturesEnabled ? (_) => onChanged() : null,
    );
  }

  Widget _buildSensitivitySliders(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sensitivity',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSensitivitySlider(
              theme,
              'Swipe Sensitivity',
              service.swipeSensitivity,
              (value) => service.setSwipeSensitivity(value),
            ),
            const SizedBox(height: 8),
            _buildSensitivitySlider(
              theme,
              'Pinch Sensitivity',
              service.pinchSensitivity,
              (value) => service.setPinchSensitivity(value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensitivitySlider(
    ThemeData theme,
    String label,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.bodyMedium),
            Text(
              '${(value * 100).toInt()}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          onChanged: service.gesturesEnabled ? onChanged : null,
          min: 0.0,
          max: 1.0,
          divisions: 10,
          label: '${(value * 100).toInt()}%',
        ),
      ],
    );
  }

  Widget _buildHapticToggle(ThemeData theme) {
    return Card(
      child: SwitchListTile(
        title: const Text('Haptic Feedback'),
        subtitle: Text(
          'Vibrate on gesture detection',
          style: theme.textTheme.bodySmall,
        ),
        secondary: const FaIcon(FontAwesomeIcons.mobile, size: 20),
        value: service.hapticFeedback,
        onChanged: service.gesturesEnabled
            ? (_) => service.toggleHapticFeedback()
            : null,
      ),
    );
  }

  Widget _buildGestureGuide(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.circleInfo,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Gesture Guide',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildGestureGuideItem(
              theme,
              FontAwesomeIcons.arrowLeft,
              'Swipe Left',
              'Go to next ayah',
            ),
            _buildGestureGuideItem(
              theme,
              FontAwesomeIcons.arrowRight,
              'Swipe Right',
              'Go to previous ayah',
            ),
            _buildGestureGuideItem(
              theme,
              FontAwesomeIcons.handPointer,
              'Double Tap',
              'Play/pause audio',
            ),
            _buildGestureGuideItem(
              theme,
              FontAwesomeIcons.handFist,
              'Long Press',
              'Show ayah options',
            ),
            _buildGestureGuideItem(
              theme,
              FontAwesomeIcons.upDownLeftRight,
              'Pinch',
              'Adjust font size',
            ),
            _buildGestureGuideItem(
              theme,
              FontAwesomeIcons.arrowUp,
              'Two-Finger Swipe Up',
              'Jump to bottom',
            ),
            _buildGestureGuideItem(
              theme,
              FontAwesomeIcons.arrowDown,
              'Two-Finger Swipe Down',
              'Jump to top',
            ),
            _buildGestureGuideItem(
              theme,
              FontAwesomeIcons.bookmark,
              'Three-Finger Swipe',
              'Toggle bookmark',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGestureGuideItem(
    ThemeData theme,
    IconData icon,
    String gesture,
    String action,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: FaIcon(
                icon,
                size: 14,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gesture,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  action,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
