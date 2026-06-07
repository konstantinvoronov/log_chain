import '../model/log_entry.dart';
import '../model/log_snapshot.dart';
/*
[ERROR] LoadDashboard | 246ms
operationId: operation_1
path: LoadDashboard

[10:42:18.102 | +000ms root | #001] LoadDashboard                            started
[10:42:18.104 | +002ms root | #002] LoadDashboard > loadUser                 started
[10:42:18.105 | +003ms root | #003] LoadDashboard > loadOffers               started
[10:42:18.193 | +091ms root | #004] LoadDashboard > loadUser                 user loaded
[10:42:18.346 | +244ms root | #006] LoadDashboard > loadOffers               HTTP 500
 */
class LogSnapshotFlatTimeStringSerializer {
  const LogSnapshotFlatTimeStringSerializer();

  String serialize(LogSnapshot snapshot) {
    final entries = <_FlatEntry>[];

    _collectEntries(
      snapshot,
      entries,
    );

    entries.sort((a, b) {
      return a.entry.sequence.compareTo(b.entry.sequence);
    });

    final buffer = StringBuffer();

    buffer.writeln(
      '[${snapshot.level.name.toUpperCase()}] '
          '${snapshot.name} | ${snapshot.duration.inMilliseconds}ms',
    );
    buffer.writeln('operationId: ${snapshot.operationId}');
    buffer.writeln('path: ${snapshot.path}');
    buffer.writeln();

    for (final item in entries) {
      final entry = item.entry;

      buffer.writeln(
        '[${_time(entry.timestamp)}'
            ' | +${entry.rootOffset.inMilliseconds}ms root'
            ' | #${entry.sequence.toString().padLeft(3, '0')}] '
            '${item.path.padRight(40)} '
            '${entry.message}',
      );
    }

    return buffer.toString().trimRight();
  }

  void _collectEntries(
      LogSnapshot snapshot,
      List<_FlatEntry> result,
      ) {
    for (final entry in snapshot.entries) {
      result.add(
        _FlatEntry(
          path: snapshot.path,
          entry: entry,
        ),
      );
    }

    for (final child in snapshot.children) {
      _collectEntries(child, result);
    }
  }

  String _time(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    final millisecond = time.millisecond.toString().padLeft(3, '0');

    return '$hour:$minute:$second.$millisecond';
  }
}

class _FlatEntry {
  final String path;
  final LogEntry entry;

  const _FlatEntry({
    required this.path,
    required this.entry,
  });
}