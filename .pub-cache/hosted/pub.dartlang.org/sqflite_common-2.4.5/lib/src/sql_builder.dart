import 'package:sqflite_common/src/value_utils.dart';

/// Insert/Update conflict resolver
enum ConflictAlgorithm {
  /// When a constraint violation occurs, an immediate ROLLBACK occurs,
  /// thus ending the current transaction, and the command aborts with a
  /// return code of SQLITE_CONSTRAINT. If no transaction is active
  /// (other than the implied transaction that is created on every command)
  /// then this algorithm works the same as ABORT.
  rollback,

  /// When a constraint violation occurs,no ROLLBACK is executed
  /// so changes from prior commands within the same transaction
  /// are preserved. This is the default behavior.
  abort,

  /// When a constraint violation occurs, the command aborts with a return
  /// code SQLITE_CONSTRAINT. But any changes to the database that
  /// the command made prior to encountering the constraint violation
  /// are preserved and are not backed out.
  fail,

  /// When a constraint violation occurs, the one row that contains
  /// the constraint violation is not inserted or changed.
  /// But the command continues executing normally. Other rows before and
  /// after the row that contained the constraint violation continue to be
  /// inserted or updated normally. No error is returned.
  ignore,

  /// When a UNIQUE constraint violation occurs, the pre-existing rows that
  /// are causing the constraint violation are removed prior to inserting
  /// or updating the current row. Thus the insert or update always occurs.
  /// The command continues executing normally. No error is returned.
  /// If a NOT NULL constraint violation occurs, the NULL value is replaced
  /// by the default value for that column. If the column has no default
  /// value, then the ABORT algorithm is used. If a CHECK constraint
  /// violation occurs then the IGNORE algorithm is used. When this conflict
  /// resolution strategy deletes rows in order to satisfy a constraint,
  /// it does not invoke delete triggers on those rows.
  /// This behavior might change in a future release.
  replace,
}

final List<String> _conflictValues = <String>[
  'OR ROLLBACK',
  'OR ABORT',
  'OR FAIL',
  'OR IGNORE',
  'OR REPLACE'
];

//final RegExp _sLimitPattern = new RegExp('\s*\d+\s*(,\s*\d+\s*)?');

/// SQL command builder.
class SqlBuilder {
  /// Convenience method for deleting rows in the database.
  ///
  /// @param table the table to delete from
  /// @param where the optional WHERE clause to apply when deleting.
  ///            Passing null will delete all rows.
  /// @param whereArgs You may include ?s in the where clause, which
  ///            will be replaced by the values from whereArgs. The values
  ///            will be bound as Strings.
  SqlBuilder.delete(String table, {String? where, List<Object?>? whereArgs}) {
    checkWhereArgs(whereArgs);
    final delete = StringBuffer();
    delete.write('DELETE FROM ');
    delete.write(_escapeName(table));
    _writeClause(delete, ' WHERE ', where);
    sql = delete.toString();
    arguments = whereArgs != null ? List<Object?>.from(whereArgs) : null;
  }

  /// Build an SQL query string from the given clauses.
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
  ///            formatted as LIMIT clause. Passing null denotes no LIMIT clause.
  SqlBuilder.query(String table,
      {bool? distinct,
      List<String>? columns,
      String? where,
      List<Object?>? whereArgs,
      String? groupBy,
      String? having,
      String? orderBy,
      int? limit,
      int? offset}) {
    if (groupBy == null && having != null) {
      throw ArgumentError(
          'HAVING clauses are only permitted when using a groupBy clause');
    }
    checkWhereArgs(whereArgs);

    final query = StringBuffer();

    query.write('SELECT ');
    if (distinct == true) {
      query.write('DISTINCT ');
    }
    if (columns != null && columns.isNotEmpty) {
      _writeColumns(query, columns);
    } else {
      query.write('* ');
    }
    query.write('FROM ');
    query.write(_escapeName(table));
    _writeClause(query, ' WHERE ', where);
    _writeClause(query, ' GROUP BY ', groupBy);
    _writeClause(query, ' HAVING ', having);
    _writeClause(query, ' ORDER BY ', orderBy);
    if (limit != null) {
      _writeClause(query, ' LIMIT ', limit.toString());
    }
    if (offset != null) {
      _writeClause(query, ' OFFSET ', offset.toString());
    }

    sql = query.toString();
    arguments = whereArgs != null ? List<Object?>.from(whereArgs) : null;
  }

  /// Convenience method for inserting a row into the database.
  /// Parameters:
  /// @table the table to insert the row into
  /// @nullColumnHack optional; may be null. SQL doesn't allow inserting a completely empty row without naming at least one column name. If your provided values is empty, no column names are known and an empty row can't be inserted. If not set to null, the nullColumnHack parameter provides the name of nullable column name to explicitly insert a NULL into in the case where your values is empty.
  /// @values this map contains the initial column values for the row. The keys should be the column names and the values the column values

  SqlBuilder.insert(String table, Map<String, Object?> values,
      {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm}) {
    final insert = StringBuffer();
    insert.write('INSERT');
    if (conflictAlgorithm != null) {
      insert.write(' ${_conflictValues[conflictAlgorithm.index]}');
    }
    insert.write(' INTO ');
    insert.write(_escapeName(table));
    insert.write(' (');

    List<Object?>? bindArgs;
    final size = values.length;

    if (size > 0) {
      final sbValues = StringBuffer(') VALUES (');

      bindArgs = <Object?>[];
      var i = 0;
      values.forEach((String colName, Object? value) {
        if (i++ > 0) {
          insert.write(', ');
          sbValues.write(', ');
        }

        /// This should be just a column name
        insert.write(_escapeName(colName));
        if (value == null) {
          sbValues.write('NULL');
        } else {
          checkNonNullValue(value);
          bindArgs!.add(value);
          sbValues.write('?');
        }
      });
      insert.write(sbValues);
    } else {
      if (nullColumnHack == null) {
        throw ArgumentError('nullColumnHack required when inserting no data');
      }
      insert.write('$nullColumnHack) VALUES (NULL');
    }
    insert.write(')');

    sql = insert.toString();
    arguments = bindArgs;
  }

  /// Convenience method for updating rows in the database.
  ///
  /// @param table the table to update in
  /// @param values a map from column names to new column values. null is a
  ///            valid value that will be translated to NULL.
  /// @param whereClause the optional WHERE clause to apply when updating.
  ///            Passing null will update all rows.
  /// @param whereArgs You may include ?s in the where clause, which
  ///            will be replaced by the values from whereArgs. The values
  ///            will be bound as Strings.
  /// @param conflictAlgorithm for update conflict resolver

  SqlBuilder.update(String table, Map<String, Object?> values,
      {String? where,
      List<Object?>? whereArgs,
      ConflictAlgorithm? conflictAlgorithm}) {
    if (values.isEmpty) {
      throw ArgumentError('Empty values');
    }
    checkWhereArgs(whereArgs);

    final update = StringBuffer();
    update.write('UPDATE');
    if (conflictAlgorithm != null) {
      update.write(' ${_conflictValues[conflictAlgorithm.index]}');
    }
    update.write(' ${_escapeName(table)}');
    update.write(' SET ');

    final bindArgs = <Object?>[];
    var i = 0;

    for (var colName in values.keys) {
      update.write((i++ > 0) ? ', ' : '');
      update.write(_escapeName(colName));
      final value = values[colName];
      if (value != null) {
        checkNonNullValue(value);
        bindArgs.add(value);
        update.write(' = ?');
      } else {
        update.write(' = NULL');
      }
    }

    if (whereArgs != null) {
      bindArgs.addAll(whereArgs);
    }

    _writeClause(update, ' WHERE ', where);

    sql = update.toString();
    arguments = bindArgs;
  }

  /// The resulting SQL command.
  late String sql;

  /// The arguments list;
  List<Object?>? arguments;

  /// Used during build if there was a name with an escaped keyword.
  bool hasEscape = false;

  String _escapeName(String name) => escapeName(name);

  void _writeClause(StringBuffer s, String name, String? clause) {
    if (clause != null) {
      s.write(name);
      s.write(clause);
    }
  }

  /// Add the names that are non-null in columns to s, separating
  /// them with commas.
  void _writeColumns(StringBuffer s, List<String> columns) {
    final n = columns.length;

    for (var i = 0; i < n; i++) {
      final column = columns[i];

      if (i > 0) {
        s.write(', ');
      }
      s.write(_escapeName(column));
    }
    s.write(' ');
  }
}

/// True if a name had been escaped already.
bool isEscapedName(String name) {
  if (name.length >= 2) {
    final codeUnits = name.codeUnits;
    if (_areCodeUnitsEscaped(codeUnits)) {
      return escapeNames
          .contains(name.substring(1, name.length - 1).toLowerCase());
    }
  }
  return false;
}

// The actual escape implementation
// We use double quote, although backtick could be used too
String _doEscape(String name) => '"$name"';

/// Escape a table or column name if necessary.
///
/// i.e. if it is an identified it will be surrounded by " (double-quote)
/// Only some name belonging to keywords can be escaped
String escapeName(String name) {
  if (escapeNames.contains(name.toLowerCase())) {
    return _doEscape(name);
  }
  return name;
}

/// Unescape a table or column name.
String unescapeName(String name) {
  if (isEscapedName(name)) {
    return name.substring(1, name.length - 1);
  }
  return name;
}

/// Escape a column name if necessary.
///
/// Only for insert and update keys
String escapeEntityName(String name) {
  if (_entityNameNeedEscape(name)) {
    return _doEscape(name);
  }
  return name;
}

const _lowercaseA = 0x61;
const _lowercaseZ = 0x7A;

const _underscore = 0x5F;
const _digit0 = 0x30;
const _digit9 = 0x39;

const _backtick = 0x60;
const _doubleQuote = 0x22;
const _singleQuote = 0x27;

const _uppercaseA = 0x41;
const _uppercaseZ = 0x5A;

/// Returns `true` if [codeUnit] represents a digit.
///
/// The definition of digit matches the Unicode `0x3?` range of Western
/// European digits.
bool _isDigit(int codeUnit) => codeUnit >= _digit0 && codeUnit <= _digit9;

/// Returns `true` if [codeUnit] represents matchs azAZ_.
bool _isAlphaOrUnderscore(int codeUnit) =>
    (codeUnit >= _lowercaseA && codeUnit <= _lowercaseZ) ||
    (codeUnit >= _uppercaseA && codeUnit <= _uppercaseZ) ||
    codeUnit == _underscore;

/// True if already escaped
bool _areCodeUnitsEscaped(List<int> codeUnits) {
  if (codeUnits.isNotEmpty) {
    final first = codeUnits.first;
    switch (first) {
      case _doubleQuote:
      case _backtick:
        final last = codeUnits.last;
        return last == first;
      case _singleQuote:
      // not yet
    }
  }
  return false;
}

bool _entityNameNeedEscape(String name) {
  /// We need to escape if not escaped yet and if not a valid keyword
  if (escapeNames.contains(name.toLowerCase())) {
    return true;
  }

  final codeUnits = name.codeUnits;

  // Must start with a alpha or underscode
  if (!_isAlphaOrUnderscore(codeUnits.first)) {
    return true;
  }
  for (var i = 1; i < codeUnits.length; i++) {
    final codeUnit = codeUnits[i];
    if (!_isAlphaOrUnderscore(codeUnit) && !_isDigit(codeUnit)) {
      return true;
    }
  }

  return false;
}

/// Unescape a table or column name.
String unescapeValueKeyName(String name) {
  final codeUnits = name.codeUnits;
  if (_areCodeUnitsEscaped(codeUnits)) {
    return name.substring(1, name.length - 1);
  }
  return name;
}

/// SQLite keywords to escape.
///
/// This list was built from the whole set of keywords
/// ([allKeywords] kept here for reference
/// ignore: prefer_collection_literals
final Set<String> escapeNames = <String>{
  'add',
  'all',
  'alter',
  'and',
  'as',
  'autoincrement',
  'between',
  'case',
  'check',
  'collate',
  'commit',
  'constraint',
  'create',
  'default',
  'deferrable',
  'delete',
  'distinct',
  'drop',
  'else',
  'escape',
  'except',
  'exists',
  'foreign',
  'from',
  'group',
  'having',
  'if',
  'in',
  'index',
  'insert',
  'intersect',
  'into',
  'is',
  'isnull',
  'join',
  'limit',
  'not',
  'notnull',
  'null',
  'on',
  'or',
  'order',
  'primary',
  'references',
  'select',
  'set',
  'table',
  'then',
  'to',
  'transaction',
  'union',
  'unique',
  'update',
  'using',
  'values',
  'when',
  'where'
};

/*
All keywords kept here for reference

Set<String> _allKeywords = new Set.from([
  'abort',
  'action',
  'add',
  'after',
  'all',
  'alter',
  'analyze',
  'and',
  'as',
  'asc',
  'attach',
  'autoincrement',
  'before',
  'begin',
  'between',
  'by',
  'cascade',
  'case',
  'cast',
  'check',
  'collate',
  'column',
  'commit',
  'conflict',
  'constraint',
  'create',
  'cross',
  'current_date',
  'current_time',
  'current_timestamp',
  'database',
  'default',
  'deferrable',
  'deferred',
  'delete',
  'desc',
  'detach',
  'distinct',
  'drop',
  'each',
  'else',
  'end',
  'escape',
  'except',
  'exclusive',
  'exists',
  'explain',
  'fail',
  'for',
  'foreign',
  'from',
  'full',
  'glob',
  'group',
  'having',
  'if',
  'ignore',
  'immediate',
  'in',
  'index',
  'indexed',
  'initially',
  'inner',
  'insert',
  'instead',
  'intersect',
  'into',
  'is',
  'isnull',
  'join',
  'key',
  'left',
  'like',
  'limit',
  'match',
  'natural',
  'no',
  'not',
  'notnull',
  'null',
  'of',
  'offset',
  'on',
  'or',
  'order',
  'outer',
  'plan',
  'pragma',
  'primary',
  'query',
  'raise',
  'recursive',
  'references',
  'regexp',
  'reindex',
  'release',
  'rename',
  'replace',
  'restrict',
  'right',
  'rollback',
  'row',
  'savepoint',
  'select',
  'set',
  'table',
  'temp',
  'temporary',
  'then',
  'to',
  'transaction',
  'trigger',
  'union',
  'unique',
  'update',
  'using',
  'vacuum',
  'values',
  'view',
  'virtual',
  'when',
  'where',
  'with',
  'without'
]);
*/
