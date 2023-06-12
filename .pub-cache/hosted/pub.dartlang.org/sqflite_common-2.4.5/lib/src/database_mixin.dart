import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common/src/batch.dart';
import 'package:sqflite_common/src/collection_utils.dart';
import 'package:sqflite_common/src/constant.dart';
import 'package:sqflite_common/src/cursor.dart';
import 'package:sqflite_common/src/database.dart';
import 'package:sqflite_common/src/exception.dart';
import 'package:sqflite_common/src/factory.dart';
import 'package:sqflite_common/src/path_utils.dart';
import 'package:sqflite_common/src/sql_builder.dart';
import 'package:sqflite_common/src/transaction.dart';
import 'package:sqflite_common/src/utils.dart';
import 'package:sqflite_common/src/utils.dart' as utils;
import 'package:sqflite_common/src/value_utils.dart';
import 'package:sqflite_common/utils/utils.dart';
import 'package:synchronized/synchronized.dart';

/// Base database implementation
class SqfliteDatabaseBase
    with SqfliteDatabaseMixin, SqfliteDatabaseExecutorMixin {
  /// ctor
  SqfliteDatabaseBase(SqfliteDatabaseOpenHelper openHelper, String path,
      {OpenDatabaseOptions? options}) {
    this.openHelper = openHelper;
    this.path = path;
  }
}

/// Common database/transaction implementation
mixin SqfliteDatabaseExecutorMixin implements SqfliteDatabaseExecutor {
  @override
  SqfliteTransaction? get txn;

  @override
  SqfliteDatabase get db;

  /// Execute an SQL query with no return value
  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) {
    db.checkNotClosed();
    return db.txnExecute<dynamic>(txn, sql, arguments);
  }

  /// Execute a raw SQL INSERT query
  ///
  /// Returns the last inserted record id
  @override
  Future<int> rawInsert(String sql, [List<Object?>? arguments]) {
    db.checkNotClosed();
    return db.txnRawInsert(txn, sql, arguments);
  }

  /// Insert a row into a table, where the keys of [values] correspond to
  /// column names
  @override
  Future<int> insert(String table, Map<String, Object?> values,
      {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm}) {
    final builder = SqlBuilder.insert(table, values,
        nullColumnHack: nullColumnHack, conflictAlgorithm: conflictAlgorithm);
    return rawInsert(builder.sql, builder.arguments);
  }

  /// Helper to query a table
  ///
  /// @param distinct true if you want each row to be unique, false otherwise.
  /// @param table The table names to compile the query against.
  /// @param columns A list of which columns to return. Passing null will
  ///            return all columns, which is discouraged to prevent reading
  ///            data from storage that isn't going to be used.
  /// @param where A filter declaring which rows to return, formatted as an SQL
  ///            WHERE clause (excluding the WHERE itself). Passing null will
  ///            return all rows for the given URL.
  /// @param groupBy A filter declaring how to group rows, formatted as an SQL
  ///            GROUP BY clause (excluding the GROUP BY itself). Passing null
  ///            will cause the rows to not be grouped.
  /// @param having A filter declare which row groups to include in the cursor,
  ///            if row grouping is being used, formatted as an SQL HAVING
  ///            clause (excluding the HAVING itself). Passing null will cause
  ///            all row groups to be included, and is required when row
  ///            grouping is not being used.
  /// @param orderBy How to order the rows, formatted as an SQL ORDER BY clause
  ///            (excluding the ORDER BY itself). Passing null will use the
  ///            default sort order, which may be unordered.
  /// @param limit Limits the number of rows returned by the query,
  /// @param offset starting index,
  ///
  /// @return the items found
  ///
  @override
  Future<List<Map<String, Object?>>> query(String table,
      {bool? distinct,
      List<String>? columns,
      String? where,
      List<Object?>? whereArgs,
      String? groupBy,
      String? having,
      String? orderBy,
      int? limit,
      int? offset}) {
    final builder = SqlBuilder.query(table,
        distinct: distinct,
        columns: columns,
        where: where,
        groupBy: groupBy,
        having: having,
        orderBy: orderBy,
        limit: limit,
        offset: offset,
        whereArgs: whereArgs);
    return rawQuery(builder.sql, builder.arguments);
  }

  /// Execute a raw SQL SELECT query
  ///
  /// Returns a list of rows that were found
  @override
  Future<List<Map<String, Object?>>> rawQuery(String sql,
      [List<Object?>? arguments]) {
    checkRawArgs(arguments);
    return _rawQuery(sql, arguments);
  }

  Future<List<Map<String, Object?>>> _rawQuery(String sql,
      [List<Object?>? arguments]) {
    db.checkNotClosed();
    return db.txnRawQuery(txn, sql, arguments);
  }

  @override
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
      int? bufferSize}) {
    final builder = SqlBuilder.query(table,
        distinct: distinct,
        columns: columns,
        where: where,
        groupBy: groupBy,
        having: having,
        orderBy: orderBy,
        limit: limit,
        offset: offset,
        whereArgs: whereArgs);
    return _rawQueryCursor(builder.sql, builder.arguments, bufferSize);
  }

  @override
  Future<QueryCursor> rawQueryCursor(String sql, List<Object?>? arguments,
      {int? bufferSize}) {
    checkRawArgs(arguments);
    return _rawQueryCursor(sql, arguments, bufferSize);
  }

  Future<QueryCursor> _rawQueryCursor(
      String sql, List<Object?>? arguments, int? pageSize) {
    pageSize ??= queryCursorBufferSizeDefault;
    db.checkNotClosed();
    return db.txnRawQueryCursor(txn, sql, arguments, pageSize);
  }

  /// Execute a raw SQL UPDATE query
  ///
  /// Returns the number of changes made
  @override
  Future<int> rawUpdate(String sql, [List<Object?>? arguments]) {
    checkRawArgs(arguments);
    return _rawUpdate(sql, arguments);
  }

  /// Execute a raw SQL UPDATE query
  ///
  /// Returns the number of changes made
  Future<int> _rawUpdate(String sql, [List<Object?>? arguments]) {
    db.checkNotClosed();
    return db.txnRawUpdate(txn, sql, arguments);
  }

  /// Convenience method for updating rows in the database.
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
  /// conflict. See [ConflictResolver] docs for more details
  @override
  Future<int> update(String table, Map<String, Object?> values,
      {String? where,
      List<Object?>? whereArgs,
      ConflictAlgorithm? conflictAlgorithm}) {
    final builder = SqlBuilder.update(table, values,
        where: where,
        whereArgs: whereArgs,
        conflictAlgorithm: conflictAlgorithm);
    return rawUpdate(builder.sql, builder.arguments);
  }

  /// Executes a raw SQL DELETE query
  ///
  /// Returns the number of changes made
  @override
  Future<int> rawDelete(String sql, [List<Object?>? arguments]) {
    checkRawArgs(arguments);
    return _rawDelete(sql, arguments);
  }

  /// Execute a raw SQL UPDATE query
  ///
  /// Returns the number of changes made
  Future<int> _rawDelete(String sql, [List<Object?>? arguments]) {
    db.checkNotClosed();
    return db.txnRawDelete(txn, sql, arguments);
  }

  /// Convenience method for deleting rows in the database.
  ///
  /// Delete from [table]
  ///
  /// [where] is the optional WHERE clause to apply when updating. Passing null
  /// will update all rows.
  ///
  /// You may include ?s in the where clause, which will be replaced by the
  /// values from [whereArgs]
  ///
  /// [conflictAlgorithm] (optional) specifies algorithm to use in case of a
  /// conflict. See [ConflictResolver] docs for more details
  ///
  /// Returns the number of rows affected if a whereClause is passed in, 0
  /// otherwise. To remove all rows and get a count pass '1' as the
  /// whereClause.
  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) {
    final builder =
        SqlBuilder.delete(table, where: where, whereArgs: whereArgs);
    return _rawDelete(builder.sql, builder.arguments);
  }
}

/// Common extension
extension SqfliteDatabaseMixinExt on SqfliteDatabase {
  ///
  /// Get the database inner version
  ///
  Future<int> txnGetVersion(SqfliteTransaction? txn) async {
    final rows = await txnRawQuery(txn, 'PRAGMA user_version', null);
    return firstIntValue(rows) ?? 0;
  }

  /// Set the database inner version
  /// Used internally for open helpers and automatic versioning
  ///
  Future<void> txnSetVersion(SqfliteTransaction? txn, int version) async {
    await txnExecute<void>(txn, 'PRAGMA user_version = $version', null);
  }

  /// Base database map parameter.
  Map<String, Object?> getBaseDatabaseMethodArguments(SqfliteTransaction? txn) {
    final map = <String, Object?>{
      paramId: id,
      // transaction v2
      if (txn?.transactionId != null) paramTransactionId: txn?.transactionId
    };
    return map;
  }

  /// v1 and v2 support
  /// Base database map parameter in transaction.
  Map<String, Object?> getBaseDatabaseMethodArgumentsInTransactionChange(
      SqfliteTransaction? txn, bool? inTransaction) {
    final map = getBaseDatabaseMethodArguments(txn);
    addInTransactionChangeParam(map, inTransaction);
    return map;
  }

  /// v1 and v2 support
  /// Base database map parameter in transaction.
  void addInTransactionChangeParam(
      Map<String, Object?> map, bool? inTransaction) {
    if (inTransaction != null) {
      map[paramInTransaction] = inTransaction;
    }
  }

  Map<String, Object?> _txnGetSqlMethodArguments(
      SqfliteTransaction? txn, String sql, List<Object?>? sqlArguments) {
    var methodArguments = <String, Object?>{
      paramSql: sql,
      if (sqlArguments != null) paramSqlArguments: sqlArguments,
    }..addAll(getBaseDatabaseMethodArguments(txn));
    return methodArguments;
  }

  SqfliteDatabaseMixin get _mixin => this as SqfliteDatabaseMixin;

  /// try if open in read-only mode.
  bool get readOnly => _mixin.openHelper?.options?.readOnly ?? false;

  /// for Update sql query
  /// returns the update count
  Future<int> _txnRawUpdateOrDelete(
      SqfliteTransaction? txn, String sql, List<Object?>? arguments) {
    return _mixin.txnWriteSynchronized(txn, (_) async {
      final result = await _mixin.safeInvokeMethod<int?>(
          methodUpdate,
          <String, Object?>{paramSql: sql, paramSqlArguments: arguments}
            ..addAll(getBaseDatabaseMethodArguments(txn)));
      return result ?? 0;
    });
  }

  /// Run transaction.
  Future<T> _txnTransaction<T>(
      Transaction? txn, Future<T> Function(Transaction txn) action,
      {bool? exclusive}) async {
    bool? successfull;
    var transactionStarted = txn == null;
    if (transactionStarted) {
      txn = await beginTransaction(exclusive: exclusive);
    }
    T result;
    try {
      result = await action(txn);
      successfull = true;
    } finally {
      if (transactionStarted) {
        final sqfliteTransaction = txn as SqfliteTransaction;
        sqfliteTransaction.successful = successfull;
        await endTransaction(sqfliteTransaction);
      }
    }
    return result;
  }

  /// Begin a transaction.
  Future<void> txnBeginTransaction(SqfliteTransaction txn,
      {bool? exclusive}) async {
    Object? response;
    // never create transaction in read-only mode
    if (readOnly != true) {
      if (exclusive == true) {
        response = await txnExecute<dynamic>(txn, 'BEGIN EXCLUSIVE', null,
            beginTransaction: true);
      } else {
        response = await txnExecute<dynamic>(txn, 'BEGIN IMMEDIATE', null,
            beginTransaction: true);
      }
    }
    // Transaction v2 support, save the transaction id
    if (response is Map) {
      var transactionId = response[paramTransactionId];
      if (transactionId is int) {
        txn.transactionId = transactionId;
      }
    }
  }
}

/// Sqflite database mixin.
mixin SqfliteDatabaseMixin implements SqfliteDatabase {
  /// Invoke native method and wrap exception.
  Future<T> safeInvokeMethod<T>(String method, [Object? arguments]) =>
      factory.wrapDatabaseException(() => invokeMethod(method, arguments));

  /// Invoke the native method of the factory.
  @override
  Future<T> invokeMethod<T>(String method, [Object? arguments]) =>
      _mixin.factory.invokeMethod(method, arguments);

  /// Keep our open helper for proper closing.
  SqfliteDatabaseOpenHelper? openHelper;
  @override
  OpenDatabaseOptions? options;

  /// The factory.
  SqfliteDatabaseFactory get factory => openHelper!.factory;

  @override
  SqfliteDatabase get database => db;

  @override
  SqfliteDatabase get db => this;

  /// True once the client called close. It should no longer invoke native
  /// code
  bool isClosed = false;

  @override
  bool get isOpen => openHelper!.isOpen;

  @override
  late String path;

  /// Special transaction created during open.
  ///
  /// Only not null during opening.
  SqfliteTransaction? openTransaction;

  @override
  SqfliteTransaction? get txn => openTransaction;

  /// Non-reentrant lock.
  final Lock _rawLock = Lock();

  // Its internal id
  @override
  int? id;

  /// Set when parsing BEGIN and COMMIT/ROLLBACK
  bool inTransaction = false;

  /// Set internally for testing
  bool doNotUseSynchronized = false;

  /// Base database map parameter.
  /*
  Map<String, Object?> get getBaseDatabaseMethodArguments(txn) =>
      getBaseDatabaseMethodArguments(txn)(id!);*/

  @override
  Batch batch() {
    return SqfliteDatabaseBatch(this);
  }

  @override
  void checkNotClosed() {
    if (isClosed) {
      throw SqfliteDatabaseException('error database_closed', null);
    }
  }

  @override
  Future<T> devInvokeMethod<T>(String method, [Object? arguments]) {
    return invokeMethod<T>(method, arguments);
  }

  @override
  Future<T> devInvokeSqlMethod<T>(String method, String sql,
      [List<Object?>? arguments]) {
    return devInvokeMethod(method,
        <String, Object?>{paramSql: sql, paramSqlArguments: arguments}..addAll(
            // Handle the open transactin if any, but this is just for testing
            getBaseDatabaseMethodArguments(txn)));
  }

  /// synchronized call to the database
  /// not re-entrant
  /// Ugly compatibility step to not support older synchronized
  /// mechanism
  Future<T> txnSynchronized<T>(
      Transaction? txn, Future<T> Function(Transaction? txn) action) async {
    // If in a transaction, execute right away
    if (txn != null || doNotUseSynchronized) {
      return await action(txn);
    } else {
      // Simple timeout warning if we cannot get the lock after XX seconds
      final handleTimeoutWarning = (utils.lockWarningDuration != null &&
          utils.lockWarningCallback != null);
      late Completer<dynamic> timeoutCompleter;
      if (handleTimeoutWarning) {
        timeoutCompleter = Completer<dynamic>();
      }

      // Grab the lock
      final operation = _rawLock.synchronized(() {
        if (handleTimeoutWarning) {
          timeoutCompleter.complete();
        }
        return action(txn);
      });
      // Simply warn the developer as this could likely be a deadlock
      if (handleTimeoutWarning) {
        // ignore: unawaited_futures
        timeoutCompleter.future.timeout(utils.lockWarningDuration!,
            onTimeout: () {
          utils.lockWarningCallback!();
        });
      }
      return await operation;
    }
  }

  /// synchronized call to the database
  /// not re-entrant
  Future<T> txnWriteSynchronized<T>(
          Transaction? txn, Future<T> Function(Transaction? txn) action) =>
      txnSynchronized(txn, action);

  /// for sql without return values
  ///
  /// [beginTransaction] is true when beginning a transaction.
  @override
  Future<T> txnExecute<T>(
      SqfliteTransaction? txn, String sql, List<Object?>? arguments,
      {bool? beginTransaction}) {
    return txnWriteSynchronized<T>(txn, (_) {
      var inTransactionChange = getSqlInTransactionArgument(sql);

      if (inTransactionChange ?? false) {
        inTransactionChange = true;
        inTransaction = true;
      } else if (inTransactionChange == false) {
        inTransactionChange = false;
        inTransaction = false;
      }
      return invokeExecute<T>(txn, sql, arguments,
          inTransactionChange: inTransactionChange,
          beginTransaction: beginTransaction);
    });
  }

  /// [inTransactionChange] is true when entering a transaction, false when leaving
  /// should be set by parsing the sql command for all commands
  ///
  /// [beginTransaction] is true when entering a transaction and should clear
  /// the transaction param.
  Future<T> invokeExecute<T>(
      SqfliteTransaction? txn, String sql, List<Object?>? arguments,
      {bool? inTransactionChange, bool? beginTransaction}) {
    var methodArguments = _txnGetSqlMethodArguments(txn, sql, arguments);
    // Transaction v2, tell our support for transaction id
    if (beginTransaction == true) {
      methodArguments[paramTransactionId] = null;
    }
    addInTransactionChangeParam(methodArguments, inTransactionChange);
    return safeInvokeMethod(methodExecute, methodArguments);
  }

  /// for INSERT sql query
  /// returns the last inserted record id
  ///
  /// 0 returned instead of null
  @override
  Future<int> txnRawInsert(
      SqfliteTransaction? txn, String sql, List<Object?>? arguments) {
    return txnWriteSynchronized(txn, (_) async {
      // The value could be null (for insert ignore). Return 0 in this case
      return await safeInvokeMethod<int?>(
              methodInsert, _txnGetSqlMethodArguments(txn, sql, arguments)) ??
          0;
    });
  }

  @override
  Future<List<Map<String, Object?>>> txnRawQuery(
      SqfliteTransaction? txn, String sql, List<Object?>? arguments) {
    return txnSynchronized(txn, (_) async {
      final dynamic result = await safeInvokeMethod<dynamic>(
          methodQuery, _txnGetSqlMethodArguments(txn, sql, arguments));
      return queryResultToList(result);
    });
  }

  @override
  Future<SqfliteQueryCursor> txnRawQueryCursor(SqfliteTransaction? txn,
      String sql, List<Object?>? arguments, int pageSize) {
    return txnSynchronized(txn, (_) async {
      var methodArguments = _txnGetSqlMethodArguments(txn, sql, arguments);
      methodArguments[paramCursorPageSize] = pageSize;
      dynamic result =
          await safeInvokeMethod<dynamic>(methodQuery, methodArguments);

      var cursorId = queryResultCursorId(result);
      var resultList = queryResultToList(result);
      return SqfliteQueryCursor(this, txn, cursorId, resultList);
    });
  }

  /// Cursor current row.
  @override
  Map<String, Object?> txnQueryCursorGetCurrent(
      SqfliteTransaction? txn, SqfliteQueryCursor cursor) {
    if (cursor.closed) {
      throw StateError('Cursor is closed, cannot get current row');
    }
    if (cursor.currentIndex < 0 ||
        cursor.currentIndex >= cursor.resultList.length) {
      throw StateError(
          'You must have a successful moveNext() before getting the current row');
    }
    return cursor.resultList[cursor.currentIndex];
  }

  Future<void> _closeCursor(SqfliteQueryCursor cursor) async {
    if (!cursor.closed) {
      cursor.closed = true;
      var cursorId = cursor.cursorId;
      if (cursorId != null) {
        cursor.cursorId = null;
        await safeInvokeMethod<dynamic>(
            methodQueryCursorNext,
            <String, Object?>{paramCursorId: cursorId, paramCursorCancel: true}
              ..addAll(getBaseDatabaseMethodArguments(txn)));
      }
    }
  }

  @override
  Future<bool> txnQueryCursorMoveNext(
      SqfliteTransaction? txn, SqfliteQueryCursor cursor) async {
    if (cursor.closed) {
      return false;
    }
    if (cursor.currentIndex < cursor.resultList.length - 1) {
      cursor.currentIndex++;
      return true;
    }
    var cursorId = cursor.cursorId;
    if (cursorId == null) {
      // At end, let's quit
      await txnQueryCursorClose(txn, cursor);
      return false;
    } else {
      return txnSynchronized(txn, (_) async {
        if (cursor.closed) {
          return false;
        }
        var cursorId = cursor.cursorId;
        if (cursorId == null) {
          // At end, let's quit
          await _closeCursor(cursor);
          return false;
        }
        // Ok let's fetch the next batch of data
        var result = await safeInvokeMethod<dynamic>(
            methodQueryCursorNext,
            <String, Object?>{
              paramCursorId: cursorId,
            }..addAll(getBaseDatabaseMethodArguments(txn)));
        var updatedCursorId = queryResultCursorId(result);
        cursor.cursorId = updatedCursorId;
        cursor.currentIndex = 0;
        cursor.resultList = queryResultToList(result);
        if (cursor.resultList.isEmpty) {
          // cursor id should be null, but who knows...
          await _closeCursor(cursor);
          return false;
        } else {
          return true;
        }
      });
    }
  }

  @override
  Future<void> txnQueryCursorClose(
      SqfliteTransaction? txn, SqfliteQueryCursor cursor) async {
    if (!cursor.closed) {
      if (cursor.cursorId != null) {
        return txnSynchronized(txn, (_) async {
          await _closeCursor(cursor);
        });
      } else {
        cursor.closed = true;
      }
    }
  }

  /// for Update sql query
  /// returns the update count
  @override
  Future<int> txnRawUpdate(
          SqfliteTransaction? txn, String sql, List<Object?>? arguments) =>
      _txnRawUpdateOrDelete(txn, sql, arguments);

  /// for Delete sql query
  /// returns the delete count
  @override
  Future<int> txnRawDelete(
          SqfliteTransaction? txn, String sql, List<Object?>? arguments) =>
      _txnRawUpdateOrDelete(txn, sql, arguments);

  @override
  Future<List<Object?>> txnApplyBatch(
      SqfliteTransaction? txn, SqfliteBatch batch,
      {bool? noResult, bool? continueOnError}) {
    return txnWriteSynchronized(txn, (_) async {
      final arguments = <String, Object?>{
        paramOperations: batch.getOperationsParam()
      }..addAll(getBaseDatabaseMethodArguments(txn));
      if (noResult == true) {
        arguments[paramNoResult] = noResult;
      }
      if (continueOnError == true) {
        arguments[paramContinueOnError] = continueOnError;
      }
      final results =
          await safeInvokeMethod<List<dynamic>?>(methodBatch, arguments);

      // Typically when noResult is true
      if (results == null) {
        return <dynamic>[];
      }
      // dart2 - wrap if we need to support more results than just int
      return BatchResults.from(results);
    });
  }

  /// New transaction.
  SqfliteTransaction newTransaction() {
    final txn = SqfliteTransaction(this);
    return txn;
  }

  @override
  Future<SqfliteTransaction> beginTransaction({bool? exclusive}) async {
    final txn = newTransaction();
    await txnBeginTransaction(txn, exclusive: exclusive);
    return txn;
  }

  @override
  Future<void> endTransaction(SqfliteTransaction txn) async {
    // never commit transaction in read-only mode
    if (readOnly != true) {
      if (txn.successful == true) {
        await txnExecute<dynamic>(txn, 'COMMIT', null);
      } else {
        await txnExecute<dynamic>(txn, 'ROLLBACK', null);
      }
    }
  }

  @override
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action,
      {bool? exclusive}) {
    checkNotClosed();
    return txnWriteSynchronized<T>(txn, (Transaction? txn) async {
      return _txnTransaction(txn, action, exclusive: exclusive);
    });
  }

  /// Close the database. Cannot be access anymore
  @override
  Future<void> close() => factory.closeDatabase(this);

  /// Close the database. Cannot be access anymore
  @override
  Future<void> doClose() => _closeDatabase(id);

  @override
  String toString() {
    return '$id $path';
  }

  /// Open a database and returns its id.
  ///
  /// id does not run any callback calls
  Future<int> openDatabase() async {
    final params = <String, Object?>{paramPath: path};
    if (readOnly == true) {
      params[paramReadOnly] = true;
    }
    // Single instance? never for standard inMemoryDatabase
    final singleInstance =
        (options?.singleInstance ?? false) && !isInMemoryDatabasePath(path);

    params[paramSingleInstance] = singleInstance;

    // Version up to 1.1.5 returns an int
    // Now it returns some database information
    // the one being about being recovered from the native world
    // where we are going to revert
    // doing first on Android without breaking ios
    final openResult =
        await safeInvokeMethod<Object?>(methodOpenDatabase, params);
    if (openResult is int) {
      return openResult;
    } else if (openResult is Map) {
      final id = openResult[paramId] as int?;
      // Recover means we found an instance in the native world
      final recoveredInTransaction =
          openResult[paramRecoveredInTransaction] == true;
      // in this case, we are going to rollback any changes in case a transaction
      // was in progress. This catches hot-restart scenario
      if (recoveredInTransaction) {
        // Don't do it for read-only
        if (readOnly != true) {
          // We are not yet open so invoke the plugin directly
          try {
            await safeInvokeMethod<Object?>(methodExecute, <String, Object?>{
              paramSql: 'ROLLBACK',
              paramId: id,

              /// Force the action even if we are in a transaction.
              paramTransactionId: paramTransactionIdValueForce,
              paramInTransaction: false
            });
          } catch (e) {
            print('ignore recovered database ROLLBACK error $e');
          }
        }
      }
      return id!;
    } else {
      throw 'unsupported result $openResult (${openResult?.runtimeType})';
    }
  }

  final Lock _closeLock = Lock();

  /// rollback any pending transaction if needed
  Future<void> _closeDatabase(int? databaseId) async {
    await _closeLock.synchronized(() async {
      // devPrint('_closeDatabase closing $databaseId inTransaction $inTransaction isClosed $isClosed readOnly $readOnly');
      if (!isClosed) {
        // Mark as closed now
        isClosed = true;

        if (readOnly != true && inTransaction) {
          // Grab lock to prevent future access
          // At least we know no other request will be ran
          try {
            await txnWriteSynchronized(txn, (Transaction? txn) async {
              // Special trick to cancel any pending transaction
              try {
                await invokeExecute<dynamic>(

                    /// Force if needed
                    (txn as SqfliteTransaction?) ??
                        getForcedSqfliteTransaction(this),
                    'ROLLBACK',
                    null,
                    inTransactionChange: false);
              } catch (_) {
                // devPrint('rollback error $_');
              }
            });
          } catch (e) {
            print('Error $e before rollback');
          }
        }

        // close for good
        // Catch exception, close should never fail
        try {
          await safeInvokeMethod<dynamic>(
              methodCloseDatabase, <String, Object?>{paramId: databaseId});
        } catch (e) {
          print('error $e closing database $databaseId');
        }
      }
    });
  }

  // To call during open
  // not exported
  @override
  Future<SqfliteDatabase> doOpen(OpenDatabaseOptions options) async {
    if (options.version != null) {
      if (options.version == 0) {
        throw ArgumentError('version cannot be set to 0 in openDatabase');
      }
    } else {
      if (options.onCreate != null) {
        throw ArgumentError('onCreate must be null if no version is specified');
      }
      if (options.onUpgrade != null) {
        throw ArgumentError(
            'onUpgrade must be null if no version is specified');
      }
      if (options.onDowngrade != null) {
        throw ArgumentError(
            'onDowngrade must be null if no version is specified');
      }
    }
    this.options = options;
    var databaseId = await openDatabase();

    try {
      // Special on downgrade delete database
      if (options.onDowngrade == onDatabaseDowngradeDelete) {
        // Downgrading will delete the database and open it again
        Future<void> onDatabaseDowngradeDoDelete(
            Database database, int oldVersion, int newVersion) async {
          final db = database as SqfliteDatabase;
          // This is tricky as we are in the middle of opening a database
          // need to close what is being done and restart
          await db.doClose();
          // But don't mark it as closed
          isClosed = false;

          await factory.deleteDatabase(db.path);

          // get a new database id after open
          db.id = databaseId = await openDatabase();

          try {
            // Since we deleted the database re-run the needed first steps:
            // onConfigure then onCreate
            if (options.onConfigure != null) {
              await options.onConfigure!(db);
            }
          } catch (e) {
            // This exception is sometimes hard te catch
            // during development
            print(e);

            // create a transaction just to make the current transaction happy
            openTransaction = await db.beginTransaction(exclusive: true);
            rethrow;
          }

          // Recreate a new transaction
          // no end transaction it will be done later before calling then onOpen
          openTransaction = await db.beginTransaction(exclusive: true);
          if (options.onCreate != null) {
            await options.onCreate!(db, options.version!);
          }
        }

        options.onDowngrade = onDatabaseDowngradeDoDelete;
      }

      id = databaseId;

      // first configure it
      if (options.onConfigure != null) {
        await options.onConfigure!(this);
      }

      if (options.version != null) {
        // Check the version outside of the transaction
        // And only create the transaction if needed (https://github.com/tekartik/sqflite/issues/459)
        final oldVersion = await getVersion();
        if (oldVersion != options.version) {
          try {
            await transaction((Transaction txn) async {
              // Set the current transaction as the open one
              // to allow direct database call during open and allowing
              // creating a fake transaction (since we are already in a transaction)
              final sqfliteTransaction = txn as SqfliteTransaction;
              openTransaction = sqfliteTransaction;

              // We read again the version to be safe regarding edge cases
              final oldVersion = await txnGetVersion(txn);
              if (oldVersion == 0) {
                if (options.onCreate != null) {
                  await options.onCreate!(this, options.version!);
                } else if (options.onUpgrade != null) {
                  await options.onUpgrade!(this, 0, options.version!);
                }
              } else if (options.version! > oldVersion) {
                if (options.onUpgrade != null) {
                  await options.onUpgrade!(this, oldVersion, options.version!);
                }
              } else if (options.version! < oldVersion) {
                if (options.onDowngrade != null) {
                  await options.onDowngrade!(
                      this, oldVersion, options.version!);
                  // Check and reuse transaction if if needed
                  // in case downgrade delete was called
                  if (openTransaction!.transactionId != txn.transactionId) {
                    txn.transactionId = openTransaction!.transactionId;
                  }
                }
              }
              if (oldVersion != options.version) {
                await setVersion(options.version!);
              }
            }, exclusive: true);
          } finally {
            // clean up open transaction
            openTransaction = null;
          }
        }
      }

      if (options.onOpen != null) {
        await options.onOpen!(this);
      }

      return this;
    } catch (e) {
      print('error $e during open, closing...');
      await _closeDatabase(databaseId);
      rethrow;
    } finally {
      // clean up open transaction
      openTransaction = null;
    }
  }
}
