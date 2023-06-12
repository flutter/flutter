import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common/sqflite_dev.dart';
import 'package:sqflite_example/src/common_import.dart';
import 'package:sqflite_example/utils.dart';

import 'test_page.dart';

// ignore_for_file: avoid_print

/// `todo` table name
const String tableTodo = 'todo';

/// id column name
const String columnId = '_id';

/// title column name
const String columnTitle = 'title';

/// done column name
const String columnDone = 'done';

/// Experiment test page.
class ExpTestPage extends TestPage {
  /// Experiment test page.
  ExpTestPage({Key? key}) : super('Exp Tests', key: key) {
    test('order_by', () async {
      //await Sqflite.setDebugModeOn(true);
      final path = await initDeleteDb('order_by_exp.db');
      final db = await openDatabase(path);

      const table = 'test';
      await db
          .execute('CREATE TABLE $table (column_1 INTEGER, column_2 INTEGER)');
      // inserted in a wrong order to check ASC/DESC
      await db
          .execute('INSERT INTO $table (column_1, column_2) VALUES (11, 180)');
      await db
          .execute('INSERT INTO $table (column_1, column_2) VALUES (10, 180)');
      await db
          .execute('INSERT INTO $table (column_1, column_2) VALUES (10, 2000)');

      final expectedResult = [
        {'column_1': 10, 'column_2': 2000},
        {'column_1': 10, 'column_2': 180},
        {'column_1': 11, 'column_2': 180}
      ];

      var result = await db.rawQuery(
          'SELECT * FROM $table ORDER BY column_1 ASC, column_2 DESC');
      //print(JSON.encode(result));
      expect(result, expectedResult);
      result = await db.query(table, orderBy: 'column_1 ASC, column_2 DESC');
      expect(result, expectedResult);

      await db.close();
    });

    test('in', () async {
      //await Sqflite.devSetDebugModeOn(true);
      final path = await initDeleteDb('simple_exp.db');
      final db = await openDatabase(path);

      const table = 'test';
      await db
          .execute('CREATE TABLE $table (column_1 INTEGER, column_2 INTEGER)');
      await db
          .execute('INSERT INTO $table (column_1, column_2) VALUES (1, 1001)');
      await db
          .execute('INSERT INTO $table (column_1, column_2) VALUES (2, 1002)');
      await db
          .execute('INSERT INTO $table (column_1, column_2) VALUES (2, 1012)');
      await db
          .execute('INSERT INTO $table (column_1, column_2) VALUES (3, 1003)');

      final expectedResult = [
        {'column_1': 1, 'column_2': 1001},
        {'column_1': 2, 'column_2': 1002},
        {'column_1': 2, 'column_2': 1012}
      ];

      // testing with value in the In clause
      var result = await db.query(table,
          where: 'column_1 IN (1, 2)', orderBy: 'column_1 ASC, column_2 ASC');
      //print(JSON.encode(result));
      expect(result, expectedResult);

      // testing with value as arguments
      result = await db.query(table,
          where: 'column_1 IN (?, ?)',
          whereArgs: ['1', '2'],
          orderBy: 'column_1 ASC, column_2 ASC');
      expect(result, expectedResult);

      await db.close();
    });

    test('Raw escaping', () async {
      //await Sqflite.devSetDebugModeOn(true);
      final path = await initDeleteDb('raw_escaping_fields.db');
      final db = await openDatabase(path);

      const table = 'table';
      await db.execute('CREATE TABLE "$table" ("group" INTEGER)');
      // inserted in a wrong order to check ASC/DESC
      await db.execute('INSERT INTO "$table" ("group") VALUES (1)');

      final expectedResult = [
        {'group': 1}
      ];

      var result = await db
          .rawQuery('SELECT "group" FROM "$table" ORDER BY "group" DESC');

      print(result);
      expect(result, expectedResult);
      result =
          await db.rawQuery("SELECT * FROM '$table' ORDER BY `group` DESC");
      //print(JSON.encode(result));
      expect(result, expectedResult);

      await db.rawDelete("DELETE FROM '$table'");

      await db.close();
    });

    test('Escaping fields', () async {
      //await Sqflite.devSetDebugModeOn(true);
      final path = await initDeleteDb('escaping_fields.db');
      final db = await openDatabase(path);

      const table = 'group';
      await db.execute('CREATE TABLE "$table" ("group" TEXT)');
      // inserted in a wrong order to check ASC/DESC

      await db.insert(table, {'group': 'group_value'});
      await db.update(table, {'group': 'group_new_value'},
          where: "\"group\" = 'group_value'");

      final expectedResult = [
        {'group': 'group_new_value'}
      ];

      final result =
          await db.query(table, columns: ['group'], orderBy: '"group" DESC');
      //print(JSON.encode(result));
      expect(result, expectedResult);

      await db.delete(table);

      await db.close();
    });

    test('Functions', () async {
      //await Sqflite.devSetDebugModeOn(true);
      final path = await initDeleteDb('exp_functions.db');
      final db = await openDatabase(path);

      const table = 'functions';
      await db.execute('CREATE TABLE "$table" (one TEXT, another TEXT)');
      await db.insert(table, {'one': '1', 'another': '2'});
      await db.insert(table, {'one': '1', 'another': '3'});
      await db.insert(table, {'one': '2', 'another': '2'});

      var result = await db.rawQuery('''
      select one, GROUP_CONCAT(another) as my_col
      from $table
      GROUP BY one''');
      //print('result :$result');
      expect(result, [
        {'one': '1', 'my_col': '2,3'},
        {'one': '2', 'my_col': '2'}
      ]);

      result = await db.rawQuery('''
      select one, GROUP_CONCAT(another)
      from $table
      GROUP BY one''');
      // print('result :$result');
      expect(result, [
        {'one': '1', 'GROUP_CONCAT(another)': '2,3'},
        {'one': '2', 'GROUP_CONCAT(another)': '2'}
      ]);

      // user alias
      result = await db.rawQuery('''
      select t.one, GROUP_CONCAT(t.another)
      from $table as t
      GROUP BY t.one''');
      //print('result :$result');
      expect(result, [
        {'one': '1', 'GROUP_CONCAT(t.another)': '2,3'},
        {'one': '2', 'GROUP_CONCAT(t.another)': '2'}
      ]);

      await db.close();
    });

    test('Alias', () async {
      //await Sqflite.devSetDebugModeOn(true);
      final path = await initDeleteDb('exp_alias.db');
      final db = await openDatabase(path);

      try {
        const table = 'alias';
        await db.execute(
            'CREATE TABLE $table (column_1 INTEGER, column_2 INTEGER)');
        await db.insert(table, {'column_1': 1, 'column_2': 2});

        final result = await db.rawQuery('''
      select t.column_1, t.column_1 as "t.column1", column_1 as column_alias_1, column_2
      from $table as t''');
        print('result :$result');
        expect(result, [
          {'t.column1': 1, 'column_1': 1, 'column_alias_1': 1, 'column_2': 2}
        ]);
      } finally {
        await db.close();
      }
    });

    test('Dart2 query', () async {
      // await Sqflite.devSetDebugModeOn(true);
      final path = await initDeleteDb('exp_dart2_query.db');
      final db = await openDatabase(path);

      try {
        const table = 'test';
        await db.execute(
            'CREATE TABLE $table (column_1 INTEGER, column_2 INTEGER)');
        await db.insert(table, {'column_1': 1, 'column_2': 2});

        final result = await db.rawQuery('''
         select column_1, column_2
         from $table as t
      ''');
        print('result: $result');
        // test output types
        print('result.first: ${result.first}');
        final first = result.first;
        print('result.first.keys: ${first.keys}');
        var keys = result.first.keys;
        var values = result.first.values;
        verify(keys.first == 'column_1' || keys.first == 'column_2');
        verify(values.first == 1 || values.first == 2);
        print('result.last.keys: ${result.last.keys}');
        keys = result.last.keys;
        values = result.last.values;
        verify(keys.last == 'column_1' || keys.last == 'column_2');
        verify(values.last == 1 || values.last == 2);
      } finally {
        await db.close();
      }
    });
    /*

    Save code that modify a map from a result - unused
    var rawResult = await rawQuery(builder.sql, builder.arguments);

    // Super slow if we escape a name, please avoid it
    // This won't be called if no keywords were used
    if (builder.hasEscape) {
      for (Map map in rawResult) {
        var keys = new Set<String>();

        for (String key in map.keys) {
          if (isEscapedName(key)) {
            keys.add(key);
          }
        }
        if (keys.isNotEmpty) {
          for (var key in keys) {
            var value = map[key];
            map.remove(key);
            map[unescapeName(key)] = value;
          }
        }
      }
    }
    return rawResult;
    */
    test('Issue#48', () async {
      // Sqflite.devSetDebugModeOn(true);
      // devPrint('issue #48');
      // Try to query on a non-indexed field
      final path = await initDeleteDb('exp_issue_48.db');
      final db = await openDatabase(path, version: 1,
          onCreate: (Database db, int version) async {
        await db
            .execute('CREATE TABLE npa (id INT, title TEXT, identifier TEXT)');
        await db.insert(
            'npa', {'id': 128, 'title': 'title 1', 'identifier': '0001'});
        await db.insert('npa',
            {'id': 215, 'title': 'title 1', 'identifier': '0008120150514'});
      });
      var resultSet = await db.query('npa',
          columns: ['id', 'title', 'identifier'],
          where: '"identifier" = ?',
          whereArgs: ['0008120150514']);
      // print(resultSet);
      expect(resultSet.length, 1);
      // but the results is always - empty QueryResultSet[].
      // If i'm trying to do the same with the id field and integer value like
      resultSet = await db.query('npa',
          columns: ['id', 'title', 'identifier'],
          where: '"id" = ?',
          whereArgs: [215]);
      // print(resultSet);
      expect(resultSet.length, 1);
      await db.close();
    });

    test('Issue#52', () async {
      // Sqflite.devSetDebugModeOn(true);
      // Try to insert string with quote
      final path = await initDeleteDb('exp_issue_52.db');
      final db = await openDatabase(path, version: 1,
          onCreate: (Database db, int version) async {
        await db.execute('CREATE TABLE test (id INT, value TEXT)');
        await db.insert('test', {'id': 1, 'value': 'without quote'});
        await db.insert('test', {'id': 2, 'value': 'with " quote'});
      });
      var resultSet = await db
          .query('test', where: 'value = ?', whereArgs: ['with " quote']);
      expect(resultSet.length, 1);
      expect(resultSet.first['id'], 2);

      resultSet = await db
          .rawQuery('SELECT * FROM test WHERE value = ?', ['with " quote']);
      expect(resultSet.length, 1);
      expect(resultSet.first['id'], 2);
      await db.close();
    });

    test('Issue#64', () async {
      // await Sqflite.devSetDebugModeOn(true);
      final path = await initDeleteDb('issue_64.db');

      // delete existing if any
      await deleteDatabase(path);

      // Copy from asset
      final data = await rootBundle.load(join('assets', 'issue_64.db'));
      final bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await writeFileAsBytes(path, bytes);

      // open the database
      final db = await openDatabase(path);

      var result = await db.query('recordings',
          columns: ['id', 'content', 'file', 'speaker', 'reference']);
      print('result1: $result');
      expect(result.length, 2);

      // This one does not work
      // to investigate
      result = await db.query('recordings',
          columns: ['id', 'content', 'file', 'speaker', 'reference'],
          where: 'speaker = ?',
          whereArgs: [1]);

      print('result2: $result');
      expect(result.length, 2);

      result = await db.query(
        'recordings',
        columns: ['id', 'content', 'file', 'speaker', 'reference'],
        where: 'speaker = 1',
      );
      print('result3: $result');
      expect(result.length, 2);

      await db.close();
    });

    test('sql dump file', () async {
      // await Sqflite.devSetDebugModeOn(true);

      // try to import an sql dump file (not working)
      final path = await initDeleteDb('sql_file.db');
      final db = await openDatabase(path);
      try {
        const table = 'test';
        const sql = '''
CREATE TABLE test (value INTEGER);
INSERT INTO test (value) VALUES (1);
INSERT INTO test (value) VALUES (10);
''';
        await db.execute(sql);
        // that should be the expected result
        // var expectedResult = [
        //   {'value': 1},
        //   {'value': 10}
        // ];
        final result = await db.rawQuery('SELECT * FROM $table');
        print(json.encode(result));

        // However (at least on Android)
        // result is empty, only the first statement is executed
        // Ok when using ffi...
        if (platform.isLinux) {
          // Ok when using ffi linux implementation
          // TODO check windows and mac.
          // that should be the expected result
          var expectedResult = [
            {'value': 1},
            {'value': 10}
          ];
          expect(result, expectedResult);
        } else {
          expect(result, isEmpty);
        }
      } finally {
        await db.close();
      }
    });

    test('Issue#164', () async {
      //await Sqflite.devSetDebugModeOn(true);
      final path = await initDeleteDb('issue_164.db');

      final db = await openDatabase(path);
      try {
        await db.execute('''
CREATE TABLE test (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	label TEXT NOT NULL,
	UNIQUE (label) ON CONFLICT IGNORE
);
''');
        // inserted in a wrong order to check ASC/DESC
        var id = await db.rawInsert('''
        INSERT INTO test (label) VALUES(?)
        ''', ['label-1']);
        expect(id, 1);

        id = await db.rawInsert('''
        INSERT INTO test (label) VALUES(?)
        ''', ['label-2']);
        expect(id, 2);

        id = await db.rawInsert('''
        INSERT INTO test (label) VALUES(?)
        ''', ['label-1']);
        expect(id, 0);
      } finally {
        await db.close();
      }
    });

    test('Defensive mode', () async {
      // This shold succeed even on on iOS 14
      final db = await openDatabase(inMemoryDatabasePath);
      try {
        await db.execute('CREATE TABLE Test(value TEXT)');
        // Workaround for iOS 14
        await db.execute('PRAGMA sqflite -- db_config_defensive_off');
        await db.execute('PRAGMA writable_schema = ON');
        expect(
            await db.update(
                'sqlite_master', {'sql': 'CREATE TABLE Test(value BLOB)'},
                where: 'name = \'Test\' and type = \'table\''),
            1);
      } finally {
        await db.close();
      }
    });

    test('Defensive mode (should fail on iOS 14)', () async {
      // This shold fail on iOS 14
      final db = await openDatabase(inMemoryDatabasePath);
      try {
        await db.execute('CREATE TABLE Test(value TEXT)');
        await db.execute('PRAGMA writable_schema = ON');
        expect(
            await db.update(
                'sqlite_master', {'sql': 'CREATE TABLE Test(value BLOB)'},
                where: 'name = \'Test\' and type = \'table\''),
            1);
      } finally {
        await db.close();
      }
    });

    test('ATTACH database', () async {
      final db1Path = await initDeleteDb('attach1.db');
      final db2Path = await initDeleteDb('attach2.db');

      // Create some data on db1 and close it
      var db1 = await databaseFactory.openDatabase(db1Path);
      try {
        var batch = db1.batch();
        batch.execute('CREATE TABLE table1 (col1 INTEGER)');
        batch.insert('table1', {'col1': 1234});
        await batch.commit();
      } finally {
        await db1.close();
      }

      // Open a new db2 database, attach db1 and query it

      var db2 = await databaseFactory.openDatabase(db2Path);
      try {
        await db2.execute('ATTACH DATABASE \'$db1Path\' AS db1');
        var rows = await db2.query('db1.table1');
        expect(rows, [
          {'col1': 1234}
        ]);
      } finally {
        await db2.close();
      }
    });

    /// fts4
    var fts4Supports = supportsCompatMode;
    if (fts4Supports) {
      test('Issue#206', () async {
        //await Sqflite.devSetDebugModeOn(true);
        final path = await initDeleteDb('issue_206.db');

        final db = await openDatabase(path);
        try {
          final sqls = LineSplitter.split(
              '''CREATE VIRTUAL TABLE Food using fts4(description TEXT)
        INSERT Into Food (description) VALUES ('banana')
        INSERT Into Food (description) VALUES ('apple')''');
          final batch = db.batch();
          for (var sql in sqls) {
            batch.execute(sql);
          }
          await batch.commit();

          final results = await db.rawQuery(
              'SELECT description, matchinfo(Food) as matchinfo FROM Food WHERE Food MATCH ?',
              ['ban*']);
          print(results);
          // matchinfo is currently returned as binary bloc
          expect(results.length, 1);
          final map = results.first;
          final matchInfo = map['matchinfo'] as Uint8List;

          // Convert to Uint32List
          final uint32ListLength = matchInfo.length ~/ 4;
          final uint32List = Uint32List(uint32ListLength);
          final data = ByteData.view(
              matchInfo.buffer, matchInfo.offsetInBytes, matchInfo.length);
          for (var i = 0; i < uint32ListLength; i++) {
            uint32List[i] = data.getUint32(i * 4, Endian.host);
          }
          // print(uint32List);
          expect(uint32List, [1, 1, 1, 1, 1]);
          expect(map['matchinfo'], const TypeMatcher<Uint8List>());
        } finally {
          await db.close();
        }
      });
    }

    test('Log level', () async {
      // test setting log level
      Database? db;
      try {
        // ignore: deprecated_member_use
        await databaseFactory.setLogLevel(sqfliteLogLevelVerbose);
        //await databaseFactory.setLogLevel(sqfliteLogLevelSql);
        db = await openDatabase(inMemoryDatabasePath);
        await db.execute('CREATE TABLE test (value TEXT UNIQUE)');
        const table = 'test';
        final map = <String, dynamic>{'value': 'test'};
        await db.insert(table, map,
            conflictAlgorithm: ConflictAlgorithm.replace);
        expect(
            Sqflite.firstIntValue(await db.query(table, columns: ['COUNT(*)'])),
            1);
      } finally {
        // ignore: deprecated_member_use
        await databaseFactory.setLogLevel(sqfliteLogLevelNone);
        await db?.close();
      }
    });

    Future<void> testBigBlog(int size) async {
      // await Sqflite.devSetDebugModeOn(true);
      final path = await initDeleteDb('big_blob.db');
      var db = await openDatabase(path, version: 1,
          onCreate: (Database db, int version) async {
        await db
            .execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, value BLOB)');
      });
      try {
        var blob =
            Uint8List.fromList(List.generate(size, (index) => index % 256));
        var id = await db.insert('Test', {'value': blob});

        /// Get the value field from a given id
        Future<Uint8List> getValue(int id) async {
          return ((await db.query('Test', where: 'id = $id')).first)['value']
              as Uint8List;
        }

        expect((await getValue(id)).length, blob.length);
      } finally {
        await db.close();
      }
    }

    // We don't test automatically above as it crashes seriously on Android
    test('big blob 800 Ko', () async {
      await testBigBlog(800000);
    });

    Future<void> testBigText(int size) async {
      // await Sqflite.devSetDebugModeOn(true);
      final path = await initDeleteDb('big_text.db');
      var db = await openDatabase(path, version: 1,
          onCreate: (Database db, int version) async {
        await db
            .execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, value TEXT)');
      });
      try {
        var text = List.generate(size, (index) => 'A').join();
        var id = await db.insert('Test', {'value': text});

        /// Get the value field from a given id
        Future<String> getValue(int id) async {
          return ((await db.query('Test', where: 'id = $id')).first)['value']
              as String;
        }

        expect((await getValue(id)).length, text.length);
      } finally {
        await db.close();
      }
    }

    // We don't test automatically above as it crashes seriously on Android
    test('big text 800 Ko', () async {
      await testBigText(800000);
    });
    /*
    test('big blob 1500 Ko (fails on Android sqlite)', () async {
      await testBigBlog(1500000);
    });
    test('big blob 2 Mo (fails on Android sqlite)', () async {
      await testBigBlog(2000000);
    });
    test('big blob 15 Mo (fails on Android sqlite)', () async {
      await testBigBlog(15000000);
    });
    */
    /*
    test('Isolate', () async {
      // This test does not work yet
      // Need background registration. I Kept the code for future reference
      await Future.sync(() async {
        // await Sqflite.devSetDebugModeOn(true);
        final path = await initDeleteDb('isolate.db');

        // Open the db in the main isolate
        Database db =
            await openDatabase(path, version: 1, onCreate: (db, version) {
          db.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)');
        });
        try {
          await insert(db, 1);
          expect(await db.rawQuery('SELECT id, name FROM Test'), [
            {'id': 1, 'name': 'item 1'}
          ]);

          // Keep it open and run the isolate
          final receivePort = ReceivePort();
          await Isolate.spawn(simpleInsertQueryIsolate, receivePort.sendPort);

          int index = 0;
          SendPort sendPort;
          List<Map<String, Object?>> results;
          var completer = Completer<void>();
          var subscription = receivePort.listen((data) {
            switch (index++) {
              case 0:
                // first is the port to send
                sendPort = data as SendPort;
                // Send path
                sendPort.send(path);
                break;
              case 1:
                // second is result
                results = data as List<Map<String, Object?>>;
                completer.complete();
                break;
            }
          });
          await completer.future;
          await subscription?.cancel();

          print(results);
          expect(results, {});

          // Query again in main isolate
          expect(await db.rawQuery('SELECT id, name FROM Test'), {});
        } finally {
          await db.close();
        }
      }).timeout(Duration(seconds: 3));
    });
    */
    test('missing parameter', () async {
      var db = await openDatabase(inMemoryDatabasePath);
      await db.execute(
          'CREATE TABLE IF NOT EXISTS foo (id int primary key, name text)');
      var missingParameterShouldFail = !supportsCompatMode;
      try {
        await db.rawQuery('SELECT * FROM foo WHERE id=?');
      } catch (e) {
        expect(missingParameterShouldFail, isTrue);
      }
      await db.close();
    });
    // Issue https://github.com/tekartik/sqflite/issues/929
    // Pragma has to use rawQuery...why, on sqflite Android
    test('wal', () async {
      // await Sqflite.devSetDebugModeOn(true);
      var db = await openDatabase(inMemoryDatabasePath);
      try {
        await db.execute('PRAGMA journal_mode=WAL');
      } catch (e) {
        print(e);
        await db.rawQuery('PRAGMA journal_mode=WAL');
      }
      await db.execute('CREATE TABLE test (id INTEGER)');
      await db.insert('test', <String, Object?>{'id': 1});
      try {
        var resultSet = await db.rawQuery('SELECT id FROM test');
        expect(resultSet, [
          {'id': 1},
        ]);
      } finally {
        await db.close();
      }
    });
  }
}

/// Insert a record with a given id.
Future insert(Database db, int id) async {
  await db.insert('Test', {'id': id, 'name': 'item $id'});
}

/// Open, insert and query for isolate testing.
Future simpleInsertQueryIsolate(SendPort sendPort) async {
  final receivePort = ReceivePort();
  // First share our receive port
  sendPort.send(receivePort.sendPort);

  // Get the path
  final path = await receivePort.first as String;
  final db = await openDatabase(path, version: 1, onCreate: (db, version) {
    db.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)');
  });
  List<Map<String, Object?>> results;
  try {
    await insert(db, 2);
    results = await db.rawQuery('SELECT id, name FROM Test');
    print(results);
  } finally {
    await db.close();
  }

  // Done send the result
  sendPort.send(results);
}
