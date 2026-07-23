import 'dart:developer' as developer;

/// Minimal local logger — never sends data off-device.
abstract class AppLogger {
  void debug(String message, {Object? error, StackTrace? stackTrace});
  void info(String message, {Object? error, StackTrace? stackTrace});
  void warning(String message, {Object? error, StackTrace? stackTrace});
  void error(String message, {Object? error, StackTrace? stackTrace});
}

final class ConsoleAppLogger implements AppLogger {
  const ConsoleAppLogger();

  void _log(
    String level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: 'ayutam.$level',
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  void debug(String message, {Object? error, StackTrace? stackTrace}) =>
      _log('debug', message, error: error, stackTrace: stackTrace);

  @override
  void info(String message, {Object? error, StackTrace? stackTrace}) =>
      _log('info', message, error: error, stackTrace: stackTrace);

  @override
  void warning(String message, {Object? error, StackTrace? stackTrace}) =>
      _log('warning', message, error: error, stackTrace: stackTrace);

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) =>
      _log('error', message, error: error, stackTrace: stackTrace);
}
