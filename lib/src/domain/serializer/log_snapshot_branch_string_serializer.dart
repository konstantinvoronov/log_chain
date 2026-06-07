import '../model/log_entry.dart';
import '../model/log_snapshot.dart';

/*
[ERROR] LoadDashboard | 246ms
operationId: operation_1
path: LoadDashboard

LoadDashboard [10:42:18.102 | 246ms]
  [10:42:18.102 | +000ms branch | #001] started

  loadUser [10:42:18.104 | 89ms]
    [10:42:18.104 | +000ms branch | #002] started
    [10:42:18.193 | +089ms branch | #004] user loaded
 */
class LogSnapshotBranchStringSerializer {
  const LogSnapshotBranchStringSerializer();

  String serialize(LogSnapshot snapshot) {
    final buffer = StringBuffer();

    buffer.writeln(
      '[${snapshot.level.name.toUpperCase()}] '
      '${snapshot.name} | ${snapshot.duration.inMilliseconds}ms',
    );
    buffer.writeln('operationId: ${snapshot.operationId}');
    buffer.writeln('path: ${snapshot.path}');
    buffer.writeln();

    _writeSnapshot(buffer, snapshot, 0);

    return buffer.toString().trimRight();
  }

  void _writeSnapshot(StringBuffer buffer, LogSnapshot snapshot, int indent) {
    final prefix = '  ' * indent;

    buffer.writeln(
      '$prefix${snapshot.name} '
      '[${_time(snapshot.startedAt)}'
      ' | ${snapshot.duration.inMilliseconds}ms]',
    );

    for (final entry in snapshot.entries) {
      _writeEntry(buffer, entry, indent + 1);
    }

    for (final child in snapshot.children) {
      buffer.writeln();
      _writeSnapshot(buffer, child, indent + 1);
    }
  }

  void _writeEntry(StringBuffer buffer, LogEntry entry, int indent) {
    final prefix = '  ' * indent;

    buffer.writeln(
      '$prefix[${_time(entry.timestamp)}'
      ' | +${entry.branchOffset.inMilliseconds}ms branch'
      ' | #${entry.sequence.toString().padLeft(3, '0')}] '
      '${entry.message}',
    );
  }

  String _time(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    final millisecond = time.millisecond.toString().padLeft(3, '0');

    return '$hour:$minute:$second.$millisecond';
  }
}
