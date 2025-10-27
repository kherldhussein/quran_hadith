import 'package:flutter/foundation.dart';

/// Enum for categorizing errors by severity
enum ErrorSeverity {
  /// Non-critical errors that don't block functionality (e.g., cache miss)
  low,

  /// Important errors that degrade user experience (e.g., failed API call with fallback)
  medium,

  /// Critical errors that require user attention or app restart (e.g., database corruption)
  high,

  /// Fatal errors that crash the app
  critical,
}

/// Error recovery suggestion data
class ErrorRecoverySuggestion {
  final String message;
  final VoidCallback? action;
  final String? actionLabel;

  ErrorRecoverySuggestion({
    required this.message,
    this.action,
    this.actionLabel,
  });
}

/// Enhanced centralized service for reporting and handling errors.
///
/// Features:
/// - Error categorization by severity and type
/// - Automatic error recovery suggestions
/// - Contextual error information
/// - Integration ready for services like Sentry or Firebase Crashlytics
class ErrorService {
  // Error tracking for analytics
  int _totalErrorsReported = 0;
  final List<String> _errorHistory = [];
  static const int _maxErrorHistorySize = 100;

  /// Reports an error with severity level, optional context, and recovery suggestions.
  ///
  /// Parameters:
  /// - error: The error object or message
  /// - stackTrace: Optional stack trace for debugging
  /// - severity: Error severity level (defaults to high)
  /// - context: Additional context about where the error occurred
  /// - recoveryAction: Optional callback for automatic recovery
  void reportError(
    dynamic error,
    StackTrace? stackTrace, {
    ErrorSeverity severity = ErrorSeverity.high,
    String? context,
    VoidCallback? recoveryAction,
  }) {
    _totalErrorsReported++;

    // Extract error information
    final errorMessage = _extractErrorMessage(error);
    final errorType = _categorizeError(error);
    final timestamp = DateTime.now().toIso8601String();

    // Build detailed error log
    final logEntry = _buildErrorLog(
      errorMessage,
      errorType,
      severity,
      context,
      stackTrace,
      timestamp,
    );

    // Add to history for analytics
    _addToErrorHistory(logEntry);

    // Log to console with appropriate emoji indicators
    _logToConsole(logEntry, severity);

    // Attempt recovery if applicable
    if (recoveryAction != null) {
      _attemptRecovery(error, recoveryAction, context);
    }

    // Integration point for Sentry/Firebase (commented out - ready to implement)
    // _reportToRemoteService(logEntry, severity);
  }

  /// Get error recovery suggestions based on error type
  ErrorRecoverySuggestion? getRecoverySuggestion(
    dynamic error,
    String? context,
  ) {
    final errorString = error.toString().toLowerCase();

    // Network errors
    if (errorString.contains('network') || errorString.contains('socket')) {
      return ErrorRecoverySuggestion(
        message:
            'Network error detected. Check your internet connection and try again.',
        actionLabel: 'Retry',
      );
    }

    // Timeout errors
    if (errorString.contains('timeout') || errorString.contains('deadline')) {
      return ErrorRecoverySuggestion(
        message: 'Connection timeout. The server took too long to respond.',
        actionLabel: 'Retry with longer timeout',
      );
    }

    // Storage errors
    if (errorString.contains('storage') || errorString.contains('database')) {
      return ErrorRecoverySuggestion(
        message:
            'Storage error detected. Try clearing app cache or restarting the app.',
        actionLabel: 'Clear cache',
      );
    }

    // Permission errors
    if (errorString.contains('permission') || errorString.contains('denied')) {
      return ErrorRecoverySuggestion(
        message: 'Permission denied. Check app settings and try again.',
        actionLabel: 'Open settings',
      );
    }

    // Generic suggestion
    return ErrorRecoverySuggestion(
      message: 'An unexpected error occurred. Try again or restart the app.',
      actionLabel: 'Retry',
    );
  }

  /// Get error statistics
  Map<String, dynamic> getErrorStatistics() {
    return {
      'totalErrors': _totalErrorsReported,
      'historySize': _errorHistory.length,
      'recentErrors': _errorHistory.take(10).toList(),
    };
  }

  /// Clear error history
  void clearErrorHistory() {
    _errorHistory.clear();
  }

  // ============ PRIVATE HELPERS ============

  /// Extract readable error message from various error types
  String _extractErrorMessage(dynamic error) {
    if (error is String) return error;
    if (error is Exception) return error.toString();
    if (error is Error) return error.toString();
    return error.toString();
  }

  /// Categorize error type for better handling
  String _categorizeError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') || errorString.contains('socket')) {
      return 'NetworkError';
    }
    if (errorString.contains('timeout') || errorString.contains('deadline')) {
      return 'TimeoutError';
    }
    if (errorString.contains('storage') || errorString.contains('database')) {
      return 'StorageError';
    }
    if (errorString.contains('permission') || errorString.contains('denied')) {
      return 'PermissionError';
    }
    if (errorString.contains('null')) {
      return 'NullPointerError';
    }
    if (errorString.contains('assertion')) {
      return 'AssertionError';
    }

    return 'UnknownError';
  }

  /// Build detailed error log entry
  String _buildErrorLog(
    String message,
    String errorType,
    ErrorSeverity severity,
    String? context,
    StackTrace? stackTrace,
    String timestamp,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('┌─ ERROR LOG (${_severityEmoji(severity)}) ─');
    buffer.writeln('│ Timestamp: $timestamp');
    buffer.writeln('│ Type: $errorType');
    buffer.writeln('│ Severity: ${severity.name.toUpperCase()}');
    if (context != null) {
      buffer.writeln('│ Context: $context');
    }
    buffer.writeln('│ Message: $message');
    if (stackTrace != null) {
      buffer.writeln('│');
      buffer.writeln('│ Stack Trace:');
      final lines = stackTrace.toString().split('\n');
      for (final line in lines.take(5)) {
        buffer.writeln('│   $line');
      }
      if (lines.length > 5) {
        buffer.writeln('│   ... (${lines.length - 5} more lines)');
      }
    }
    buffer.write('└─────────────────────');

    return buffer.toString();
  }

  /// Add error to history with size limit
  void _addToErrorHistory(String logEntry) {
    _errorHistory.add(logEntry);
    if (_errorHistory.length > _maxErrorHistorySize) {
      _errorHistory.removeAt(0);
    }
  }

  /// Log to console with severity indicator
  void _logToConsole(String logEntry, ErrorSeverity severity) {
    final prefix = switch (severity) {
      ErrorSeverity.low => '⚠️',
      ErrorSeverity.medium => '⚠️⚠️',
      ErrorSeverity.high => '❌',
      ErrorSeverity.critical => '🔴',
    };

    debugPrint('$prefix ERROR SERVICE LOG:\n$logEntry');
  }

  /// Get emoji for severity
  String _severityEmoji(ErrorSeverity severity) {
    return switch (severity) {
      ErrorSeverity.low => '⚠️',
      ErrorSeverity.medium => '⚠️',
      ErrorSeverity.high => '❌',
      ErrorSeverity.critical => '🔴',
    };
  }

  /// Attempt recovery from error
  void _attemptRecovery(
    dynamic error,
    VoidCallback recoveryAction,
    String? context,
  ) {
    try {
      debugPrint(
          '🔧 Attempting recovery for ${_categorizeError(error)} in context: $context');
      recoveryAction();
      debugPrint('✅ Recovery successful');
    } catch (recoveryError) {
      debugPrint('❌ Recovery failed: $recoveryError');
    }
  }

  /// Integration point for remote error reporting (Sentry, Firebase, etc.)
  /// Uncomment and configure when ready to use
  /*
  void _reportToRemoteService(String logEntry, ErrorSeverity severity) {
    try {
      // Example: Send to Sentry
      // await Sentry.captureException(
      //   error,
      //   stackTrace: stackTrace,
      //   level: _mapSeverityToSentryLevel(severity),
      // );
    } catch (e) {
      debugPrint('❌ Failed to report to remote service: $e');
    }
  }
  */
}

/// A global instance of the [ErrorService].
///
/// While global instances are generally discouraged, this is a reasonable
/// exception for a top-level service like this.
final errorService = ErrorService();
