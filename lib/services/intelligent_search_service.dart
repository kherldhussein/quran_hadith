import 'package:flutter/foundation.dart';
import 'package:quran_hadith/models/search/ayah.dart';
import 'package:quran_hadith/controller/search.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Enhanced search modes
enum SearchMode {
  text, // Standard text search
  fuzzy, // Fuzzy search with typo tolerance
  root, // Arabic root letters search
  topic, // Search by topic/theme
  characteristics, // Search by surah characteristics
}

/// Search result with relevance scoring
class SearchResult {
  final Aya ayah;
  final double relevance;
  final String highlightedText;
  final List<String> matchedTerms;
  final String matchType; // 'exact', 'fuzzy', 'root', 'topic'

  SearchResult({
    required this.ayah,
    required this.relevance,
    required this.highlightedText,
    required this.matchedTerms,
    required this.matchType,
  });

  Map<String, dynamic> toJson() => {
        'ayah': ayah,
        'surah': ayah.surah,
        'ayahNumber': ayah.num,
        'relevance': relevance,
        'matchType': matchType,
      };
}

/// Intelligent search service with advanced features
class IntelligentSearchService extends ChangeNotifier {
  static final IntelligentSearchService _instance =
      IntelligentSearchService._internal();
  factory IntelligentSearchService() => _instance;
  IntelligentSearchService._internal();

  final Search _basicSearch = Search();
  bool _isInitialized = false;

  // Search history
  List<String> _searchHistory = [];
  List<String> _savedSearches = [];

  // Topic/theme mappings (simplified - in production, load from database)
  final Map<String, List<String>> _topicKeywords = {
    'prayer': ['صلاة', 'الصلاة', 'يصلون', 'صلوا'],
    'charity': ['زكاة', 'الزكاة', 'صدقة', 'انفقوا'],
    'paradise': ['جنة', 'الجنة', 'جنات', 'فردوس'],
    'hellfire': ['نار', 'النار', 'جهنم', 'حطمة'],
    'patience': ['صبر', 'الصبر', 'صابرين', 'اصبروا'],
    'gratitude': ['شكر', 'الشكر', 'اشكروا', 'شاكرين'],
    'forgiveness': ['مغفرة', 'غفور', 'غفران', 'استغفر'],
    'mercy': ['رحمة', 'الرحمة', 'رحيم', 'رحمن'],
  };

  // Surah characteristics
  final Map<String, List<int>> _surahCharacteristics = {
    'makki': [
      1,
      6,
      7,
      10,
      11,
      12,
      15,
      17,
      18,
      19,
      20,
      21,
      23,
      25,
      26,
      27,
      28,
      29,
      30,
      31,
      32,
      34,
      35,
      36,
      37,
      38,
      39,
      40,
      41,
      42,
      43,
      44,
      45,
      46,
      50,
      51,
      52,
      53,
      54,
      55,
      56,
      67,
      68,
      69,
      70,
      71,
      72,
      73,
      74,
      75,
      76,
      77,
      78,
      79,
      80,
      81,
      82,
      83,
      84,
      85,
      86,
      87,
      88,
      89,
      90,
      91,
      92,
      93,
      94,
      95,
      96,
      97,
      100,
      101,
      102,
      103,
      104,
      105,
      106,
      107,
      108,
      109,
      111,
      112,
      113,
      114
    ],
    'madani': [
      2,
      3,
      4,
      5,
      8,
      9,
      13,
      14,
      16,
      22,
      24,
      33,
      47,
      48,
      49,
      57,
      58,
      59,
      60,
      61,
      62,
      63,
      64,
      65,
      66,
      98,
      99,
      110
    ],
  };

  // Arabic root patterns (simplified)
  final Map<String, List<String>> _rootVariations = {
    'كتب': ['كتب', 'كتاب', 'كاتب', 'مكتوب', 'يكتب', 'الكتاب'],
    'علم': ['علم', 'عالم', 'معلم', 'علماء', 'يعلم', 'العلم'],
    'قرأ': ['قرأ', 'قرآن', 'قارئ', 'يقرأ', 'القرآن'],
  };

  // Getters
  bool get isInitialized => _isInitialized;
  List<String> get searchHistory => List.unmodifiable(_searchHistory);
  List<String> get savedSearches => List.unmodifiable(_savedSearches);

  // Preferences keys
  static const String _keySearchHistory = 'search_history';
  static const String _keySavedSearches = 'search_saved';

  /// Initialize the intelligent search service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Load surah data for basic search
    await _basicSearch.loadSurah();

    // Load search history
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_keySearchHistory);
    if (historyJson != null) {
      _searchHistory = List<String>.from(json.decode(historyJson));
    }

    final savedJson = prefs.getString(_keySavedSearches);
    if (savedJson != null) {
      _savedSearches = List<String>.from(json.decode(savedJson));
    }

    _isInitialized = true;
    notifyListeners();
    debugPrint('🔍 Intelligent Search Service initialized');
  }

  /// Perform intelligent search with multiple modes
  Future<List<SearchResult>> search(
    String query, {
    SearchMode mode = SearchMode.text,
    bool fuzzyTolerance = true,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (query.trim().isEmpty) {
      return [];
    }

    // Add to search history
    await _addToHistory(query);

    List<SearchResult> results = [];

    switch (mode) {
      case SearchMode.text:
        results = await _textSearch(query, fuzzyTolerance);
        break;
      case SearchMode.fuzzy:
        results = await _fuzzySearch(query);
        break;
      case SearchMode.root:
        results = await _rootSearch(query);
        break;
      case SearchMode.topic:
        results = await _topicSearch(query);
        break;
      case SearchMode.characteristics:
        results = await _characteristicsSearch(query);
        break;
    }

    // Sort by relevance
    results.sort((a, b) => b.relevance.compareTo(a.relevance));

    debugPrint('🔍 Search completed: ${results.length} results for "$query"');
    return results;
  }

  /// Standard text search with exact matching
  Future<List<SearchResult>> _textSearch(
      String query, bool fuzzyEnabled) async {
    final List<SearchResult> results = [];
    final normalized = _basicSearch.normalise(query.trim());

    for (var surah in _basicSearch.surahList) {
      for (int i = 1; i < surah.ayahCount! + 1; i++) {
        final verse = surah.verses!['verse_$i'].toString();
        final normalizedVerse = _basicSearch.normalise(verse);

        if (normalizedVerse.contains(normalized)) {
          // Exact match - high relevance
          results.add(SearchResult(
            ayah: Aya(i, verse, surah.name),
            relevance: 1.0,
            highlightedText: _highlightMatch(verse, query),
            matchedTerms: [query],
            matchType: 'exact',
          ));
        } else if (fuzzyEnabled) {
          // Check for fuzzy match
          final fuzzyScore = _calculateFuzzyScore(normalized, normalizedVerse);
          if (fuzzyScore > 0.6) {
            results.add(SearchResult(
              ayah: Aya(i, verse, surah.name),
              relevance: fuzzyScore * 0.8, // Reduce relevance for fuzzy
              highlightedText: verse,
              matchedTerms: [query],
              matchType: 'fuzzy',
            ));
          }
        }
      }
    }

    return results;
  }

  /// Fuzzy search with typo tolerance
  Future<List<SearchResult>> _fuzzySearch(String query) async {
    return await _textSearch(query, true);
  }

  /// Search by Arabic root letters
  Future<List<SearchResult>> _rootSearch(String query) async {
    final List<SearchResult> results = [];
    final normalized = _basicSearch.normalise(query.trim());

    // Check if query matches any known root
    List<String> variations = [];
    for (var entry in _rootVariations.entries) {
      if (_basicSearch.normalise(entry.key).contains(normalized)) {
        variations = entry.value;
        break;
      }
    }

    if (variations.isEmpty) {
      variations = [query]; // Fallback to direct search
    }

    // Search for all variations
    for (var variation in variations) {
      final normalizedVariation = _basicSearch.normalise(variation);

      for (var surah in _basicSearch.surahList) {
        for (int i = 1; i < surah.ayahCount! + 1; i++) {
          final verse = surah.verses!['verse_$i'].toString();
          final normalizedVerse = _basicSearch.normalise(verse);

          if (normalizedVerse.contains(normalizedVariation)) {
            results.add(SearchResult(
              ayah: Aya(i, verse, surah.name),
              relevance: 0.9,
              highlightedText: _highlightMatch(verse, variation),
              matchedTerms: [variation],
              matchType: 'root',
            ));
          }
        }
      }
    }

    return results;
  }

  /// Search by topic/theme
  Future<List<SearchResult>> _topicSearch(String query) async {
    final List<SearchResult> results = [];
    final normalized = query.toLowerCase().trim();

    // Find topic keywords
    List<String> keywords = [];
    for (var entry in _topicKeywords.entries) {
      if (entry.key.contains(normalized) || normalized.contains(entry.key)) {
        keywords = entry.value;
        break;
      }
    }

    if (keywords.isEmpty) {
      return []; // No matching topic found
    }

    // Search for all keywords in the topic
    for (var keyword in keywords) {
      final keywordResults = await _textSearch(keyword, false);
      results.addAll(keywordResults.map((r) => SearchResult(
            ayah: r.ayah,
            relevance: 0.85,
            highlightedText: r.highlightedText,
            matchedTerms: [keyword],
            matchType: 'topic',
          )));
    }

    return results;
  }

  /// Search by surah characteristics (Makki/Madani, etc.)
  Future<List<SearchResult>> _characteristicsSearch(String query) async {
    final List<SearchResult> results = [];
    final normalized = query.toLowerCase().trim();

    List<int> surahNumbers = [];
    if (normalized.contains('makk') || normalized.contains('مك')) {
      surahNumbers = _surahCharacteristics['makki']!;
    } else if (normalized.contains('madan') || normalized.contains('مدن')) {
      surahNumbers = _surahCharacteristics['madani']!;
    }

    if (surahNumbers.isEmpty) {
      return [];
    }

    // Return all ayahs from matching surahs
    for (var surahNum in surahNumbers) {
      if (surahNum <= _basicSearch.surahList.length) {
        final surah = _basicSearch.surahList[surahNum - 1];
        for (int i = 1; i < surah.ayahCount! + 1; i++) {
          final verse = surah.verses!['verse_$i'].toString();
          results.add(SearchResult(
            ayah: Aya(i, verse, surah.name),
            relevance: 0.7,
            highlightedText: verse,
            matchedTerms: [query],
            matchType: 'characteristics',
          ));
        }
      }
    }

    return results;
  }

  /// Calculate fuzzy match score using Levenshtein distance
  double _calculateFuzzyScore(String query, String text) {
    if (text.contains(query)) return 1.0;

    // Simple word-based fuzzy matching
    final queryWords = query.split(' ');
    final textWords = text.split(' ');

    int matches = 0;
    for (var qWord in queryWords) {
      for (var tWord in textWords) {
        if (_levenshteinDistance(qWord, tWord) <= 2) {
          matches++;
          break;
        }
      }
    }

    return matches / queryWords.length;
  }

  /// Calculate Levenshtein distance between two strings
  int _levenshteinDistance(String s1, String s2) {
    if (s1.length > s2.length) {
      final temp = s1;
      s1 = s2;
      s2 = temp;
    }

    final len1 = s1.length;
    final len2 = s2.length;

    List<int> costs = List.generate(len1 + 1, (i) => i);

    for (int j = 1; j <= len2; j++) {
      int prev = j;
      for (int i = 1; i <= len1; i++) {
        int temp = costs[i];
        costs[i] = s1[i - 1] == s2[j - 1]
            ? costs[i - 1]
            : 1 +
                [costs[i - 1], prev, costs[i]].reduce((a, b) => a < b ? a : b);
        prev = temp;
      }
    }

    return costs[len1];
  }

  /// Highlight matched text in the verse
  String _highlightMatch(String text, String query) {
    // For now, return the text as-is
    // In production, you might want to return a TextSpan or similar
    return text;
  }

  /// Add query to search history
  Future<void> _addToHistory(String query) async {
    if (_searchHistory.contains(query)) {
      _searchHistory.remove(query);
    }

    _searchHistory.insert(0, query);

    // Keep only last 20 searches
    if (_searchHistory.length > 20) {
      _searchHistory = _searchHistory.take(20).toList();
    }

    await _saveHistory();
    notifyListeners();
  }

  /// Save a search for later
  Future<void> saveSearch(String query) async {
    if (!_savedSearches.contains(query)) {
      _savedSearches.add(query);
      await _saveSavedSearches();
      notifyListeners();
    }
  }

  /// Remove a saved search
  Future<void> removeSavedSearch(String query) async {
    _savedSearches.remove(query);
    await _saveSavedSearches();
    notifyListeners();
  }

  /// Clear search history
  Future<void> clearHistory() async {
    _searchHistory.clear();
    await _saveHistory();
    notifyListeners();
  }

  /// Save history to preferences
  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySearchHistory, json.encode(_searchHistory));
  }

  /// Save saved searches to preferences
  Future<void> _saveSavedSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySavedSearches, json.encode(_savedSearches));
  }

  /// Get search suggestions based on history
  List<String> getSuggestions(String partialQuery) {
    if (partialQuery.isEmpty) return _searchHistory;

    return _searchHistory
        .where(
            (query) => query.toLowerCase().contains(partialQuery.toLowerCase()))
        .toList();
  }

  /// Cross-reference with hadith (placeholder)
  Future<List<String>> crossReferenceWithHadith(String query) async {
    // TODO: Implement hadith cross-referencing
    debugPrint('🔍 Cross-referencing with hadith: $query');
    return [];
  }
}
