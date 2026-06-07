import '../domain/app/i_log_branch.dart';
import '../domain/model/log_entry.dart';
import '../domain/model/log_level.dart';
import '../domain/model/log_snapshot.dart';
import 'log_root.dart';

class LogBranch implements IlogBranch {
  final LogRoot root;
  final LogBranch? parent;

  @override
  final String id;

  final String? parentBranchId;

  @override
  final String operationId;

  @override
  final String name;

  @override
  final String path;

  final DateTime startedAt;

  final bool Function(LogSnapshot snapshot)? logWhen;

  final List<LogEntry> _entries = [];
  final List<LogSnapshot> _children = [];

  DateTime? _finishedAt;
  bool _closed = false;

  LogBranch({
    required this.root,
    required this.parent,
    required this.id,
    required this.parentBranchId,
    required this.operationId,
    required this.name,
    required this.path,
    required this.startedAt,
    required this.logWhen,
  });

  @override
  LogBranch branch(
    String name, {
    bool Function(LogSnapshot snapshot)? logWhen,
  }) {
    _assertOpen();

    final startedAt = DateTime.now();

    return LogBranch(
      root: root,
      parent: this,
      id: root.nextBranchId(),
      parentBranchId: id,
      operationId: operationId,
      name: name,
      path: '$path > $name',
      startedAt: startedAt,
      logWhen: logWhen,
    );
  }

  @override
  Future<T> asyncBranch<T>(
      String name,
      Future<T> Function(IlogBranch log) run, {
        bool Function(LogSnapshot snapshot)? logWhen,
      }) async {
    final child = branch(name, logWhen: logWhen);

    try {
      return await run(child);
    } catch (error, stackTrace) {
      child.error(
        'Unhandled exception',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    } finally {
      child.close();
    }
  }

  @override
  void add(
    String message, {
    LogLevel level = LogLevel.info,
    Map<String, Object?> extra = const {},
  }) {
    _assertOpen();

    final timestamp = DateTime.now();

    _entries.add(
      LogEntry(
        id: root.nextEntryId(),
        sequence: root.nextSequence(),
        timestamp: timestamp,
        rootOffset: root.rootOffset(timestamp),
        branchOffset: timestamp.difference(startedAt),
        level: level,
        message: message,
        extra: extra,
      ),
    );
  }

  @override
  void debug(String message, {Map<String, Object?> extra = const {}}) {
    add(message, level: LogLevel.debug, extra: extra);
  }

  @override
  void info(String message, {Map<String, Object?> extra = const {}}) {
    add(message, level: LogLevel.info, extra: extra);
  }

  @override
  void warning(String message, {Map<String, Object?> extra = const {}}) {
    add(message, level: LogLevel.warning, extra: extra);
  }

  @override
  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> extra = const {},
  }) {
    _assertOpen();

    final timestamp = DateTime.now();

    _entries.add(
      LogEntry(
        id: root.nextEntryId(),
        sequence: root.nextSequence(),
        timestamp: timestamp,
        rootOffset: root.rootOffset(timestamp),
        branchOffset: timestamp.difference(startedAt),
        level: LogLevel.error,
        message: message,
        error: error,
        stackTrace: stackTrace,
        extra: extra,
      ),
    );
  }

  @override
  String fail(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> extra = const {},
  }) {
    this.error(message, error: error, stackTrace: stackTrace, extra: extra);

    return message;
  }

  @override
  LogSnapshot snapshot() {
    final finishedAt = _finishedAt;
    final endTime = finishedAt ?? DateTime.now();

    return LogSnapshot(
      id: root.nextSnapshotId(),
      branchId: id,
      parentBranchId: parentBranchId,
      operationId: operationId,
      name: name,
      path: path,
      startedAt: startedAt,
      finishedAt: finishedAt,
      duration: endTime.difference(startedAt),
      entries: List.unmodifiable(_entries),
      children: List.unmodifiable(_children),
    );
  }

  @override
  Future<void> close() async {
    if (_closed) return;

    _closed = true;
    _finishedAt = DateTime.now();

    final closedSnapshot = snapshot();

    final shouldGather = logWhen?.call(closedSnapshot) ?? true;

    if (!shouldGather) return;

    if (parent == null) {
      root.attachRootSnapshot(closedSnapshot);
    } else {
      parent!._attachChildSnapshot(closedSnapshot);
    }

    await root.processAcceptedSnapshot(closedSnapshot);
  }

  void _attachChildSnapshot(LogSnapshot snapshot) {
    _assertOpen();
    _children.add(snapshot);
  }

  void _assertOpen() {
    if (_closed) {
      throw StateError('LogBranch "$path" is already closed.');
    }
  }

  @override
  T syncBranch<T>(
      String name,
      T Function(IlogBranch log) run, {
        bool Function(LogSnapshot snapshot)? logWhen,
      }) {
    final child = branch(name, logWhen: logWhen);

    try {
      return run(child);
    } catch (error, stackTrace) {
      child.error(
        'Unhandled exception',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    } finally {
      child.close();
    }
  }


  @override
  String toBranchString() {
    return snapshot().toBranchString();
  }

  @override
  String toFlatTimeString() {
    return snapshot().toFlatTimeString();
  }

  @override
  Map<String, Object?> toJson() {
    return snapshot().toJson();
  }
}
