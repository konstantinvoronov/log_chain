/// Defines when accepted branch snapshots are sent to the connected system logger.
///
/// Accepted means: the branch was closed and its local `logWhen` condition
/// either was not provided or returned true.
enum LogType {
  /// Log every accepted branch snapshot when the branch closes.
  logAsReceive,

  /// Do not log branches when they close.
  /// Log the full root snapshot only when [LogRoot.close] is called.
  logOnClose,

  /// Log accepted branch snapshots when they close,
  /// and also log the full root snapshot when [LogRoot.close] is called.
  logNowAndThen,
}