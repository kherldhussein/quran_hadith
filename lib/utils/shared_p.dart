import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';


/// Custom exceptions for Shared Preferences operations
class StorageException implements Exception {
  final String message;
  final String key;
  final dynamic error;

  StorageException({
    required this.message,
    required this.key,
    this.error,
  });

  @override
  String toString() =>
      'StorageException(key: $key, message: $message, error: $error)';
}

class StorageInitializationException implements Exception {
  final String message;

  StorageInitializationException(this.message);

  @override
  String toString() => 'StorageInitializationException: $message';
}

/// Enhanced Shared Preferences wrapper with comprehensive error handling,
/// type safety, and advanced features
class SharedP {
  static SharedPreferences? _sp;
  static bool _isInitialized = false;

  SharedP._internal();

  static final SharedP _instance = SharedP._internal();

  /// Get singleton instance
  factory SharedP() => _instance;


  /// Initialize Shared Preferences
  /// Throws [StorageInitializationException] if initialization fails
  Future<void> init() async {
    try {
      if (_sp != null) return;

      _sp = await SharedPreferences.getInstance();
      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
      debugPrint('⚠️ Failed to initialize SharedPreferences: $e');
    }
  }

  /// Check if storage is initialized
  bool get isInitialized => _isInitialized && _sp != null;

  /// Ensure storage is initialized before operations
  /// Auto-initializes if not ready (lazy initialization)
  Future<void> _ensureInitialized() async {
    if (!isInitialized) {
      try {
        await init();
      } catch (e) {
        debugPrint(
            '⚠️ Warning: Failed to auto-initialize SharedPreferences: $e');
      }
    }
  }


  int getInt(String key, {int defaultValue = 0}) {
    try {
      if (!isInitialized) {
        print(
            'Warning: SharedPreferences not initialized, returning default for $key');
        return defaultValue;
      }
      return _sp!.getInt(key) ?? defaultValue;
    } catch (e) {
      print('Error getting int for $key: $e');
      return defaultValue;
    }
  }

  List<String> getListString(String key,
      {List<String> defaultValue = const []}) {
    try {
      if (!isInitialized) {
        print(
            'Warning: SharedPreferences not initialized, returning default for $key');
        return defaultValue;
      }
      return _sp!.getStringList(key) ?? defaultValue;
    } catch (e) {
      print('Error getting string list for $key: $e');
      return defaultValue;
    }
  }

  bool getBool(String key, {bool defaultValue = false}) {
    try {
      if (!isInitialized) {
        print(
            'Warning: SharedPreferences not initialized, returning default for $key');
        return defaultValue;
      }
      return _sp!.getBool(key) ?? defaultValue;
    } catch (e) {
      print('Error getting bool for $key: $e');
      return defaultValue;
    }
  }

  String getString(String key, {String defaultValue = ''}) {
    try {
      if (!isInitialized) {
        print(
            'Warning: SharedPreferences not initialized, returning default for $key');
        return defaultValue;
      }
      return _sp!.getString(key) ?? defaultValue;
    } catch (e) {
      print('Error getting string for $key: $e');
      return defaultValue;
    }
  }

  double getDouble(String key, {double defaultValue = 0.0}) {
    try {
      if (!isInitialized) {
        print(
            'Warning: SharedPreferences not initialized, returning default for $key');
        return defaultValue;
      }
      return _sp!.getDouble(key) ?? defaultValue;
    } catch (e) {
      print('Error getting double for $key: $e');
      return defaultValue;
    }
  }


  Future<bool> setInt(String key, int value) async {
    try {
      await _ensureInitialized();
      if (!isInitialized) {
        print(
            'Warning: Cannot save int for $key - SharedPreferences not initialized');
        return false;
      }
      return await _sp!.setInt(key, value);
    } catch (e) {
      print('Error setting int for $key: $e');
      return false;
    }
  }

  Future<bool> setBool(String key, bool value) async {
    try {
      await _ensureInitialized();
      if (!isInitialized) {
        print(
            'Warning: Cannot save bool for $key - SharedPreferences not initialized');
        return false;
      }
      return await _sp!.setBool(key, value);
    } catch (e) {
      print('Error setting bool for $key: $e');
      return false;
    }
  }

  Future<bool> setString(String key, String value) async {
    try {
      await _ensureInitialized();
      if (!isInitialized) {
        print(
            'Warning: Cannot save string for $key - SharedPreferences not initialized');
        return false;
      }
      return await _sp!.setString(key, value);
    } catch (e) {
      print('Error setting string for $key: $e');
      return false;
    }
  }

  Future<bool> setListString(String key, List<String> value) async {
    try {
      await _ensureInitialized();
      if (!isInitialized) {
        print(
            'Warning: Cannot save string list for $key - SharedPreferences not initialized');
        return false;
      }
      return await _sp!.setStringList(key, value);
    } catch (e) {
      print('Error setting string list for $key: $e');
      return false;
    }
  }

  Future<bool> setDouble(String key, double value) async {
    try {
      await _ensureInitialized();
      if (!isInitialized) {
        print(
            'Warning: Cannot save double for $key - SharedPreferences not initialized');
        return false;
      }
      return await _sp!.setDouble(key, value);
    } catch (e) {
      print('Error setting double for $key: $e');
      return false;
    }
  }


  /// Check if a key exists
  bool containsKey(String key) {
    _ensureInitialized();
    try {
      return _sp!.containsKey(key);
    } catch (e) {
      throw StorageException(
        message: 'Failed to check if key exists',
        key: key,
        error: e,
      );
    }
  }

  /// Remove a specific key
  Future<bool> remove(String key) async {
    _ensureInitialized();
    try {
      return await _sp!.remove(key);
    } catch (e) {
      throw StorageException(
        message: 'Failed to remove key',
        key: key,
        error: e,
      );
    }
  }

  /// Get all keys
  Set<String> getKeys() {
    _ensureInitialized();
    try {
      return _sp!.getKeys();
    } catch (e) {
      throw StorageException(
        message: 'Failed to get all keys',
        key: 'ALL_KEYS',
        error: e,
      );
    }
  }

  /// Clear all data (use with caution!)
  Future<bool> clear() async {
    _ensureInitialized();
    try {
      return await _sp!.clear();
    } catch (e) {
      throw StorageException(
        message: 'Failed to clear all data',
        key: 'CLEAR_ALL',
        error: e,
      );
    }
  }

  /// Batch multiple operations atomically
  Future<List<bool>> batchOperations(Map<String, dynamic> operations) async {
    _ensureInitialized();
    try {
      final results = <Future<bool>>[];

      operations.forEach((key, value) {
        if (value is int) {
          results.add(setInt(key, value));
        } else if (value is bool) {
          results.add(setBool(key, value));
        } else if (value is String) {
          results.add(setString(key, value));
        } else if (value is List<String>) {
          results.add(setListString(key, value));
        } else if (value is double) {
          results.add(setDouble(key, value));
        } else if (value == null) {
          results.add(remove(key));
        }
      });

      return await Future.wait(results);
    } catch (e) {
      throw StorageException(
        message: 'Failed to execute batch operations',
        key: 'BATCH_OPERATIONS',
        error: e,
      );
    }
  }

  /// Increment an integer value
  Future<bool> increment(String key, {int incrementBy = 1}) async {
    _ensureInitialized();
    try {
      final currentValue = getInt(key);
      return await setInt(key, currentValue + incrementBy);
    } catch (e) {
      throw StorageException(
        message: 'Failed to increment value',
        key: key,
        error: e,
      );
    }
  }

  /// Toggle a boolean value
  Future<bool> toggle(String key) async {
    _ensureInitialized();
    try {
      final currentValue = getBool(key);
      return await setBool(key, !currentValue);
    } catch (e) {
      throw StorageException(
        message: 'Failed to toggle value',
        key: key,
        error: e,
      );
    }
  }

  /// Add an item to a string list
  Future<bool> addToList(String key, String value) async {
    _ensureInitialized();
    try {
      final currentList = getListString(key);
      if (!currentList.contains(value)) {
        currentList.add(value);
        return await setListString(key, currentList);
      }
      return true; // Already exists, no need to save
    } catch (e) {
      throw StorageException(
        message: 'Failed to add item to list',
        key: key,
        error: e,
      );
    }
  }

  /// Remove an item from a string list
  Future<bool> removeFromList(String key, String value) async {
    _ensureInitialized();
    try {
      final currentList = getListString(key);
      currentList.remove(value);
      return await setListString(key, currentList);
    } catch (e) {
      throw StorageException(
        message: 'Failed to remove item from list',
        key: key,
        error: e,
      );
    }
  }


  /// Get storage statistics
  Map<String, dynamic> getStorageStats() {
    _ensureInitialized();
    try {
      final keys = getKeys();
      final stats = <String, dynamic>{
        'totalKeys': keys.length,
        'keys': keys.toList(),
        'sizeEstimate': keys.length * 32, // Rough estimate
      };

      final typeCount = <String, int>{};
      for (final key in keys) {
        final type = _getValueType(key);
        typeCount[type] = (typeCount[type] ?? 0) + 1;
      }
      stats['typeCount'] = typeCount;

      return stats;
    } catch (e) {
      throw StorageException(
        message: 'Failed to get storage statistics',
        key: 'STATS',
        error: e,
      );
    }
  }

  /// Backup all data to a Map
  Map<String, dynamic> backupData() {
    _ensureInitialized();
    try {
      final backup = <String, dynamic>{};
      final keys = getKeys();

      for (final key in keys) {
        final value = _sp!.get(key);
        backup[key] = value;
      }

      return backup;
    } catch (e) {
      throw StorageException(
        message: 'Failed to backup data',
        key: 'BACKUP',
        error: e,
      );
    }
  }

  /// Restore data from backup Map
  Future<List<bool>> restoreData(Map<String, dynamic> backup) async {
    _ensureInitialized();
    try {
      return await batchOperations(backup);
    } catch (e) {
      throw StorageException(
        message: 'Failed to restore data from backup',
        key: 'RESTORE',
        error: e,
      );
    }
  }


  String _getValueType(String key) {
    final value = _sp!.get(key);
    if (value is int) return 'int';
    if (value is bool) return 'bool';
    if (value is String) return 'string';
    if (value is double) return 'double';
    if (value is List<String>) return 'stringList';
    return 'unknown';
  }
}

SharedP appSP = SharedP();
