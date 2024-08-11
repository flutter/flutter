// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Efficient JavaScript based implementation of a linked hash map used as a
// backing map for constant maps and the [LinkedHashMap] patch

part of _js_helper;

class JsLinkedHashMap<K, V> extends MapBase<K, V>
    implements LinkedHashMap<K, V>, InternalMap {
  int _length = 0;

  // The hash map contents are divided into three parts: one part for
  // string keys, one for numeric keys, and one for the rest. String
  // and numeric keys map directly to their linked cells, but the rest
  // of the entries are stored in bucket lists of the form:
  //
  //    [cell-0, cell-1, ...]
  //
  // where all keys in the same bucket share the same hash code.
  var _strings;
  var _nums;
  var _rest;

  // Integer properties of JavaScript objects are more efficient if they are
  // small integers. This mask is used to reduce a hashCode to such a small
  // integer.
  static const bucketHashMask = (1 << 30) - 1;

  // The keys and values are stored in cells that are linked together
  // to form a double linked list.
  LinkedHashMapCell? _first;
  LinkedHashMapCell? _last;

  // We track the number of modifications done to the key set of the
  // hash map to be able to throw when the map is modified while being
  // iterated over.
  int _modifications = 0;

  JsLinkedHashMap();

  int get length => _length;
  bool get isEmpty => _length == 0;
  bool get isNotEmpty => !isEmpty;

  Iterable<K> get keys {
    return LinkedHashMapKeyIterable<K>(this);
  }

  Iterable<V> get values {
    return MappedIterable<K, V>(keys, (each) => this[each] as V);
  }

  bool containsKey(Object? key) {
    if (_isStringKey(key)) {
      var strings = _strings;
      if (strings == null) return false;
      return _containsTableEntry(strings, key);
    } else if (_isNumericKey(key)) {
      var nums = _nums;
      if (nums == null) return false;
      return _containsTableEntry(nums, key);
    } else {
      return internalContainsKey(key);
    }
  }

  bool internalContainsKey(Object? key) {
    var rest = _rest;
    if (rest == null) return false;
    var bucket = _getBucket(rest, key);
    return internalFindBucketIndex(bucket, key) >= 0;
  }

  bool containsValue(Object? value) {
    return keys.any((each) => this[each] == value);
  }

  void addAll(Map<K, V> other) {
    other.forEach((K key, V value) {
      this[key] = value;
    });
  }

  V? operator [](Object? key) {
    if (_isStringKey(key)) {
      var strings = _strings;
      if (strings == null) return null;
      LinkedHashMapCell? cell = _getTableCell(strings, key);
      return JS('', '#', cell == null ? null : cell.hashMapCellValue);
    } else if (_isNumericKey(key)) {
      var nums = _nums;
      if (nums == null) return null;
      LinkedHashMapCell? cell = _getTableCell(nums, key);
      return JS('', '#', cell == null ? null : cell.hashMapCellValue);
    } else {
      return internalGet(key);
    }
  }

  V? internalGet(Object? key) {
    var rest = _rest;
    if (rest == null) return null;
    var bucket = _getBucket(rest, key);
    int index = internalFindBucketIndex(bucket, key);
    if (index < 0) return null;
    LinkedHashMapCell cell = JS('var', '#[#]', bucket, index);
    return JS('', '#', cell.hashMapCellValue);
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
      internalSet(key, value);
    }
  }

  void internalSet(K key, V value) {
    var rest = _rest;
    if (rest == null) _rest = rest = _newHashTable();
    var hash = internalComputeHashCode(key);
    var bucket = _getTableBucket(rest, hash);
    if (bucket == null) {
      LinkedHashMapCell cell = _newLinkedCell(key, value);
      _setTableEntry(rest, hash, JS('var', '[#]', cell));
    } else {
      int index = internalFindBucketIndex(bucket, key);
      if (index >= 0) {
        LinkedHashMapCell cell = JS('var', '#[#]', bucket, index);
        cell.hashMapCellValue = value;
      } else {
        LinkedHashMapCell cell = _newLinkedCell(key, value);
        JS('void', '#.push(#)', bucket, cell);
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
      return internalRemove(key);
    }
  }

  V? internalRemove(Object? key) {
    var rest = _rest;
    if (rest == null) return null;
    var hash = internalComputeHashCode(key);
    var bucket = _getTableBucket(rest, hash);
    int index = internalFindBucketIndex(bucket, key);
    if (index < 0) return null;
    // Use splice to remove the [cell] element at the index and
    // unlink the cell before returning its value.
    LinkedHashMapCell cell = JS('var', '#.splice(#, 1)[0]', bucket, index);
    _unlinkCell(cell);
    // Remove empty bucket list to avoid memory leak.
    if (JS('int', '#.length', bucket) == 0) {
      _deleteTableEntry(rest, hash);
    }
    return JS('', '#', cell.hashMapCellValue);
  }

  void clear() {
    if (_length > 0) {
      _strings = _nums = _rest = _first = _last = null;
      _length = 0;
      _modified();
    }
  }

  void forEach(void action(K key, V value)) {
    LinkedHashMapCell? cell = _first;
    int modifications = _modifications;
    while (cell != null) {
      K key = JS('', '#', cell.hashMapCellKey);
      V value = JS('', '#', cell.hashMapCellValue);
      action(key, value);
      if (modifications != _modifications) {
        throw ConcurrentModificationError(this);
      }
      cell = cell._next;
    }
  }

  void _addHashTableEntry(var table, K key, V value) {
    LinkedHashMapCell? cell = _getTableCell(table, key);
    if (cell == null) {
      _setTableEntry(table, key, _newLinkedCell(key, value));
    } else {
      cell.hashMapCellValue = value;
    }
  }

  V? _removeHashTableEntry(var table, Object? key) {
    if (table == null) return null;
    LinkedHashMapCell? cell = _getTableCell(table, key);
    if (cell == null) return null;
    _unlinkCell(cell);
    _deleteTableEntry(table, key);
    return JS('', '#', cell.hashMapCellValue);
  }

  void _modified() {
    // Value cycles after 2^30 modifications so that modification counts are
    // always unboxed (Smi) values. Modification detection will be missed if you
    // make exactly some multiple of 2^30 modifications between advances of an
    // iterator.
    _modifications = (_modifications + 1) & 0x3fffffff;
  }

  // Create a new cell and link it in as the last one in the list.
  LinkedHashMapCell _newLinkedCell(K key, V value) {
    LinkedHashMapCell cell = LinkedHashMapCell(key, value);
    if (_first == null) {
      _first = _last = cell;
    } else {
      LinkedHashMapCell last = _last!;
      cell._previous = last;
      _last = last._next = cell;
    }
    _length++;
    _modified();
    return cell;
  }

  // Unlink the given cell from the linked list of cells.
  void _unlinkCell(LinkedHashMapCell cell) {
    LinkedHashMapCell? previous = cell._previous;
    LinkedHashMapCell? next = cell._next;
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

  static bool _isStringKey(var key) {
    return key is String;
  }

  static bool _isNumericKey(var key) {
    // Only treat unsigned 30-bit integers as numeric keys. This way,
    // we avoid converting them to strings when we use them as keys in
    // the JavaScript hash table object.
    return key is num && JS('bool', '(# & 0x3fffffff) === #', key, key);
  }

  int internalComputeHashCode(var key) {
    return bucketHashMask & key.hashCode;
  }

  List<LinkedHashMapCell>? _getBucket(var table, var key) {
    var hash = internalComputeHashCode(key);
    return _getTableBucket(table, hash);
  }

  int internalFindBucketIndex(var bucket, var key) {
    if (bucket == null) return -1;
    int length = JS('int', '#.length', bucket);
    for (int i = 0; i < length; i++) {
      LinkedHashMapCell cell = JS('var', '#[#]', bucket, i);
      if (cell.hashMapCellKey == key) return i;
    }
    return -1;
  }

  String toString() => MapBase.mapToString(this);

  LinkedHashMapCell? _getTableCell(var table, var key) {
    return JS('var', '#[#]', table, key);
  }

  List<LinkedHashMapCell>? _getTableBucket(var table, var key) {
    return JS('var', '#[#]', table, key);
  }

  void _setTableEntry(var table, var key, var value) {
    assert(value != null);
    JS('void', '#[#] = #', table, key, value);
  }

  void _deleteTableEntry(var table, var key) {
    JS('void', 'delete #[#]', table, key);
  }

  bool _containsTableEntry(var table, var key) {
    LinkedHashMapCell? cell = _getTableCell(table, key);
    return cell != null;
  }

  _newHashTable() {
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

class LinkedHashMapCell {
  final dynamic hashMapCellKey;
  dynamic hashMapCellValue;

  LinkedHashMapCell? _next;
  LinkedHashMapCell? _previous;

  LinkedHashMapCell(this.hashMapCellKey, this.hashMapCellValue);
}

class LinkedHashMapKeyIterable<E> extends EfficientLengthIterable<E>
    implements HideEfficientLengthIterable<E> {
  final JsLinkedHashMap _map;
  LinkedHashMapKeyIterable(this._map);

  int get length => _map._length;
  bool get isEmpty => _map._length == 0;

  Iterator<E> get iterator {
    return LinkedHashMapKeyIterator<E>(_map, _map._modifications);
  }

  bool contains(Object? element) {
    return _map.containsKey(element);
  }

  void forEach(void f(E element)) {
    LinkedHashMapCell? cell = _map._first;
    int modifications = _map._modifications;
    while (cell != null) {
      f(JS('', '#', cell.hashMapCellKey));
      if (modifications != _map._modifications) {
        throw ConcurrentModificationError(_map);
      }
      cell = cell._next;
    }
  }
}

class LinkedHashMapKeyIterator<E> implements Iterator<E> {
  final JsLinkedHashMap _map;
  final int _modifications;
  LinkedHashMapCell? _cell;
  E? _current;

  LinkedHashMapKeyIterator(this._map, this._modifications) {
    _cell = _map._first;
  }

  @pragma('dart2js:as:trust')
  E get current => _current as E;

  bool moveNext() {
    if (_modifications != _map._modifications) {
      throw ConcurrentModificationError(_map);
    }
    var cell = _cell;
    if (cell == null) {
      _current = null;
      return false;
    } else {
      _current = JS('', '#', cell.hashMapCellKey);
      _cell = cell._next;
      return true;
    }
  }
}

base class JsIdentityLinkedHashMap<K, V> extends JsLinkedHashMap<K, V> {
  JsIdentityLinkedHashMap();

  int internalComputeHashCode(var key) {
    return JsLinkedHashMap.bucketHashMask & identityHashCode(key);
  }

  int internalFindBucketIndex(var bucket, var key) {
    if (bucket == null) return -1;
    int length = JS('int', '#.length', bucket);
    for (int i = 0; i < length; i++) {
      LinkedHashMapCell cell = JS('var', '#[#]', bucket, i);
      if (identical(cell.hashMapCellKey, key)) return i;
    }
    return -1;
  }
}

/// Map used as backing store for constant maps that are not initialized at
/// program startup, either because prerequisites are not initialized, or to
/// defer computation until the Map is used.
base class JsConstantLinkedHashMap<K, V> extends JsLinkedHashMap<K, V> {
  JsConstantLinkedHashMap();

  int internalComputeHashCode(var key) {
    return JsLinkedHashMap.bucketHashMask & constantHashCode(key);
  }

  int internalFindBucketIndex(var bucket, var key) {
    if (bucket == null) return -1;
    int length = JS('int', '#.length', bucket);
    for (int i = 0; i < length; i++) {
      LinkedHashMapCell cell = JS('var', '#[#]', bucket, i);
      // The keys of a constant map have 'primitive equality'. Mostly this means
      // that there is no override of `==`. A few constants do override `==` in
      // the implementation, like `Symbol`, `Type` and `Record`. For these, `==`
      // is necessary.
      if (cell.hashMapCellKey == key) return i;
    }
    return -1;
  }
}
