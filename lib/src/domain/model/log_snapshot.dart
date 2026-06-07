import '../serializer/log_snapshot_branch_string_serializer.dart';
import '../serializer/log_snapshot_flat_time_string_serializer.dart';
import '../serializer/log_snapshot_json_serializer.dart';
import 'log_entry.dart';
import 'log_level.dart';

class LogSnapshot {
  final String id;
  final String branchId;
  final String? parentBranchId;
  final String operationId;
  final String name;
  final String path;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final Duration duration;
  final List<LogEntry> entries;
  final List<LogSnapshot> children;

  const LogSnapshot({
    required this.id,
    required this.branchId,
    required this.parentBranchId,
    required this.operationId,
    required this.name,
    required this.path,
    required this.startedAt,
    required this.finishedAt,
    required this.duration,
    required this.entries,
    required this.children,
  });

  bool get isClosed => finishedAt != null;

  bool get hasWarning {
    return entries.any((entry) => entry.isWarning) ||
        children.any((child) => child.hasWarning);
  }

  bool get hasFailure {
    return entries.any((entry) => entry.isFailure) ||
        children.any((child) => child.hasFailure);
  }

  LogLevel get level {
    if (hasFailure) return LogLevel.error;
    if (hasWarning) return LogLevel.warning;
    return LogLevel.info;
  }

  String toBranchString() {
    return LogSnapshotBranchStringSerializer().serialize(this);
  }

  String toFlatTimeString() {
    return LogSnapshotFlatTimeStringSerializer().serialize(this);
  }

  Map<String, Object?> toJson() {
    return LogSnapshotJsonSerializer().serialize(this);
  }
}
