import '../../domain/model/log_snapshot.dart';
import '../../domain/repository/log_snapshot_output_repository.dart';

class ConsoleLogSnapshotOutputRepository
    implements LogSnapshotOutputRepository {
  final bool useFlatTimeOutput;

  const ConsoleLogSnapshotOutputRepository({
    this.useFlatTimeOutput = false,
  });

  @override
  Future<void> output(LogSnapshot snapshot) async {
    // ignore: avoid_print
    print(
      useFlatTimeOutput
          ? snapshot.toFlatTimeString()
          : snapshot.toBranchString(),
    );
  }
}