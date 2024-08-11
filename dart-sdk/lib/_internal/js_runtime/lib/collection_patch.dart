// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch file for dart:collection classes.
import 'dart:_foreign_helper' show JS;
import 'dart:_internal' show patch;
import 'dart:_js_helper'
    show
        fillLiteralMap,
        fillLiteralSet,
        InternalMap,
        JsLinkedHashMap,
        JsIdentityLinkedHashMap,
        LinkedHashMapCell,
        LinkedHashMapKeyIterable,
        LinkedHashMapKeyIterator;

import 'dart:_internal' hide Symbol;

const int _mask30 = 0x3fffffff; // Low 30 bits.

@patch
class HashMap<K, V> {
  @patch
  factory HashMap(
      {bool equals(K key1, K key2)?,
      int hashCode(K key)?,
      bool isValidKey(potentialKey)?}) {
    if (isValidKey == null) {
      if (hashCode == null) {
        if (equals == null) {
          return _HashMap<K, V>();
        }
        hashCode = _defaultHashCode;
      } else {
        if (identical(identityHashCode, hashCode) &&
            identical(identical, equals)) {
          return _IdentityHashMap<K, V>();
        }
        if (equals == null) {
          equals = _defaultEquals;
        }
      }
    } else {
      if (hashCode == null) {
        hashCode = _defaultHashCode;
      }
      if (equals == null) {
        equals = _defaultEquals;
      }
    }
    return _CustomHashMap<K, V>(equals, hashCode, isValidKey);
  }

  @patch
  factory HashMap.identity() = _IdentityHashMap<K, V>;
}

base class _HashMap<K, V> extends MapBase<K, V> implements HashMap<K, V> {
  int _length = 0;

  // The hash map contents are divided into three parts: one part for
  // string keys, one for numeric keys, and one for the rest. String
  // and numeric keys map directly to their values, but the rest of
  // the entries are stored in bucket lists of the form:
  //
  //    [key-0, value-0, key-1, value-1, ...]
  //
  // where all keys in the same bucket share the same hash code.
  var _strings;
  var _nums;
  var _rest;

  // When iterating over the hash map, it is very convenient to have a
  // list of all the keys. We cache that on the instance and clear the
  // the cache whenever the key set changes. This is also used to
  // guard against concurrent modifications.
  List? _keys;

  _HashMap();

  int get length => _length;
  bool get isEmpty => _length == 0;
  bool get isNotEmpty => !isEmpty;

  Iterable<K> get keys {
    return _HashMapKeyIterable<K>(this);
  }

  Iterable<V> get values {
    return MappedIterable<K, V>(keys, (each) => this[each] as V);
  }

  bool containsKey(Object? key) {
    if (_isStringKey(key)) {
      var strings = _strings;
      return (strings == null) ? false : _hasTableEntry(strings, key);
    } else if (_isNumericKey(key)) {
      var nums = _nums;
      return (nums == null) ? false : _hasTableEntry(nums, key);
    } else {
      return _containsKey(key);
    }
  }

  bool _containsKey(Object? key) {
    var rest = _rest;
    if (rest == null) return false;
    var bucket = _getBucket(rest, key);
    return _findBucketIndex(bucket, key) >= 0;
  }

  bool containsValue(Object? value) {
    return _computeKeys().any((each) => this[each] == value);
  }

  void addAll(Map<K, V> other) {
    other.forEach((K key, V value) {
      this[key] = value;
    });
  }

  V? operator [](Object? key) {
    if (_isStringKey(key)) {
      var strings = _strings;
      return JS('', '#', strings == null ? null : _getTableEntry(strings, key));
    } else if (_isNumericKey(key)) {
      var nums = _nums;
      return JS('', '#', nums == null ? null : _getTableEntry(nums, key));
    } else {
      return _get(key);
    }
  }

  V? _get(Object? key) {
    var rest = _rest;
    if (rest == null) return null;
    var bucket = _getBucket(rest, key);
    int index = _findBucketIndex(bucket, key);
    return (index < 0) ? null : JS('', '#[#]', bucket, index + 1);
  }

  void operator []=(K key, V value) {
    if (_isStringKey(key)) {
      var strings = _strings;
      if (strings == null) _strings = strings = _newHashTable();
      _addHashTableEntry(strings, key, value);
    } else if (_isNumericKey(key)) {
      var nums = _nums;
      if (nums == null) _nums = nums = _newHashTable();
      _addHashTableEntry(nums, key, value);
    } else {
      _set(key, value);
    }
  }

  void _set(K key, V value) {
    var rest = _rest;
    if (rest == null) _rest = rest = _newHashTable();
    var hash = _computeHashCode(key);
    var bucket = JS('var', '#[#]', rest, hash);
    if (bucket == null) {
      _setTableEntry(rest, hash, JS('var', '[#, #]', key, value));
      _length++;
      _keys = null;
    } else {
      int index = _findBucketIndex(bucket, key);
      if (index >= 0) {
        JS('void', '#[#] = #', bucket, index + 1, value);
      } else {
        JS('void', '#.push(#, #)', bucket, key, value);
        _length++;
        _keys = null;
      }
    }
  }

  V putIfAbsent(K key, V ifAbsent()) {
    if (containsKey(key)) return this[key] as V;
    V value = ifAbsent();
    this[key] = value;
    return value;
  }

  V? remove(Object? key) {
    if (_isStringKey(key)) {
      return _removeHashTableEntry(_strings, key);
    } else if (_isNumericKey(key)) {
      return _removeHashTableEntry(_nums, key);
    } else {
      return _remove(key);
    }
  }

  V? _remove(Object? key) {
    var rest = _rest;
    if (rest == null) return null;
    var hash = _computeHashCode(key);
    var bucket = JS('var', '#[#]', rest, hash);
    int index = _findBucketIndex(bucket, key);
    if (index < 0) return null;
    _length--;
    _keys = null;
    // Use splice to remove the two [key, value] elements at the index and
    // return the value.
    V result = JS('', '#.splice(#, 2)[1]', bucket, index);
    if (0 == JS('int', '#.length', bucket)) {
      _deleteTableEntry(rest, hash);
    }
    return result;
  }

  void clear() {
    if (_length > 0) {
      _strings = _nums = _rest = _keys = null;
      _length = 0;
    }
  }

  void forEach(void action(K key, V value)) {
    List keys = _computeKeys();
    for (int i = 0, length = keys.length; i < length; i++) {
      var key = JS('var', '#[#]', keys, i);
      action(key, this[key] as V);
      if (JS('bool', '# !== #', keys, _keys)) {
        throw ConcurrentModificationError(this);
      }
    }
  }

  List _computeKeys() {
    var result = _keys;
    if (result != null) return result;
    result = List.filled(_length, null);
    int index = 0;

    // Add all string keys to the list.
    var strings = _strings;
    if (strings != null) {
      var names = JS('var', 'Object.getOwnPropertyNames(#)', strings);
      int entries = JS('int', '#.length', names);
      for (int i = 0; i < entries; i++) {
        String key = JS('String', '#[#]', names, i);
        JS('void', '#[#] = #', result, index, key);
        index++;
      }
    }

    // Add all numeric keys to the list.
    var nums = _nums;
    if (nums != null) {
      var names = JS('var', 'Object.getOwnPropertyNames(#)', nums);
      int entries = JS('int', '#.length', names);
      for (int i = 0; i < entries; i++) {
        // Object.getOwnPropertyNames returns a list of strings, so we
        // have to convert the keys back to numbers (+).
        num key = JS('num', '+#[#]', names, i);
        JS('void', '#[#] = #', result, index, key);
        index++;
      }
    }

    // Add all the remaining keys to the list.
    var rest = _rest;
    if (rest != null) {
      var names = JS('var', 'Object.getOwnPropertyNames(#)', rest);
      int entries = JS('int', '#.length', names);
      for (int i = 0; i < entries; i++) {
        var key = JS('String', '#[#]', names, i);
        var bucket = JS('var', '#[#]', rest, key);
        int length = JS('int', '#.length', bucket);
        for (int i = 0; i < length; i += 2) {
          var key = JS('var', '#[#]', bucket, i);
          JS('void', '#[#] = #', result, index, key);
          index++;
        }
      }
    }
    assert(index == _length);
    _keys = result;
    return result;
  }

  void _addHashTableEntry(var table, K key, V value) {
    if (!_hasTableEntry(table, key)) {
      _length++;
      _keys = null;
    }
    _setTableEntry(table, key, value);
  }

  V? _removeHashTableEntry(var table, Object? key) {
    if (table != null && _hasTableEntry(table, key)) {
      V value = _getTableEntry(table, key);
      _deleteTableEntry(table, key);
      _length--;
      _keys = null;
      return value;
    } else {
      return null;
    }
  }

  static bool _isStringKey(var key) {
    return key is String && key != '__proto__';
  }

  static bool _isNumericKey(var key) {
    // Only treat unsigned 30-bit integers as numeric keys. This way,
    // we avoid converting them to strings when we use them as keys in
    // the JavaScript hash table object.
    return key is num && JS('bool', '(# & #) === #', key, _mask30, key);
  }

  int _computeHashCode(var key) {
    // We force the hash codes to be unsigned 30-bit integers to avoid
    // issues with problematic keys like '__proto__'. Another option
    // would be to throw an exception if the hash code isn't a number.
    return JS('int', '# & #', key.hashCode, _mask30);
  }

  static bool _hasTableEntry(var table, var key) {
    var entry = JS('var', '#[#]', table, key);
    // We take care to only store non-null entries in the table, so we
    // can check if the table has an entry for the given key with a
    // simple null check.
    return entry != null;
  }

  static _getTableEntry(var table, var key) {
    var entry = JS('var', '#[#]', table, key);
    // We store the table itself as the entry to signal that it really
    // is a null value, so we have to map back to null here.
    return JS('bool', '# === #', entry, table) ? null : entry;
  }

  static void _setTableEntry(var table, var key, var value) {
    // We only store non-null entries in the table, so we have to
    // change null values to refer to the table itself. Such values
    // will be recognized and mapped back to null on access.
    if (value == null) {
      // Do not update [value] with [table], otherwise our
      // optimizations could be confused by this opaque object being
      // now used for more things than storing and fetching from it.
      JS('void', '#[#] = #', table, key, table);
    } else {
      JS('void', '#[#] = #', table, key, value);
    }
  }

  static void _deleteTableEntry(var table, var key) {
    JS('void', 'delete #[#]', table, key);
  }

  List? _getBucket(var table, var key) {
    var hash = _computeHashCode(key);
    return JS('var', '#[#]', table, hash);
  }

  int _findBucketIndex(var bucket, var key) {
    if (bucket == null) return -1;
    int length = JS('int', '#.length', bucket);
    for (int i = 0; i < length; i += 2) {
      if (JS('var', '#[#]', bucket, i) == key) return i;
    }
    return -1;
  }

  static _newHashTable() {
    // Create a new JavaScript object to be used as a hash table. Use
    // Object.create to avoid the properties on Object.prototype
    // showing up as entries.
    var table = JS('var', 'Object.create(null)');
    // Attempt to force the hash table into 'dictionary' mode by
    // adding a property to it and deleting it again.
    var temporaryKey = '<non-identifier-key>';
    _setTableEntry(table, temporaryKey, table);
    _deleteTableEntry(table, temporaryKey);
    return table;
  }
}

base class _IdentityHashMap<K, V> extends _HashMap<K, V> {
  int _computeHashCode(var key) {
    // We force the hash codes to be unsigned 30-bit integers to avoid
    // issues with problematic keys like '__proto__'. Another option
    // would be to throw an exception if the hash code isn't a number.
    return JS('int', '# & #', identityHashCode(key), _mask30);
  }

  int _findBucketIndex(var bucket, var key) {
    if (bucket == null) return -1;
    int length = JS('int', '#.length', bucket);
    for (int i = 0; i < length; i += 2) {
      if (identical(JS('var', '#[#]', bucket, i), key)) return i;
    }
    return -1;
  }
}

base class _CustomHashMap<K, V> extends _HashMap<K, V> {
  final _Equality<K> _equals;
  final _Hasher<K> _hashCode;
  final _Predicate _validKey;

  _CustomHashMap(this._equals, this._hashCode, bool validKey(potentialKey)?)
      : _validKey = (validKey != null) ? validKey : ((v) => v is K);

  V? operator [](Object? key) {
    if (!_validKey(key)) return null;
    return super._get(key);
  }

  void operator []=(K key, V value) {
    super._set(key, value);
  }

  bool containsKey(Object? key) {
    if (!_validKey(key)) return false;
    return super._containsKey(key);
  }

  V? remove(Object? key) {
    if (!_validKey(key)) return null;
    return super._remove(key);
  }

  int _computeHashCode(var key) {
    // We force the hash codes to be unsigned 30-bit integers to avoid
    // issues with problematic keys like '__proto__'. Another option
    // would be to throw an exception if the hash code isn't a number.
    return JS('int', '# & #', _hashCode(key), _mask30);
  }

  int _findBucketIndex(var bucket, var key) {
    if (bucket == null) return -1;
    int length = JS('int', '#.length', bucket);
    for (int i = 0; i < length; i += 2) {
      if (_equals(JS('var', '#[#]', bucket, i), key)) return i;
    }
    return -1;
  }
}

class _HashMapKeyIterable<E> extends EfficientLengthIterable<E>
    implements HideEfficientLengthIterable<E> {
  final _HashMap _map;
  _HashMapKeyIterable(this._map);

  int get length => _map._length;
  bool get isEmpty => _map._length == 0;
  bool get isNotEmpty => _map._length != 0;

  Iterator<E> get iterator {
    return _HashMapKeyIterator<E>(_map, _map._computeKeys());
  }

  bool contains(Object? element) {
    return _map.containsKey(element);
  }

  void forEach(void f(E element)) {
    List keys = _map._computeKeys();
    for (int i = 0, length = JS('int', '#.length', keys); i < length; i++) {
      f(JS('var', '#[#]', keys, i));
      if (JS('bool', '# !== #', keys, _map._keys)) {
        throw ConcurrentModificationError(_map);
      }
    }
  }
}

class _HashMapKeyIterator<E> implements Iterator<E> {
  final _HashMap _map;
  final List _keys;
  int _offset = 0;
  E? _current;

  _HashMapKeyIterator(this._map, this._keys);

  E get current => _current as E;

  bool moveNext() {
    var keys = _keys;
    int offset = _offset;
    if (JS('bool', '# !== #', keys, _map._keys)) {
      throw ConcurrentModificationError(_map);
    } else if (offset >= JS('int', '#.length', keys)) {
      _current = null;
      return false;
    } else {
      _current = JS('var', '#[#]', keys, offset);
      // TODO(kasperl): For now, we have to tell the type inferrer to
      // treat the result of doing offset + 1 as an int. Otherwise, we
      // get unnecessary bailout code.
      _offset = JS('int', '#', offset + 1);
      return true;
    }
  }
}

@patch
class LinkedHashMap<K, V> {
  @patch
  factory LinkedHashMap(
      {bool equals(K key1, K key2)?,
      int hashCode(K key)?,
      bool isValidKey(potentialKey)?}) {
    if (isValidKey == null) {
      if (hashCode == null) {
        if (equals == null) {
          return JsLinkedHashMap<K, V>();
        }
        hashCode = _defaultHashCode;
      } else {
        if (identical(identityHashCode, hashCode) &&
            identical(identical, equals)) {
          return JsIdentityLinkedHashMap<K, V>();
        }
        if (equals == null) {
          equals = _defaultEquals;
        }
      }
    } else {
      if (hashCode == null) {
        hashCode = _defaultHashCode;
      }
      if (equals == null) {
        equals = _defaultEquals;
      }
    }
    return _LinkedCustomHashMap<K, V>(equals, hashCode, isValidKey);
  }

  @patch
  factory LinkedHashMap.identity() = JsIdentityLinkedHashMap<K, V>;

  // Private factory constructor called by generated code for map literals.
  @pragma('dart2js:noInline')
  factory LinkedHashMap._literal(List keyValuePairs) {
    return fillLiteralMap(keyValuePairs, JsLinkedHashMap<K, V>());
  }

  // Private factory constructor called by generated code for map literals.
  @pragma('dart2js:noThrows')
  @pragma('dart2js:noInline')
  @pragma('dart2js:noSideEffects')
  factory LinkedHashMap._empty() {
    return JsLinkedHashMap<K, V>();
  }

  // Private factory static function called by generated code for map literals.
  // This version is for map literals without type parameters.
  @pragma('dart2js:noThrows')
  @pragma('dart2js:noInline')
  @pragma('dart2js:noSideEffects')
  static _makeEmpty() => JsLinkedHashMap();

  // Private factory static function called by generated code for map literals.
  // This version is for map literals without type parameters.
  @pragma('dart2js:noInline')
  static _makeLiteral(keyValuePairs) =>
      fillLiteralMap(keyValuePairs, JsLinkedHashMap());
}

// TODO(sra): Move to same library as JsLinkedHashMap and make the `internalXXX`
// names private.
base class _LinkedCustomHashMap<K, V> extends JsLinkedHashMap<K, V> {
  final _Equality<K> _equals;
  final _Hasher<K> _hashCode;
  final _Predicate _validKey;

  _LinkedCustomHashMap(
      this._equals, this._hashCode, bool validKey(potentialKey)?)
      : _validKey = (validKey != null) ? validKey : ((v) => v is K);

  V? operator [](Object? key) {
    if (!_validKey(key)) return null;
    return super.internalGet(key);
  }

  void operator []=(K key, V value) {
    super.internalSet(key, value);
  }

  bool containsKey(Object? key) {
    if (!_validKey(key)) return false;
    return super.internalContainsKey(key);
  }

  V? remove(Object? key) {
    if (!_validKey(key)) return null;
    return super.internalRemove(key);
  }

  int internalComputeHashCode(var key) {
    // We force the hash codes to be unsigned 30-bit integers to avoid
    // issues with problematic keys like '__proto__'. Another option
    // would be to throw an exception if the hash code isn't a number.
    return JS('int', '# & #', _hashCode(key), _mask30);
  }

  int internalFindBucketIndex(var bucket, var key) {
    if (bucket == null) return -1;
    int length = JS('int', '#.length', bucket);
    for (int i = 0; i < length; i++) {
      LinkedHashMapCell cell = JS('var', '#[#]', bucket, i);
      if (_equals(cell.hashMapCellKey, key)) return i;
    }
    return -1;
  }
}

@patch
class HashSet<E> {
  @patch
  factory HashSet(
      {bool equals(E e1, E e2)?,
      int hashCode(E e)?,
      bool isValidKey(potentialKey)?}) {
    if (isValidKey == null) {
      if (hashCode == null) {
        if (equals == null) {
          return _HashSet<E>();
        }
        hashCode = _defaultHashCode;
      } else {
        if (identical(identityHashCode, hashCode) &&
            identical(identical, equals)) {
          return _IdentityHashSet<E>();
        }
        if (equals == null) {
          equals = _defaultEquals;
        }
      }
    } else {
      if (hashCode == null) {
        hashCode = _defaultHashCode;
      }
      if (equals == null) {
        equals = _defaultEquals;
      }
    }
    return _CustomHashSet<E>(equals, hashCode, isValidKey);
  }

  @patch
  factory HashSet.identity() = _IdentityHashSet<E>;
}

base class _HashSet<E> extends _SetBase<E> implements HashSet<E> {
  int _length = 0;

  // The hash set contents are divided into three parts: one part for
  // string elements, one for numeric elements, and one for the
  // rest. String and numeric elements map directly to a sentinel
  // value, but the rest of the entries are stored in bucket lists of
  // the form:
  //
  //    [element-0, element-1, element-2, ...]
  //
  // where all elements in the same bucket share the same hash code.
  var _strings;
  var _nums;
  var _rest;

  // When iterating over the hash set, it is very convenient to have a
  // list of all the elements. We cache that on the instance and clear
  // the cache whenever the set changes. This is also used to
  // guard against concurrent modifications.
  List? _elements;

  _HashSet();

  Set<E> _newSet() => _HashSet<E>();
  Set<R> _newSimilarSet<R>() => _HashSet<R>();

  // Iterable.
  Iterator<E> get iterator {
    return _HashSetIterator<E>(this, _computeElements());
  }

  int get length => _length;
  bool get isEmpty => _length == 0;
  bool get isNotEmpty => !isEmpty;

  bool contains(Object? object) {
    if (_isStringElement(object)) {
      var strings = _strings;
      return (strings == null) ? false : _hasTableEntry(strings, object);
    } else if (_isNumericElement(object)) {
      var nums = _nums;
      return (nums == null) ? false : _hasTableEntry(nums, object);
    } else {
      return _contains(object);
    }
  }

  bool _contains(Object? object) {
    var rest = _rest;
    if (rest == null) return false;
    var bucket = _getBucket(rest, object);
    return _findBucketIndex(bucket, object) >= 0;
  }

  E? lookup(Object? object) {
    if (_isStringElement(object) || _isNumericElement(object)) {
      return this.contains(object) ? object as E : null;
    }
    return _lookup(object);
  }

  E? _lookup(Object? object) {
    var rest = _rest;
    if (rest == null) return null;
    var bucket = _getBucket(rest, object);
    var index = _findBucketIndex(bucket, object);
    if (index < 0) return null;
    return JS('', '#[#]', bucket, index);
  }

  // Collection.
  bool add(E element) {
    if (_isStringElement(element)) {
      var strings = _strings;
      if (strings == null) _strings = strings = _newHashTable();
      return _addHashTableEntry(strings, element);
    } else if (_isNumericElement(element)) {
      var nums = _nums;
      if (nums == null) _nums = nums = _newHashTable();
      return _addHashTableEntry(nums, element);
    } else {
      return _add(element);
    }
  }

  bool _add(E element) {
    var rest = _rest;
    if (rest == null) _rest = rest = _newHashTable();
    var hash = _computeHashCode(element);
    var bucket = JS('var', '#[#]', rest, hash);
    if (bucket == null) {
      _setTableEntry(rest, hash, JS('var', '[#]', element));
    } else {
      int index = _findBucketIndex(bucket, element);
      if (index >= 0) return false;
      JS('void', '#.push(#)', bucket, element);
    }
    _length++;
    _elements = null;
    return true;
  }

  void addAll(Iterable<E> objects) {
    for (E each in objects) {
      add(each);
    }
  }

  bool remove(Object? object) {
    if (_isStringElement(object)) {
      return _removeHashTableEntry(_strings, object);
    } else if (_isNumericElement(object)) {
      return _removeHashTableEntry(_nums, object);
    } else {
      return _remove(object);
    }
  }

  bool _remove(Object? object) {
    var rest = _rest;
    if (rest == null) return false;
    var hash = _computeHashCode(object);
    var bucket = JS('var', '#[#]', rest, hash);
    int index = _findBucketIndex(bucket, object);
    if (index < 0) return false;
    // TODO(kasperl): Consider getting rid of the bucket list when
    // the length reaches zero.
    _length--;
    _elements = null;
    // TODO(kasperl): It would probably be faster to move the element to the end
    // and reduce the length of the bucket list.
    JS('void', '#.splice(#, 1)', bucket, index);
    if (0 == JS('int', '#.length', bucket)) {
      _deleteTableEntry(rest, hash);
    }
    return true;
  }

  void clear() {
    if (_length > 0) {
      _strings = _nums = _rest = _elements = null;
      _length = 0;
    }
  }

  List _computeElements() {
    var result = _elements;
    if (result != null) return result;
    result = List.filled(_length, null);
    int index = 0;

    // Add all string elements to the list.
    var strings = _strings;
    if (strings != null) {
      var names = JS('var', 'Object.getOwnPropertyNames(#)', strings);
      int entries = JS('int', '#.length', names);
      for (int i = 0; i < entries; i++) {
        String element = JS('String', '#[#]', names, i);
        JS('void', '#[#] = #', result, index, element);
        index++;
      }
    }

    // Add all numeric elements to the list.
    var nums = _nums;
    if (nums != null) {
      var names = JS('var', 'Object.getOwnPropertyNames(#)', nums);
      int entries = JS('int', '#.length', names);
      for (int i = 0; i < entries; i++) {
        // Object.getOwnPropertyNames returns a list of strings, so we
        // have to convert the elements back to numbers (+).
        num element = JS('num', '+#[#]', names, i);
        JS('void', '#[#] = #', result, index, element);
        index++;
      }
    }

    // Add all the remaining elements to the list.
    var rest = _rest;
    if (rest != null) {
      var names = JS('var', 'Object.getOwnPropertyNames(#)', rest);
      int entries = JS('int', '#.length', names);
      for (int i = 0; i < entries; i++) {
        var entry = JS('String', '#[#]', names, i);
        var bucket = JS('var', '#[#]', rest, entry);
        int length = JS('int', '#.length', bucket);
        for (int i = 0; i < length; i++) {
          JS('void', '#[#] = #[#]', result, index, bucket, i);
          index++;
        }
      }
    }
    assert(index == _length);
    _elements = result;
    return result;
  }

  bool _addHashTableEntry(var table, E element) {
    if (_hasTableEntry(table, element)) return false;
    _setTableEntry(table, element, 0);
    _length++;
    _elements = null;
    return true;
  }

  bool _removeHashTableEntry(var table, Object? element) {
    if (table != null && _hasTableEntry(table, element)) {
      _deleteTableEntry(table, element);
      _length--;
      _elements = null;
      return true;
    } else {
      return false;
    }
  }

  static bool _isStringElement(var element) {
    return element is String && element != '__proto__';
  }

  static bool _isNumericElement(var element) {
    // Only treat unsigned 30-bit integers as numeric elements. This
    // way, we avoid converting them to strings when we use them as
    // keys in the JavaScript hash table object.
    return element is num &&
        JS('bool', '(# & #) === #', element, _mask30, element);
  }

  int _computeHashCode(var element) {
    // We force the hash codes to be unsigned 30-bit integers to avoid
    // issues with problematic elements like '__proto__'. Another
    // option would be to throw an exception if the hash code isn't a
    // number.
    return JS('int', '# & #', element.hashCode, _mask30);
  }

  static bool _hasTableEntry(var table, var key) {
    var entry = JS('var', '#[#]', table, key);
    // We take care to only store non-null entries in the table, so we
    // can check if the table has an entry for the given key with a
    // simple null check.
    return entry != null;
  }

  static void _setTableEntry(var table, var key, var value) {
    assert(value != null);
    JS('void', '#[#] = #', table, key, value);
  }

  static void _deleteTableEntry(var table, var key) {
    JS('void', 'delete #[#]', table, key);
  }

  List? _getBucket(var table, var element) {
    var hash = _computeHashCode(element);
    return JS('var', '#[#]', table, hash);
  }

  int _findBucketIndex(var bucket, var element) {
    if (bucket == null) return -1;
    int length = JS('int', '#.length', bucket);
    for (int i = 0; i < length; i++) {
      if (JS('var', '#[#]', bucket, i) == element) return i;
    }
    return -1;
  }

  static _newHashTable() {
    // Create a new JavaScript object to be used as a hash table. Use
    // Object.create to avoid the properties on Object.prototype
    // showing up as entries.
    var table = JS('var', 'Object.create(null)');
    // Attempt to force the hash table into 'dictionary' mode by
    // adding a property to it and deleting it again.
    var temporaryKey = '<non-identifier-key>';
    _setTableEntry(table, temporaryKey, table);
    _deleteTableEntry(table, temporaryKey);
    return table;
  }
}

base class _IdentityHashSet<E> extends _HashSet<E> {
  Set<E> _newSet() => _IdentityHashSet<E>();
  Set<R> _newSimilarSet<R>() => _IdentityHashSet<R>();

  int _computeHashCode(var key) {
    // We force the hash codes to be unsigned 30-bit integers to avoid
    // issues with problematic keys like '__proto__'. Another option
    // would be to throw an exception if the hash code isn't a number.
    return JS('int', '# & #', identityHashCode(key), _mask30);
  }

  int _findBucketIndex(var bucket, var element) {
    if (bucket == null) return -1;
    int length = JS('int', '#.length', bucket);
    for (int i = 0; i < length; i++) {
      if (identical(JS('var', '#[#]', bucket, i), element)) return i;
    }
    return -1;
  }
}

base class _CustomHashSet<E> extends _HashSet<E> {
  _Equality<E> _equality;
  _Hasher<E> _hasher;
  _Predicate _validKey;
  _CustomHashSet(this._equality, this._hasher, bool validKey(potentialKey)?)
      : _validKey = (validKey != null) ? validKey : ((x) => x is E);

  Set<E> _newSet() => _CustomHashSet<E>(_equality, _hasher, _validKey);
  Set<R> _newSimilarSet<R>() => _HashSet<R>();

  int _findBucketIndex(var bucket, var element) {
    if (bucket == null) return -1;
    int length = JS('int', '#.length', bucket);
    for (int i = 0; i < length; i++) {
      if (_equality(JS('var', '#[#]', bucket, i), element)) return i;
    }
    return -1;
  }

  int _computeHashCode(var element) {
    // We force the hash codes to be unsigned 30-bit integers to avoid
    // issues with problematic elements like '__proto__'. Another
    // option would be to throw an exception if the hash code isn't a
    // number.
    return JS('int', '# & #', _hasher(element), _mask30);
  }

  bool add(E object) => super._add(object);

  bool contains(Object? object) {
    if (!_validKey(object)) return false;
    return super._contains(object);
  }

  E? lookup(Object? object) {
    if (!_validKey(object)) return null;
    return super._lookup(object);
  }

  bool remove(Object? object) {
    if (!_validKey(object)) return false;
    return super._remove(object);
  }
}

// TODO(kasperl): Share this code with _HashMapKeyIterator<E>?
class _HashSetIterator<E> implements Iterator<E> {
  final _HashSet<E> _set;
  final List _elements;
  int _offset = 0;
  E? _current;

  _HashSetIterator(this._set, this._elements);

  E get current => _current as E;

  bool moveNext() {
    var elements = _elements;
    int offset = _offset;
    if (JS('bool', '# !== #', elements, _set._elements)) {
      throw ConcurrentModificationError(_set);
    } else if (offset >= JS('int', '#.length', elements)) {
      _current = null;
      return false;
    } else {
      _current = JS('var', '#[#]', elements, offset);
      // TODO(kasperl): For now, we have to tell the type inferrer to
      // treat the result of doing offset + 1 as an int. Otherwise, we
      // get unnecessary bailout code.
      _offset = JS('int', '#', offset + 1);
      return true;
    }
  }
}

@patch
class LinkedHashSet<E> {
  @patch
  factory LinkedHashSet(
      {bool equals(E e1, E e2)?,
      int hashCode(E e)?,
      bool isValidKey(potentialKey)?}) {
    if (isValidKey == null) {
      if (hashCode == null) {
        if (equals == null) {
          return _LinkedHashSet<E>();
        }
        hashCode = _defaultHashCode;
      } else {
        if (identical(identityHashCode, hashCode) &&
            identical(identical, equals)) {
          return _LinkedIdentityHashSet<E>();
        }
        if (equals == null) {
          equals = _defaultEquals;
        }
      }
    } else {
      if (hashCode == null) {
        hashCode = _defaultHashCode;
      }
      if (equals == null) {
        equals = _defaultEquals;
      }
    }
    return _LinkedCustomHashSet<E>(equals, hashCode, isValidKey);
  }

  @patch
  factory LinkedHashSet.identity() = _LinkedIdentityHashSet<E>;

  // Private factory constructor called by generated code for set literals.
  @pragma('dart2js:noThrows')
  @pragma('dart2js:noInline')
  @pragma('dart2js:noSideEffects')
  factory LinkedHashSet._empty() => _LinkedHashSet<E>();

  // Private factory constructor called by generated code for set literals.
  @pragma('dart2js:noInline')
  factory LinkedHashSet._literal(List values) =>
      fillLiteralSet(values, _LinkedHashSet<E>());

  // Private factory static function called by generated code for set literals.
  // This version is for set literals without type parameters.
  @pragma('dart2js:noThrows')
  @pragma('dart2js:noInline')
  @pragma('dart2js:noSideEffects')
  static _makeEmpty() => _LinkedHashSet();

  // Private factory static function called by generated code for set literals.
  // This version is for set literals without type parameters.
  @pragma('dart2js:noInline')
  static _makeLiteral(List values) => fillLiteralSet(values, _LinkedHashSet());
}

base class _LinkedHashSet<E> extends _SetBase<E> implements LinkedHashSet<E> {
  int _length = 0;

  // The hash set contents are divided into three parts: one part for
  // string elements, one for numeric elements, and one for the
  // rest. String and numeric elements map directly to their linked
  // cells, but the rest of the entries are stored in bucket lists of
  // the form:
  //
  //    [cell-0, cell-1, ...]
  //
  // where all elements in the same bucket share the same hash code.
  var _strings;
  var _nums;
  var _rest;

  // The elements are stored in cells that are linked together
  // to form a double linked list.
  _LinkedHashSetCell? _first;
  _LinkedHashSetCell? _last;

  // We track the number of modifications done to the element set to
  // be able to throw when the set is modified while being iterated
  // over.
  int _modifications = 0;

  _LinkedHashSet();

  Set<E> _newSet() => _LinkedHashSet<E>();
  Set<R> _newSimilarSet<R>() => _LinkedHashSet<R>();

  void _unsupported(String operation) {
    throw 'LinkedHashSet: unsupported $operation';
  }

  // Iterable.
  Iterator<E> get iterator {
    return _LinkedHashSetIterator(this, _modifications);
  }

  int get length => _length;
  bool get isEmpty => _length == 0;
  bool get isNotEmpty => !isEmpty;

  bool contains(Object? object) {
    if (_isStringElement(object)) {
      var strings = _strings;
      if (strings == null) return false;
      _LinkedHashSetCell? cell = _getTableEntry(strings, object);
      return cell != null;
    } else if (_isNumericElement(object)) {
      var nums = _nums;
      if (nums == null) return false;
      _LinkedHashSetCell? cell = _getTableEntry(nums, object);
      return cell != null;
    } else {
      return _contains(object);
    }
  }

  bool _contains(Object? object) {
    var rest = _rest;
    if (rest == null) return false;
    var bucket = _getBucket(rest, object);
    return _findBucketIndex(bucket, object) >= 0;
  }

  E? lookup(Object? object) {
    if (_isStringElement(object) || _isNumericElement(object)) {
      return this.contains(object) ? object as E : null;
    } else {
      return _lookup(object);
    }
  }

  E? _lookup(Object? object) {
    var rest = _rest;
    if (rest == null) return null;
    var bucket = _getBucket(rest, object);
    var index = _findBucketIndex(bucket, object);
    if (index < 0) return null;
    return JS<_LinkedHashSetCell>('', '#[#]', bucket, index)._element;
  }

  void forEach(void action(E element)) {
    _LinkedHashSetCell? cell = _first;
    int modifications = _modifications;
    while (cell != null) {
      action(cell._element);
      if (modifications != _modifications) {
        throw ConcurrentModificationError(this);
      }
      cell = cell._next;
    }
  }

  E get first {
    var first = _first;
    if (first == null) throw StateError("No elements");
    return first._element;
  }

  E get last {
    var last = _last;
    if (last == null) throw StateError("No elements");
    return last._element;
  }

  // Collection.
  bool add(E element) {
    if (_isStringElement(element)) {
      var strings = _strings;
      if (strings == null) _strings = strings = _newHashTable();
      return _addHashTableEntry(strings, element);
    } else if (_isNumericElement(element)) {
      var nums = _nums;
      if (nums == null) _nums = nums = _newHashTable();
      return _addHashTableEntry(nums, element);
    } else {
      return _add(element);
    }
  }

  bool _add(E element) {
    var rest = _rest;
    if (rest == null) _rest = rest = _newHashTable();
    var hash = _computeHashCode(element);
    var bucket = JS('var', '#[#]', rest, hash);
    if (bucket == null) {
      _LinkedHashSetCell cell = _newLinkedCell(element);
      _setTableEntry(rest, hash, JS('var', '[#]', cell));
    } else {
      int index = _findBucketIndex(bucket, element);
      if (index >= 0) return false;
      _LinkedHashSetCell cell = _newLinkedCell(element);
      JS('void', '#.push(#)', bucket, cell);
    }
    return true;
  }

  bool remove(Object? object) {
    if (_isStringElement(object)) {
      return _removeHashTableEntry(_strings, object);
    } else if (_isNumericElement(object)) {
      return _removeHashTableEntry(_nums, object);
    } else {
      return _remove(object);
    }
  }

  bool _remove(Object? object) {
    var rest = _rest;
    if (rest == null) return false;
    var hash = _computeHashCode(object);
    var bucket = JS('var', '#[#]', rest, hash);
    int index = _findBucketIndex(bucket, object);
    if (index < 0) return false;
    // Use splice to remove the [cell] element at the index and unlink it.
    _LinkedHashSetCell cell = JS('var', '#.splice(#, 1)[0]', bucket, index);
    if (0 == JS('int', '#.length', bucket)) {
      _deleteTableEntry(rest, hash);
    }
    _unlinkCell(cell);
    return true;
  }

  void removeWhere(bool test(E element)) {
    _filterWhere(test, true);
  }

  void retainWhere(bool test(E element)) {
    _filterWhere(test, false);
  }

  void _filterWhere(bool test(E element), bool removeMatching) {
    _LinkedHashSetCell? cell = _first;
    while (cell != null) {
      E element = cell._element;
      _LinkedHashSetCell? next = cell._next;
      int modifications = _modifications;
      bool shouldRemove = (removeMatching == test(element));
      if (modifications != _modifications) {
        throw ConcurrentModificationError(this);
      }
      if (shouldRemove) remove(element);
      cell = next;
    }
  }

  void clear() {
    if (_length > 0) {
      _strings = _nums = _rest = _first = _last = null;
      _length = 0;
      _modified();
    }
  }

  bool _addHashTableEntry(var table, E element) {
    _LinkedHashSetCell? cell = _getTableEntry(table, element);
    if (cell != null) return false;
    _setTableEntry(table, element, _newLinkedCell(element));
    return true;
  }

  bool _removeHashTableEntry(var table, Object? element) {
    if (table == null) return false;
    _LinkedHashSetCell? cell = _getTableEntry(table, element);
    if (cell == null) return false;
    _unlinkCell(cell);
    _deleteTableEntry(table, element);
    return true;
  }

  void _modified() {
    // Value cycles after 2^30 modifications. If you keep hold of an
    // iterator for that long, you might miss a modification
    // detection, and iteration can go sour. Don't do that.
    _modifications = _mask30 & (_modifications + 1);
  }

  // Create a new cell and link it in as the last one in the list.
  _LinkedHashSetCell _newLinkedCell(E element) {
    _LinkedHashSetCell cell = _LinkedHashSetCell(element);
    if (_first == null) {
      _first = _last = cell;
    } else {
      _LinkedHashSetCell last = _last!;
      cell._previous = last;
      _last = last._next = cell;
    }
    _length++;
    _modified();
    return cell;
  }

  // Unlink the given cell from the linked list of cells.
  void _unlinkCell(_LinkedHashSetCell cell) {
    _LinkedHashSetCell? previous = cell._previous;
    _LinkedHashSetCell? next = cell._next;
    if (previous == null) {
      assert(cell == _first);
      _first = next;
    } else {
      previous._next = next;
    }
    if (next == null) {
      assert(cell == _last);
      _last = previous;
    } else {
      next._previous = previous;
    }
    _length--;
    _modified();
  }

  static bool _isStringElement(var element) {
    return element is String && element != '__proto__';
  }

  static bool _isNumericElement(var element) {
    // Only treat unsigned 30-bit integers as numeric elements. This
    // way, we avoid converting them to strings when we use them as
    // keys in the JavaScript hash table object.
    return element is num &&
        JS('bool', '(# & #) === #', element, _mask30, element);
  }

  int _computeHashCode(var element) {
    // We force the hash codes to be unsigned 30-bit integers to avoid
    // issues with problematic elements like '__proto__'. Another
    // option would be to throw an exception if the hash code isn't a
    // number.
    return JS('int', '# & #', element.hashCode, _mask30);
  }

  static _getTableEntry(var table, var key) {
    return JS('var', '#[#]', table, key);
  }

  static void _setTableEntry(var table, var key, var value) {
    assert(value != null);
    JS('void', '#[#] = #', table, key, value);
  }

  static void _deleteTableEntry(var table, var key) {
    JS('void', 'delete #[#]', table, key);
  }

  List? _getBucket(var table, var element) {
    var hash = _computeHashCode(element);
    return JS('var', '#[#]', table, hash);
  }

  int _findBucketIndex(var bucket, var element) {
    if (bucket == null) return -1;
    int length = JS('int', '#.length', bucket);
    for (int i = 0; i < length; i++) {
      _LinkedHashSetCell cell = JS('var', '#[#]', bucket, i);
      if (cell._element == element) return i;
    }
    return -1;
  }

  static _newHashTable() {
    // Create a new JavaScript object to be used as a hash table. Use
    // Object.create to avoid the properties on Object.prototype
    // showing up as entries.
    var table = JS('var', 'Object.create(null)');
    // Attempt to force the hash table into 'dictionary' mode by
    // adding a property to it and deleting it again.
    var temporaryKey = '<non-identifier-key>';
    _setTableEntry(table, temporaryKey, table);
    _deleteTableEntry(table, temporaryKey);
    return table;
  }
}

base class _LinkedIdentityHashSet<E> extends _LinkedHashSet<E> {
  Set<E> _newSet() => _LinkedIdentityHashSet<E>();
  Set<R> _newSimilarSet<R>() => _LinkedIdentityHashSet<R>();

  int _computeHashCode(var key) {
    // We force the hash codes to be unsigned 30-bit integers to avoid
    // issues with problematic keys like '__proto__'. Another option
    // would be to throw an exception if the hash code isn't a number.
    return JS('int', '# & #', identityHashCode(key), _mask30);
  }

  int _findBucketIndex(var bucket, var element) {
    if (bucket == null) return -1;
    int length = JS('int', '#.length', bucket);
    for (int i = 0; i < length; i++) {
      _LinkedHashSetCell cell = JS('var', '#[#]', bucket, i);
      if (identical(cell._element, element)) return i;
    }
    return -1;
  }
}

base class _LinkedCustomHashSet<E> extends _LinkedHashSet<E> {
  _Equality<E> _equality;
  _Hasher<E> _hasher;
  _Predicate _validKey;
  _LinkedCustomHashSet(
      this._equality, this._hasher, bool validKey(potentialKey)?)
      : _validKey = (validKey != null) ? validKey : ((x) => x is E);

  Set<E> _newSet() => _LinkedCustomHashSet<E>(_equality, _hasher, _validKey);
  Set<R> _newSimilarSet<R>() => _LinkedHashSet<R>();

  int _findBucketIndex(var bucket, var element) {
    if (bucket == null) return -1;
    int length = JS('int', '#.length', bucket);
    for (int i = 0; i < length; i++) {
      _LinkedHashSetCell cell = JS('var', '#[#]', bucket, i);
      if (_equality(cell._element, element)) return i;
    }
    return -1;
  }

  int _computeHashCode(var element) {
    // We force the hash codes to be unsigned 30-bit integers to avoid
    // issues with problematic elements like '__proto__'. Another
    // option would be to throw an exception if the hash code isn't a
    // number.
    return JS('int', '# & #', _hasher(element), _mask30);
  }

  bool add(E element) => super._add(element);

  bool contains(Object? object) {
    if (!_validKey(object)) return false;
    return super._contains(object);
  }

  E? lookup(Object? object) {
    if (!_validKey(object)) return null;
    return super._lookup(object);
  }

  bool remove(Object? object) {
    if (!_validKey(object)) return false;
    return super._remove(object);
  }

  bool containsAll(Iterable<Object?> elements) {
    for (Object? element in elements) {
      if (!_validKey(element) || !this.contains(element)) return false;
    }
    return true;
  }

  void removeAll(Iterable<Object?> elements) {
    for (Object? element in elements) {
      if (_validKey(element)) {
        super._remove(element);
      }
    }
  }
}

class _LinkedHashSetCell {
  final _element;

  _LinkedHashSetCell? _next;
  _LinkedHashSetCell? _previous;

  _LinkedHashSetCell(this._element);
}

// TODO(kasperl): Share this code with LinkedHashMapKeyIterator<E>?
class _LinkedHashSetIterator<E> implements Iterator<E> {
  final _LinkedHashSet<E> _set;
  final int _modifications;
  _LinkedHashSetCell? _cell;
  E? _current;

  _LinkedHashSetIterator(this._set, this._modifications) {
    _cell = _set._first;
  }

  E get current => _current as E;

  bool moveNext() {
    var cell = _cell;
    if (_modifications != _set._modifications) {
      throw ConcurrentModificationError(_set);
    } else if (cell == null) {
      _current = null;
      return false;
    } else {
      _current = cell._element;
      _cell = cell._next;
      return true;
    }
  }
}
