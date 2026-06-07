import '../../log_chain.dart';
import '../domain/app/i_log_branch.dart';
import '../domain/model/log_snapshot.dart';

import 'log_branch.dart';

/// Root controller for a log chain session.
///
/// Responsibilities:
/// - creates top-level branches
/// - owns global ids
/// - owns global sequence numbers
/// - owns root start time
/// - stores snapshots explicitly selected by branch-level `logWhen`
///
/// It does not:
/// - define default `logWhen`
/// - output snapshots
/// - know about files, console, developer log, or external repositories
/*
  final root = LogRoot(
    name: 'AppSession',
    logType: LogType.logNowAndThen,
    outputRepositories: [
      const DeveloperLogSnapshotOutputRepository(),
      const ConsoleLogSnapshotOutputRepository(),
      JsonFileLogSnapshotOutputRepository(
        directory: Directory('logs'),
      ),
    ],
  );

  await root.asyncBranch(
    'LoadUser',
    (log) async {
      log.info('started');
      log.error('failed');
    },
    logWhen: (snapshot) => snapshot.hasFailure,
  );
 */

class LogRoot {
  final String name;
  final LogType logType;
  final List<LogSnapshotOutputRepository> outputRepositories;

  final DateTime startedAt;

  final List<LogSnapshot> _rootSnapshots = [];

  DateTime? _finishedAt;
  bool _closed = false;

  int _branchCounter = 0;
  int _entryCounter = 0;
  int _snapshotCounter = 0;
  int _operationCounter = 0;
  int _sequenceCounter = 0;

  LogRoot({
    required this.name,
    this.logType = LogType.logOnClose,
    this.outputRepositories = const [],
    DateTime? startedAt,
  }) : startedAt = startedAt ?? DateTime.now();

  List<LogSnapshot> get rootSnapshots {
    return List.unmodifiable(_rootSnapshots);
  }

  IlogBranch branch(
    String name, {
    bool Function(LogSnapshot snapshot)? logWhen,
  }) {
    _assertOpen();

    return LogBranch(
      root: this,
      parent: null,
      id: nextBranchId(),
      parentBranchId: null,
      operationId: nextOperationId(),
      name: name,
      path: name,
      startedAt: DateTime.now(),
      logWhen: logWhen,
    );
  }

  Future<T> asyncBranch<T>(
    String name,
    Future<T> Function(IlogBranch log) run, {
    bool Function(LogSnapshot snapshot)? logWhen,
  }) async {
    final child = branch(name, logWhen: logWhen);

    try {
      return await run(child);
    } catch (error, stackTrace) {
      child.error('Unhandled exception', error: error, stackTrace: stackTrace);

      rethrow;
    } finally {
      child.close();
    }
  }

  void attachRootSnapshot(LogSnapshot snapshot) {
    _assertOpen();
    _rootSnapshots.add(snapshot);
  }

  Future<void> processAcceptedSnapshot(LogSnapshot snapshot) async {
    if (logType == LogType.logAsReceive || logType == LogType.logNowAndThen) {
      await _output(snapshot);
    }
  }

  LogSnapshot snapshot() {
    final finishedAt = _finishedAt;
    final endTime = finishedAt ?? DateTime.now();

    return LogSnapshot(
      id: nextSnapshotId(),
      branchId: 'root',
      parentBranchId: null,
      operationId: 'root',
      name: name,
      path: name,
      startedAt: startedAt,
      finishedAt: finishedAt,
      duration: endTime.difference(startedAt),
      entries: const [],
      children: List.unmodifiable(_rootSnapshots),
    );
  }

  Future<void> close() async {
    if (_closed) return;

    _closed = true;
    _finishedAt = DateTime.now();

    if (logType == LogType.logOnClose || logType == LogType.logNowAndThen) {
      await _output(snapshot());
    }
  }

  String nextBranchId() => 'branch_${++_branchCounter}';
  String nextEntryId() => 'entry_${++_entryCounter}';
  String nextSnapshotId() => 'snapshot_${++_snapshotCounter}';
  String nextOperationId() => 'operation_${++_operationCounter}';
  int nextSequence() => ++_sequenceCounter;

  Duration rootOffset(DateTime timestamp) {
    return timestamp.difference(startedAt);
  }

  void _assertOpen() {
    if (_closed) {
      throw StateError('LogRoot "$name" is already closed.');
    }
  }

  Future<void> _output(LogSnapshot snapshot) async {
    for (final repository in outputRepositories) {
      await repository.output(snapshot);
    }
  }
}
