import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqlite_api.dart';

void main() {
  group('sqlite_api', () {
    // Check that public api are exported
    test('exported', () {
      for (var value in <dynamic>[
        OpenDatabaseOptions,
        DatabaseFactory,
        Database,
        Transaction,
        Batch,
        ConflictAlgorithm,
        inMemoryDatabasePath,
        OnDatabaseConfigureFn,
        OnDatabaseCreateFn,
        OnDatabaseOpenFn,
        OnDatabaseVersionChangeFn,
        onDatabaseDowngradeDelete,
        sqfliteLogLevelNone,
        sqfliteLogLevelSql,
        sqfliteLogLevelVerbose,
      ]) {
        expect(value, isNotNull);
      }
    });
  });
}
