import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import 'test_page.dart';

/// Batch test page.
class BatchTestPage extends TestPage {
  /// Batch test page.
  BatchTestPage({Key? key}) : super('Batch tests', key: key) {
    test('BatchQuery', () async {
      // await Sqflite.devSetDebugModeOn();
      final path = await initDeleteDb('batch_query.db');
      final db = await openDatabase(path);

      // empty batch
      var batch = db.batch();
      batch.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)');
      batch.rawInsert('INSERT INTO Test (name) VALUES (?)', ['item1']);
      var results = await batch.commit();
      expect(results, [null, 1]);

      final dbResult = await db.rawQuery('SELECT id, name FROM Test');
      // devPrint('dbResult $dbResult');
      expect(dbResult, [
        {'id': 1, 'name': 'item1'}
      ]);

      // one query
      batch = db.batch();
      batch.rawQuery('SELECT id, name FROM Test');
      batch.query('Test', columns: ['id', 'name']);
      results = await batch.commit();
      // devPrint('select $results ${results?.first}');
      expect(results, [
        [
          {'id': 1, 'name': 'item1'}
        ],
        [
          {'id': 1, 'name': 'item1'}
        ]
      ]);
      await db.close();
    });
    test('Batch', () async {
      // await databaseFactory.devSetDebugModeOn();
      final path = await initDeleteDb('batch.db');
      final db = await openDatabase(path);

      // empty batch
      var batch = db.batch();
      var results = await batch.commit();
      expect(results.length, 0);
      expect(results, isEmpty);

      // one create table
      batch = db.batch();
      batch.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)');
      results = await batch.commit();
      // devPrint('1 $results ${results?.first}');
      expect(results, [null]);
      expect(results[0], null);

      // one insert
      batch = db.batch();
      batch.rawInsert('INSERT INTO Test (name) VALUES (?)', ['item1']);
      results = await batch.commit();
      expect(results, [1]);

      // one query
      batch = db.batch();
      batch.rawQuery('SELECT id, name FROM Test');
      batch.query('Test', columns: ['id', 'name']);
      results = await batch.commit();
      // devPrint('select $results ${results?.first}');
      expect(results, [
        [
          {'id': 1, 'name': 'item1'}
        ],
        [
          {'id': 1, 'name': 'item1'}
        ]
      ]);

      // two insert
      batch = db.batch();
      batch.rawInsert('INSERT INTO Test (name) VALUES (?)', ['item2']);
      batch.insert('Test', {'name': 'item3'});
      results = await batch.commit();
      expect(results, [2, 3]);

      // update
      batch = db.batch();
      batch.rawUpdate(
          'UPDATE Test SET name = ? WHERE name = ?', ['new_item', 'item1']);
      batch.update('Test', {'name': 'new_other_item'},
          where: 'name != ?', whereArgs: <String>['new_item']);
      results = await batch.commit();
      expect(results, [1, 2]);

      // delete
      batch = db.batch();
      batch.rawDelete('DELETE FROM Test WHERE name = ?', ['new_item']);
      batch.delete('Test',
          where: 'name = ?', whereArgs: <String>['new_other_item']);
      results = await batch.commit();
      expect(results, [1, 2]);

      // No result
      batch = db.batch();
      batch.insert('Test', {'name': 'item'});
      batch.update('Test', {'name': 'new_item'},
          where: 'name = ?', whereArgs: <String>['item']);
      batch.delete('Test', where: 'name = ?', whereArgs: ['item']);
      results = await batch.commit(noResult: true);
      expect(results, isEmpty);

      await db.close();
    });

    test('Batch in transaction', () async {
      // await Sqflite.devSetDebugModeOn();
      final path = await initDeleteDb('batch_in_transaction.db');
      final db = await openDatabase(path);

      late List<Object?> results;

      await db.transaction((txn) async {
        final batch1 = txn.batch();
        batch1.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)');
        final batch2 = txn.batch();
        batch2.rawInsert('INSERT INTO Test (name) VALUES (?)', ['item1']);
        results = await batch1.commit();
        expect(results, [null]);

        results = await batch2.commit();
        expect(results, [1]);
      });

      await db.close();
    });

    test('Apply in database', () async {
      // await Sqflite.devSetDebugModeOn();
      final path = await initDeleteDb('apply_in_database.db');
      final db = await openDatabase(path);

      late List<Object?> results;

      final batch1 = db.batch();
      batch1.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)');
      final batch2 = db.batch();
      batch2.rawInsert('INSERT INTO Test (name) VALUES (?)', ['item1']);
      results = await batch1.apply();
      expect(results, [null]);

      results = await batch2.apply();
      expect(results, [1]);
      await db.close();
    });

    test('Apply in transaction', () async {
      // await Sqflite.devSetDebugModeOn();
      final path = await initDeleteDb('apply_in_transaction.db');
      final db = await openDatabase(path);

      late List<Object?> results;

      await db.transaction((txn) async {
        final batch1 = txn.batch();
        batch1.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)');
        final batch2 = txn.batch();
        batch2.rawInsert('INSERT INTO Test (name) VALUES (?)', ['item1']);
        results = await batch1.apply();
        expect(results, [null]);

        results = await batch2.apply();
        expect(results, [1]);
      });

      await db.close();
    });

    test('Batch continue on error', () async {
      // await Sqflite.devSetDebugModeOn();
      final path = await initDeleteDb('batch_continue_on_error.db');
      final db = await openDatabase(path);
      try {
        final batch = db.batch();
        batch.rawInsert('INSERT INTO Test (name) VALUES (?)', ['item1']);
        batch.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)');
        batch.execute('DUMMY');
        batch.rawInsert('INSERT INTO Test (name) VALUES (?)', ['item1']);
        batch.rawQuery('SELECT * FROM Test');
        final results = await batch.commit(continueOnError: true);
        // devPrint(results);
        // First result is an exception
        var exception = results[0] as DatabaseException;
        expect(exception.isNoSuchTableError(), true);
        // Second result is null (create table)
        expect(results[1], null);
        // Third result is an exception
        exception = results[2] as DatabaseException;
        expect(exception.isSyntaxError(), true);
        // Fourth result is an insert
        expect(results[3], 1);
        // Fifth is a select
        expect(results[4], [
          {'id': 1, 'name': 'item1'}
        ]);
      } finally {
        await db.close();
      }
    });
  }
}
