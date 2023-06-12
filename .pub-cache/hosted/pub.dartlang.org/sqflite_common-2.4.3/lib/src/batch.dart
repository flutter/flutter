import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common/src/constant.dart';
import 'package:sqflite_common/src/database.dart';
import 'package:sqflite_common/src/sql_builder.dart';
import 'package:sqflite_common/src/sql_command.dart';
import 'package:sqflite_common/src/transaction.dart';
import 'package:sqflite_common/src/utils.dart';

/// Batch mixin.
mixin SqfliteBatchMixin implements Batch {
  @override
  void insert(String table, Map<String, Object?> values,
      {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm}) {
    final builder = SqlBuilder.insert(table, values,
        nullColumnHack: nullColumnHack, conflictAlgorithm: conflictAlgorithm);
    return rawInsert(builder.sql, builder.arguments);
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
}

/// Internal batch operation.
class SqfliteBatchOperation extends SqfliteSqlCommand {
  /// Protocol method for each operation.
  final String method;

  Map<String, Object?> _getOperationParam() {
    var map = <String, Object?>{
      paramMethod: method,
      paramSql: sql,
      if (arguments != null) paramSqlArguments: arguments
    };
    // Handle in transaction change if needed
    if (type == SqliteSqlCommandType.execute) {
      // Check for begin/end transaction
      final inTransaction = getSqlInTransactionArgument(sql);
      if (inTransaction != null) {
        map[paramInTransaction] = inTransaction;
      }
    }
    return map;
  }

  /// Internal batch operation.
  SqfliteBatchOperation(super.type, this.method, super.sql, super.arguments);
}

/// Batch implementation
abstract class SqfliteBatch with SqfliteBatchMixin implements Batch {
  /// Get the list of operation as parameter for batch.
  List<Map<String, Object?>> getOperationsParam() =>
      operations.map((e) => e._getOperationParam()).toList();

  /// List of operations
  final operations = <SqfliteBatchOperation>[];

  @override
  void rawInsert(String sql, [List<Object?>? arguments]) {
    operations.add(SqfliteBatchOperation(
        SqliteSqlCommandType.insert, methodInsert, sql, arguments));
  }

  @override
  void rawQuery(String sql, [List<Object?>? arguments]) {
    operations.add(SqfliteBatchOperation(
        SqliteSqlCommandType.query, methodQuery, sql, arguments));
  }

  @override
  void rawUpdate(String sql, [List<Object?>? arguments]) {
    operations.add(SqfliteBatchOperation(
        SqliteSqlCommandType.update, methodUpdate, sql, arguments));
  }

  @override
  void rawDelete(String sql, [List<Object?>? arguments]) {
    operations.add(SqfliteBatchOperation(
        SqliteSqlCommandType.delete, methodUpdate, sql, arguments));
  }

  @override
  void execute(String sql, [List<Object?>? arguments]) {
    operations.add(SqfliteBatchOperation(
        SqliteSqlCommandType.execute, methodExecute, sql, arguments));
  }

  /// Batch size
  @override
  int get length => operations.length;
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
