import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Comprehensive touch gesture system for intuitive navigation
///
/// Features:
/// - Swipe left/right for next/previous ayah
/// - Double-tap for play/pause
/// - Long-press for ayah options
/// - Pinch for font size adjustment
/// - Two-finger swipe for jump to top/bottom
/// - Three-finger swipe for bookmark
/// - Customizable gesture sensitivity
class GestureService extends ChangeNotifier {
  static final GestureService _instance = GestureService._internal();
  factory GestureService() => _instance;
  GestureService._internal();

  // Gesture settings
  bool _gesturesEnabled = true;
  bool _horizontalSwipeEnabled = true;
  bool _verticalSwipeEnabled = true;
  bool _doubleTapEnabled = true;
  bool _longPressEnabled = true;
  bool _pinchEnabled = true;
  bool _multiFingerGesturesEnabled = true;

  // Sensitivity settings (0.0 - 1.0)
  double _swipeSensitivity = 0.5;
  double _pinchSensitivity = 0.5;
  final double _doubleTapDelay = 0.3; // seconds

  // Haptic feedback
  bool _hapticFeedback = true;

  // Gesture state
  DateTime? _lastTapTime;
  Offset? _lastTapPosition;
  double _initialFontSize = 18.0;
  double _currentScale = 1.0;

  // Getters
  bool get gesturesEnabled => _gesturesEnabled;
  bool get horizontalSwipeEnabled => _horizontalSwipeEnabled;
  bool get verticalSwipeEnabled => _verticalSwipeEnabled;
  bool get doubleTapEnabled => _doubleTapEnabled;
  bool get longPressEnabled => _longPressEnabled;
  bool get pinchEnabled => _pinchEnabled;
  bool get multiFingerGesturesEnabled => _multiFingerGesturesEnabled;
  bool get hapticFeedback => _hapticFeedback;
  double get swipeSensitivity => _swipeSensitivity;
  double get pinchSensitivity => _pinchSensitivity;

  // Preferences keys
  static const String _keyGesturesEnabled = 'gestures_enabled';
  static const String _keyHorizontalSwipe = 'gestures_horizontal_swipe';
  static const String _keyVerticalSwipe = 'gestures_vertical_swipe';
  static const String _keyDoubleTap = 'gestures_double_tap';
  static const String _keyLongPress = 'gestures_long_press';
  static const String _keyPinch = 'gestures_pinch';
  static const String _keyMultiFinger = 'gestures_multi_finger';
  static const String _keySwipeSensitivity = 'gestures_swipe_sensitivity';
  static const String _keyPinchSensitivity = 'gestures_pinch_sensitivity';
  static const String _keyHapticFeedback = 'gestures_haptic_feedback';

  /// Initialize gesture service
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    _gesturesEnabled = prefs.getBool(_keyGesturesEnabled) ?? true;
    _horizontalSwipeEnabled = prefs.getBool(_keyHorizontalSwipe) ?? true;
    _verticalSwipeEnabled = prefs.getBool(_keyVerticalSwipe) ?? true;
    _doubleTapEnabled = prefs.getBool(_keyDoubleTap) ?? true;
    _longPressEnabled = prefs.getBool(_keyLongPress) ?? true;
    _pinchEnabled = prefs.getBool(_keyPinch) ?? true;
    _multiFingerGesturesEnabled = prefs.getBool(_keyMultiFinger) ?? true;
    _swipeSensitivity = prefs.getDouble(_keySwipeSensitivity) ?? 0.5;
    _pinchSensitivity = prefs.getDouble(_keyPinchSensitivity) ?? 0.5;
    _hapticFeedback = prefs.getBool(_keyHapticFeedback) ?? true;

    notifyListeners();
    debugPrint('👆 GestureService initialized');
  }

  /// Toggle all gestures
  Future<void> toggleGestures() async {
    _gesturesEnabled = !_gesturesEnabled;
    await _saveBool(_keyGesturesEnabled, _gesturesEnabled);
    notifyListeners();
  }

  /// Toggle horizontal swipe gestures
  Future<void> toggleHorizontalSwipe() async {
    _horizontalSwipeEnabled = !_horizontalSwipeEnabled;
    await _saveBool(_keyHorizontalSwipe, _horizontalSwipeEnabled);
    notifyListeners();
  }

  /// Toggle vertical swipe gestures
  Future<void> toggleVerticalSwipe() async {
    _verticalSwipeEnabled = !_verticalSwipeEnabled;
    await _saveBool(_keyVerticalSwipe, _verticalSwipeEnabled);
    notifyListeners();
  }

  /// Toggle double-tap gestures
  Future<void> toggleDoubleTap() async {
    _doubleTapEnabled = !_doubleTapEnabled;
    await _saveBool(_keyDoubleTap, _doubleTapEnabled);
    notifyListeners();
  }

  /// Toggle long-press gestures
  Future<void> toggleLongPress() async {
    _longPressEnabled = !_longPressEnabled;
    await _saveBool(_keyLongPress, _longPressEnabled);
    notifyListeners();
  }

  /// Toggle pinch gestures
  Future<void> togglePinch() async {
    _pinchEnabled = !_pinchEnabled;
    await _saveBool(_keyPinch, _pinchEnabled);
    notifyListeners();
  }

  /// Toggle multi-finger gestures
  Future<void> toggleMultiFingerGestures() async {
    _multiFingerGesturesEnabled = !_multiFingerGesturesEnabled;
    await _saveBool(_keyMultiFinger, _multiFingerGesturesEnabled);
    notifyListeners();
  }

  /// Toggle haptic feedback
  Future<void> toggleHapticFeedback() async {
    _hapticFeedback = !_hapticFeedback;
    await _saveBool(_keyHapticFeedback, _hapticFeedback);
    notifyListeners();
  }

  /// Set swipe sensitivity
  Future<void> setSwipeSensitivity(double value) async {
    _swipeSensitivity = value.clamp(0.0, 1.0);
    await _saveDouble(_keySwipeSensitivity, _swipeSensitivity);
    notifyListeners();
  }

  /// Set pinch sensitivity
  Future<void> setPinchSensitivity(double value) async {
    _pinchSensitivity = value.clamp(0.0, 1.0);
    await _saveDouble(_keyPinchSensitivity, _pinchSensitivity);
    notifyListeners();
  }

  /// Handle tap gesture
  GestureType? handleTap(Offset position) {
    if (!_gesturesEnabled) return null;

    final now = DateTime.now();

    // Check for double-tap
    if (_doubleTapEnabled && _lastTapTime != null && _lastTapPosition != null) {
      final timeDiff = now.difference(_lastTapTime!);
      final positionDiff = (position - _lastTapPosition!).distance;

      if (timeDiff.inMilliseconds < (_doubleTapDelay * 1000) &&
          positionDiff < 50) {
        _lastTapTime = null;
        _lastTapPosition = null;
        debugPrint('👆 GestureService: Double-tap detected');
        return GestureType.doubleTap;
      }
    }

    // Record tap for potential double-tap
    _lastTapTime = now;
    _lastTapPosition = position;

    return GestureType.singleTap;
  }

  /// Handle long-press gesture
  GestureType? handleLongPress(Offset position) {
    if (!_gesturesEnabled || !_longPressEnabled) return null;

    debugPrint('👆 GestureService: Long-press detected at $position');
    return GestureType.longPress;
  }

  /// Handle horizontal swipe gesture
  GestureType? handleHorizontalSwipe(DragEndDetails details) {
    if (!_gesturesEnabled || !_horizontalSwipeEnabled) return null;

    final velocity = details.primaryVelocity ?? 0;
    final threshold = 800 * (1.0 - _swipeSensitivity);

    if (velocity > threshold) {
      debugPrint('👆 GestureService: Swipe right detected');
      return GestureType.swipeRight;
    } else if (velocity < -threshold) {
      debugPrint('👆 GestureService: Swipe left detected');
      return GestureType.swipeLeft;
    }

    return null;
  }

  /// Handle vertical swipe gesture
  GestureType? handleVerticalSwipe(DragEndDetails details) {
    if (!_gesturesEnabled || !_verticalSwipeEnabled) return null;

    final velocity = details.primaryVelocity ?? 0;
    final threshold = 800 * (1.0 - _swipeSensitivity);

    if (velocity > threshold) {
      debugPrint('👆 GestureService: Swipe down detected');
      return GestureType.swipeDown;
    } else if (velocity < -threshold) {
      debugPrint('👆 GestureService: Swipe up detected');
      return GestureType.swipeUp;
    }

    return null;
  }

  /// Handle pinch gesture (for font size)
  double handlePinch(ScaleUpdateDetails details, double currentFontSize) {
    if (!_gesturesEnabled || !_pinchEnabled) return currentFontSize;

    if (_currentScale == 1.0) {
      _initialFontSize = currentFontSize;
    }

    _currentScale = details.scale;

    // Apply sensitivity
    final scaleDiff = (_currentScale - 1.0) * _pinchSensitivity;
    final newFontSize = _initialFontSize + (scaleDiff * 10);

    // Clamp between reasonable values
    return newFontSize.clamp(12.0, 48.0);
  }

  /// Reset pinch state
  void resetPinch() {
    _currentScale = 1.0;
  }

  /// Handle two-finger swipe gesture
  GestureType? handleTwoFingerSwipe(DragEndDetails details, int pointerCount) {
    if (!_gesturesEnabled ||
        !_multiFingerGesturesEnabled ||
        pointerCount != 2) {
      return null;
    }

    final velocity = details.primaryVelocity ?? 0;
    final threshold = 800 * (1.0 - _swipeSensitivity);

    if (velocity.abs() > threshold) {
      if (velocity > 0) {
        debugPrint('👆 GestureService: Two-finger swipe down (jump to top)');
        return GestureType.twoFingerSwipeDown;
      } else {
        debugPrint('👆 GestureService: Two-finger swipe up (jump to bottom)');
        return GestureType.twoFingerSwipeUp;
      }
    }

    return null;
  }

  /// Handle three-finger swipe gesture
  GestureType? handleThreeFingerSwipe(
      DragEndDetails details, int pointerCount) {
    if (!_gesturesEnabled ||
        !_multiFingerGesturesEnabled ||
        pointerCount != 3) {
      return null;
    }

    debugPrint('👆 GestureService: Three-finger swipe (bookmark)');
    return GestureType.threeFingerSwipe;
  }

  /// Get gesture description
  String getGestureDescription(GestureType type) {
    switch (type) {
      case GestureType.singleTap:
        return 'Single tap';
      case GestureType.doubleTap:
        return 'Double tap to play/pause';
      case GestureType.longPress:
        return 'Long press for options';
      case GestureType.swipeLeft:
        return 'Swipe left for next ayah';
      case GestureType.swipeRight:
        return 'Swipe right for previous ayah';
      case GestureType.swipeUp:
        return 'Swipe up to scroll';
      case GestureType.swipeDown:
        return 'Swipe down to scroll';
      case GestureType.pinch:
        return 'Pinch to adjust font size';
      case GestureType.twoFingerSwipeUp:
        return 'Two-finger swipe up to jump to bottom';
      case GestureType.twoFingerSwipeDown:
        return 'Two-finger swipe down to jump to top';
      case GestureType.threeFingerSwipe:
        return 'Three-finger swipe to bookmark';
    }
  }

  /// Save boolean preference
  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  /// Save double preference
  Future<void> _saveDouble(String key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(key, value);
  }

  /// Get gesture settings status
  Map<String, dynamic> getStatus() {
    return {
      'gesturesEnabled': _gesturesEnabled,
      'horizontalSwipeEnabled': _horizontalSwipeEnabled,
      'verticalSwipeEnabled': _verticalSwipeEnabled,
      'doubleTapEnabled': _doubleTapEnabled,
      'longPressEnabled': _longPressEnabled,
      'pinchEnabled': _pinchEnabled,
      'multiFingerGesturesEnabled': _multiFingerGesturesEnabled,
      'swipeSensitivity': _swipeSensitivity,
      'pinchSensitivity': _pinchSensitivity,
      'hapticFeedback': _hapticFeedback,
    };
  }
}

/// Gesture types
enum GestureType {
  singleTap,
  doubleTap,
  longPress,
  swipeLeft,
  swipeRight,
  swipeUp,
  swipeDown,
  pinch,
  twoFingerSwipeUp,
  twoFingerSwipeDown,
  threeFingerSwipe,
}

/// Global gesture service instance
final gestureService = GestureService();
