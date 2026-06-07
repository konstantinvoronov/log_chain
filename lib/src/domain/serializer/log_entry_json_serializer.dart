import '../model/log_entry.dart';

class LogEntryJsonSerializer {
  const LogEntryJsonSerializer();

  Map<String, Object?> serialize(LogEntry entry) {
    return {
      'id': entry.id,
      'sequence': entry.sequence,
      'timestamp': entry.timestamp.toIso8601String(),
      'rootOffsetMs': entry.rootOffset.inMilliseconds,
      'branchOffsetMs': entry.branchOffset.inMilliseconds,
      'level': entry.level.name,
      'message': entry.message,
      'error': entry.error?.toString(),
      'stackTrace': entry.stackTrace?.toString(),
      'extra': entry.extra,
    };
  }
}