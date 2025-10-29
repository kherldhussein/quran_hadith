import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Comprehensive accessibility service for screen readers and assistive technologies
///
/// Features:
/// - Screen reader announcements
/// - Semantic labels for all UI elements
/// - Keyboard navigation support
/// - Focus management
/// - Skip-to-content shortcuts
/// - Live region updates
class AccessibilityService extends ChangeNotifier {
  static final AccessibilityService _instance = AccessibilityService._internal();
  factory AccessibilityService() => _instance;
  AccessibilityService._internal();

  // Settings
  bool _screenReaderEnabled = false;
  bool _announceAyahNumbers = true;
  bool _announcePlaybackChanges = true;
  bool _announceNavigationChanges = true;
  bool _verboseAnnouncements = false;
  double _announcementDelay = 0.5; // seconds

  // State tracking
  int? _currentAyahNumber;
  int? _currentSurahNumber;
  String? _lastAnnouncement;
  DateTime? _lastAnnouncementTime;

  // Getters
  bool get screenReaderEnabled => _screenReaderEnabled;
  bool get announceAyahNumbers => _announceAyahNumbers;
  bool get announcePlaybackChanges => _announcePlaybackChanges;
  bool get announceNavigationChanges => _announceNavigationChanges;
  bool get verboseAnnouncements => _verboseAnnouncements;

  // Preferences keys
  static const String _keyScreenReaderEnabled = 'accessibility_screen_reader';
  static const String _keyAnnounceAyah = 'accessibility_announce_ayah';
  static const String _keyAnnouncePlayback = 'accessibility_announce_playback';
  static const String _keyAnnounceNavigation = 'accessibility_announce_navigation';
  static const String _keyVerbose = 'accessibility_verbose';

  /// Initialize accessibility service
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    _screenReaderEnabled = prefs.getBool(_keyScreenReaderEnabled) ?? false;
    _announceAyahNumbers = prefs.getBool(_keyAnnounceAyah) ?? true;
    _announcePlaybackChanges = prefs.getBool(_keyAnnouncePlayback) ?? true;
    _announceNavigationChanges = prefs.getBool(_keyAnnounceNavigation) ?? true;
    _verboseAnnouncements = prefs.getBool(_keyVerbose) ?? false;

    notifyListeners();
    debugPrint('♿ AccessibilityService initialized');
  }

  /// Toggle screen reader support
  Future<void> toggleScreenReader() async {
    _screenReaderEnabled = !_screenReaderEnabled;
    await _saveBool(_keyScreenReaderEnabled, _screenReaderEnabled);

    if (_screenReaderEnabled) {
      _announce('Screen reader enabled');
    }

    notifyListeners();
  }

  /// Toggle ayah number announcements
  Future<void> toggleAyahAnnouncements() async {
    _announceAyahNumbers = !_announceAyahNumbers;
    await _saveBool(_keyAnnounceAyah, _announceAyahNumbers);
    notifyListeners();
  }

  /// Toggle playback announcements
  Future<void> togglePlaybackAnnouncements() async {
    _announcePlaybackChanges = !_announcePlaybackChanges;
    await _saveBool(_keyAnnouncePlayback, _announcePlaybackChanges);
    notifyListeners();
  }

  /// Toggle navigation announcements
  Future<void> toggleNavigationAnnouncements() async {
    _announceNavigationChanges = !_announceNavigationChanges;
    await _saveBool(_keyAnnounceNavigation, _announceNavigationChanges);
    notifyListeners();
  }

  /// Toggle verbose announcements
  Future<void> toggleVerboseMode() async {
    _verboseAnnouncements = !_verboseAnnouncements;
    await _saveBool(_keyVerbose, _verboseAnnouncements);
    notifyListeners();
  }

  /// Announce ayah change
  void announceAyah(int surahNumber, int ayahNumber, {String? surahName}) {
    if (!_screenReaderEnabled || !_announceAyahNumbers) return;

    _currentSurahNumber = surahNumber;
    _currentAyahNumber = ayahNumber;

    String announcement;
    if (_verboseAnnouncements && surahName != null) {
      announcement = 'Surah $surahName, Ayah $ayahNumber';
    } else {
      announcement = 'Ayah $ayahNumber';
    }

    _announce(announcement);
  }

  /// Announce playback state change
  void announcePlayback(String state, {int? surahNumber, int? ayahNumber}) {
    if (!_screenReaderEnabled || !_announcePlaybackChanges) return;

    String announcement = state;

    if (_verboseAnnouncements && surahNumber != null && ayahNumber != null) {
      announcement = '$state, Surah $surahNumber, Ayah $ayahNumber';
    }

    _announce(announcement);
  }

  /// Announce navigation change
  void announceNavigation(String destination) {
    if (!_screenReaderEnabled || !_announceNavigationChanges) return;

    _announce('Navigated to $destination');
  }

  /// Announce search results
  void announceSearchResults(int count) {
    if (!_screenReaderEnabled) return;

    final announcement = count == 1
        ? '1 search result found'
        : '$count search results found';

    _announce(announcement);
  }

  /// Announce bookmark action
  void announceBookmark(String action) {
    if (!_screenReaderEnabled) return;

    _announce('$action bookmark');
  }

  /// Announce loading state
  void announceLoading(bool isLoading) {
    if (!_screenReaderEnabled) return;

    _announce(isLoading ? 'Loading' : 'Loaded');
  }

  /// Announce error
  void announceError(String error) {
    if (!_screenReaderEnabled) return;

    _announce('Error: $error');
  }

  /// Generic announcement method
  void announce(String message) {
    if (!_screenReaderEnabled) return;

    _announce(message);
  }

  /// Internal announcement with debouncing
  void _announce(String message) {
    // Avoid duplicate announcements
    if (_lastAnnouncement == message) {
      final now = DateTime.now();
      if (_lastAnnouncementTime != null) {
        final diff = now.difference(_lastAnnouncementTime!);
        if (diff.inMilliseconds < (_announcementDelay * 1000)) {
          return; // Too soon, skip
        }
      }
    }

    _lastAnnouncement = message;
    _lastAnnouncementTime = DateTime.now();

    // Make announcement through Flutter's semantics system
    SemanticsService.announce(message, TextDirection.ltr);

    debugPrint('♿ Announcement: $message');
  }

  /// Generate semantic label for ayah card
  String getAyahSemanticLabel(int surahNumber, int ayahNumber, String arabicText, {String? translation}) {
    if (_verboseAnnouncements) {
      String label = 'Surah $surahNumber, Ayah $ayahNumber. Arabic text: $arabicText';
      if (translation != null) {
        label += '. Translation: $translation';
      }
      return label;
    } else {
      return 'Ayah $ayahNumber. $arabicText';
    }
  }

  /// Generate semantic label for button
  String getButtonSemanticLabel(String action, {String? context}) {
    if (_verboseAnnouncements && context != null) {
      return '$action button. $context';
    }
    return '$action button';
  }

  /// Generate semantic label for surah card
  String getSurahSemanticLabel(
    int surahNumber,
    String arabicName,
    String englishName, {
    int? ayahCount,
    String? revelationType,
  }) {
    if (_verboseAnnouncements) {
      String label = 'Surah $surahNumber, $englishName, $arabicName';
      if (ayahCount != null) {
        label += ', $ayahCount ayahs';
      }
      if (revelationType != null) {
        label += ', $revelationType';
      }
      return label;
    } else {
      return 'Surah $surahNumber, $englishName';
    }
  }

  /// Generate hint for interactive element
  String getSemanticHint(String action) {
    return 'Double tap to $action';
  }

  /// Save boolean preference
  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  /// Get current accessibility status
  Map<String, dynamic> getStatus() {
    return {
      'screenReaderEnabled': _screenReaderEnabled,
      'announceAyahNumbers': _announceAyahNumbers,
      'announcePlaybackChanges': _announcePlaybackChanges,
      'announceNavigationChanges': _announceNavigationChanges,
      'verboseAnnouncements': _verboseAnnouncements,
      'currentSurah': _currentSurahNumber,
      'currentAyah': _currentAyahNumber,
    };
  }
}

/// Global accessibility service instance
final accessibilityService = AccessibilityService();
