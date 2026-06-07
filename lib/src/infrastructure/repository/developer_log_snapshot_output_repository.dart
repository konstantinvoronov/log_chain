import 'dart:developer' as developer;

import '../../domain/model/log_level.dart';
import '../../domain/model/log_snapshot.dart';
import '../../domain/repository/log_snapshot_output_repository.dart';

class DeveloperLogSnapshotOutputRepository
    implements LogSnapshotOutputRepository {
  const DeveloperLogSnapshotOutputRepository();

  @override
  Future<void> output(LogSnapshot snapshot) async {
    developer.log(
      snapshot.toBranchString(),
      name: snapshot.path,
      level: _toDeveloperLevel(snapshot.level),
      time: snapshot.finishedAt ?? DateTime.now(),
    );
  }

  int _toDeveloperLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
      case LogLevel.fatal:
        return 1200;
    }
  }
}