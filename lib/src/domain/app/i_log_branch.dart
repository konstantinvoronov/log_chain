
import '../model/log_level.dart';
import '../model/log_snapshot.dart';

abstract interface class IlogBranch {
  String get id;
  String get name;
  String get path;
  String get operationId;

  IlogBranch branch(
      String name, {
        bool Function(LogSnapshot snapshot)? logWhen,
      });

  Future<T> asyncBranch<T>(
      String name,
      Future<T> Function(IlogBranch log) run, {
        bool Function(LogSnapshot snapshot)? logWhen,
      });

  void add(
      String message, {
        LogLevel level = LogLevel.info,
        Map<String, Object?> extra = const {},
      });

  void debug(
      String message, {
        Map<String, Object?> extra = const {},
      });

  void info(
      String message, {
        Map<String, Object?> extra = const {},
      });

  void warning(
      String message, {
        Map<String, Object?> extra = const {},
      });

  void error(
      String message, {
        Object? error,
        StackTrace? stackTrace,
        Map<String, Object?> extra = const {},
      });

  String fail(
      String message, {
        Object? error,
        StackTrace? stackTrace,
        Map<String, Object?> extra = const {},
      });

  LogSnapshot snapshot();

  String toBranchString();

  String toFlatTimeString();

  Map<String, Object?> toJson();

  Future<void> close();
}