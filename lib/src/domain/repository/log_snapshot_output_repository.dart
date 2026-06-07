import '../model/log_snapshot.dart';

abstract interface class LogSnapshotOutputRepository {
  Future<void> output(LogSnapshot snapshot);
}
