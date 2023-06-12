import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_example/utils.dart';

import 'test_page.dart';

// ignore_for_file: avoid_print

class _Data {
  late Database db;
}

/// Type test page.
class TypeTestPage extends TestPage {
  /// Type test page.
  TypeTestPage({Key? key}) : super('Type tests', key: key) {
    test('int', () async {
      //await Sqflite.devSetDebugModeOn(true);
      final path = await initDeleteDb('type_int.db');
      data.db = await openDatabase(path, version: 1,
          onCreate: (Database db, int version) async {
        await db.execute(
            'CREATE TABLE Test (id INTEGER PRIMARY KEY AUTOINCREMENT, value INTEGER)');
      });
      var id = await insertValue(-1);
      expect(await getValue(id), -1);

      // less than 32 bits
      id = await insertValue(pow(2, 31));
      expect(await getValue(id), pow(2, 31));

      // more than 32 bits
      id = await insertValue(pow(2, 33));
      //devPrint('2^33: ${await getValue(id)}');
      expect(await getValue(id), pow(2, 33));

      id = await insertValue(pow(2, 62));
      //devPrint('2^62: ${pow(2, 62)} ${await getValue(id)}');
      expect(await getValue(id), pow(2, 62),
          reason: '2^62: ${pow(2, 62)} ${await getValue(id)}');

      var value = pow(2, 63).round() - 1;
      id = await insertValue(value);
      //devPrint('${value} ${await getValue(id)}');
      expect(await getValue(id), value, reason: '$value ${await getValue(id)}');

      value = -(pow(2, 63)).round();
      id = await insertValue(value);
      //devPrint('${value} ${await getValue(id)}');
      expect(await getValue(id), value, reason: '$value ${await getValue(id)}');
      /*
      id = await insertValue(pow(2, 63));
      devPrint('2^63: ${pow(2, 63)} ${await getValue(id)}');
      assert(await getValue(id) == pow(2, 63), '2^63: ${pow(2, 63)} ${await getValue(id)}');

      // more then 64 bits
      id = await insertValue(pow(2, 65));
      assert(await getValue(id) == pow(2, 65));

      // more then 128 bits
      id = await insertValue(pow(2, 129));
      assert(await getValue(id) == pow(2, 129));
      */
      await data.db.close();
    });

    test('real', () async {
      //await Sqflite.devSetDebugModeOn(true);
      final path = await initDeleteDb('type_real.db');
      data.db = await openDatabase(path, version: 1,
          onCreate: (Database db, int version) async {
        await db
            .execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, value REAL)');
      });
      var id = await insertValue(-1.1);
      expect(await getValue(id), -1.1);
      // big float
      id = await insertValue(1 / 3);
      expect(await getValue(id), 1 / 3);
      id = await insertValue(pow(2, 63) + .1);
      expect(await getValue(id), pow(2, 63) + 0.1);

      // integer?
      id = await insertValue(pow(2, 62));
      expect(await getValue(id), pow(2, 62));
      await data.db.close();
    });

    test('text', () async {
      // await Sqflite.devSetDebugModeOn(true);
      final path = await initDeleteDb('type_text.db');
      data.db = await openDatabase(path, version: 1,
          onCreate: (Database db, int version) async {
        await db.execute(
            'CREATE TABLE Test (id INTEGER PRIMARY KEY AUTOINCREMENT, value TEXT)');
      });
      try {
        var id = await insertValue('simple text');
        expect(await getValue(id), 'simple text');
        // null
        id = await insertValue(null);
        expect(await getValue(id), null);

        // utf-8
        id = await insertValue('àöé');
        expect(await getValue(id), 'àöé');
      } finally {
        await data.db.close();
      }
    });

    test('blob', () async {
      // await Sqflite.devSetDebugModeOn(true);
      final path = await initDeleteDb('type_blob.db');
      data.db = await openDatabase(path, version: 1,
          onCreate: (Database db, int version) async {
        await db
            .execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, value BLOB)');
      });
      int id;
      try {
        // insert text in blob
        id = await insertValue('simple text');
        expect(await getValue(id), 'simple text');

        // UInt8List - default
        final byteData = ByteData(1);
        byteData.setInt8(0, 1);
        final blob = byteData.buffer.asUint8List();
        id = await insertValue(blob);
        //print(await getValue(id));
        final result = (await getValue(id)) as List;
        print(result.runtimeType);
        expect(result is Uint8List, true);
        expect(result.length, 1);
        expect(result, [1]);

        // empty array not supported
        //id = await insertValue([]);
        //print(await getValue(id));
        //assert(eq.equals(await getValue(id), []));

        var blob1234 = [1, 2, 3, 4];
        if (!supportsCompatMode) {
          blob1234 = Uint8List.fromList(blob1234);
        }
        id = await insertValue(blob1234);
        dynamic value = (await getValue(id)) as List;
        print(value);
        print('${(value as List).length}');
        expect(value, blob1234, reason: '${await getValue(id)}');

        // test hex feature on sqlite
        final hexResult = await data.db
            .rawQuery('SELECT hex(value) FROM Test WHERE id = ?', [id]);
        expect(hexResult[0].values.first, '01020304');

        // try blob lookup (works on Android since 2022-09-19)
        var rows = await data.db
            .rawQuery('SELECT * FROM Test WHERE value = ?', [blob1234]);
        expect(rows.length, 1);

        // try blob lookup using hex
        rows = await data.db.rawQuery(
            'SELECT * FROM Test WHERE hex(value) = ?', [Sqflite.hex(blob1234)]);
        expect(rows.length, 1);
        expect(rows[0]['id'], 3);

        // Insert empty blob
        final blobEmpty = Uint8List(0);
        id = await insertValue(blobEmpty);
        value = await getValue(id);
        expect(value, const TypeMatcher<Uint8List>());
        expect(value, isEmpty);
      } finally {
        await data.db.close();
      }
    });

    test('null', () async {
      // await Sqflite.devSetDebugModeOn(true);
      final path = await initDeleteDb('type_null.db');
      data.db = await openDatabase(path, version: 1,
          onCreate: (Database db, int version) async {
        await db
            .execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, value TEXT)');
      });
      try {
        final id = await insertValue(null);
        expect(await getValue(id), null);

        // Make a string
        expect(await updateValue(id, 'dummy'), 1);
        expect(await getValue(id), 'dummy');

        expect(await updateValue(id, null), 1);
        expect(await getValue(id), null);
      } finally {
        await data.db.close();
      }
    });

    test('date_time', () async {
      // await Sqflite.devSetDebugModeOn(true);
      final path = await initDeleteDb('type_date_time.db');
      data.db = await openDatabase(path, version: 1,
          onCreate: (Database db, int version) async {
        await db
            .execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, value TEXT)');
      });
      try {
        var failed = false;
        try {
          await insertValue(DateTime.fromMillisecondsSinceEpoch(1234567890));
        } on ArgumentError catch (_) {
          failed = true;
        }
        expect(failed, true);
      } finally {
        await data.db.close();
      }
    });

    test('bool', () async {
      //await Sqflite.devSetDebugModeOn(true);
      data.db = await openDatabase(inMemoryDatabasePath, version: 1,
          onCreate: (Database db, int version) async {
        await db.execute(
            'CREATE TABLE Test (id INTEGER PRIMARY KEY, value BOOLEAN)');
      });
      try {
        var failed = false;
        try {
          await insertValue(true);
        } on ArgumentError catch (_) {
          failed = true;
        }
        if (supportsCompatMode) {
          print('for now bool are accepted but inconsistent on iOS/Android');
          expect(failed, isFalse);
        }
      } finally {
        await data.db.close();
      }
    });
  }

  /// Out internal data.
  // ignore: library_private_types_in_public_api
  final _Data data = _Data();

  /// Get the value field from a given id
  Future<dynamic> getValue(int id) async {
    return ((await data.db.query('Test', where: 'id = $id')).first)['value'];
  }

  /// insert the value field and return the id
  Future<int> insertValue(dynamic value) async {
    return await data.db.insert('Test', {'value': value});
  }

  /// insert the value field and return the id
  Future<int> updateValue(int id, dynamic value) async {
    return await data.db.update('Test', {'value': value}, where: 'id = $id');
  }
}
