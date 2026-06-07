import 'log_level.dart';

class LogEntry {
  final String id;
  final int sequence;
  final DateTime timestamp;

  /// Time from root branch start.
  final Duration rootOffset;

  /// Time from current branch start.
  final Duration branchOffset;

  final LogLevel level;
  final String message;

  final Object? error;
  final StackTrace? stackTrace;

  final Map<String, Object?> extra;

  const LogEntry({
    required this.id,
    required this.sequence,
    required this.timestamp,
    required this.rootOffset,
    required this.branchOffset,
    required this.level,
    required this.message,
    this.error,
    this.stackTrace,
    this.extra = const {},
  });

  bool get isWarning => level == LogLevel.warning;

  bool get isFailure {
    return level == LogLevel.error || level == LogLevel.fatal;
  }
}
