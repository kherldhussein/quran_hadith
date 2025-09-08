import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:quran_hadith/utils/sp_util.dart';

/// Represents a favorite item with additional metadata
class FavoriteItem {
  final String id;
  final String name;
  final String type; // 'surah', 'ayah', 'bookmark'
  final DateTime addedAt;
  final Map<String, dynamic>? metadata;

  FavoriteItem({
    required this.id,
    required this.name,
    this.type = 'surah',
    DateTime? addedAt,
    this.metadata,
  }) : addedAt = addedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'addedAt': addedAt.millisecondsSinceEpoch,
      'metadata': metadata,
    };
  }

  factory FavoriteItem.fromMap(Map<String, dynamic> map) {
    return FavoriteItem(
      id: map['id'],
      name: map['name'],
      type: map['type'] ?? 'surah',
      addedAt: DateTime.fromMillisecondsSinceEpoch(map['addedAt']),
      metadata: map['metadata'],
    );
  }

  @override
  String toString() => 'FavoriteItem(id: $id, name: $name, type: $type)';
}

/// Enhanced favorite manager with better state management and error handling
class FavoriteManager extends ChangeNotifier {
  bool _isFavorite = false;
  List<FavoriteItem> _favorites = [];
  bool _isLoading = false;
  String? _lastError;

  // Getters
  bool get isFavorite => _isFavorite;
  List<FavoriteItem> get favorites => List.unmodifiable(_favorites);
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  int get favoriteCount => _favorites.length;

  FavoriteManager() {
    _initialize();
  }

  // Initialize favorites from storage
  Future<void> _initialize() async {
    await _loadFavorites();
  }

  // Check if an item is favorited
  bool isFavorited(String itemId) {
    return _favorites.any((item) => item.id == itemId);
  }

  // Get favorite item by ID
  FavoriteItem? getFavorite(String itemId) {
    try {
      return _favorites.firstWhere((item) => item.id == itemId);
    } catch (e) {
      return null;
    }
  }

  // SIMPLIFIED: Get favorites list (for QPageView compatibility)
  Future<List<FavoriteItem>> getFavorites() async {
    if (_favorites.isEmpty) {
      await _loadFavorites();
    }
    return List<FavoriteItem>.from(_favorites);
  }

  // Load favorites from shared preferences
  Future<void> _loadFavorites() async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final favoriteStrings = SpUtil.getFavorites();
      _favorites = favoriteStrings.map((str) {
        try {
          final map = Map<String, dynamic>.from(json.decode(str));
          return FavoriteItem.fromMap(map);
        } catch (e) {
          // Fallback for legacy string format
          return FavoriteItem(id: str, name: str);
        }
      }).toList();

      _isFavorite = SpUtil.getFavorite();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _lastError = 'Failed to load favorites: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Add a favorite item with enhanced error handling and metadata support
  Future<bool> addFavorite({
    required String id,
    required String name,
    String type = 'surah',
    Map<String, dynamic>? metadata,
  }) async {
    if (isFavorited(id)) {
      return true; // Already favorited
    }

    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final newItem = FavoriteItem(
        id: id,
        name: name,
        type: type,
        metadata: metadata,
      );

      _favorites.add(newItem);
      _isFavorite = true;

      // Save to storage
      final success = await _saveFavoritesToStorage();

      if (!success) {
        _favorites.remove(newItem);
        throw Exception('Failed to save to storage');
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = 'Failed to add favorite: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Remove a favorite item - FIXED VERSION
  Future<bool> removeFavorite(String itemId) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final initialLength = _favorites.length;
      _favorites.removeWhere((item) => item.id == itemId);
      final removedCount = initialLength - _favorites.length;

      if (removedCount == 0) {
        _isLoading = false;
        notifyListeners();
        return true; // Item wasn't in favorites
      }

      _isFavorite = _favorites.isNotEmpty;

      final success = await _saveFavoritesToStorage();

      if (!success) {
        // Restore the item if save failed
        await _loadFavorites(); // Reload from storage
        throw Exception('Failed to save changes');
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = 'Failed to remove favorite: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Toggle favorite status - OPTIMIZED VERSION
  Future<bool> toggleFavorite({
    required String id,
    required String name,
    String type = 'surah',
    Map<String, dynamic>? metadata,
  }) async {
    // Quick synchronous check first
    if (isFavorited(id)) {
      return await removeFavorite(id);
    } else {
      return await addFavorite(
        id: id,
        name: name,
        type: type,
        metadata: metadata,
      );
    }
  }

  /// Clear all favorites
  Future<bool> clearAllFavorites() async {
    _isLoading = true;
    notifyListeners();

    try {
      final previousFavorites = List<FavoriteItem>.from(_favorites);
      _favorites.clear();
      _isFavorite = false;

      final success = await _saveFavoritesToStorage();

      if (!success) {
        _favorites = previousFavorites;
        _isFavorite = previousFavorites.isNotEmpty;
        throw Exception('Failed to clear favorites from storage');
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = 'Failed to clear favorites: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Reorder favorites
  Future<bool> reorderFavorites(int oldIndex, int newIndex) async {
    if (oldIndex < 0 ||
        oldIndex >= _favorites.length ||
        newIndex < 0 ||
        newIndex >= _favorites.length) {
      return false;
    }

    final previousOrder = List<FavoriteItem>.from(_favorites);

    try {
      final item = _favorites.removeAt(oldIndex);
      _favorites.insert(newIndex, item);

      final success = await _saveFavoritesToStorage();

      if (!success) {
        _favorites = previousOrder;
        throw Exception('Failed to save reordered favorites');
      }

      notifyListeners();
      return true;
    } catch (e) {
      _favorites = previousOrder;
      _lastError = 'Failed to reorder favorites: $e';
      notifyListeners();
      return false;
    }
  }

  /// Search favorites by name or metadata
  List<FavoriteItem> searchFavorites(String query) {
    if (query.isEmpty) return _favorites;

    final lowercaseQuery = query.toLowerCase();
    return _favorites.where((item) {
      return item.name.toLowerCase().contains(lowercaseQuery) ||
          item.id.toLowerCase().contains(lowercaseQuery) ||
          (item.metadata?.values.any((value) =>
                  value.toString().toLowerCase().contains(lowercaseQuery)) ??
              false);
    }).toList();
  }

  /// Get favorites by type
  List<FavoriteItem> getFavoritesByType(String type) {
    return _favorites.where((item) => item.type == type).toList();
  }

  /// Get ayah favorites for a specific surah (QPageView compatibility)
  List<FavoriteItem> getAyahFavoritesForSurah(int surahNumber) {
    return _favorites.where((item) {
      return item.type == 'ayah' && item.metadata?['surah'] == surahNumber;
    }).toList();
  }

  // Private method to save favorites to storage
  Future<bool> _saveFavoritesToStorage() async {
    try {
      final favoriteStrings =
          _favorites.map((item) => json.encode(item.toMap())).toList();
      final results = await Future.wait([
        SpUtil.setFavorites(favoriteStrings),
        SpUtil.setFavorite(_isFavorite),
      ]);
      return results.every((result) => result);
    } catch (e) {
      _lastError = 'Storage error: $e';
      return false;
    }
  }

  /// Clear any error state
  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  /// Refresh favorites from storage
  Future<void> refresh() async {
    await _loadFavorites();
  }
}
