# log_chain

`log_chain` is a structured diagnostic logging package for Dart.

It is not a classic logger that immediately prints every message.

Instead, it builds a **log branch tree** around a specific execution flow. A branch collects logs while work is happening. When the branch closes, it creates an immutable `LogSnapshot`.

A snapshot can be rendered as:

```dart
snapshot.toBranchString();
snapshot.toFlatTimeString();
snapshot.toJson();
```

This makes it possible to inspect one complete operation as a tree, as a flat timeline, or as structured JSON for later browsing in external tools.

---

## Main idea

Normal logs often look like this:

```text
UserBloc: started
Repository: loading user
ApiClient: request failed
UserBloc: failed
```

The messages are disconnected.

`log_chain` keeps the execution path:

```text
LoadUser
  UserRepository.loadUser
    ApiClient.getUser
      HTTP request
      HTTP 500
  failed
```

The log branch is passed along the same path as the work.

---

## Core concepts

### LogRoot

`LogRoot` starts a log chain session.

It owns:

- global branch ids
- global entry ids
- global sequence numbers
- root start time
- accepted root snapshots
- connection to output repositories, if configured

```dart
final root = LogRoot(
  name: 'AppSession',
  logType: LogType.logOnClose,
  outputRepositories: [
    const DeveloperLogSnapshotOutputRepository(),
  ],
);
```

`LogRoot` does not define a default `logWhen`.

`logWhen` belongs to a specific branch and controls whether that branch is gathered into the parent/root chain when it closes.

---

## LogType

`LogType` defines when accepted branch snapshots are sent to the connected output repositories.

```dart
enum LogType {
  logAsReceive,
  logOnClose,
  logNowAndThen,
}
```

An **accepted snapshot** means:

```text
branch closed
  snapshot was created
  logWhen was not provided or returned true
  snapshot was attached to parent/root chain
```

---

### LogType.logAsReceive

Every accepted branch snapshot is output when the branch closes.

```text
branch closes
  logWhen allows it
  branch is attached to parent/root
  output repositories are called immediately
```

Use this when you want to see important branches as soon as they finish.

---

### LogType.logOnClose

Accepted branch snapshots are gathered into the root tree, but nothing is output immediately.

The full root snapshot is output only when `root.close()` is called.

```text
branch closes
  logWhen allows it
  branch is attached to parent/root
  no output yet

root.close()
  full root snapshot is sent to output repositories
```

Use this when you want one complete final diagnostic artifact.

---

### LogType.logNowAndThen

Accepted branch snapshots are output when they close, and the full root snapshot is also output when `root.close()` is called.

```text
branch closes
  logWhen allows it
  branch is attached to parent/root
  output repositories are called immediately

root.close()
  full root snapshot is sent to output repositories
```

Use this when you want both live diagnostics and one final complete tree.

---

## Output repositories

Output repositories define where accepted snapshots go.

Default implementations:

```text
DeveloperLogSnapshotOutputRepository
ConsoleLogSnapshotOutputRepository
JsonFileLogSnapshotOutputRepository
```

They are not called for every log entry.

They are called only when `LogRoot` decides to output an accepted snapshot according to `LogType`.

---

### Default Dart system logger

Uses `dart:developer`.

```dart
final root = LogRoot(
  name: 'AppSession',
  logType: LogType.logAsReceive,
  outputRepositories: [
    const DeveloperLogSnapshotOutputRepository(),
  ],
);
```

When an accepted snapshot is output, it is sent to the Dart developer log.

---

### Console output

Uses `print()`.

```dart
final root = LogRoot(
  name: 'AppSession',
  logType: LogType.logAsReceive,
  outputRepositories: [
    const ConsoleLogSnapshotOutputRepository(),
  ],
);
```

This is useful for command-line tools, tests, and simple Dart scripts.

---

### JSON file output

Saves snapshots as `.logchain.json`.

```dart
final root = LogRoot(
  name: 'AppSession',
  logType: LogType.logAsReceive,
  outputRepositories: [
    JsonFileLogSnapshotOutputRepository(
      directory: Directory('logs'),
    ),
  ],
);
```

This is useful when you want to open the diagnostic tree later in dedicated viewer software.

---

### Multiple output repositories

The same accepted snapshot can be sent to several outputs.

```dart
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
```

When a snapshot is output, all repositories are called in order.

---

## When output repositories are called

### With `LogType.logAsReceive`

```dart
final root = LogRoot(
  name: 'AppSession',
  logType: LogType.logAsReceive,
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
```

Flow:

```text
LoadUser branch opens
  info added
  error added
LoadUser branch closes
  snapshot is created
  logWhen(snapshot) returns true
  snapshot is attached to root
  DeveloperLogSnapshotOutputRepository.output(snapshot)
  ConsoleLogSnapshotOutputRepository.output(snapshot)
  JsonFileLogSnapshotOutputRepository.output(snapshot)
```

---

### With `LogType.logOnClose`

```dart
final root = LogRoot(
  name: 'AppSession',
  logType: LogType.logOnClose,
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

await root.close();
```

Flow:

```text
LoadUser branch closes
  snapshot is created
  logWhen(snapshot) returns true
  snapshot is attached to root
  no output yet

root.close()
  root snapshot is created
  DeveloperLogSnapshotOutputRepository.output(rootSnapshot)
  ConsoleLogSnapshotOutputRepository.output(rootSnapshot)
  JsonFileLogSnapshotOutputRepository.output(rootSnapshot)
```

---

### With `LogType.logNowAndThen`

```dart
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

await root.close();
```

Flow:

```text
LoadUser branch closes
  snapshot is created
  logWhen(snapshot) returns true
  snapshot is attached to root
  output repositories are called for LoadUser snapshot

root.close()
  root snapshot is created
  output repositories are called again for the full root snapshot
```

---

## LogBranch

A `LogBranch` is a live log collector.

It can:

- add entries
- create child branches
- create an immutable snapshot
- close itself
- render itself as text
- export itself as JSON

```dart
final log = root.branch('LoadUser');

log.info('started');
log.warning('cache miss');
log.error('request failed');

await log.close();
```

---

## LogSnapshot

A `LogSnapshot` is an immutable representation of a branch.

It contains:

- branch id
- parent branch id
- operation id
- path
- start time
- finish time
- duration
- entries
- child snapshots

Snapshots can be rendered or exported:

```dart
final snapshot = log.snapshot();

print(snapshot.toBranchString());
print(snapshot.toFlatTimeString());

final json = snapshot.toJson();
```

---

## Branch lifecycle

A branch has a clear lifecycle:

```text
open branch
  add entries
  create child branches
close branch
  create immutable LogSnapshot
  evaluate branch logWhen if provided
  if logWhen is missing or returns true:
    attach snapshot to parent/root branch
    process snapshot according to LogRoot.logType
  if logWhen returns false:
    discard this branch snapshot
```

`logWhen` controls whether a branch is gathered into the parent tree.

This allows the package to avoid collecting branches that are not needed.

---

## logWhen

`logWhen` is a local branch condition:

```dart
bool Function(LogSnapshot snapshot)
```

It is evaluated when the branch closes.

Example:

```dart
logWhen: (snapshot) => snapshot.hasFailure
```

This means:

```text
Collect logs inside this branch while it is running.
When the branch closes, create a snapshot.
If the snapshot has a failure, attach it to the parent/root chain.
If not, discard this branch snapshot.
```

Other examples:

```dart
logWhen: (snapshot) => snapshot.hasWarning
```

```dart
logWhen: (snapshot) {
  return snapshot.hasFailure ||
      snapshot.duration > const Duration(seconds: 2);
}
```

If no `logWhen` is provided, the branch is gathered by default when it closes.

---

## Opening and closing a branch manually

Manual branches must be closed in `finally`.

```dart
final log = root.branch(
  'LoadUser',
  logWhen: (snapshot) => snapshot.hasFailure,
);

try {
  log.info('started');

  // do work

  log.info('finished');
} catch (error, stackTrace) {
  log.error(
    'failed',
    error: error,
    stackTrace: stackTrace,
  );

  rethrow;
} finally {
  await log.close();
}
```

Here the closing is explicit:

```dart
finally {
  await log.close();
}
```

When `close()` runs, the branch creates its snapshot, checks `logWhen`, and if the condition allows it, attaches itself to the parent/root chain.

---

## Preferred async pattern

Use `asyncBranch` for short async operations.

It creates a child branch and automatically closes it in `finally`.

```dart
await root.asyncBranch(
  'LoadUser',
  (log) async {
    log.info('started');

    // do async work

    log.info('finished');
  },
  logWhen: (snapshot) => snapshot.hasFailure,
);
```

`asyncBranch` is equivalent to:

```dart
final log = root.branch(
  'LoadUser',
  logWhen: (snapshot) => snapshot.hasFailure,
);

try {
  await run(log);
} catch (error, stackTrace) {
  log.error(
    'Unhandled exception',
    error: error,
    stackTrace: stackTrace,
  );

  rethrow;
} finally {
  await log.close();
}
```

The branch always closes, even if an exception is thrown.

---

## Passing branches through async work

The main rule:

```text
Pass the log branch along the same path as the work.
```

Example:

```dart
await root.asyncBranch(
  'LoadUser',
  (log) async {
    final result = await repository.loadUser(
      userId,
      log: log.branch('UserRepository.loadUser'),
    );

    // handle result
  },
  logWhen: (snapshot) => snapshot.hasFailure,
);
```

Repository:

```dart
class UserRepository {
  Future<User> loadUser(
    String userId, {
    required LogBranch log,
  }) async {
    return log.asyncBranch(
      'loadUser',
      (log) async {
        log.info('loading user');

        final user = await apiClient.getUser(
          userId,
          log: log.branch('ApiClient.getUser'),
        );

        log.info('user loaded');

        return user;
      },
    );
  }
}
```

This creates a connected chain:

```text
LoadUser
  UserRepository.loadUser
    loadUser
      ApiClient.getUser
```

---

## Passing branches to objects

Objects may receive a branch when they are created.

```dart
final featureLog = root.branch('UserFeature');

final repository = UserRepository(
  log: featureLog.branch('UserRepository'),
);
```

The object owns that branch and should close it when the object is disposed.

```dart
class UserRepository {
  final LogBranch log;

  UserRepository({
    required this.log,
  });

  Future<void> dispose() async {
    await log.close();
  }
}
```

This is useful for lifecycle logs:

```dart
log.info('repository created');
log.info('repository disposed');
```

For specific method calls, still pass an operation branch:

```dart
await repository.loadUser(
  userId,
  log: eventLog.branch('UserRepository.loadUser'),
);
```

Constructor branch describes object lifetime.  
Method branch describes a specific execution flow.

---

## Bloc / controller pattern

A Bloc can own a branch for its lifetime.

```dart
class UserBloc extends Bloc<UserEvent, UserState> {
  final LogBranch log;
  final UserRepository repository;

  UserBloc({
    required LogBranch parentLog,
    required this.repository,
  })  : log = parentLog.branch('UserBloc'),
        super(UserInitial()) {
    on<LoadUser>(_onLoadUser);
  }

  Future<void> _onLoadUser(
    LoadUser event,
    Emitter<UserState> emit,
  ) async {
    await log.asyncBranch(
      'LoadUser',
      (log) async {
        log.info('event started');

        final result = await repository.loadUser(
          event.userId,
          log: log.branch('UserRepository.loadUser'),
        );

        // handle result

        log.info('event finished');
      },
      logWhen: (snapshot) => snapshot.hasFailure,
    );
  }

  @override
  Future<void> close() async {
    await log.close();
    return super.close();
  }
}
```

---

## Branch string output

`toBranchString()` shows the causal tree.

```dart
print(snapshot.toBranchString());
```

Example:

```text
[ERROR] LoadDashboard | 246ms
operationId: operation_1
path: LoadDashboard

LoadDashboard [10:42:18.102 | 246ms]
  [10:42:18.102 | +000ms branch | #001] started

  loadUser [10:42:18.104 | 89ms]
    [10:42:18.104 | +000ms branch | #002] started
    [10:42:18.193 | +089ms branch | #004] user loaded

  loadOffers [10:42:18.105 | 242ms]
    [10:42:18.105 | +000ms branch | #003] started
    [10:42:18.346 | +241ms branch | #006] HTTP 500
```

Branch output is best for understanding:

- parent-child relation
- where the failure happened
- which operation called which sub-operation

Each entry shows:

```text
global timestamp | offset from current branch start | global sequence number
```

---

## Flat time output

`toFlatTimeString()` shows all entries ordered by global sequence.

```dart
print(snapshot.toFlatTimeString());
```

Example:

```text
[ERROR] LoadDashboard | 246ms
operationId: operation_1
path: LoadDashboard

[10:42:18.102 | +000ms root | #001] LoadDashboard                    started
[10:42:18.104 | +002ms root | #002] LoadDashboard > loadUser         started
[10:42:18.105 | +003ms root | #003] LoadDashboard > loadOffers       started
[10:42:18.193 | +091ms root | #004] LoadDashboard > loadUser         user loaded
[10:42:18.346 | +244ms root | #006] LoadDashboard > loadOffers       HTTP 500
```

Flat output is best for understanding:

- async timing
- overlapping work
- race conditions
- exact order of events

Each entry shows:

```text
global timestamp | offset from root start | global sequence number
```

---

## JSON output

Every branch and snapshot can be exported as JSON.

```dart
final json = snapshot.toJson();
```

The JSON keeps the recursive tree:

```json
{
  "schemaVersion": 1,
  "snapshotId": "snapshot_1",
  "branchId": "branch_1",
  "parentBranchId": null,
  "operationId": "operation_1",
  "name": "LoadDashboard",
  "path": "LoadDashboard",
  "level": "error",
  "startedAt": "2026-06-07T10:42:18.102",
  "finishedAt": "2026-06-07T10:42:18.348",
  "durationMs": 246,
  "isClosed": true,
  "hasFailure": true,
  "hasWarning": false,
  "entries": [],
  "children": []
}
```

This format can be saved and opened later in dedicated viewer software.

---

## Current design rule

```text
LogRoot owns the runtime chain and output connection.
LogBranch collects live entries.
LogSnapshot is the immutable artifact.
logWhen controls whether a closed branch is gathered into the parent/root chain.
LogType controls when gathered snapshots are sent to output repositories.
Output repositories define where accepted snapshots go: developer log, console, JSON file, or custom outputs.
String and JSON outputs are generated from snapshots.
```
