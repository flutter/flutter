import 'package:sqflite_common/src/arg_utils.dart';
import 'package:sqflite_common/src/constant.dart';

/// Wrap sqlite native exception
abstract class DatabaseException implements Exception {
  /// Create an exception with a message
  DatabaseException(this._message);

  final String? _message;

  @override
  String toString() => 'DatabaseException($_message)';

  /// True if the exception is a no such table exception
  bool isNoSuchTableError([String? table]) {
    if (_message != null) {
      var expected = 'no such table: ';
      if (table != null) {
        expected += table;
      }
      return _message!.contains(expected);
    }
    return false;
  }

  /// True if the exception is a duplicate column error
  bool isDuplicateColumnError([String? column]) {
    if (_message != null) {
      var expected = 'duplicate column name: ';
      if (column != null) {
        expected += column;
      }
      return _message!.contains(expected);
    }
    return false;
  }

  /// True if the exception is a syntax error
  bool isSyntaxError() {
    if (_message != null) {
      return _message!.contains('syntax error');
    }
    return false;
  }

  /// True if the exception is an open failed error
  bool isOpenFailedError() {
    if (_message != null) {
      return _message!.contains('open_failed');
    }
    return false;
  }

  /// True if the exception is a database closed error
  bool isDatabaseClosedError() {
    if (_message != null) {
      return _message!.contains('database_closed') ||
          _message!.contains('This database has already been closed');
    }
    return false;
  }

  /// True if the exception is a read-only error
  bool isReadOnlyError() {
    if (_message != null) {
      return _message!.contains('readonly');
    }
    return false;
  }

  /// True if the exception is a unique constraint error
  bool isUniqueConstraintError([String? field]) {
    if (_message != null) {
      var expected = 'UNIQUE constraint failed: ';
      if (field != null) {
        expected += field;
      }
      return _message!.toLowerCase().contains(expected.toLowerCase());
    }
    return false;
  }

  /// True if the exception is a not null constraint error
  bool isNotNullConstraintError([String? field]) {
    if (_message != null) {
      var expected = 'NOT NULL constraint failed: ';
      if (field != null) {
        expected += field;
      }
      return _message!.toLowerCase().contains(expected.toLowerCase());
    }
    return false;
  }

  /// Extended result code on Android/ffi, normal result code on iOS.
  ///
  /// This might involve parsing the sqlite native message to extract the code
  /// See https://www.sqlite.org/rescode.html for the list of result code
  int? getResultCode();

  /// Platform specific error result.
  ///
  /// Its content is platform dependent and used internally and could change
  /// in the future but could help in analyzing the error.
  Object? get result;
}

/// Exception implementation
class SqfliteDatabaseException extends DatabaseException {
  /// ctor with a message and some data
  SqfliteDatabaseException(String? message, this.result, {int? resultCode})
      : super(message) {
    _resultCode = resultCode;
  }

  /// Our exception message
  String? get message => _message;

  /// Extended result code.
  int? _resultCode;

  /// Typically the result of a native call
  @override
  Object? result;

  /// The result as a map
  Map get resultMap => result as Map;

  @override
  String toString() {
    if (result is Map) {
      if (resultMap[paramSql] != null) {
        final dynamic args = resultMap[paramSqlArguments];
        if (args is List) {
          return "DatabaseException($_message) sql '${resultMap[paramSql]}' args ${argumentsToString(args)}";
        } else {
          return "DatabaseException($_message) sql '${resultMap[paramSql]}'";
        }
      }
    }
    return super.toString();
  }

  /// Get the (extended if available) result code.
  ///
  /// This might involve parsing the sqlite native message to extract the code
  /// See https://www.sqlite.org/rescode.html for the list of result code.
  ///
  /// iOS returns normal code while Android/ffi returns extended code for now
  /// The application should handle both.
  @override
  int? getResultCode() => _resultCode ??= () {
        final message = _message!.toLowerCase();
        int? findCode(String patternPrefix) {
          final index = message.indexOf(patternPrefix);
          if (index != -1) {
            try {
              // Split at first space
              var code = message
                  .substring(index + patternPrefix.length)
                  .trim()
                  .split(' ')[0];
              // Find ending parenthesis if any
              final endIndex = code.indexOf(')');
              if (endIndex != -1) {
                code = code.substring(0, endIndex);
              }

              final resultCode = int.tryParse(code);
              if (resultCode != null) {
                return resultCode;
              }
            } catch (_) {}
          }
          return null;
        }

        var code = findCode('(sqlite code ');
        if (code != null) {
          return code;
        }
        code = findCode('(code ');
        if (code != null) {
          return code;
        }
        // ios
        code = findCode('code=');
        if (code != null) {
          return code;
        }
        return null;
      }();
}
