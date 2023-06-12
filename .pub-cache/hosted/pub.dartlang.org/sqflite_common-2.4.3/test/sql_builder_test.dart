//import 'package:test/test.dart';
import 'package:sqflite_common/src/sql_builder.dart';
import 'package:test/test.dart';

void main() {
  group('sql_builder', () {
    test('delete', () {
      var builder =
          SqlBuilder.delete('test', where: 'value = ?', whereArgs: <Object>[1]);
      expect(builder.sql, 'DELETE FROM test WHERE value = ?');
      expect(builder.arguments, <int>[1]);

      builder = SqlBuilder.delete('test');
      expect(builder.sql, 'DELETE FROM test');
      expect(builder.arguments, isNull);

      // escape
      builder = SqlBuilder.delete('table');
      expect(builder.sql, 'DELETE FROM "table"');
      expect(builder.arguments, isNull);
    });

    test('query', () {
      var builder = SqlBuilder.query('test');
      expect(builder.sql, 'SELECT * FROM test');
      expect(builder.arguments, isNull);

      builder = SqlBuilder.query('test', columns: ['COUNT(*)']);
      expect(builder.sql, 'SELECT COUNT(*) FROM test');
      expect(builder.arguments, isNull);

      builder = SqlBuilder.query('test',
          distinct: true,
          columns: <String>['value'],
          where: 'value = ?',
          whereArgs: <Object>[1],
          groupBy: 'group_value',
          having: 'value > 0',
          orderBy: 'other_value',
          limit: 2,
          offset: 3);
      expect(builder.sql,
          'SELECT DISTINCT value FROM test WHERE value = ? GROUP BY group_value HAVING value > 0 ORDER BY other_value LIMIT 2 OFFSET 3');
      expect(builder.arguments, <int>[1]);
    });

    test('insert', () {
      try {
        SqlBuilder.insert('test', <String, Object?>{});
        fail('should fail, no nullColumnHack');
      } on ArgumentError catch (_) {}

      var builder = SqlBuilder.insert('test', <String, Object?>{},
          nullColumnHack: 'value');
      expect(builder.sql, 'INSERT INTO test (value) VALUES (NULL)');
      expect(builder.arguments, isNull);

      builder = SqlBuilder.insert('test', <String, Object?>{'value': 1});
      expect(builder.sql, 'INSERT INTO test (value) VALUES (?)');
      expect(builder.arguments, <int>[1]);

      builder = SqlBuilder.insert(
          'test', <String, Object?>{'value': 1, 'other_value': null});
      expect(builder.sql,
          'INSERT INTO test (value, other_value) VALUES (?, NULL)');
      expect(builder.arguments, <int>[1]);

      builder = SqlBuilder.insert('test', <String, Object?>{'value': 1},
          conflictAlgorithm: ConflictAlgorithm.ignore);
      expect(builder.sql, 'INSERT OR IGNORE INTO test (value) VALUES (?)');
      expect(builder.arguments, <int>[1]);

      // no escape yet
      builder = SqlBuilder.insert('test', <String, Object?>{'value:': 1});
      expect(builder.sql, 'INSERT INTO test (value:) VALUES (?)');
      expect(builder.arguments, <int>[1]);

      // escape
      builder = SqlBuilder.insert('table', <String, Object?>{'table': 1});
      expect(builder.sql, 'INSERT INTO "table" ("table") VALUES (?)');
      expect(builder.arguments, <int>[1]);
    });

    test('update', () {
      try {
        SqlBuilder.update('test', <String, Object?>{});
        fail('should fail, no values');
      } on ArgumentError catch (_) {}

      var builder = SqlBuilder.update('test', <String, Object?>{'value': 1});
      expect(builder.sql, 'UPDATE test SET value = ?');
      expect(builder.arguments, <dynamic>[1]);

      builder = SqlBuilder.update(
          'test', <String, Object?>{'value': 1, 'other_value': null});
      expect(builder.sql, 'UPDATE test SET value = ?, other_value = NULL');
      expect(builder.arguments, <dynamic>[1]);

      // testing where
      builder = SqlBuilder.update('test', <String, Object?>{'value': 1},
          where: 'a = ? AND b = ?', whereArgs: <Object>['some_test', 1]);
      expect(builder.arguments, <dynamic>[1, 'some_test', 1]);

      // no escape yet
      builder = SqlBuilder.update('test:', <String, Object?>{'value:': 1});
      expect(builder.sql, 'UPDATE test: SET value: = ?');
      expect(builder.arguments, <int>[1]);

      // escape
      builder = SqlBuilder.update('test:', <String, Object?>{'table': 1});
      expect(builder.sql, 'UPDATE test: SET "table" = ?');
      expect(builder.arguments, <int>[1]);
    });

    test('query', () {
      var builder = SqlBuilder.query('table', orderBy: 'value');
      expect(builder.sql, 'SELECT * FROM "table" ORDER BY value');
      expect(builder.arguments, isNull);

      builder =
          SqlBuilder.query('table', orderBy: 'column_1 ASC, column_2 DESC');
      expect(builder.sql,
          'SELECT * FROM "table" ORDER BY column_1 ASC, column_2 DESC');
      expect(builder.arguments, isNull);

      // testing where
      builder = SqlBuilder.query('test',
          where: 'a = ? AND b = ?', whereArgs: <Object>['some_test', 1]);
      expect(builder.arguments, <dynamic>['some_test', 1]);
    });

    test('isEscapedName', () {
      //expect(isEscapedName(null), false);
      expect(isEscapedName('group'), false);
      expect(isEscapedName("'group'"), false);
      expect(isEscapedName('"group"'), true);
      expect(isEscapedName('`group`'), true);
      expect(isEscapedName("`group'"), false);
      expect(isEscapedName('"group"'), true);
    });

    test('escapeName', () {
      // expect(escapeName(null!), null);
      expect(escapeName('group'), '"group"');
      expect(escapeName('dummy'), 'dummy');
      expect(escapeName('"dummy"'), '"dummy"');
      expect(escapeName('semicolumn:'), 'semicolumn:'); // for now no escape
      expect(
          escapeName(
              'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789'),
          'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789');

      for (var name in escapeNames) {
        expect(escapeName(name), '"$name"');
      }
    });

    test('escapeEntityName', () {
      // expect(escapeEntityName(null!), null);
      expect(escapeEntityName('group'), '"group"');
      expect(escapeEntityName('dummy'), 'dummy');
      expect(escapeEntityName('"dummy"'), '""dummy""');
      expect(escapeEntityName('semicolumn:'), '"semicolumn:"');
      expect(
          escapeEntityName(
              'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789'),
          'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789');

      for (var name in escapeNames) {
        expect(escapeEntityName(name), '"$name"');
      }
    });

    test('unescapeName', () {
      // expect(unescapeName(null!), null);

      expect(unescapeName('dummy'), 'dummy');
      expect(unescapeName("'dummy'"), "'dummy'");
      expect(unescapeName("'group'"), "'group'");
      expect(unescapeName('"group"'), 'group');
      expect(unescapeName('`group`'), 'group');

      for (var name in escapeNames) {
        expect(unescapeName('"$name"'), name);
      }
    });
  });
}
