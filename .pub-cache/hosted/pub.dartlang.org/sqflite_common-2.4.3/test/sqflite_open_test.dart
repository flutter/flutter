import 'package:sqflite_common/sqlite_api.dart';
import 'package:test/test.dart';

import 'test_scenario.dart';

void main() {
  group('sqflite', () {
    test('open id result compat', () async {
      final scenario = startScenario([
        [
          'openDatabase',
          {'path': ':memory:', 'singleInstance': false},
          1
        ],
        [
          'closeDatabase',
          {'id': 1},
          null
        ],
      ]);
      final factory = scenario.factory;
      final db = await factory.openDatabase(inMemoryDatabasePath);
      await db.close();
      scenario.end();
    });
    test('open map result', () async {
      final scenario = startScenario([
        [
          'openDatabase',
          {'path': ':memory:', 'singleInstance': false},
          {'id': 1},
        ],
        [
          'closeDatabase',
          {'id': 1},
          null
        ],
      ]);
      final factory = scenario.factory;
      final db = await factory.openDatabase(inMemoryDatabasePath);
      await db.close();
      scenario.end();
    });
    test('open with version', () async {
      final scenario = startScenario([
        protocolOpenStep,
        [
          'query',
          {'sql': 'PRAGMA user_version', 'id': 1},
          // ignore: inference_failure_on_collection_literal
          {}
        ],
        [
          'execute',
          {
            'sql': 'BEGIN EXCLUSIVE',
            'id': 1,
            'inTransaction': true,
            'transactionId': null
          },
          null
        ],
        [
          'query',
          {'sql': 'PRAGMA user_version', 'id': 1},
          // ignore: inference_failure_on_collection_literal
          {}
        ],
        [
          'execute',
          {'sql': 'PRAGMA user_version = 1', 'id': 1},
          null
        ],
        [
          'execute',
          {'sql': 'COMMIT', 'id': 1, 'inTransaction': false},
          null
        ],
        protocolCloseStep,
      ]);
      final db = await scenario.factory.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(version: 1, onCreate: (db, version) {}));
      await db.close();
      scenario.end();
    });
  });
}
