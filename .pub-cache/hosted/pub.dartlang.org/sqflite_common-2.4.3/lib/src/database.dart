import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common/src/batch.dart';
import 'package:sqflite_common/src/factory.dart';
import 'package:sqflite_common/src/transaction.dart';

import 'cursor.dart';

/// Base database executor.
abstract class SqfliteDatabaseExecutor implements DatabaseExecutor {
  /// Executor transaction if any.
  SqfliteTransaction? get txn;

  /// Executor database.
  SqfliteDatabase get db;
}

/// Open helper.
class SqfliteDatabaseOpenHelper {
  /// Creates a database helper.
  SqfliteDatabaseOpenHelper(this.factory, this.path, this.options);

  /// Our database factory
  final SqfliteDatabaseFactory factory;

  /// Open options
  final OpenDatabaseOptions? options;

  /// Our database pathy
  final String path;

  /// The database once opened.
  SqfliteDatabase? sqfliteDatabase;

  /// Creates a new database object.
  SqfliteDatabase newDatabase(String path) => factory.newDatabase(this, path);

  /// True if the database is opened
  bool get isOpen => sqfliteDatabase != null;

  // Future<SqfliteDatabase> get databaseReady => _completer.future;

  /// Open or return the one opened.
  Future<SqfliteDatabase> openDatabase() async {
    if (!isOpen) {
      final database = newDatabase(path);
      await database.doOpen(options!);
      sqfliteDatabase = database;
    }
    return sqfliteDatabase!;
  }

  /// Open the database if opened.
  Future<void> closeDatabase(SqfliteDatabase sqfliteDatabase) async {
    if (!isOpen) {
      return;
    }
    await sqfliteDatabase.doClose();
    this.sqfliteDatabase = null;
  }
}

/// Internal database interface.
abstract class SqfliteDatabase extends SqfliteDatabaseExecutor
    implements Database {
  /// Actually open the database.
  Future<SqfliteDatabase> doOpen(OpenDatabaseOptions options);

  /// Actually close the database.
  Future<void> doClose();

  /// Database internal id.
  int? id;

  /// Open options.
  OpenDatabaseOptions? options;

  /// Begin a transaction.
  Future<SqfliteTransaction> beginTransaction({bool? exclusive});

  /// Ends a transaction.
  Future<void> endTransaction(SqfliteTransaction txn);

  /// Commit a batch.
  Future<List<Object?>> txnApplyBatch(
      SqfliteTransaction? txn, SqfliteBatch batch,
      {bool? noResult, bool? continueOnError});

  /// Execute a command.
  Future<T> txnExecute<T>(
      SqfliteTransaction? txn, String sql, List<Object?>? arguments,
      {bool? beginTransaction});

  /// Execute a raw INSERT command.
  Future<int> txnRawInsert(
      SqfliteTransaction? txn, String sql, List<Object?>? arguments);

  /// Execute a raw SELECT command.
  Future<List<Map<String, Object?>>> txnRawQuery(
      SqfliteTransaction? txn, String sql, List<Object?>? arguments);

  /// Execute a raw SELECT command by page.
  Future<SqfliteQueryCursor> txnRawQueryCursor(SqfliteTransaction? txn,
      String sql, List<Object?>? arguments, int pageSize);

  /// Cursor move next.
  Future<bool> txnQueryCursorMoveNext(
      SqfliteTransaction? txn, SqfliteQueryCursor cursor);

  /// Cursor current row.
  Map<String, Object?> txnQueryCursorGetCurrent(
      SqfliteTransaction? txn, SqfliteQueryCursor cursor);

  /// Close the cursor.
  Future<void> txnQueryCursorClose(
      SqfliteTransaction? txn, SqfliteQueryCursor cursor);

  /// Execute a raw UPDATE command.
  Future<int> txnRawUpdate(
      SqfliteTransaction? txn, String sql, List<Object?>? arguments);

  /// Execute a raw DELETE command.
  Future<int> txnRawDelete(
      SqfliteTransaction? txn, String sql, List<Object?>? arguments);

  /// Check if a database is not closed.
  ///
  /// Throw an exception if closed.
  void checkNotClosed();

  /// Allow database overriding.
  Future<T> invokeMethod<T>(String method, [Object? arguments]);
}
