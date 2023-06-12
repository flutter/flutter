import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common/src/database.dart';
import 'package:sqflite_common/src/transaction.dart';

/// Sqflite query cursor wrapper.
class SqfliteQueryCursor implements QueryCursor {
  final SqfliteDatabase _database;

  /// Current transaction if any
  final SqfliteTransaction? txn; // transaction if any

  /// True when closed. moveNext should fail but current row remains ok
  var closed = false;

  /// The native cursor id, null if not supported or if closed
  int? cursorId;

  /// The current result list
  List<Map<String, Object?>> resultList;

  /// The current index
  int currentIndex = -1;

  /// Sqflite query cursor wrapper.
  SqfliteQueryCursor(this._database, this.txn, this.cursorId, this.resultList);

  @override
  Map<String, Object?> get current =>
      _database.txnQueryCursorGetCurrent(txn, this);

  @override
  Future<bool> moveNext() => _database.txnQueryCursorMoveNext(txn, this);

  @override
  Future<void> close() => _database.txnQueryCursorClose(txn, this);
}
