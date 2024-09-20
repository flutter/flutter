/// A client-side key-value store with support for indexes.
///
/// > [!Note]
/// > New projects should prefer to use
/// > [package:web](https://pub.dev/packages/web). For existing projects, see
/// > our [migration guide](https://dart.dev/go/package-web).
///
/// IndexedDB is a web standard API for client-side storage of
/// structured data. By storing data on the client in an IndexedDB,
/// apps can get advantages such as faster performance and
/// persistence.
///
/// In IndexedDB, each record is identified by a unique index or key,
/// making data retrieval speedy.
/// You can store structured data,
/// such as images, arrays, and maps using IndexedDB.
/// The standard does not specify size limits for individual data items
/// or for the database itself, but browsers may impose storage limits.
///
/// ## Using indexed_db
///
/// The classes in this library provide an interface
/// to the browser's IndexedDB, if it has one.
/// To use this library in your code:
///
///     import 'dart:indexed_db';
///
/// IndexedDB is almost universally supported in modern web browsers, but
/// a web app can determine if the browser supports IndexedDB
/// with [IdbFactory.supported]:
///
///     if (IdbFactory.supported)
///       // Use indexeddb.
///     else
///       // Find an alternative.
///
/// Access to the browser's IndexedDB is provided by the app's top-level
/// [Window] object, which your code can refer to with `window.indexedDB`.
/// So, for example,
/// here's how to use window.indexedDB to open a database:
///
///     Future open() {
///       return window.indexedDB.open('myIndexedDB',
///           version: 1,
///           onUpgradeNeeded: _initializeDatabase)
///         .then(_loadFromDB);
///     }
///     void _initializeDatabase(VersionChangeEvent e) {
///       ...
///     }
///     Future _loadFromDB(Database db) {
///       ...
///     }
///
/// All data in an IndexedDB is stored within an [ObjectStore].
/// To manipulate the database use [Transaction]s.
///
/// ## Other resources
///
/// Other options for client-side data storage include:
///
/// * [Window.localStorage]&mdash;a
/// basic mechanism that stores data as a [Map],
/// and where both the keys and the values are strings.
///
/// MDN provides [API
/// documentation](https://developer.mozilla.org/en-US/docs/Web/API/IndexedDB_API).
///
/// {@category Web (Legacy)}
library dart.dom.indexed_db;

import 'dart:async';
import 'dart:html';
import 'dart:html_common';
import 'dart:_native_typed_data';
import 'dart:typed_data';
import 'dart:_js_helper' show Creates, Returns, JSName, Native;
import 'dart:_foreign_helper' show JS;
import 'dart:_interceptors' show JavaScriptObject, JSExtendableArray;
import 'dart:_js_helper' show convertDartClosureToJS;
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// DO NOT EDIT - unless you are editing documentation as per:
// https://code.google.com/p/dart/wiki/ContributingHTMLDocumentation
// Auto-generated dart:indexed_db library.

class _KeyRangeFactoryProvider {
  static KeyRange createKeyRange_only(/*Key*/ value) =>
      _only(_class(), _translateKey(value));

  static KeyRange createKeyRange_lowerBound(/*Key*/ bound,
          [bool open = false]) =>
      _lowerBound(_class(), _translateKey(bound), open);

  static KeyRange createKeyRange_upperBound(/*Key*/ bound,
          [bool open = false]) =>
      _upperBound(_class(), _translateKey(bound), open);

  static KeyRange createKeyRange_bound(/*Key*/ lower, /*Key*/ upper,
          [bool lowerOpen = false, bool upperOpen = false]) =>
      _bound(_class(), _translateKey(lower), _translateKey(upper), lowerOpen,
          upperOpen);

  static var _cachedClass;

  static _class() {
    if (_cachedClass != null) return _cachedClass;
    return _cachedClass = _uncachedClass();
  }

  static _uncachedClass() =>
      JS('var', '''window.webkitIDBKeyRange || window.mozIDBKeyRange ||
          window.msIDBKeyRange || window.IDBKeyRange''');

  static _translateKey(idbkey) => idbkey; // TODO: fixme.

  static KeyRange _only(cls, value) => JS('KeyRange', '#.only(#)', cls, value);

  static KeyRange _lowerBound(cls, bound, open) =>
      JS('KeyRange', '#.lowerBound(#, #)', cls, bound, open);

  static KeyRange _upperBound(cls, bound, open) =>
      JS('KeyRange', '#.upperBound(#, #)', cls, bound, open);

  static KeyRange _bound(cls, lower, upper, lowerOpen, upperOpen) => JS(
      'KeyRange',
      '#.bound(#, #, #, #)',
      cls,
      lower,
      upper,
      lowerOpen,
      upperOpen);
}

// Conversions for IDBKey.
//
// Per http://www.w3.org/TR/IndexedDB/#key-construct
//
// "A value is said to be a valid key if it is one of the following types: Array
// JavaScript objects [ECMA-262], DOMString [WEBIDL], Date [ECMA-262] or float
// [WEBIDL]. However Arrays are only valid keys if every item in the array is
// defined and is a valid key (i.e. sparse arrays can not be valid keys) and if
// the Array doesn't directly or indirectly contain itself. Any non-numeric
// properties are ignored, and thus does not affect whether the Array is a valid
// key. Additionally, if the value is of type float, it is only a valid key if
// it is not NaN, and if the value is of type Date it is only a valid key if its
// [[PrimitiveValue]] internal property, as defined by [ECMA-262], is not NaN."

// What is required is to ensure that an Lists in the key are actually
// JavaScript arrays, and any Dates are JavaScript Dates.

/**
 * Converts a native IDBKey into a Dart object.
 *
 * May return the original input.  May mutate the original input (but will be
 * idempotent if mutation occurs).  It is assumed that this conversion happens
 * on native IDBKeys on all paths that return IDBKeys from native DOM calls.
 *
 * If necessary, JavaScript Dates are converted into Dart Dates.
 */
_convertNativeToDart_IDBKey(nativeKey) {
  containsDate(object) {
    if (isJavaScriptDate(object)) return true;
    if (object is List) {
      for (int i = 0; i < object.length; i++) {
        if (containsDate(object[i])) return true;
      }
    }
    return false; // number, string.
  }

  if (containsDate(nativeKey)) {
    throw new UnimplementedError('Key containing DateTime');
  }
  // TODO: Cache conversion somewhere?
  return nativeKey;
}

/**
 * Converts a Dart object into a valid IDBKey.
 *
 * May return the original input.  Does not mutate input.
 *
 * If necessary, [dartKey] may be copied to ensure all lists are converted into
 * JavaScript Arrays and Dart Dates into JavaScript Dates.
 */
_convertDartToNative_IDBKey(dartKey) {
  // TODO: Implement.
  return dartKey;
}

/// May modify original.  If so, action is idempotent.
_convertNativeToDart_IDBAny(object) {
  return convertNativeToDart_AcceptStructuredClone(object, mustCopy: false);
}

// TODO(sra): Add DateTime.
const String _idbKey = 'JSExtendableArray|=Object|num|String';
const _annotation_Creates_IDBKey = const Creates(_idbKey);
const _annotation_Returns_IDBKey = const Returns(_idbKey);
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Unstable()
@Native("IDBCursor")
class Cursor extends JavaScriptObject {
  Future delete() {
    try {
      return _completeRequest(_delete());
    } catch (e, stacktrace) {
      return new Future.error(e, stacktrace);
    }
  }

  Future update(value) {
    try {
      return _completeRequest(_update(value));
    } catch (e, stacktrace) {
      return new Future.error(e, stacktrace);
    }
  }

  @JSName('continue')
  void next([Object? key]) {
    if (key == null) {
      JS('void', '#.continue()', this);
    } else {
      JS('void', '#.continue(#)', this, key);
    }
  }

  // To suppress missing implicit constructor warnings.
  factory Cursor._() {
    throw new UnsupportedError("Not supported");
  }

  String? get direction native;

  @_annotation_Creates_IDBKey
  @_annotation_Returns_IDBKey
  Object? get key native;

  @_annotation_Creates_IDBKey
  @_annotation_Returns_IDBKey
  Object? get primaryKey native;

  @Creates('Null')
  @Returns('ObjectStore|Index|Null')
  Object? get source native;

  void advance(int count) native;

  void continuePrimaryKey(Object key, Object primaryKey) native;

  @JSName('delete')
  Request _delete() native;

  Request _update(/*any*/ value) {
    var value_1 = convertDartToNative_SerializedScriptValue(value);
    return _update_1(value_1);
  }

  @JSName('update')
  Request _update_1(value) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Unstable()
@Native("IDBCursorWithValue")
class CursorWithValue extends Cursor {
  // To suppress missing implicit constructor warnings.
  factory CursorWithValue._() {
    throw new UnsupportedError("Not supported");
  }

  dynamic get value => _convertNativeToDart_IDBAny(this._get_value);
  @JSName('value')
  @annotation_Creates_SerializedScriptValue
  @annotation_Returns_SerializedScriptValue
  dynamic get _get_value native;
}
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * An indexed database object for storing client-side data
 * in web apps.
 */
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX, '15')
@SupportedBrowser(SupportedBrowser.IE, '10')
@Unstable()
@Native("IDBDatabase")
class Database extends EventTarget {
  ObjectStore createObjectStore(String name, {keyPath, bool? autoIncrement}) {
    var options = {};
    if (keyPath != null) {
      options['keyPath'] = keyPath;
    }
    if (autoIncrement != null) {
      options['autoIncrement'] = autoIncrement;
    }

    return _createObjectStore(name, options);
  }

  Transaction transaction(storeName_OR_storeNames, String mode) {
    if (mode != 'readonly' && mode != 'readwrite') {
      throw new ArgumentError(mode);
    }

    // TODO(sra): Ensure storeName_OR_storeNames is a string or List<String>,
    // and copy to JavaScript array if necessary.

    // Try and create a transaction with a string mode.  Browsers that expect a
    // numeric mode tend to convert the string into a number.  This fails
    // silently, resulting in zero ('readonly').
    return _transaction(storeName_OR_storeNames, mode);
  }

  Transaction transactionStore(String storeName, String mode) {
    if (mode != 'readonly' && mode != 'readwrite') {
      throw new ArgumentError(mode);
    }
    // Try and create a transaction with a string mode.  Browsers that expect a
    // numeric mode tend to convert the string into a number.  This fails
    // silently, resulting in zero ('readonly').
    return _transaction(storeName, mode);
  }

  Transaction transactionList(List<String> storeNames, String mode) {
    if (mode != 'readonly' && mode != 'readwrite') {
      throw new ArgumentError(mode);
    }
    List storeNames_1 = convertDartToNative_StringArray(storeNames);
    return _transaction(storeNames_1, mode);
  }

  Transaction transactionStores(DomStringList storeNames, String mode) {
    if (mode != 'readonly' && mode != 'readwrite') {
      throw new ArgumentError(mode);
    }
    return _transaction(storeNames, mode);
  }

  @JSName('transaction')
  Transaction _transaction(stores, mode) native;

  // To suppress missing implicit constructor warnings.
  factory Database._() {
    throw new UnsupportedError("Not supported");
  }

  /**
   * Static factory designed to expose `abort` events to event
   * handlers that are not necessarily instances of [Database].
   *
   * See [EventStreamProvider] for usage information.
   */
  static const EventStreamProvider<Event> abortEvent =
      const EventStreamProvider<Event>('abort');

  /**
   * Static factory designed to expose `close` events to event
   * handlers that are not necessarily instances of [Database].
   *
   * See [EventStreamProvider] for usage information.
   */
  static const EventStreamProvider<Event> closeEvent =
      const EventStreamProvider<Event>('close');

  /**
   * Static factory designed to expose `error` events to event
   * handlers that are not necessarily instances of [Database].
   *
   * See [EventStreamProvider] for usage information.
   */
  static const EventStreamProvider<Event> errorEvent =
      const EventStreamProvider<Event>('error');

  /**
   * Static factory designed to expose `versionchange` events to event
   * handlers that are not necessarily instances of [Database].
   *
   * See [EventStreamProvider] for usage information.
   */
  static const EventStreamProvider<VersionChangeEvent> versionChangeEvent =
      const EventStreamProvider<VersionChangeEvent>('versionchange');

  String? get name native;

  @Returns('DomStringList')
  @Creates('DomStringList')
  List<String>? get objectStoreNames native;

  @Creates('int|String|Null')
  @Returns('int|String|Null')
  int? get version native;

  void close() native;

  ObjectStore _createObjectStore(String name, [Map? options]) {
    if (options != null) {
      var options_1 = convertDartToNative_Dictionary(options);
      return _createObjectStore_1(name, options_1);
    }
    return _createObjectStore_2(name);
  }

  @JSName('createObjectStore')
  ObjectStore _createObjectStore_1(name, options) native;
  @JSName('createObjectStore')
  ObjectStore _createObjectStore_2(name) native;

  void deleteObjectStore(String name) native;

  /// Stream of `abort` events handled by this [Database].
  Stream<Event> get onAbort => abortEvent.forTarget(this);

  /// Stream of `close` events handled by this [Database].
  Stream<Event> get onClose => closeEvent.forTarget(this);

  /// Stream of `error` events handled by this [Database].
  Stream<Event> get onError => errorEvent.forTarget(this);

  /// Stream of `versionchange` events handled by this [Database].
  Stream<VersionChangeEvent> get onVersionChange =>
      versionChangeEvent.forTarget(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

typedef void ObserverCallback(ObserverChanges changes);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX, '15')
@SupportedBrowser(SupportedBrowser.IE, '10')
@Unstable()
@Native("IDBFactory")
class IdbFactory extends JavaScriptObject {
  /**
   * Checks to see if Indexed DB is supported on the current platform.
   */
  static bool get supported {
    return JS(
        'bool',
        '!!(window.indexedDB || '
            'window.webkitIndexedDB || '
            'window.mozIndexedDB)');
  }

  Future<Database> open(String name,
      {int? version,
      void onUpgradeNeeded(VersionChangeEvent event)?,
      void onBlocked(Event event)?}) {
    if ((version == null) != (onUpgradeNeeded == null)) {
      return new Future.error(new ArgumentError(
          'version and onUpgradeNeeded must be specified together'));
    }
    try {
      OpenDBRequest request;
      if (version != null) {
        request = _open(name, version);
      } else {
        request = _open(name);
      }

      if (onUpgradeNeeded != null) {
        request.onUpgradeNeeded.listen(onUpgradeNeeded);
      }
      if (onBlocked != null) {
        request.onBlocked.listen(onBlocked);
      }
      return _completeRequest(request);
    } catch (e, stacktrace) {
      return new Future.error(e, stacktrace);
    }
  }

  Future<IdbFactory> deleteDatabase(String name, {void onBlocked(Event e)?}) {
    try {
      var request = _deleteDatabase(name);

      if (onBlocked != null) {
        request.onBlocked.listen(onBlocked);
      }
      var completer = new Completer<IdbFactory>.sync();
      request.onSuccess.listen((e) {
        completer.complete(this);
      });
      request.onError.listen(completer.completeError);
      return completer.future;
    } catch (e, stacktrace) {
      return new Future.error(e, stacktrace);
    }
  }

  /**
   * Deprecated. Always returns `false`.
   */
  @Deprecated('No longer supported on modern browsers. Always returns false.')
  bool get supportsDatabaseNames => false;

  // To suppress missing implicit constructor warnings.
  factory IdbFactory._() {
    throw new UnsupportedError("Not supported");
  }

  int cmp(Object first, Object second) native;

  @JSName('deleteDatabase')
  OpenDBRequest _deleteDatabase(String name) native;

  @JSName('open')
  @Returns('Request')
  @Creates('Request')
  @Creates('Database')
  OpenDBRequest _open(String name, [int? version]) native;
}

/**
 * Ties a request to a completer, so the completer is completed when it succeeds
 * and errors out when the request errors.
 */
Future<T> _completeRequest<T>(Request request) {
  var completer = new Completer<T>.sync();
  // TODO: make sure that completer.complete is synchronous as transactions
  // may be committed if the result is not processed immediately.
  request.onSuccess.listen((e) {
    T result = request.result;
    completer.complete(result);
  });
  request.onError.listen(completer.completeError);
  return completer.future;
}
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Unstable()
@Native("IDBIndex")
class Index extends JavaScriptObject {
  Future<int> count([key_OR_range]) {
    try {
      var request = _count(key_OR_range);
      return _completeRequest(request);
    } catch (e, stacktrace) {
      return new Future.error(e, stacktrace);
    }
  }

  Future get(key) {
    try {
      var request = _get(key);

      return _completeRequest(request);
    } catch (e, stacktrace) {
      return new Future.error(e, stacktrace);
    }
  }

  Future getKey(key) {
    try {
      var request = _getKey(key);

      return _completeRequest(request);
    } catch (e, stacktrace) {
      return new Future.error(e, stacktrace);
    }
  }

  /**
   * Creates a stream of cursors over the records in this object store.
   *
   * See also:
   *
   * * [ObjectStore.openCursor]
   */
  Stream<CursorWithValue> openCursor(
      {key, KeyRange? range, String? direction, bool? autoAdvance}) {
    var key_OR_range = null;
    if (key != null) {
      if (range != null) {
        throw new ArgumentError('Cannot specify both key and range.');
      }
      key_OR_range = key;
    } else {
      key_OR_range = range;
    }
    var request;
    if (direction == null) {
      // FIXME: Passing in "next" should be unnecessary.
      request = _openCursor(key_OR_range, "next");
    } else {
      request = _openCursor(key_OR_range, direction);
    }
    return ObjectStore._cursorStreamFromResult(request, autoAdvance);
  }

  /**
   * Creates a stream of cursors over the records in this object store.
   *
   * See also:
   *
   * * [ObjectStore.openCursor]
   */
  Stream<Cursor> openKeyCursor(
      {key, KeyRange? range, String? direction, bool? autoAdvance}) {
    var key_OR_range = null;
    if (key != null) {
      if (range != null) {
        throw new ArgumentError('Cannot specify both key and range.');
      }
      key_OR_range = key;
    } else {
      key_OR_range = range;
    }
    var request;
    if (direction == null) {
      // FIXME: Passing in "next" should be unnecessary.
      request = _openKeyCursor(key_OR_range, "next");
    } else {
      request = _openKeyCursor(key_OR_range, direction);
    }
    return ObjectStore._cursorStreamFromResult(request, autoAdvance);
  }

  // To suppress missing implicit constructor warnings.
  factory Index._() {
    throw new UnsupportedError("Not supported");
  }

  @annotation_Creates_SerializedScriptValue
  Object? get keyPath native;

  bool? get multiEntry native;

  String? get name native;

  set name(String? value) native;

  ObjectStore? get objectStore native;

  bool? get unique native;

  @JSName('count')
  Request _count(Object? key) native;

  @JSName('get')
  @Returns('Request')
  @Creates('Request')
  @annotation_Creates_SerializedScriptValue
  Request _get(Object key) native;

  Request getAll(Object? query, [int? count]) native;

  Request getAllKeys(Object? query, [int? count]) native;

  @JSName('getKey')
  @Returns('Request')
  @Creates('Request')
  @annotation_Creates_SerializedScriptValue
  @Creates('ObjectStore')
  Request _getKey(Object key) native;

  @JSName('openCursor')
  @Returns('Request')
  @Creates('Request')
  @Creates('Cursor')
  Request _openCursor(Object? range, [String? direction]) native;

  @JSName('openKeyCursor')
  @Returns('Request')
  @Creates('Request')
  @Creates('Cursor')
  Request _openKeyCursor(Object? range, [String? direction]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Unstable()
@Native("IDBKeyRange")
class KeyRange extends JavaScriptObject {
  factory KeyRange.only(/*Key*/ value) =>
      _KeyRangeFactoryProvider.createKeyRange_only(value);

  factory KeyRange.lowerBound(/*Key*/ bound, [bool open = false]) =>
      _KeyRangeFactoryProvider.createKeyRange_lowerBound(bound, open);

  factory KeyRange.upperBound(/*Key*/ bound, [bool open = false]) =>
      _KeyRangeFactoryProvider.createKeyRange_upperBound(bound, open);

  factory KeyRange.bound(/*Key*/ lower, /*Key*/ upper,
          [bool lowerOpen = false, bool upperOpen = false]) =>
      _KeyRangeFactoryProvider.createKeyRange_bound(
          lower, upper, lowerOpen, upperOpen);

  // To suppress missing implicit constructor warnings.
  factory KeyRange._() {
    throw new UnsupportedError("Not supported");
  }

  @annotation_Creates_SerializedScriptValue
  Object? get lower native;

  bool? get lowerOpen native;

  @annotation_Creates_SerializedScriptValue
  Object? get upper native;

  bool? get upperOpen native;

  @JSName('bound')
  static KeyRange bound_(Object lower, Object upper,
      [bool? lowerOpen, bool? upperOpen]) native;

  bool includes(Object key) native;

  @JSName('lowerBound')
  static KeyRange lowerBound_(Object bound, [bool? open]) native;

  @JSName('only')
  static KeyRange only_(Object value) native;

  @JSName('upperBound')
  static KeyRange upperBound_(Object bound, [bool? open]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Unstable()
@Native("IDBObjectStore")
class ObjectStore extends JavaScriptObject {
  Future add(value, [key]) {
    try {
      var request;
      if (key != null) {
        request = _add(value, key);
      } else {
        request = _add(value);
      }
      return _completeRequest(request);
    } catch (e, stacktrace) {
      return new Future.error(e, stacktrace);
    }
  }

  Future clear() {
    try {
      return _completeRequest(_clear());
    } catch (e, stacktrace) {
      return new Future.error(e, stacktrace);
    }
  }

  Future delete(key_OR_keyRange) {
    try {
      return _completeRequest(_delete(key_OR_keyRange));
    } catch (e, stacktrace) {
      return new Future.error(e, stacktrace);
    }
  }

  Future<int> count([key_OR_range]) {
    try {
      var request = _count(key_OR_range);
      return _completeRequest(request);
    } catch (e, stacktrace) {
      return new Future.error(e, stacktrace);
    }
  }

  Future put(value, [key]) {
    try {
      var request;
      if (key != null) {
        request = _put(value, key);
      } else {
        request = _put(value);
      }
      return _completeRequest(request);
    } catch (e, stacktrace) {
      return new Future.error(e, stacktrace);
    }
  }

  Future getObject(key) {
    try {
      var request = _get(key);

      return _completeRequest(request);
    } catch (e, stacktrace) {
      return new Future.error(e, stacktrace);
    }
  }

  /**
   * Creates a stream of cursors over the records in this object store.
   *
   * **The stream must be manually advanced by calling [Cursor.next] after
   * each item or by specifying autoAdvance to be true.**
   *
   *     var cursors = objectStore.openCursor().listen(
   *       (cursor) {
   *         // ...some processing with the cursor
   *         cursor.next(); // advance onto the next cursor.
   *       },
   *       onDone: () {
   *         // called when there are no more cursors.
   *         print('all done!');
   *       });
   *
   * Asynchronous operations which are not related to the current transaction
   * will cause the transaction to automatically be committed-- all processing
   * must be done synchronously unless they are additional async requests to
   * the current transaction.
   */
  Stream<CursorWithValue> openCursor(
      {key, KeyRange? range, String? direction, bool? autoAdvance}) {
    var key_OR_range = null;
    if (key != null) {
      if (range != null) {
        throw new ArgumentError('Cannot specify both key and range.');
      }
      key_OR_range = key;
    } else {
      key_OR_range = range;
    }

    // TODO: try/catch this and return a stream with an immediate error.
    var request;
    if (direction == null) {
      request = _openCursor(key_OR_range);
    } else {
      request = _openCursor(key_OR_range, direction);
    }
    return _cursorStreamFromResult(request, autoAdvance);
  }

  Index createIndex(String name, keyPath, {bool? unique, bool? multiEntry}) {
    var options = {};
    if (unique != null) {
      options['unique'] = unique;
    }
    if (multiEntry != null) {
      options['multiEntry'] = multiEntry;
    }

    return _createIndex(name, keyPath, options);
  }

  // To suppress missing implicit constructor warnings.
  factory ObjectStore._() {
    throw new UnsupportedError("Not supported");
  }

  bool? get autoIncrement native;

  @Returns('DomStringList')
  @Creates('DomStringList')
  List<String>? get indexNames native;

  @annotation_Creates_SerializedScriptValue
  Object? get keyPath native;

  String? get name native;

  set name(String? value) native;

  Transaction? get transaction native;

  @Returns('Request')
  @Creates('Request')
  @_annotation_Creates_IDBKey
  Request _add(/*any*/ value, [/*any*/ key]) {
    if (key != null) {
      var value_1 = convertDartToNative_SerializedScriptValue(value);
      var key_2 = convertDartToNative_SerializedScriptValue(key);
      return _add_1(value_1, key_2);
    }
    var value_1 = convertDartToNative_SerializedScriptValue(value);
    return _add_2(value_1);
  }

  @JSName('add')
  @Returns('Request')
  @Creates('Request')
  @_annotation_Creates_IDBKey
  Request _add_1(value, key) native;
  @JSName('add')
  @Returns('Request')
  @Creates('Request')
  @_annotation_Creates_IDBKey
  Request _add_2(value) native;

  @JSName('clear')
  Request _clear() native;

  @JSName('count')
  Request _count(Object? key) native;

  Index _createIndex(String name, Object keyPath, [Map? options]) {
    if (options != null) {
      var options_1 = convertDartToNative_Dictionary(options);
      return _createIndex_1(name, keyPath, options_1);
    }
    return _createIndex_2(name, keyPath);
  }

  @JSName('createIndex')
  Index _createIndex_1(name, keyPath, options) native;
  @JSName('createIndex')
  Index _createIndex_2(name, keyPath) native;

  @JSName('delete')
  Request _delete(Object key) native;

  void deleteIndex(String name) native;

  @JSName('get')
  @Returns('Request')
  @Creates('Request')
  @annotation_Creates_SerializedScriptValue
  Request _get(Object key) native;

  Request getAll(Object? query, [int? count]) native;

  Request getAllKeys(Object? query, [int? count]) native;

  Request getKey(Object key) native;

  Index index(String name) native;

  @JSName('openCursor')
  @Returns('Request')
  @Creates('Request')
  @Creates('Cursor')
  Request _openCursor(Object? range, [String? direction]) native;

  Request openKeyCursor(Object? range, [String? direction]) native;

  @Returns('Request')
  @Creates('Request')
  @_annotation_Creates_IDBKey
  Request _put(/*any*/ value, [/*any*/ key]) {
    if (key != null) {
      var value_1 = convertDartToNative_SerializedScriptValue(value);
      var key_2 = convertDartToNative_SerializedScriptValue(key);
      return _put_1(value_1, key_2);
    }
    var value_1 = convertDartToNative_SerializedScriptValue(value);
    return _put_2(value_1);
  }

  @JSName('put')
  @Returns('Request')
  @Creates('Request')
  @_annotation_Creates_IDBKey
  Request _put_1(value, key) native;
  @JSName('put')
  @Returns('Request')
  @Creates('Request')
  @_annotation_Creates_IDBKey
  Request _put_2(value) native;

  /**
   * Helper for iterating over cursors in a request.
   */
  static Stream<T> _cursorStreamFromResult<T extends Cursor>(
      Request request, bool? autoAdvance) {
    // TODO: need to guarantee that the controller provides the values
    // immediately as waiting until the next tick will cause the transaction to
    // close.
    var controller = new StreamController<T>(sync: true);

    //TODO: Report stacktrace once issue 4061 is resolved.
    request.onError.listen(controller.addError);

    request.onSuccess.listen((e) {
      T? cursor = request.result as dynamic;
      if (cursor == null) {
        controller.close();
      } else {
        controller.add(cursor);
        if (autoAdvance == true && controller.hasListener) {
          cursor.next();
        }
      }
    });
    return controller.stream;
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("IDBObservation")
class Observation extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory Observation._() {
    throw new UnsupportedError("Not supported");
  }

  Object? get key native;

  String? get type native;

  Object? get value native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("IDBObserver")
class Observer extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory Observer._() {
    throw new UnsupportedError("Not supported");
  }

  factory Observer(ObserverCallback callback) {
    var callback_1 = convertDartClosureToJS(callback, 1);
    return Observer._create_1(callback_1);
  }
  static Observer _create_1(callback) =>
      JS('Observer', 'new IDBObserver(#)', callback);

  void observe(Database db, Transaction tx, Map options) {
    var options_1 = convertDartToNative_Dictionary(options);
    _observe_1(db, tx, options_1);
    return;
  }

  @JSName('observe')
  void _observe_1(Database db, Transaction tx, options) native;

  void unobserve(Database db) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("IDBObserverChanges")
class ObserverChanges extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory ObserverChanges._() {
    throw new UnsupportedError("Not supported");
  }

  Database? get database native;

  Object? get records native;

  Transaction? get transaction native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Unstable()
@Native("IDBOpenDBRequest,IDBVersionChangeRequest")
class OpenDBRequest extends Request {
  // To suppress missing implicit constructor warnings.
  factory OpenDBRequest._() {
    throw new UnsupportedError("Not supported");
  }

  /**
   * Static factory designed to expose `blocked` events to event
   * handlers that are not necessarily instances of [OpenDBRequest].
   *
   * See [EventStreamProvider] for usage information.
   */
  static const EventStreamProvider<Event> blockedEvent =
      const EventStreamProvider<Event>('blocked');

  /**
   * Static factory designed to expose `upgradeneeded` events to event
   * handlers that are not necessarily instances of [OpenDBRequest].
   *
   * See [EventStreamProvider] for usage information.
   */
  static const EventStreamProvider<VersionChangeEvent> upgradeNeededEvent =
      const EventStreamProvider<VersionChangeEvent>('upgradeneeded');

  /// Stream of `blocked` events handled by this [OpenDBRequest].
  Stream<Event> get onBlocked => blockedEvent.forTarget(this);

  /// Stream of `upgradeneeded` events handled by this [OpenDBRequest].
  Stream<VersionChangeEvent> get onUpgradeNeeded =>
      upgradeNeededEvent.forTarget(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Unstable()
@Native("IDBRequest")
class Request extends EventTarget {
  // To suppress missing implicit constructor warnings.
  factory Request._() {
    throw new UnsupportedError("Not supported");
  }

  /**
   * Static factory designed to expose `error` events to event
   * handlers that are not necessarily instances of [Request].
   *
   * See [EventStreamProvider] for usage information.
   */
  static const EventStreamProvider<Event> errorEvent =
      const EventStreamProvider<Event>('error');

  /**
   * Static factory designed to expose `success` events to event
   * handlers that are not necessarily instances of [Request].
   *
   * See [EventStreamProvider] for usage information.
   */
  static const EventStreamProvider<Event> successEvent =
      const EventStreamProvider<Event>('success');

  DomException? get error native;

  String? get readyState native;

  dynamic get result => _convertNativeToDart_IDBAny(this._get_result);
  @JSName('result')
  @Creates('Null')
  dynamic get _get_result native;

  @Creates('Null')
  Object? get source native;

  Transaction? get transaction native;

  /// Stream of `error` events handled by this [Request].
  Stream<Event> get onError => errorEvent.forTarget(this);

  /// Stream of `success` events handled by this [Request].
  Stream<Event> get onSuccess => successEvent.forTarget(this);
}
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Unstable()
@Native("IDBTransaction")
class Transaction extends EventTarget {
  /**
   * Provides a Future which will be completed once the transaction has
   * completed.
   *
   * The future will error if an error occurs on the transaction or if the
   * transaction is aborted.
   */
  Future<Database> get completed {
    var completer = new Completer<Database>();

    this.onComplete.first.then((_) {
      completer.complete(db);
    });

    this.onError.first.then((e) {
      completer.completeError(e);
    });

    this.onAbort.first.then((e) {
      // Avoid completing twice if an error occurs.
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
    });

    return completer.future;
  }

  // To suppress missing implicit constructor warnings.
  factory Transaction._() {
    throw new UnsupportedError("Not supported");
  }

  /**
   * Static factory designed to expose `abort` events to event
   * handlers that are not necessarily instances of [Transaction].
   *
   * See [EventStreamProvider] for usage information.
   */
  static const EventStreamProvider<Event> abortEvent =
      const EventStreamProvider<Event>('abort');

  /**
   * Static factory designed to expose `complete` events to event
   * handlers that are not necessarily instances of [Transaction].
   *
   * See [EventStreamProvider] for usage information.
   */
  static const EventStreamProvider<Event> completeEvent =
      const EventStreamProvider<Event>('complete');

  /**
   * Static factory designed to expose `error` events to event
   * handlers that are not necessarily instances of [Transaction].
   *
   * See [EventStreamProvider] for usage information.
   */
  static const EventStreamProvider<Event> errorEvent =
      const EventStreamProvider<Event>('error');

  Database? get db native;

  DomException? get error native;

  String? get mode native;

  @Returns('DomStringList')
  @Creates('DomStringList')
  List<String>? get objectStoreNames native;

  void abort() native;

  ObjectStore objectStore(String name) native;

  /// Stream of `abort` events handled by this [Transaction].
  Stream<Event> get onAbort => abortEvent.forTarget(this);

  /// Stream of `complete` events handled by this [Transaction].
  Stream<Event> get onComplete => completeEvent.forTarget(this);

  /// Stream of `error` events handled by this [Transaction].
  Stream<Event> get onError => errorEvent.forTarget(this);
}
// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Unstable()
@Native("IDBVersionChangeEvent")
class VersionChangeEvent extends Event {
  // To suppress missing implicit constructor warnings.
  factory VersionChangeEvent._() {
    throw new UnsupportedError("Not supported");
  }

  factory VersionChangeEvent(String type, [Map? eventInitDict]) {
    if (eventInitDict != null) {
      var eventInitDict_1 = convertDartToNative_Dictionary(eventInitDict);
      return VersionChangeEvent._create_1(type, eventInitDict_1);
    }
    return VersionChangeEvent._create_2(type);
  }
  static VersionChangeEvent _create_1(type, eventInitDict) => JS(
      'VersionChangeEvent',
      'new IDBVersionChangeEvent(#,#)',
      type,
      eventInitDict);
  static VersionChangeEvent _create_2(type) =>
      JS('VersionChangeEvent', 'new IDBVersionChangeEvent(#)', type);

  String? get dataLoss native;

  String? get dataLossMessage native;

  @Creates('int|String|Null')
  @Returns('int|String|Null')
  int? get newVersion native;

  @Creates('int|String|Null')
  @Returns('int|String|Null')
  int? get oldVersion native;

  @JSName('target')
  OpenDBRequest get target native;
}
