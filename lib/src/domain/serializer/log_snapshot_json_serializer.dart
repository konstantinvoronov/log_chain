import '../model/log_snapshot.dart';
import 'log_entry_json_serializer.dart';

class LogSnapshotJsonSerializer {
  final LogEntryJsonSerializer entrySerializer;

  const LogSnapshotJsonSerializer({
    this.entrySerializer = const LogEntryJsonSerializer(),
  });

  Map<String, Object?> serialize(LogSnapshot snapshot) {
    return {
      'schemaVersion': 1,
      'snapshotId': snapshot.id,
      'branchId': snapshot.branchId,
      'parentBranchId': snapshot.parentBranchId,
      'operationId': snapshot.operationId,
      'name': snapshot.name,
      'path': snapshot.path,
      'level': snapshot.level.name,
      'startedAt': snapshot.startedAt.toIso8601String(),
      'finishedAt': snapshot.finishedAt?.toIso8601String(),
      'durationMs': snapshot.duration.inMilliseconds,
      'isClosed': snapshot.isClosed,
      'hasFailure': snapshot.hasFailure,
      'hasWarning': snapshot.hasWarning,
      'entries': snapshot.entries.map(entrySerializer.serialize).toList(),
      'children': snapshot.children.map(serialize).toList(),
    };
  }
}
