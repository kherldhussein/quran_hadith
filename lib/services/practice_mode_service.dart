import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage recitation practice mode for memorization (Hifz)
class PracticeModeService extends ChangeNotifier {
  static final PracticeModeService _instance = PracticeModeService._internal();
  factory PracticeModeService() => _instance;
  PracticeModeService._internal();

  // Practice mode state
  bool _isPracticeModeActive = false;
  int? _practiceAyahNumber;
  int? _practiceSurahNumber;
  int _loopCount = 0;
  int _targetLoops = 3;
  int _pauseDuration = 2; // seconds between repetitions
  bool _showTranslation = false;
  bool _autoAdvance = false;

  // Recording state
  bool _isRecording = false;
  String? _recordingPath;
  final List<String> _recordings =
      []; // List of recording file paths for this ayah

  // Progress tracking
  Map<String, int> _ayahPracticeCount = {}; // "surah:ayah" -> practice count
  Map<String, DateTime> _lastPracticed =
      {}; // "surah:ayah" -> last practice date

  // Getters
  bool get isPracticeModeActive => _isPracticeModeActive;
  int? get practiceAyahNumber => _practiceAyahNumber;
  int? get practiceSurahNumber => _practiceSurahNumber;
  int get loopCount => _loopCount;
  int get targetLoops => _targetLoops;
  int get pauseDuration => _pauseDuration;
  bool get showTranslation => _showTranslation;
  bool get autoAdvance => _autoAdvance;
  bool get isRecording => _isRecording;
  List<String> get recordings => List.unmodifiable(_recordings);

  // Preferences keys
  static const String _keyTargetLoops = 'practice_target_loops';
  static const String _keyPauseDuration = 'practice_pause_duration';
  static const String _keyShowTranslation = 'practice_show_translation';
  static const String _keyAutoAdvance = 'practice_auto_advance';
  static const String _keyPracticeCount = 'practice_ayah_count';
  static const String _keyLastPracticed = 'practice_last_date';

  /// Initialize practice mode service
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    _targetLoops = prefs.getInt(_keyTargetLoops) ?? 3;
    _pauseDuration = prefs.getInt(_keyPauseDuration) ?? 2;
    _showTranslation = prefs.getBool(_keyShowTranslation) ?? false;
    _autoAdvance = prefs.getBool(_keyAutoAdvance) ?? false;

    // Load practice count map
    final practiceCountJson = prefs.getString(_keyPracticeCount);
    if (practiceCountJson != null) {
      try {
        final decoded = Map<String, dynamic>.from(
          Uri.splitQueryString(practiceCountJson),
        );
        _ayahPracticeCount = decoded.map((k, v) => MapEntry(k, int.parse(v)));
      } catch (e) {
        debugPrint('Error loading practice count: $e');
      }
    }

    // Load last practiced dates
    final lastPracticedJson = prefs.getString(_keyLastPracticed);
    if (lastPracticedJson != null) {
      try {
        final decoded = Map<String, dynamic>.from(
          Uri.splitQueryString(lastPracticedJson),
        );
        _lastPracticed = decoded.map(
          (k, v) => MapEntry(k, DateTime.parse(v)),
        );
      } catch (e) {
        debugPrint('Error loading last practiced dates: $e');
      }
    }

    notifyListeners();
    debugPrint('🎯 Practice Mode Service initialized');
  }

  /// Start practice mode for a specific ayah
  Future<void> startPracticeMode({
    required int surahNumber,
    required int ayahNumber,
  }) async {
    _isPracticeModeActive = true;
    _practiceSurahNumber = surahNumber;
    _practiceAyahNumber = ayahNumber;
    _loopCount = 0;

    // Load existing recordings for this ayah
    await _loadRecordings(surahNumber, ayahNumber);

    notifyListeners();
    debugPrint(
        '🎯 Practice mode started for Surah $surahNumber, Ayah $ayahNumber');
  }

  /// Stop practice mode
  Future<void> stopPracticeMode() async {
    _isPracticeModeActive = false;

    // Save practice progress
    if (_practiceSurahNumber != null && _practiceAyahNumber != null) {
      await _savePracticeProgress(_practiceSurahNumber!, _practiceAyahNumber!);
    }

    _practiceSurahNumber = null;
    _practiceAyahNumber = null;
    _loopCount = 0;
    _recordings.clear();

    notifyListeners();
    debugPrint('🎯 Practice mode stopped');
  }

  /// Increment loop count (called when ayah finishes playing)
  void incrementLoopCount() {
    _loopCount++;

    // Check if we've reached target loops and auto-advance is enabled
    if (_autoAdvance && _loopCount >= _targetLoops) {
      debugPrint('🎯 Target loops reached, advancing to next ayah');
      // The caller should handle advancing to next ayah
    }

    notifyListeners();
    debugPrint('🎯 Loop count: $_loopCount / $_targetLoops');
  }

  /// Reset loop count
  void resetLoopCount() {
    _loopCount = 0;
    notifyListeners();
  }

  /// Set target number of loops
  Future<void> setTargetLoops(int loops) async {
    _targetLoops = loops.clamp(1, 20);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTargetLoops, _targetLoops);
    notifyListeners();
    debugPrint('🎯 Target loops set to $_targetLoops');
  }

  /// Set pause duration between repetitions
  Future<void> setPauseDuration(int seconds) async {
    _pauseDuration = seconds.clamp(0, 10);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyPauseDuration, _pauseDuration);
    notifyListeners();
    debugPrint('🎯 Pause duration set to $_pauseDuration seconds');
  }

  /// Toggle showing translation during practice
  Future<void> toggleShowTranslation() async {
    _showTranslation = !_showTranslation;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowTranslation, _showTranslation);
    notifyListeners();
    debugPrint('🎯 Show translation: $_showTranslation');
  }

  /// Toggle auto-advance to next ayah after target loops
  Future<void> toggleAutoAdvance() async {
    _autoAdvance = !_autoAdvance;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoAdvance, _autoAdvance);
    notifyListeners();
    debugPrint('🎯 Auto-advance: $_autoAdvance');
  }

  /// Start recording user's recitation
  Future<bool> startRecording() async {
    if (_isRecording) return false;

    try {
      // TODO: Integrate with audio recording package
      _isRecording = true;
      notifyListeners();
      debugPrint('🎙️ Recording started');
      return true;
    } catch (e) {
      debugPrint('Error starting recording: $e');
      return false;
    }
  }

  /// Stop recording
  Future<String?> stopRecording() async {
    if (!_isRecording) return null;

    try {
      // TODO: Save recording file and return path
      _isRecording = false;

      // Mock recording path
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final recordingPath =
          'recordings/${_practiceSurahNumber}_${_practiceAyahNumber}_$timestamp.m4a';
      _recordingPath = recordingPath;
      _recordings.add(recordingPath);

      notifyListeners();
      debugPrint('🎙️ Recording stopped: $recordingPath');
      return recordingPath;
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      _isRecording = false;
      notifyListeners();
      return null;
    }
  }

  /// Load existing recordings for an ayah
  Future<void> _loadRecordings(int surahNumber, int ayahNumber) async {
    // TODO: Load recordings from storage
    _recordings.clear();
    debugPrint(
        '🎙️ Loaded recordings for Surah $surahNumber, Ayah $ayahNumber');
  }

  /// Delete a recording
  Future<bool> deleteRecording(String recordingPath) async {
    try {
      // TODO: Delete file from storage
      _recordings.remove(recordingPath);
      notifyListeners();
      debugPrint('🎙️ Recording deleted: $recordingPath');
      return true;
    } catch (e) {
      debugPrint('Error deleting recording: $e');
      return false;
    }
  }

  /// Save practice progress for an ayah
  Future<void> _savePracticeProgress(int surahNumber, int ayahNumber) async {
    final key = '$surahNumber:$ayahNumber';

    // Increment practice count
    _ayahPracticeCount[key] = (_ayahPracticeCount[key] ?? 0) + 1;

    // Update last practiced date
    _lastPracticed[key] = DateTime.now();

    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();

    final practiceCountString =
        _ayahPracticeCount.entries.map((e) => '${e.key}=${e.value}').join('&');
    await prefs.setString(_keyPracticeCount, practiceCountString);

    final lastPracticedString = _lastPracticed.entries
        .map((e) => '${e.key}=${e.value.toIso8601String()}')
        .join('&');
    await prefs.setString(_keyLastPracticed, lastPracticedString);

    debugPrint('🎯 Practice progress saved for $key');
  }

  /// Get practice count for a specific ayah
  int getPracticeCount(int surahNumber, int ayahNumber) {
    final key = '$surahNumber:$ayahNumber';
    return _ayahPracticeCount[key] ?? 0;
  }

  /// Get last practiced date for a specific ayah
  DateTime? getLastPracticedDate(int surahNumber, int ayahNumber) {
    final key = '$surahNumber:$ayahNumber';
    return _lastPracticed[key];
  }

  /// Check if an ayah needs practice (not practiced in last 7 days)
  bool needsPractice(int surahNumber, int ayahNumber) {
    final lastDate = getLastPracticedDate(surahNumber, ayahNumber);
    if (lastDate == null) return true;

    final daysSince = DateTime.now().difference(lastDate).inDays;
    return daysSince >= 7;
  }

  /// Get all ayahs that need practice
  List<String> getAyahsNeedingPractice() {
    final List<String> needsPracticeList = [];

    for (final entry in _lastPracticed.entries) {
      final daysSince = DateTime.now().difference(entry.value).inDays;
      if (daysSince >= 7) {
        needsPracticeList.add(entry.key);
      }
    }

    return needsPracticeList;
  }

  /// Get total practice time (all ayahs)
  int getTotalPracticeCount() {
    return _ayahPracticeCount.values.fold(0, (sum, count) => sum + count);
  }

  /// Get most practiced ayahs
  List<MapEntry<String, int>> getMostPracticedAyahs({int limit = 10}) {
    final sorted = _ayahPracticeCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }

  /// Check if target loops are completed
  bool isTargetCompleted() {
    return _loopCount >= _targetLoops;
  }

  /// Get progress percentage
  double getProgress() {
    if (_targetLoops == 0) return 0.0;
    return (_loopCount / _targetLoops).clamp(0.0, 1.0);
  }
}
