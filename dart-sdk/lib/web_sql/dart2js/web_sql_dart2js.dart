/// An API for storing data in the browser that can be queried with SQL.
///
/// **Caution:** this specification is no longer actively maintained by the Web
/// Applications Working Group and may be removed at any time.
/// See [the W3C Web SQL Database specification](http://www.w3.org/TR/webdatabase/)
/// for more information.
///
/// The [dart:indexed_db] APIs is a recommended alternatives.
///
/// {@category Web (Legacy)}
/// {@nodoc}
library dart.dom.web_sql;

import 'dart:async';
import 'dart:collection' hide LinkedList, LinkedListEntry;
import 'dart:_internal' show FixedLengthListMixin;
import 'dart:html';
import 'dart:html_common';
import 'dart:_foreign_helper' show JS;
import 'dart:_interceptors' show JavaScriptObject;
// DO NOT EDIT - unless you are editing documentation as per:
// https://code.google.com/p/dart/wiki/ContributingHTMLDocumentation
// Auto-generated dart:web_sql library.

@deprecated
import 'dart:_js_helper'
    show
        applyExtension,
        convertDartClosureToJS,
        Creates,
        JSName,
        Native,
        JavaScriptIndexingBehavior,
        Returns;

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

typedef void SqlStatementCallback(
    SqlTransaction transaction, SqlResultSet resultSet);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

typedef void SqlStatementErrorCallback(
    SqlTransaction transaction, SqlError error);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

typedef void SqlTransactionCallback(SqlTransaction transaction);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

typedef void SqlTransactionErrorCallback(SqlError error);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Native("Database")
class SqlDatabase extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory SqlDatabase._() {
    throw new UnsupportedError("Not supported");
  }

  /// Checks if this type is supported on the current platform.
  static bool get supported => JS('bool', '!!(window.openDatabase)');

  String? get version native;

  @JSName('changeVersion')
  /**
   * Atomically update the database version to [newVersion], asynchronously
   * running [callback] on the [SqlTransaction] representing this
   * [changeVersion] transaction.
   *
   * If [callback] runs successfully, then [successCallback] is called.
   * Otherwise, [errorCallback] is called.
   *
   * [oldVersion] should match the database's current [version] exactly.
   *
   * See also:
   *
   * * [Database.changeVersion](http://www.w3.org/TR/webdatabase/#dom-database-changeversion) from W3C.
   */
  void _changeVersion(String oldVersion, String newVersion,
      [SqlTransactionCallback? callback,
      SqlTransactionErrorCallback? errorCallback,
      VoidCallback? successCallback]) native;

  @JSName('changeVersion')
  /**
   * Atomically update the database version to [newVersion], asynchronously
   * running [callback] on the [SqlTransaction] representing this
   * [changeVersion] transaction.
   *
   * If [callback] runs successfully, then [successCallback] is called.
   * Otherwise, [errorCallback] is called.
   *
   * [oldVersion] should match the database's current [version] exactly.
   *
   * See also:
   *
   * * [Database.changeVersion](http://www.w3.org/TR/webdatabase/#dom-database-changeversion) from W3C.
   */
  Future<SqlTransaction> changeVersion(String oldVersion, String newVersion) {
    var completer = new Completer<SqlTransaction>();
    _changeVersion(oldVersion, newVersion, (value) {
      completer.complete(value);
    }, (error) {
      completer.completeError(error);
    });
    return completer.future;
  }

  @JSName('readTransaction')
  void _readTransaction(SqlTransactionCallback callback,
      [SqlTransactionErrorCallback? errorCallback,
      VoidCallback? successCallback]) native;

  @JSName('readTransaction')
  Future<SqlTransaction> readTransaction() {
    var completer = new Completer<SqlTransaction>();
    _readTransaction((value) {
      completer.complete(value);
    }, (error) {
      completer.completeError(error);
    });
    return completer.future;
  }

  void transaction(SqlTransactionCallback callback,
      [SqlTransactionErrorCallback? errorCallback,
      VoidCallback? successCallback]) native;

  @JSName('transaction')
  Future<SqlTransaction> transaction_future() {
    var completer = new Completer<SqlTransaction>();
    transaction((value) {
      applyExtension('SQLTransaction', value);
      completer.complete(value);
    }, (error) {
      completer.completeError(error);
    });
    return completer.future;
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("SQLError")
class SqlError extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory SqlError._() {
    throw new UnsupportedError("Not supported");
  }

  static const int CONSTRAINT_ERR = 6;

  static const int DATABASE_ERR = 1;

  static const int QUOTA_ERR = 4;

  static const int SYNTAX_ERR = 5;

  static const int TIMEOUT_ERR = 7;

  static const int TOO_LARGE_ERR = 3;

  static const int UNKNOWN_ERR = 0;

  static const int VERSION_ERR = 2;

  int? get code native;

  String? get message native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("SQLResultSet")
class SqlResultSet extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory SqlResultSet._() {
    throw new UnsupportedError("Not supported");
  }

  int? get insertId native;

  SqlResultSetRowList? get rows native;

  int? get rowsAffected native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("SQLResultSetRowList")
class SqlResultSetRowList extends JavaScriptObject
    with ListMixin<Map>, ImmutableListMixin<Map>
    implements List<Map> {
  // To suppress missing implicit constructor warnings.
  factory SqlResultSetRowList._() {
    throw new UnsupportedError("Not supported");
  }

  int get length => JS("int", "#.length", this);

  Map operator [](int index) {
    if (JS("bool", "# >>> 0 !== # || # >= #", index, index, index, length))
      throw new IndexError.withLength(index, length, indexable: this);
    return this.item(index)!;
  }

  void operator []=(int index, Map value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<Map> mixins.
  // Map is the element type.

  set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  Map get first {
    if (this.length > 0) {
      return JS('Map', '#[0]', this);
    }
    throw new StateError("No elements");
  }

  Map get last {
    int len = this.length;
    if (len > 0) {
      return JS('Map', '#[#]', this, len - 1);
    }
    throw new StateError("No elements");
  }

  Map get single {
    int len = this.length;
    if (len == 1) {
      return JS('Map', '#[0]', this);
    }
    if (len == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  Map elementAt(int index) => this[index];
  // -- end List<Map> mixins.

  Map? item(int index) {
    return convertNativeToDart_Dictionary(_item_1(index));
  }

  @JSName('item')
  _item_1(index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.SAFARI)
// http://www.w3.org/TR/webdatabase/#sqltransaction
@deprecated // deprecated
@Native("SQLTransaction")
class SqlTransaction extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory SqlTransaction._() {
    throw new UnsupportedError("Not supported");
  }

  @JSName('executeSql')
  void _executeSql(String sqlStatement,
      [List? arguments,
      SqlStatementCallback? callback,
      SqlStatementErrorCallback? errorCallback]) native;

  @JSName('executeSql')
  Future<SqlResultSet> executeSql(String sqlStatement, [List? arguments]) {
    var completer = new Completer<SqlResultSet>();
    _executeSql(sqlStatement, arguments, (transaction, resultSet) {
      applyExtension('SQLResultSet', resultSet);
      applyExtension('SQLResultSetRowList', resultSet.rows);
      completer.complete(resultSet);
    }, (transaction, error) {
      completer.completeError(error);
    });
    return completer.future;
  }
}
