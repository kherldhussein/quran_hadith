import 'package:flutter/foundation.dart';

/// A centralized service for reporting errors.
///
/// This service can be extended to integrate with third-party error reporting
/// tools like Sentry or Firebase Crashlytics.
class ErrorService {
  /// Reports an error, optionally with a stack trace.
  ///
  /// In a production environment, this method could send the error information
  /// to a remote logging service.
  void reportError(dynamic error, StackTrace? stackTrace) {
    // todo: integrate with a service like Sentry.
    debugPrint('Error: $error');
    if (stackTrace != null) {
      debugPrint('StackTrace: $stackTrace');
    }
  }
}

/// A global instance of the [ErrorService].
///
/// While global instances are generally discouraged, this is a reasonable
/// exception for a top-level service like this.
final errorService = ErrorService();
