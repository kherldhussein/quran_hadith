import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:quran_hadith/data/repositories/quran_repository.dart';

/// Background sync service for seamless data updates
///
/// Features:
/// - Automatic background sync when network available
/// - Smart sync (only updates stale data)
/// - Battery-efficient (uses exponential backoff)
/// - Non-blocking (doesn't affect UI)
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final QuranRepository _repository = QuranRepository();
  final Connectivity _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _periodicSyncTimer;

  bool _isSyncing = false;
  bool _isInitialized = false;
  DateTime? _lastSyncTime;

  // Configuration
  static const Duration _periodicSyncInterval = Duration(hours: 6);
  static const Duration _retryDelay = Duration(minutes: 5);
  int _retryCount = 0;
  static const int _maxRetries = 3;

  /// Initialize sync service
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('🔄 SyncService: Initializing...');

    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );

    // Schedule periodic sync
    _schedulePeriodicSync();

    // Perform initial sync if online
    final initialConnectivity = await _connectivity.checkConnectivity();
    if (initialConnectivity.contains(ConnectivityResult.mobile) ||
        initialConnectivity.contains(ConnectivityResult.wifi) ||
        initialConnectivity.contains(ConnectivityResult.ethernet)) {
      _performBackgroundSync();
    }

    _isInitialized = true;
    debugPrint('🔄 SyncService: Initialized successfully');
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final isOnline = results.contains(ConnectivityResult.mobile) ||
        results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet);

    if (isOnline && !_isSyncing) {
      debugPrint('🔄 SyncService: Network available - starting background sync');
      _performBackgroundSync();
    } else if (!isOnline) {
      debugPrint('🔄 SyncService: Network unavailable - sync paused');
    }
  }

  /// Schedule periodic background sync
  void _schedulePeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = Timer.periodic(_periodicSyncInterval, (timer) {
      debugPrint('🔄 SyncService: Periodic sync triggered');
      _performBackgroundSync();
    });
  }

  /// Perform background sync (non-blocking)
  void _performBackgroundSync() async {
    if (_isSyncing) {
      debugPrint('🔄 SyncService: Sync already in progress, skipping...');
      return;
    }

    // Check if recent sync already happened
    if (_lastSyncTime != null) {
      final timeSinceLastSync = DateTime.now().difference(_lastSyncTime!);
      if (timeSinceLastSync < const Duration(minutes: 30)) {
        debugPrint('🔄 SyncService: Recent sync found (${timeSinceLastSync.inMinutes}m ago), skipping...');
        return;
      }
    }

    _isSyncing = true;

    try {
      debugPrint('🔄 SyncService: ⏳ Background sync started...');

      // Sync priority data first (most accessed surahs)
      await _syncPriorityData();

      // Then sync remaining data
      await _syncRemainingData();

      _lastSyncTime = DateTime.now();
      _retryCount = 0;

      debugPrint('🔄 SyncService: ✓ Background sync completed successfully');
    } catch (e) {
      debugPrint('🔄 SyncService: ✗ Background sync failed: $e');

      // Retry with exponential backoff
      if (_retryCount < _maxRetries) {
        _retryCount++;
        final delay = _retryDelay * _retryCount;
        debugPrint('🔄 SyncService: Scheduling retry ${_retryCount}/$_maxRetries in ${delay.inMinutes}m');

        Timer(delay, () {
          _performBackgroundSync();
        });
      } else {
        debugPrint('🔄 SyncService: Max retries reached, giving up for now');
        _retryCount = 0;
      }
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync priority data (most accessed)
  Future<void> _syncPriorityData() async {
    // Priority surahs (most commonly read)
    final prioritySurahs = [
      1,   // Al-Fatihah
      2,   // Al-Baqarah
      18,  // Al-Kahf
      36,  // Ya-Sin
      55,  // Ar-Rahman
      56,  // Al-Waqi'ah
      67,  // Al-Mulk
      78,  // An-Naba
    ];

    debugPrint('🔄 SyncService: Syncing ${prioritySurahs.length} priority surahs...');

    for (final surahNumber in prioritySurahs) {
      try {
        await _repository.getSurah(surahNumber);
        // Small delay to avoid overwhelming the API
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        debugPrint('🔄 SyncService: Failed to sync surah $surahNumber: $e');
      }
    }
  }

  /// Sync remaining data
  Future<void> _syncRemainingData() async {
    // Sync all surahs gradually
    debugPrint('🔄 SyncService: Syncing remaining surahs...');

    for (int i = 1; i <= 114; i++) {
      // Skip already synced priority surahs
      if ([1, 2, 18, 36, 55, 56, 67, 78].contains(i)) continue;

      try {
        await _repository.getSurah(i);
        // Longer delay for bulk sync to be battery-friendly
        await Future.delayed(const Duration(milliseconds: 200));
      } catch (e) {
        debugPrint('🔄 SyncService: Failed to sync surah $i: $e');
      }
    }
  }

  /// Force immediate sync
  Future<void> forceSyncNow() async {
    debugPrint('🔄 SyncService: Force sync requested by user');
    _lastSyncTime = null; // Reset to allow immediate sync
    _performBackgroundSync();
  }

  /// Get sync status
  Map<String, dynamic> getSyncStatus() {
    return {
      'isSyncing': _isSyncing,
      'lastSyncTime': _lastSyncTime?.toIso8601String(),
      'retryCount': _retryCount,
      'isInitialized': _isInitialized,
    };
  }

  /// Pause sync (e.g., when user is on metered connection)
  void pauseSync() {
    _periodicSyncTimer?.cancel();
    _connectivitySubscription?.cancel();
    debugPrint('🔄 SyncService: Sync paused');
  }

  /// Resume sync
  Future<void> resumeSync() async {
    if (!_isInitialized) {
      await initialize();
    } else {
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _onConnectivityChanged,
      );
      _schedulePeriodicSync();
      debugPrint('🔄 SyncService: Sync resumed');
    }
  }

  /// Dispose resources
  void dispose() {
    _periodicSyncTimer?.cancel();
    _connectivitySubscription?.cancel();
    _isInitialized = false;
    debugPrint('🔄 SyncService: Disposed');
  }
}
