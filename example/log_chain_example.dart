import 'dart:io';

import 'package:log_chain/log_chain.dart';
import 'package:log_chain/src/app/log_branch.dart';
import 'package:log_chain/src/app/log_root.dart';
import 'package:log_chain/src/domain/app/i_log_branch.dart';

Future<void> main() async {
  final root = LogRoot(
    name: 'ExampleAppSession',
    logType: LogType.logNowAndThen,
    outputRepositories: [
      const DeveloperLogSnapshotOutputRepository(),
      const ConsoleLogSnapshotOutputRepository(),
      JsonFileLogSnapshotOutputRepository(directory: Directory('logs')),
    ],
  );

  final repository = UserRepository();

  await root.asyncBranch(
    'LoadUserFlow',
    (log) async {
      log.info('Flow started');

      final user = await repository.loadUser(
        'user_42',
        log: log.branch('UserRepository.loadUser'),
      );

      log.info(
        'Flow finished',
        extra: {'userId': user.id, 'userName': user.name},
      );
    },
    logWhen: (snapshot) {
      return snapshot.hasFailure ||
          snapshot.duration > const Duration(milliseconds: 100);
    },
  );

  await root.close();
}

class UserRepository {
  Future<User> loadUser(String userId, {required IlogBranch log}) async {
    return log.asyncBranch('loadUser', (log) async {
      log.info('Loading user', extra: {'userId': userId});

      final user = await ApiClient().getUser(
        userId,
        log: log.branch('ApiClient.getUser'),
      );

      log.info('User loaded');

      return user;
    }, logWhen: (snapshot) => snapshot.hasFailure);
  }
}

class ApiClient {
  Future<User> getUser(String userId, {required IlogBranch log}) async {
    return log.asyncBranch('getUser', (log) async {
      log.info('Preparing request');

      await Future<void>.delayed(const Duration(milliseconds: 120));

      log.info('Response received', extra: {'statusCode': 200});

      return User(id: userId, name: 'Alex');
    });
  }
}

class User {
  final String id;
  final String name;

  const User({required this.id, required this.name});
}
