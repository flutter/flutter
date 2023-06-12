import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import 'src_mixin_test.dart' show MockDatabaseFactoryEmpty, MockInvalidFactory;

T? _ambiguate<T>(T? value) => value;
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  databaseFactory = databaseFactorySqflitePlugin;

  group('sqflite', () {
    const channel = MethodChannel('com.tekartik.sqflite');

    final log = <MethodCall>[];
    String? response;

    _ambiguate(TestDefaultBinaryMessengerBinding.instance)!
        .defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      log.add(methodCall);
      return response;
    });

    tearDown(() {
      log.clear();
    });

    test('setDebugModeOn', () async {
      // ignore: deprecated_member_use_from_same_package
      await Sqflite.setDebugModeOn();
      expect(log.first.method, 'debugMode');
      expect(log.first.arguments, true);
    });

    // Check that public api are exported
    test('exported', () {
      for (var value in <dynamic>[
        // Not part of sqflite_api
        openDatabase,
        openReadOnlyDatabase,
        getDatabasesPath,
        deleteDatabase,
        databaseExists,
        Sqflite,
        // ignore: deprecated_member_use, deprecated_member_use_from_same_package
        SqfliteOptions,
        // sqflite_api
        OpenDatabaseOptions,
        DatabaseFactory,
        Database,
        Transaction,
        Batch,
        ConflictAlgorithm,
        // ignore: deprecated_member_use, deprecated_member_use_from_same_package
        Sqflite.devSetOptions,
        sqfliteLogLevelNone,
        sqfliteLogLevelSql,
        sqfliteLogLevelVerbose,
        databaseFactory,
      ]) {
        expect(value, isNotNull);
      }
    });

    test('firstIntValue', () {
      expect(
          Sqflite.firstIntValue(<Map<String, Object?>>[
            <String, Object?>{'test': 1}
          ]),
          1);
      expect(
          Sqflite.firstIntValue(<Map<String, Object?>>[
            <String, Object?>{'test': 1},
            <String, Object?>{'test': 1}
          ]),
          1);
      expect(
          Sqflite.firstIntValue(<Map<String, Object?>>[
            <String, Object?>{'test': null}
          ]),
          null);
      expect(Sqflite.firstIntValue(<Map<String, Object?>>[<String, Object?>{}]),
          isNull);
      expect(Sqflite.firstIntValue(<Map<String, Object?>>[]), isNull);
      expect(Sqflite.firstIntValue(<Map<String, Object?>>[<String, Object?>{}]),
          isNull);
    });

    test('hex', () {
      expect(
          Sqflite.hex(<int>[
            0,
            1,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            9,
            10,
            11,
            12,
            13,
            14,
            15,
            16,
            17,
            255
          ]),
          '000102030405060708090A0B0C0D0E0F1011FF');
      expect(Sqflite.hex(<int>[]), '');
      expect(Sqflite.hex(<int>[32]), '20');

      try {
        Sqflite.hex(<int>[-1]);
        fail('should fail');
      } on FormatException catch (_) {}

      try {
        Sqflite.hex(<int>[256]);
        fail('should fail');
      } on FormatException catch (_) {}
    });

    /*
    test('open null', () async {
      AssertionError? exception;
      try {
        await openDatabase(null!);
      } on AssertionError catch (e) {
        exception = e;
      }
      expect(exception, isNotNull);
    });
     */

    test('databaseFactory', () {
      final originalDefaultFactory = databaseFactory;
      try {
        databaseFactory = null;
        final factory = MockDatabaseFactoryEmpty();
        databaseFactory = factory;
        expect(databaseFactory, factory);
        expect(databaseFactory, isNot(originalDefaultFactory));
        databaseFactory = originalDefaultFactory; // stderr trigger here

        try {
          databaseFactory = MockInvalidFactory();
          fail('should fail');
        } on ArgumentError catch (_) {}
      } finally {
        databaseFactory = null;
        databaseFactory = originalDefaultFactory;
      }
    });
  });
}
