import 'dart:async';

import 'package:sqflite_common/sql.dart' show ConflictAlgorithm;
import 'package:sqflite_common/src/database.dart';
import 'package:sqflite_common/src/database_mixin.dart';
import 'package:sqflite_common/src/open_options.dart' as impl;
import 'package:sqflite_common/src/transaction.dart';

export 'package:sqflite_common/sql.dart' show ConflictAlgorithm;
export 'package:sqflite_common/src/constant.dart'
    show
        inMemoryDatabasePath,
        sqfliteLogLevelNone,
        sqfliteLogLevelSql,
        sqfliteLogLevelVerbose;
export 'package:sqflite_common/src/exception.dart' show DatabaseException;
export 'package:sqflite_common/src/sqflite_debug.dart'
    show SqfliteDatabaseFactoryDebug, DatabaseFactoryLoggerDebugExt;

/// Basic databases operations
abstract class DatabaseFactory {
  /// Open a database at [path] with the given [OpenDatabaseOptions]`options`
  ///
  /// ```
  ///   var databasesPath = await getDatabasesPath();
  ///   String path = join(databasesPath, 'demo.db');
  ///   Database database = await openDatabase(path, version: 1,
  ///       onCreate: (Database db, int version) async {
  ///     // When creating the db, create the table
  ///     await db.execute(
  ///         'CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT, value INTEGER, num REAL)');
  ///   });
  ///```
  /// Notice, `join` is a part of the [path](https://pub.dev/packages/path) package
  Future<Database> openDatabase(String path, {OpenDatabaseOptions? options});

  /// Get the default databases location path.
  ///
  /// When using sqfliteFactory:
  /// * On Android, it is typically data/data/<package_name>/databases
  /// * On iOS and MacOS, it is the Documents directory
  ///
  /// For other implementation (ffi), the location is a default location
  /// that makes mainly sense for debug/testing and you'd better rely on a
  /// custom strategy using package such as `path_provider`.
  Future<String> getDatabasesPath();

  /// Set the default databases location path
  Future<void> setDatabasesPath(String path);

  /// Delete a database if it exists
  Future<void> deleteDatabase(String path);

  /// Check if a database exists
  Future<bool> databaseExists(String path);
}

///
/// Common API for [Database] and [Transaction] to execute SQL commands
///
abstract class DatabaseExecutor {
  /// Execute an SQL query with no return value.
  ///
  /// ```
  ///   await db.execute(
  ///   'CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT, value INTEGER, num REAL)');
  /// ```
  Future<void> execute(String sql, [List<Object?>? arguments]);

  /// Executes a raw SQL INSERT query and returns the last inserted row ID.
  ///
  /// ```
  /// int id1 = await database.rawInsert(
  ///   'INSERT INTO Test(name, value, num) VALUES("some name", 1234, 456.789)');
  /// ```
  ///
  /// 0 could be returned for some specific conflict algorithms if not inserted.
  Future<int> rawInsert(String sql, [List<Object?>? arguments]);

  /// This method helps insert a map of [values]
  /// into the specified [table] and returns the
  /// id of the last inserted row.
  ///
  /// ```
  ///    var value = {
  ///      'age': 18,
  ///      'name': 'value'
  ///    };
  ///    int id = await db.insert(
  ///      'table',
  ///      value,
  ///      conflictAlgorithm: ConflictAlgorithm.replace,
  ///    );
  /// ```
  ///
  /// 0 could be returned for some specific conflict algorithms if not inserted.
  Future<int> insert(String table, Map<String, Object?> values,
      {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm});

  /// This is a helper to query a table and return the items found. All optional
  /// clauses and filters are formatted as SQL queries
  /// excluding the clauses' names.
  ///
  /// [table] contains the table names to compile the query against.
  ///
  /// [distinct] when set to true ensures each row is unique.
  ///
  /// The [columns] list specify which columns to return. Passing null will
  /// return all columns, which is discouraged.
  ///
  /// [where] filters which rows to return. Passing null will return all rows
  /// for the given URL. '?'s are replaced with the items in the
  /// [whereArgs] field.
  ///
  /// [groupBy] declares how to group rows. Passing null
  /// will cause the rows to not be grouped.
  ///
  /// [having] declares which row groups to include in the cursor,
  /// if row grouping is being used. Passing null will cause
  /// all row groups to be included, and is required when row
  /// grouping is not being used.
  ///
  /// [orderBy] declares how to order the rows,
  /// Passing null will use the default sort order,
  /// which may be unordered.
  ///
  /// [limit] limits the number of rows returned by the query.
  ///
  /// [offset] specifies the starting index.
  ///
  /// ```
  ///  List<Map> maps = await db.query(tableTodo,
  ///      columns: ['columnId', 'columnDone', 'columnTitle'],
  ///      where: 'columnId = ?',
  ///      whereArgs: [id]);
  /// ```
  Future<List<Map<String, Object?>>> query(String table,
      {bool? distinct,
      List<String>? columns,
      String? where,
      List<Object?>? whereArgs,
      String? groupBy,
      String? having,
      String? orderBy,
      int? limit,
      int? offset});

  /// Executes a raw SQL SELECT query and returns a list
  /// of the rows that were found.
  ///
  /// ```
  /// List<Map> list = await database.rawQuery('SELECT * FROM Test');
  /// ```
  Future<List<Map<String, Object?>>> rawQuery(String sql,
      [List<Object?>? arguments]);

  /// Executes a raw SQL SELECT with a cursor.
  ///
  /// Returns a cursor, that must either be closed when reaching the end or
  /// that must be closed manually. You have to do [QueryCursor.moveNext] to
  /// navigate (forward) in the cursor.
  ///
  /// Since its implementation cache rows for efficiency, [bufferSize] specified the
  /// number of rows to cache (100 being the default)
  ///
  /// ```
  /// var cursor = await database.rawQueryCursor('SELECT * FROM Test');
  /// ```
  Future<QueryCursor> rawQueryCursor(String sql, List<Object?>? arguments,
      {int? bufferSize});

  /// See [DatabaseExecutor.rawQueryCursor] for details about the argument [bufferSize]
  /// See [DatabaseExecutor.query] for the other arguments.
  Future<QueryCursor> queryCursor(String table,
      {bool? distinct,
      List<String>? columns,
      String? where,
      List<Object?>? whereArgs,
      String? groupBy,
      String? having,
      String? orderBy,
      int? limit,
      int? offset,
      int? bufferSize});

  /// Executes a raw SQL UPDATE query and returns
  /// the number of changes made.
  ///
  /// ```
  /// int count = await database.rawUpdate(
  ///   'UPDATE Test SET name = ?, value = ? WHERE name = ?',
  ///   ['updated name', '9876', 'some name']);
  /// ```
  Future<int> rawUpdate(String sql, [List<Object?>? arguments]);

  /// Convenience method for updating rows in the database. Returns
  /// the number of changes made
  ///
  /// Update [table] with [values], a map from column names to new column
  /// values. null is a valid value that will be translated to NULL.
  ///
  /// [where] is the optional WHERE clause to apply when updating.
  /// Passing null will update all rows.
  ///
  /// You may include ?s in the where clause, which will be replaced by the
  /// values from [whereArgs]
  ///
  /// [conflictAlgorithm] (optional) specifies algorithm to use in case of a
  /// conflict. See [ConflictAlgorithm] docs for more details
  ///
  /// ```
  /// int count = await db.update(tableTodo, todo.toMap(),
  ///    where: '$columnId = ?', whereArgs: [todo.id]);
  /// ```
  Future<int> update(String table, Map<String, Object?> values,
      {String? where,
      List<Object?>? whereArgs,
      ConflictAlgorithm? conflictAlgorithm});

  /// Executes a raw SQL DELETE query and returns the
  /// number of changes made.
  ///
  /// ```
  /// int count = await database
  ///   .rawDelete('DELETE FROM Test WHERE name = ?', ['another name']);
  /// ```
  Future<int> rawDelete(String sql, [List<Object?>? arguments]);

  /// Convenience method for deleting rows in the database.
  ///
  /// Delete from [table]
  ///
  /// [where] is the optional WHERE clause to apply when updating. Passing null
  /// will delete all rows.
  ///
  /// You may include ?s in the where clause, which will be replaced by the
  /// values from [whereArgs]
  ///
  /// Returns the number of rows affected.
  /// ```
  ///  int count = await db.delete(tableTodo, where: 'columnId = ?', whereArgs: [id]);
  /// ```
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs});

  /// Creates a batch, used for performing multiple operation
  /// in a single atomic operation.
  ///
  /// A batch can either be committed atomically with [Batch.commit], or non-
  /// atomically by calling [Batch.apply]. For details on the two methods, see
  /// their documentation.
  /// In general, it is recommended to finish batches with [Batch.commit].
  ///
  /// When committed with [Batch.commit], sqflite will manage a transaction to
  /// execute statements in the batch. If this [batch] method has been called on
  /// a [Transaction], committing the batch is deferred to when the transaction
  /// completes (but [Batch.apply] or [Batch.commit] still need to be called).
  Batch batch();

  /// Get the database.
  Database get database;
}

/// Database transaction
/// to use during a transaction
abstract class Transaction implements DatabaseExecutor {}

///
/// Database to send sql commands, created during [openDatabase]
///
abstract class Database implements DatabaseExecutor {
  /// The path of the database
  String get path;

  /// Close the database. Cannot be accessed anymore
  Future<void> close();

  /// Calls in action must only be done using the transaction object
  /// using the database will trigger a dead-lock.
  ///
  /// ```
  /// await database.transaction((txn) async {
  ///   // Ok
  ///   await txn.execute('CREATE TABLE Test1 (id INTEGER PRIMARY KEY)');
  ///
  ///   // DON'T  use the database object in a transaction
  ///   // this will deadlock!
  ///   await database.execute('CREATE TABLE Test2 (id INTEGER PRIMARY KEY)');
  /// });
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action,
      {bool? exclusive});

  /// Tell if the database is open, returns false once close has been called
  bool get isOpen;

  /// testing only
  @Deprecated('Dev only')
  Future<T> devInvokeMethod<T>(String method, [Object? arguments]);

  /// testing only
  @Deprecated('Dev only')
  Future<T> devInvokeSqlMethod<T>(String method, String sql,
      [List<Object?>? arguments]);
}

/// Helpers
extension SqfliteDatabaseExecutorExt on DatabaseExecutor {
  SqfliteDatabase get _db => (this as SqfliteDatabaseExecutor).db;
  SqfliteTransaction? get _txn => (this as SqfliteDatabaseExecutor).txn;

  ///
  /// Set the database inner version
  /// Used internally for open helpers and automatic versioning
  ///
  Future<void> setVersion(int version) {
    _db.checkNotClosed();
    return _db.txnSetVersion(_txn, version);
  }

  ///
  /// Get the database inner version
  ///
  Future<int> getVersion() {
    _db.checkNotClosed();
    return _db.txnGetVersion(_txn);
  }
}

/// Prototype of the function called when the version has changed.
///
/// Schema migration (adding column, adding table, adding trigger...)
/// should happen here.
typedef OnDatabaseVersionChangeFn = FutureOr<void> Function(
    Database db, int oldVersion, int newVersion);

/// Prototype of the function called when the database is created.
///
/// Database intialization (creating tables, views, triggers...)
/// should happen here.
typedef OnDatabaseCreateFn = FutureOr<void> Function(Database db, int version);

/// Prototype of the function called when the database is open.
///
/// Post initialization should happen here.
typedef OnDatabaseOpenFn = FutureOr<void> Function(Database db);

/// Prototype of the function called before calling [onCreate]/[onUpdate]/[onOpen]
/// when the database is open.
///
/// Post initialization should happen here.
typedef OnDatabaseConfigureFn = FutureOr<void> Function(Database db);

/// to specify during [openDatabase] for [onDowngrade]
/// Downgrading will always fail
Future<void> onDatabaseVersionChangeError(
    Database db, int oldVersion, int newVersion) async {
  throw ArgumentError("can't change version from $oldVersion to $newVersion");
}

Future<void> __onDatabaseDowngradeDelete(
    Database db, int oldVersion, int newVersion) async {
  // Implementation is hidden implemented in openDatabase._onDatabaseDowngradeDelete
}

/// Downgrading will delete the database and open it again.
///
/// To set in [onDowngrade] if you want to delete everything on downgrade.
final OnDatabaseVersionChangeFn onDatabaseDowngradeDelete =
    __onDatabaseDowngradeDelete;

///
/// Options for opening the database
/// see [openDatabase] for details
///
abstract class OpenDatabaseOptions {
  /// Open the database at a given path
  ///
  /// [version] (optional) specifies the schema version of the database being
  /// opened. This is used to decide whether to call [onCreate], [onUpgrade],
  /// and [onDowngrade]. If specified, it must be a 32-bits integer greater than
  /// 0.
  ///
  /// The optional callbacks are called in the following order:
  ///
  /// 1. [onConfigure]
  /// 2. [onCreate] or [onUpgrade] or [onDowngrade]
  /// 5. [onOpen]
  ///
  /// [onConfigure] is the first callback invoked when opening the database. It
  /// allows you to perform database initialization such as enabling foreign keys
  /// or write-ahead logging
  ///
  /// If [version] is specified, [onCreate], [onUpgrade], and [onDowngrade] can
  /// be called. These functions are mutually exclusive — only one of them can be
  /// called depending on the context, although they can all be specified to
  /// cover multiple scenarios
  ///
  /// [onCreate] is called if the database did not exist prior to calling
  /// [openDatabase]. You can use the opportunity to create the required tables
  /// in the database according to your schema
  ///
  /// [onUpgrade] is called if either of the following conditions are met:
  ///
  /// 1. [onCreate] is not specified
  /// 2. The database already exists and [version] is higher than the last
  /// database version
  ///
  /// In the first case where [onCreate] is not specified, [onUpgrade] is called
  /// with its [oldVersion] parameter as `0`. In the second case, you can perform
  /// the necessary migration procedures to handle the differing schema
  ///
  /// [onDowngrade] is called only when [version] is lower than the last database
  /// version. This is a rare case and should only come up if a newer version of
  /// your code has created a database that is then interacted with by an older
  /// version of your code. You should try to avoid this scenario
  ///
  /// [onOpen] is the last optional callback to be invoked. It is called after
  /// the database version has been set and before [openDatabase] returns
  ///
  /// When [readOnly] (false by default) is true, all other parameters are
  /// ignored and the database is opened as-is
  ///
  /// When [singleInstance] is true (the default), a single database instance is
  /// returned for a given path. Subsequent calls to [openDatabase] with the
  /// same path will return the same instance, and will discard all other
  /// parameters such as callbacks for that invocation. You could set it to
  /// false for in memory database (it is forced to false for `:memory:` path)
  /// but not for uri.
  ///
  factory OpenDatabaseOptions(
      {int? version,
      OnDatabaseConfigureFn? onConfigure,
      OnDatabaseCreateFn? onCreate,
      OnDatabaseVersionChangeFn? onUpgrade,
      OnDatabaseVersionChangeFn? onDowngrade,
      OnDatabaseOpenFn? onOpen,
      bool? readOnly = false,
      bool? singleInstance = true}) {
    return impl.SqfliteOpenDatabaseOptions(
        version: version,
        onConfigure: onConfigure,
        onCreate: onCreate,
        onUpgrade: onUpgrade,
        onDowngrade: onDowngrade,
        onOpen: onOpen,
        readOnly: readOnly,
        singleInstance: singleInstance);
  }

  /// Specify the expected version.
  int? version;

  /// called right after opening the database.
  OnDatabaseConfigureFn? onConfigure;

  /// Called when the database is created.
  OnDatabaseCreateFn? onCreate;

  /// Called when the database is upgraded.
  OnDatabaseVersionChangeFn? onUpgrade;

  /// Called when the database is downgraded.
  ///
  /// Use [onDatabaseDowngradeDelete] for re-creating the database
  OnDatabaseVersionChangeFn? onDowngrade;

  /// Called after all other callbacks have been called.
  OnDatabaseOpenFn? onOpen;

  /// Open the database in read-only mode (no callback called).
  late bool readOnly;

  /// The existing single-instance (hot-restart)
  late bool singleInstance;
}

///
/// A batch is used to perform multiple operation as a single atomic unit.
/// A Batch object can be acquired by calling [Database.batch]. It provides
/// methods for adding operation. None of the operation will be
/// executed (or visible locally) until commit() is called.
///
///
/// ```
/// batch = db.batch();
/// batch.insert('Test', {'name': 'item'});
/// batch.update('Test', {'name': 'new_item'}, where: 'name = ?', whereArgs: ['item']);
/// batch.delete('Test', where: 'name = ?', whereArgs: ['item']);
/// results = await batch.commit();
/// ```
abstract class Batch {
  /// Commits all of the operations in this batch as a single atomic unit
  /// The result is a list of the result of each operation in the same order
  /// if [noResult] is true, the result list is empty (i.e. the id inserted
  /// the count of item changed is not returned.
  ///
  /// The batch is stopped if any operation failed
  /// If [continueOnError] is true, all the operations in the batch are executed
  /// and the failure are ignored (i.e. the result for the given operation will
  /// be a DatabaseException)
  ///
  /// During [Database.onCreate], [Database.onUpgrade], [Database.onDowngrade]
  /// (we are already in a transaction) or if the batch was created in a
  /// transaction it will only be commited when
  /// the transaction is commited ([exclusive] is not used then).
  ///
  /// Otherwise, sqflite will start a transaction to commit this batch. In rare
  /// cases where you don't need an atomic operation, or where you are manually
  /// managing the transaction without using sqflite APIs, you can also use
  /// [apply] to run statements in this batch without a transaction managed by
  /// sqflite.
  Future<List<Object?>> commit({
    bool? exclusive,
    bool? noResult,
    bool? continueOnError,
  });

  /// Runs all statements in this batch non-atomically.
  ///
  /// Unlike [commit], which starts a transaction to commit statements in this
  /// batch atomically, [apply] will simply run the statements without starting
  /// a transaction internally.
  ///
  /// This can be useful in the rare cases where you don't need a sqflite
  /// transaction, for instance because you are manually starting a transaction
  /// or because you simply don't need the batch to be applied atomically.
  ///
  /// In general, prefer [commit] to run batches over this method.
  Future<List<Object?>> apply({bool? noResult, bool? continueOnError});

  /// See [Database.rawInsert]
  void rawInsert(String sql, [List<Object?>? arguments]);

  /// See [Database.insert]
  void insert(String table, Map<String, Object?> values,
      {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm});

  /// See [Database.rawUpdate]
  void rawUpdate(String sql, [List<Object?>? arguments]);

  /// See [Database.update]
  void update(String table, Map<String, Object?> values,
      {String? where,
      List<Object?>? whereArgs,
      ConflictAlgorithm? conflictAlgorithm});

  /// See [Database.rawDelete]
  void rawDelete(String sql, [List<Object?>? arguments]);

  /// See [Database.delete]
  void delete(String table, {String? where, List<Object?>? whereArgs});

  /// See [Database.execute];
  void execute(String sql, [List<Object?>? arguments]);

  /// See [Database.query];
  void query(String table,
      {bool? distinct,
      List<String>? columns,
      String? where,
      List<Object?>? whereArgs,
      String? groupBy,
      String? having,
      String? orderBy,
      int? limit,
      int? offset});

  /// See [Database.query];
  void rawQuery(String sql, [List<Object?>? arguments]);

  /// Current batch size
  int get length;
}

/// Cursor for query by page cursor.
abstract class QueryCursor {
  /// Move to the next row.
  ///
  /// If false is returned, the cursor is closed and is no longer valid.
  Future<bool> moveNext();

  /// Current row data.
  Map<String, Object?> get current;

  /// Close the current cursor.
  ///
  /// Not needed when reaching the end of the cursor (moveNext returning false.
  Future<void> close();
}
