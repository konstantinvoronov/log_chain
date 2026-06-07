import 'dart:convert';
import 'dart:io';

import '../../domain/model/log_snapshot.dart';
import '../../domain/repository/log_snapshot_output_repository.dart';
import '../../domain/serializer/log_snapshot_json_serializer.dart';

class JsonFileLogSnapshotOutputRepository
    implements LogSnapshotOutputRepository {
  final Directory directory;
  final String Function(LogSnapshot snapshot)? fileNameBuilder;

  const JsonFileLogSnapshotOutputRepository({
    required this.directory,
    this.fileNameBuilder,
  });

  @override
  Future<void> output(LogSnapshot snapshot) async {
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final fileName =
        fileNameBuilder?.call(snapshot) ??
        '${snapshot.operationId}_${snapshot.id}.logchain.json';

    final file = File('${directory.path}/$fileName');

    const encoder = JsonEncoder.withIndent('  ');

    await file.writeAsString(encoder.convert(snapshot.toJson()));
  }
}
