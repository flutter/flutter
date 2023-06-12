import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common/src/database.dart';
import 'package:sqflite_common/src/mixin/factory.dart';

/// Internal database factory interface.
abstract class SqfliteDatabaseFactory
    implements DatabaseFactory, SqfliteInvokeHandler {
  /// Wrap any exception to a [DatabaseException].
  Future<T> wrapDatabaseException<T>(Future<T> Function() action);

  // To override
  // This also should wrap exception
  //Future<T> safeInvokeMethod<T>(String method, [Object? arguments]);

  /// Create a new database object.
  SqfliteDatabase newDatabase(
      SqfliteDatabaseOpenHelper openHelper, String path);

  /// Remove our internal open helper.
  void removeDatabaseOpenHelper(String path);

  @override
  Future<Database> openDatabase(String path, {OpenDatabaseOptions? options});

  /// Close the database.
  ///
  /// db.close() calls this right await.
  Future<void> closeDatabase(SqfliteDatabase database);

  @override
  Future<void> deleteDatabase(String path);

  @override
  Future<bool> databaseExists(String path);
}
