## 1.0.0

- Initial release of `log_chain`.
- Added structured log branches for collecting diagnostic entries across async flows.
- Added `LogRoot`, `LogBranch`, `LogEntry`, and immutable `LogSnapshot` models.
- Added automatic branch closing with `asyncBranch`.
- Added `logWhen` conditions to decide whether closed branches are gathered into the parent/root chain.
- Added `LogType` modes: `logAsReceive`, `logOnClose`, and `logNowAndThen`.
- Added snapshot rendering as branch/tree output with `toBranchString()`.
- Added snapshot rendering as flat timeline output with `toFlatTimeString()`.
- Added JSON export with `toJson()` for later inspection in external tools.
- Added output repositories for Dart developer log, console output, and JSON file export.