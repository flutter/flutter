// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch file for dart:convert library.

import 'dart:_js_helper' show argumentErrorValue;
import 'dart:_foreign_helper' show JS;
import 'dart:_interceptors' show JSExtendableArray;
import 'dart:_internal' show MappedIterable, ListIterable, patch;
import 'dart:collection' show LinkedHashMap, MapBase;

/// Parses [json] and builds the corresponding parsed JSON value.
///
/// Parsed JSON values Nare of the types [num], [String], [bool], [Null],
/// [List]s of parsed JSON values or [Map]s from [String] to parsed
/// JSON values.
///
/// The optional [reviver] function, if provided, is called once for each object
/// or list property parsed. The arguments are the property name ([String]) or
/// list index ([int]), and the value is the parsed value.  The return value of
/// the reviver will be used as the value of that property instead of the parsed
/// value.  The top level value is passed to the reviver with the empty string
/// as a key.
///
/// Throws [FormatException] if the input is not valid JSON text.
@patch
_parseJson(String source, reviver(key, value)?) {
  if (source is! String) throw argumentErrorValue(source);

  var parsed;
  try {
    parsed = JS('=Object|JSExtendableArray|Null|bool|num|String',
        'JSON.parse(#)', source);
  } catch (e) {
    throw FormatException(JS<String>('!', 'String(#)', e));
  }

  if (reviver == null) {
    return _convertJsonToDartLazy(parsed);
  } else {
    return _convertJsonToDart(parsed, reviver);
  }
}

/// Walks the raw JavaScript value [json], replacing JavaScript Objects with
/// Maps. [json] is expected to be freshly allocated so elements can be replaced
/// in-place.
_convertJsonToDart(json, reviver(Object? key, Object? value)) {
  walk(e) {
    // JavaScript null, string, number, bool are in the correct representation.
    if (JS<bool>('!', '# == null', e) ||
        JS<bool>('!', 'typeof # != "object"', e)) {
      return e;
    }

    if (JS<bool>('!', 'Array.isArray(#)', e)) {
      // In-place update of the elements since JS Array is a Dart List.
      for (int i = 0; i < JS<int>('!', '#.length', e); i++) {
        // Use JS indexing to avoid range checks.  We know this is the only
        // reference to the list, but the compiler will likely never be able to
        // tell that this instance of the list cannot have its length changed by
        // the reviver even though it later will be passed to the reviver at the
        // outer level.
        var item = JS('', '#[#]', e, i);
        JS('', '#[#]=#', e, i, reviver(i, walk(item)));
      }
      return e;
    }

    // Otherwise it is a plain object, so copy to a JSON map, so we process
    // and revive all entries recursively.
    _JsonMap map = _JsonMap(e);
    var processed = map._processed;
    List<String> keys = map._computeKeys();
    for (int i = 0; i < keys.length; i++) {
      String key = keys[i];
      var revived = reviver(key, walk(JS('', '#[#]', e, key)));
      JS('', '#[#]=#', processed, key, revived);
    }

    // Update the JSON map structure so future access is cheaper.
    map._original = processed; // Don't keep two objects around.
    return map;
  }

  return reviver(null, walk(json));
}

_convertJsonToDartLazy(object) {
  // JavaScript null and undefined are represented as null.
  if (object == null) return null;

  // JavaScript string, number, bool already has the correct representation.
  if (JS<bool>('!', 'typeof # != "object"', object)) {
    return object;
  }

  if (JS<bool>('!', '!Array.isArray(#)', object)) {
    return _JsonMap(object);
  }

  // Update the elements in place since JS arrays are Dart lists.
  for (int i = 0; i < JS<int>('!', '#.length', object); i++) {
    // Use JS indexing to avoid range checks.  We know this is the only
    // reference to the list, but the compiler will likely never be able to
    // tell that this instance of the list cannot have its length changed by
    // the reviver even though it later will be passed to the reviver at the
    // outer level.
    var item = JS('', '#[#]', object, i);
    JS('', '#[#]=#', object, i, _convertJsonToDartLazy(item));
  }
  return object;
}

class _JsonMap extends MapBase<String, dynamic> {
  // The original JavaScript object remains unchanged until
  // the map is eventually upgraded, in which case we null it
  // out to reclaim the memory used by it.
  var _original;

  // We keep track of the map entries that we have already
  // processed by adding them to a separate JavaScript object.
  var _processed = _newJavaScriptObject();

  // If the data slot isn't null, it represents either the list
  // of keys (for non-upgraded JSON maps) or the upgraded map.
  var _data = null;

  _JsonMap(this._original);

  operator [](key) {
    if (_isUpgraded) {
      return _upgradedMap[key];
    } else if (key is! String) {
      return null;
    } else {
      var result = _getProperty(_processed, key);
      if (_isUnprocessed(result)) result = _process(key);
      return result;
    }
  }

  int get length => _isUpgraded ? _upgradedMap.length : _computeKeys().length;

  bool get isEmpty => length == 0;
  bool get isNotEmpty => length > 0;

  Iterable<String> get keys {
    if (_isUpgraded) return _upgradedMap.keys;
    return _JsonMapKeyIterable(this);
  }

  Iterable get values {
    if (_isUpgraded) return _upgradedMap.values;
    return MappedIterable(_computeKeys(), (each) => this[each]);
  }

  operator []=(key, value) {
    if (_isUpgraded) {
      _upgradedMap[key] = value;
    } else if (containsKey(key)) {
      var processed = _processed;
      _setProperty(processed, key, value);
      var original = _original;
      if (!identical(original, processed)) {
        _setProperty(original, key, null); // Reclaim memory.
      }
    } else {
      _upgrade()[key] = value;
    }
  }

  void addAll(Map<String, dynamic> other) {
    other.forEach((key, value) {
      this[key] = value;
    });
  }

  bool containsValue(value) {
    if (_isUpgraded) return _upgradedMap.containsValue(value);
    List<String> keys = _computeKeys();
    for (int i = 0; i < keys.length; i++) {
      String key = keys[i];
      if (this[key] == value) return true;
    }
    return false;
  }

  bool containsKey(key) {
    if (_isUpgraded) return _upgradedMap.containsKey(key);
    if (key is! String) return false;
    return _hasProperty(_original, key);
  }

  putIfAbsent(key, ifAbsent()) {
    if (containsKey(key)) return this[key];
    var value = ifAbsent();
    this[key] = value;
    return value;
  }

  remove(Object? key) {
    if (!_isUpgraded && !containsKey(key)) return null;
    return _upgrade().remove(key);
  }

  void clear() {
    if (_isUpgraded) {
      _upgradedMap.clear();
    } else {
      if (_data != null) {
        // Clear the list of keys to make sure we force
        // a concurrent modification error if anyone is
        // currently iterating over it.
        _data.clear();
      }
      _original = _processed = null;
      _data = {};
    }
  }

  void forEach(void f(String key, value)) {
    if (_isUpgraded) return _upgradedMap.forEach(f);
    List<String> keys = _computeKeys();
    for (int i = 0; i < keys.length; i++) {
      String key = keys[i];

      // Compute the value under the assumption that the property
      // is present but potentially not processed.
      var value = _getProperty(_processed, key);
      if (_isUnprocessed(value)) {
        value = _convertJsonToDartLazy(_getProperty(_original, key));
        _setProperty(_processed, key, value);
      }

      // Do the callback.
      f(key, value);

      // Check if invoking the callback function changed
      // the key set. If so, throw an exception.
      if (!identical(keys, _data)) {
        throw ConcurrentModificationError(this);
      }
    }
  }

  // ------------------------------------------
  // Private helper methods.
  // ------------------------------------------

  bool get _isUpgraded => _processed == null;

  Map<String, dynamic> get _upgradedMap {
    assert(_isUpgraded);
    // 'cast' the union type to LinkedHashMap.  It would be even better if we
    // could 'cast' to the implementation type, since LinkedHashMap includes
    // _JsonMap.
    return JS('LinkedHashMap', '#', _data);
  }

  List<String> _computeKeys() {
    assert(!_isUpgraded);
    List? keys = _data;
    if (keys == null) {
      keys = _data = _getPropertyNames(_original);
    }
    return JS('JSExtendableArray', '#', keys);
  }

  Map<String, dynamic> _upgrade() {
    if (_isUpgraded) return _upgradedMap;

    // Copy all the (key, value) pairs to a freshly allocated
    // linked hash map thus preserving the ordering.
    var result = <String, dynamic>{};
    List<String> keys = _computeKeys();
    for (int i = 0; i < keys.length; i++) {
      String key = keys[i];
      result[key] = this[key];
    }

    // We only upgrade when we need to extend the map, so we can
    // safely force a concurrent modification error in case
    // someone is iterating over the map here.
    if (keys.isEmpty) {
      keys.add("");
    } else {
      keys.clear();
    }

    // Clear out the associated JavaScript objects and mark the
    // map as having been upgraded.
    _original = _processed = null;
    _data = result;
    assert(_isUpgraded);
    return result;
  }

  _process(String key) {
    if (!_hasProperty(_original, key)) return null;
    var result = _convertJsonToDartLazy(_getProperty(_original, key));
    return _setProperty(_processed, key, result);
  }

  // ------------------------------------------
  // Private JavaScript helper methods.
  // ------------------------------------------

  static bool _hasProperty(object, String key) =>
      JS<bool>('!', 'Object.prototype.hasOwnProperty.call(#,#)', object, key);
  static _getProperty(object, String key) => JS('', '#[#]', object, key);
  static _setProperty(object, String key, value) =>
      JS('', '#[#]=#', object, key, value);
  static List _getPropertyNames(object) =>
      JS('JSExtendableArray', 'Object.keys(#)', object);
  static bool _isUnprocessed(object) =>
      JS<bool>('!', 'typeof(#)=="undefined"', object);
  static _newJavaScriptObject() => JS('=Object', 'Object.create(null)');
}

class _JsonMapKeyIterable extends ListIterable<String> {
  final _JsonMap _parent;

  _JsonMapKeyIterable(this._parent);

  int get length => _parent.length;

  String elementAt(int index) {
    return _parent._isUpgraded
        ? _parent.keys.elementAt(index)
        : _parent._computeKeys()[index];
  }

  /// Although [ListIterable] defines its own iterator, we return the iterator
  /// of the underlying list [_keys] in order to propagate
  /// [ConcurrentModificationError]s.
  Iterator<String> get iterator {
    return _parent._isUpgraded
        ? _parent.keys.iterator
        : _parent._computeKeys().iterator;
  }

  /// Delegate to [parent.containsKey] to ensure the performance expected
  /// from [Map.keys.containsKey].
  bool contains(Object? key) => _parent.containsKey(key);
}

@patch
class JsonDecoder {
  @patch
  StringConversionSink startChunkedConversion(Sink<Object?> sink) {
    return _JsonDecoderSink(_reviver, sink);
  }
}

/// Implements the chunked conversion from a JSON string to its corresponding
/// object.
///
/// The sink only creates one object, but its input can be chunked.
// TODO(floitsch): don't accumulate everything before starting to decode.
class _JsonDecoderSink extends _StringSinkConversionSink<StringBuffer> {
  final Object? Function(Object? key, Object? value)? _reviver;
  final Sink<Object?> _sink;

  _JsonDecoderSink(this._reviver, this._sink) : super(StringBuffer(''));

  void close() {
    super.close();
    String accumulated = _stringSink.toString();
    _stringSink.clear();
    Object? decoded = _parseJson(accumulated, _reviver);
    _sink.add(decoded);
    _sink.close();
  }
}
