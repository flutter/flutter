import 'package:sqflite_common/sqlite_api.dart';
import 'package:test/test.dart';

import 'test_scenario.dart';

void main() {
  group('sqflite', () {
    var startCommands = [protocolOpenStep];
    var endCommands = [protocolCloseStep];
    test('batch commit', () async {
      final scenario = startScenario([
        ...startCommands,
        [
          'execute',
          {
            'sql': 'BEGIN IMMEDIATE',
            'id': 1,
            'inTransaction': true,
            'transactionId': null
          },
          null
        ],
        [
          'batch',
          {
            'operations': [
              {'method': 'execute', 'sql': 'PRAGMA dummy'}
            ],
            'id': 1
          },
          null
        ],
        [
          'execute',
          {'sql': 'COMMIT', 'id': 1, 'inTransaction': false},
          null
        ],
        ...endCommands,
      ]);
      final factory = scenario.factory;
      final db = await factory.openDatabase(inMemoryDatabasePath);
      var batch = db.batch();
      expect(batch.length, 0);
      batch.execute('PRAGMA dummy');
      expect(batch.length, 1);
      expect(await batch.commit(), isEmpty); // Mock return values
      await db.close();
      scenario.end();
    });
    test('batch apply', () async {
      final scenario = startScenario([
        ...startCommands,
        [
          'batch',
          {
            'operations': [
              {'method': 'execute', 'sql': 'PRAGMA dummy'}
            ],
            'id': 1
          },
          null
        ],
        ...endCommands,
      ]);
      final factory = scenario.factory;
      final db = await factory.openDatabase(inMemoryDatabasePath);
      var batch = db.batch();
      batch.execute('PRAGMA dummy');
      await batch.apply();
      await db.close();
      scenario.end();
    });
  });
}
