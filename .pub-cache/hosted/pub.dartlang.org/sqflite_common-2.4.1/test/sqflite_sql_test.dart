import 'dart:typed_data';

import 'package:sqflite_common/sqlite_api.dart';
import 'package:test/test.dart';

import 'test_scenario.dart';

var openStep = [
  'openDatabase',
  {'path': ':memory:', 'singleInstance': true},
  1
];
var closeStep = [
  'closeDatabase',
  {'id': 1},
  null
];

void main() {
  group('sqflite', () {
    test('open execute', () async {
      final scenario = startScenario([
        openStep,
        [
          'execute',
          {'sql': 'PRAGMA user_version = 1', 'id': 1},
          null,
        ],
        closeStep
      ]);
      final db = await scenario.factory.openDatabase(inMemoryDatabasePath);
      await db.setVersion(1);

      await db.close();
      scenario.end();
    });
    test('transaction v2', () async {
      final scenario = startScenario([
        openStep,
        [
          'execute',
          {
            'sql': 'BEGIN IMMEDIATE',
            'id': 1,
            'inTransaction': true,
            'transactionId': null
          },
          {'transactionId': 1},
        ],
        [
          'execute',
          {
            'sql': 'COMMIT',
            'id': 1,
            'inTransaction': false,
            'transactionId': 1
          },
          null,
        ],
        closeStep
      ]);
      final db = await scenario.factory.openDatabase(inMemoryDatabasePath);
      await db.transaction((txn) async {});

      await db.close();
      scenario.end();
    });

    test('transaction v1', () async {
      final scenario = startScenario([
        openStep,
        [
          'execute',
          {
            'sql': 'BEGIN IMMEDIATE',
            'id': 1,
            'inTransaction': true,
            'transactionId': null
          },
          null,
        ],
        [
          'execute',
          {
            'sql': 'COMMIT',
            'id': 1,
            'inTransaction': false,
          },
          null,
        ],
        closeStep
      ]);
      final db = await scenario.factory.openDatabase(inMemoryDatabasePath);
      await db.transaction((txn) async {});

      await db.close();
      scenario.end();
    });

    test('manual begin transaction', () async {
      final scenario = startScenario([
        openStep,
        [
          'execute',
          {'sql': 'BEGIN TRANSACTION', 'id': 1, 'inTransaction': true},
          null,
        ],
        [
          'execute',
          {
            'sql': 'ROLLBACK',
            'id': 1,
            'inTransaction': false,
            'transactionId': -1
          },
          null,
        ],
        closeStep
      ]);
      final db = await scenario.factory.openDatabase(inMemoryDatabasePath);
      await db.execute('BEGIN TRANSACTION');

      await db.close();
      scenario.end();
    });

    test('manual begin end transaction', () async {
      final scenario = startScenario([
        openStep,
        [
          'execute',
          {'sql': 'BEGIN TRANSACTION', 'id': 1, 'inTransaction': true},
          null,
        ],
        [
          'execute',
          {'sql': 'ROLLBACK TRANSACTION', 'id': 1, 'inTransaction': false},
          null,
        ],
        closeStep
      ]);
      final db = await scenario.factory.openDatabase(inMemoryDatabasePath);
      await db.execute('BEGIN TRANSACTION');
      await db.execute('ROLLBACK TRANSACTION');

      await db.close();
      scenario.end();
    });
    test('open insert', () async {
      final scenario = startScenario([
        openStep,
        [
          'insert',
          {
            'sql': 'INSERT INTO test (blob) VALUES (?)',
            'arguments': [
              [1, 2, 3]
            ],
            'id': 1
          },
          1
        ],
        closeStep
      ]);
      final db = await scenario.factory.openDatabase(inMemoryDatabasePath);
      expect(
          await db.insert('test', {
            'blob': Uint8List.fromList([1, 2, 3])
          }),
          1);
      await db.close();
      scenario.end();
    });

    test('open insert conflict', () async {
      final scenario = startScenario([
        openStep,
        [
          'insert',
          {
            'sql': 'INSERT OR IGNORE INTO test (value) VALUES (?)',
            'arguments': [1],
            'id': 1
          },
          1
        ],
        closeStep
      ]);
      final db = await scenario.factory.openDatabase(inMemoryDatabasePath);
      expect(
          await db.insert('test', {'value': 1},
              conflictAlgorithm: ConflictAlgorithm.ignore),
          1);
      await db.close();
      scenario.end();
    });

    test('open batch insert', () async {
      final scenario = startScenario([
        openStep,
        [
          'execute',
          {
            'sql': 'BEGIN IMMEDIATE',
            'id': 1,
            'inTransaction': true,
            'transactionId': null,
          },
          {'transactionId': 1}
        ],
        [
          'batch',
          {
            'operations': [
              {
                'method': 'insert',
                'sql': 'INSERT INTO test (blob) VALUES (?)',
                'arguments': [
                  [1, 2, 3]
                ]
              }
            ],
            'id': 1,
            'transactionId': 1
          },
          null
        ],
        [
          'execute',
          {
            'sql': 'COMMIT',
            'id': 1,
            'inTransaction': false,
            'transactionId': 1
          },
          null
        ],
        closeStep
      ]);
      final db = await scenario.factory.openDatabase(inMemoryDatabasePath);
      final batch = db.batch();
      batch.insert('test', {
        'blob': Uint8List.fromList([1, 2, 3])
      });
      await batch.commit();
      await db.close();
      scenario.end();
    });

    test('queryCursor', () async {
      final scenario = startScenario([
        openStep,
        [
          'query',
          {
            'sql': '_',
            'id': 1,
            'cursorPageSize': 2,
          },
          {
            'cursorId': 1,
            'rows': [
              // ignore: inference_failure_on_collection_literal
              [{}]
            ],
            // ignore: inference_failure_on_collection_literal
            'columns': []
          }
        ],
        [
          'queryCursorNext',
          {'cursorId': 1, 'id': 1},
          {
            'cursorId': 1,
            'rows': [
              // ignore: inference_failure_on_collection_literal
              [{}]
            ],
            // ignore: inference_failure_on_collection_literal
            'columns': []
          },
        ],
        [
          'queryCursorNext',
          {'cursorId': 1, 'cancel': true, 'id': 1},
          null
        ],
        closeStep
      ]);
      var resultList = <Map<String, Object?>>[];
      final db = await scenario.factory.openDatabase(inMemoryDatabasePath);
      var cursor = await db.rawQueryCursor(
        '_',
        null,
        bufferSize: 2,
      );
      expect(await cursor.moveNext(), isTrue);
      resultList.add(cursor.current);
      expect(await cursor.moveNext(), isTrue);
      resultList.add(cursor.current);
      await cursor.close();

      // ignore: inference_failure_on_collection_literal
      expect(resultList, [{}, {}]);
      await db.close();
      scenario.end();
    });
  });
}
