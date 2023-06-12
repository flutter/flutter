import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqflite_dev.dart';

import 'src_mixin_test.dart' show MockDatabaseFactoryEmpty;

void main() {
  group('sqflite_dev', () {
    test('setMockDatabaseFactory', () async {
      final factory = MockDatabaseFactoryEmpty();
      expect(factory, isNot(databaseFactoryOrNull));
      // ignore: deprecated_member_use_from_same_package
      setMockDatabaseFactory(factory);
      expect(factory, databaseFactory);

      try {
        await openDatabase(inMemoryDatabasePath);
        expect(factory.methods, ['openDatabase']);
      } finally {
        // ignore: deprecated_member_use_from_same_package
        setMockDatabaseFactory(null);
      }
    });

    // Check that public api are exported
    test('exported', () {
      for (var value in <dynamic>[
        MockDatabaseFactoryEmpty,
      ]) {
        expect(value, isNotNull);
      }
    });
  });
}
