import 'dart:collection';

import 'package:sqflite_common/src/constant.dart';
import 'package:sqflite_common/src/constant.dart' as constant;
import 'package:sqflite_common/src/exception.dart';

export 'dart:async';

/// Native result wrapper
class Rows extends PluginList<Map<String, Object?>> {
  /// Wrap the native list as a raw
  Rows.from(List<dynamic> list) : super.from(list);

  @override
  Map<String, Object?> operator [](int index) {
    final item = rawList[index] as Map<dynamic, dynamic>;
    return item.cast<String, Object?>();
  }
}

/// Unpack the native results
QueryResultSet queryResultSetFromMap(Map<dynamic, dynamic> queryResultSetMap) {
  final columns = queryResultSetMap['columns'] as List<dynamic>?;
  final rows = queryResultSetMap['rows'] as List<dynamic>?;
  return QueryResultSet(columns, rows);
}

/// Native exception wrapper
DatabaseException databaseExceptionFromOperationError(
    Map<dynamic, dynamic> errorMap) {
  final message = errorMap[paramErrorMessage] as String?;
  return SqfliteDatabaseException(message, errorMap[paramErrorData],
      resultCode: errorMap[paramErrorResultCode] as int?);
}

/// A batch operation result is either
/// {'result':...}
/// or
/// {'error':...}
dynamic fromRawOperationResult(Map<dynamic, dynamic> rawOperationResultMap) {
  final errorMap =
      rawOperationResultMap[constant.paramError] as Map<dynamic, dynamic>?;
  if (errorMap != null) {
    return databaseExceptionFromOperationError(errorMap);
  }
  final dynamic successResult = rawOperationResultMap[constant.paramResult];
  if (successResult is Map) {
    return queryResultToList(successResult);
  } else if (successResult is List) {
    return queryResultToList(successResult);
  }

  // This could be just an int (insert)
  return successResult;
}

/// Native result to a map list as expected by the sqflite API
List<Map<String, Object?>> queryResultToList(dynamic queryResult) {
  if (queryResult is Map) {
    return queryResultSetFromMap(queryResult);
  }
  // dart1
  // dart2 support <= 0.7.0 - this is a list
  // to remove once done on iOS and Android
  if (queryResult is List) {
    final rows = Rows.from(queryResult);
    return rows;
  }

  throw UnsupportedError('Unsupported queryResult type $queryResult');
}

/// Native result to a map list as expected by the sqflite API
int? queryResultCursorId(dynamic queryResult) {
  if (queryResult is Map) {
    return queryResult[paramCursorId] as int?;
  }
  throw UnsupportedError('Unsupported queryResult type $queryResult');
}

/// Query native result
class QueryResultSet extends ListBase<Map<String, Object?>> {
  /// Creates a result set from a native column/row values
  QueryResultSet(List<dynamic>? rawColumns, List<dynamic>? rawRows) {
    _columns = rawColumns?.cast<String>();
    _rows = rawRows?.cast<List<dynamic>>();

    if (_columns != null) {
      _columnIndexMap = <String, int>{};

      for (var i = 0; i < _columns!.length; i++) {
        _columnIndexMap[_columns![i]] = i;
      }
    }
  }

  List<List<dynamic>>? _rows;
  List<String>? _columns;
  List<String>? _keys;
  late Map<String, int> _columnIndexMap;

  @override
  int get length => _rows?.length ?? 0;

  @override
  Map<String, Object?> operator [](int index) {
    return QueryRow(this, _rows![index]);
  }

  @override
  void operator []=(int index, Map<String, Object?> value) {
    throw UnsupportedError('read-only');
  }

  @override
  set length(int newLength) {
    throw UnsupportedError('read-only');
  }

  /// Get the column index for a give column name
  int? columnIndex(String? name) {
    return _columnIndexMap[name!];
  }

  /// Remove duplicated
  List<String> get keys => _keys ??= _columns!.toSet().toList(growable: false);
}

/// Query Row wrapper
class QueryRow extends MapBase<String, dynamic> {
  /// Create a row from a result set information and a list of values
  QueryRow(this.queryResultSet, this.row);

  /// Our result set
  final QueryResultSet queryResultSet;

  /// Our row values
  final List<dynamic> row;

  @override
  dynamic operator [](Object? key) {
    final stringKey = key as String?;
    final columnIndex = queryResultSet.columnIndex(stringKey);
    if (columnIndex != null) {
      return row[columnIndex];
    }
    return null;
  }

  @override
  void operator []=(String key, dynamic value) {
    throw UnsupportedError('read-only');
  }

  @override
  void clear() {
    throw UnsupportedError('read-only');
  }

  @override
  Iterable<String> get keys => queryResultSet.keys;

  @override
  dynamic remove(Object? key) {
    throw UnsupportedError('read-only');
  }
}

/// Single batch operation results.
class BatchResult {
  /// Wrap a batch  operation result.
  BatchResult(this.result);

  /// Our operation result
  final dynamic result;
}

/// Batch results.
class BatchResults extends PluginList<dynamic> {
  /// Creates a batch result from a native list.
  BatchResults.from(List<dynamic> list) : super.from(list);

  @override
  dynamic operator [](int index) {
    // New in 0.13
    // It is always a Map and can be either a result or an error
    final rawMap = _list[index] as Map<dynamic, dynamic>;
    return fromRawOperationResult(rawMap);
  }
}

/// Helper to handle a native list.
abstract class PluginList<T> extends ListBase<T> {
  /// Creates a types list from a native list.
  PluginList.from(List<dynamic> list) : _list = list;

  final List<dynamic> _list;

  /// Our raw native list.
  List<dynamic> get rawList => _list;

  /// Get a raw element.
  dynamic rawElementAt(int index) => _list[index];

  @override
  int get length => _list.length;

  @override
  set length(int newLength) {
    throw UnsupportedError('read-only');
  }

  @override
  void operator []=(int index, T value) {
    throw UnsupportedError('read-only');
  }
}
