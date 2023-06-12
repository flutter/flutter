import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common/src/constant.dart';
import 'package:sqflite_common/src/database.dart';
import 'package:sqflite_common/src/sql_builder.dart';
import 'package:sqflite_common/src/transaction.dart';
import 'package:sqflite_common/src/utils.dart';

/// Batch implementation
abstract class SqfliteBatch implements Batch {
  /// List of operations
  final List<Map<String, Object?>> operations = <Map<String, Object?>>[];

  Map<String, Object?> _getOperationMap(
      String method, String sql, List<Object?>? arguments) {
    return <String, Object?>{
      paramMethod: method,
      paramSql: sql,
      if (arguments != null) paramSqlArguments: arguments
    };
  }

  void _add(String method, String sql, List<Object?>? arguments) {
    operations.add(_getOperationMap(method, sql, arguments));
  }

  void _addExecute(String method, String sql, List<Object?>? arguments,
      bool? inTransaction) {
    final map = _getOperationMap(method, sql, arguments);
    if (inTransaction != null) {
      map[paramInTransaction] = inTransaction;
    }
    operations.add(map);
  }

  @override
  void rawInsert(String sql, [List<Object?>? arguments]) {
    _add(methodInsert, sql, arguments);
  }

  @override
  void insert(String table, Map<String, Object?> values,
      {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm}) {
    final builder = SqlBuilder.insert(table, values,
        nullColumnHack: nullColumnHack, conflictAlgorithm: conflictAlgorithm);
    return rawInsert(builder.sql, builder.arguments);
  }

  @override
  void rawQuery(String sql, [List<Object?>? arguments]) {
    _add(methodQuery, sql, arguments);
  }

  @override
  void query(String table,
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
        whereArgs: whereArgs,
        groupBy: groupBy,
        having: having,
        orderBy: orderBy,
        limit: limit,
        offset: offset);
    return rawQuery(builder.sql, builder.arguments);
  }

  @override
  void rawUpdate(String sql, [List<Object?>? arguments]) {
    _add(methodUpdate, sql, arguments);
  }

  @override
  void update(String table, Map<String, Object?> values,
      {String? where,
      List<Object?>? whereArgs,
      ConflictAlgorithm? conflictAlgorithm}) {
    final builder = SqlBuilder.update(table, values,
        where: where,
        whereArgs: whereArgs,
        conflictAlgorithm: conflictAlgorithm);
    return rawUpdate(builder.sql, builder.arguments);
  }

  @override
  void delete(String table, {String? where, List<Object?>? whereArgs}) {
    final builder =
        SqlBuilder.delete(table, where: where, whereArgs: whereArgs);
    return rawDelete(builder.sql, builder.arguments);
  }

  @override
  void rawDelete(String sql, [List<Object?>? arguments]) {
    rawUpdate(sql, arguments);
  }

  @override
  void execute(String sql, [List<Object?>? arguments]) {
    // Check for begin/end transaction
    final inTransaction = getSqlInTransactionArgument(sql);
    _addExecute(methodExecute, sql, arguments, inTransaction);
  }
}

/// Batch on a given database
class SqfliteDatabaseBatch extends SqfliteBatch {
  /// Create a batch in a database
  SqfliteDatabaseBatch(this.database);

  /// Our database
  final SqfliteDatabase database;

  @override
  Future<List<Object?>> commit({
    bool? exclusive,
    bool? noResult,
    bool? continueOnError,
  }) {
    database.checkNotClosed();

    return database.transaction<List<Object?>>((Transaction txn) {
      final sqfliteTransaction = txn as SqfliteTransaction;
      return database.txnApplyBatch(sqfliteTransaction, this,
          noResult: noResult, continueOnError: continueOnError);
    }, exclusive: exclusive);
  }

  @override
  Future<List<Object?>> apply({bool? noResult, bool? continueOnError}) {
    return database.txnApplyBatch(null, this,
        noResult: noResult, continueOnError: continueOnError);
  }
}

/// Batch on a given transaction
class SqfliteTransactionBatch extends SqfliteBatch {
  /// Create a batch in a transaction
  SqfliteTransactionBatch(this.transaction);

  /// Our transaction
  final SqfliteTransaction transaction;

  @override
  Future<List<Object?>> commit({
    bool? exclusive,
    bool? noResult,
    bool? continueOnError,
  }) {
    if (exclusive != null) {
      throw ArgumentError.value(exclusive, 'exclusive',
          'must not be set when commiting a batch in a transaction');
    }

    return apply(noResult: noResult, continueOnError: continueOnError);
  }

  @override
  Future<List<Object?>> apply({bool? noResult, bool? continueOnError}) {
    return transaction.database.txnApplyBatch(transaction, this,
        noResult: noResult, continueOnError: continueOnError);
  }
}
