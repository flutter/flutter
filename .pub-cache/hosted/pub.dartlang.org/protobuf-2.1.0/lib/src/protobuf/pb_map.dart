// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of protobuf;

class PbMap<K, V> extends MapBase<K, V> {
  /// Key type of the map. Per proto2 and proto3 specs, this needs to be an
  /// integer type or `string`, and the type cannot be `repeated`.
  ///
  /// The `int` value is interpreted the same way as [FieldInfo.type].
  final int keyFieldType;

  /// Value type of the map. Per proto2 and proto3 specs, this can be any type
  /// other than `map`, and the type cannot be `repeated`.
  ///
  /// The `int` value is interpreted the same way as [FieldInfo.type].
  final int valueFieldType;

  static const int _keyFieldNumber = 1;
  static const int _valueFieldNumber = 2;

  final Map<K, V> _wrappedMap;

  bool _isReadonly = false;

  // The provided [info] will be ignored.
  PbMap(this.keyFieldType, this.valueFieldType, [BuilderInfo? info])
      : _wrappedMap = <K, V>{};

  PbMap.unmodifiable(PbMap other)
      : keyFieldType = other.keyFieldType,
        valueFieldType = other.valueFieldType,
        _wrappedMap = Map.unmodifiable(other._wrappedMap),
        _isReadonly = other._isReadonly;

  @override
  V? operator [](Object? key) => _wrappedMap[key];

  @override
  void operator []=(K key, V value) {
    if (_isReadonly) {
      throw UnsupportedError('Attempted to change a read-only map field');
    }
    _checkNotNull(key);
    _checkNotNull(value);
    _wrappedMap[key] = value;
  }

  /// A [PbMap] is equal to another [PbMap] with equal key/value
  /// pairs in any order.
  @override
  bool operator ==(other) {
    if (identical(other, this)) {
      return true;
    }
    if (other is! PbMap) {
      return false;
    }
    if (other.length != length) {
      return false;
    }
    for (final key in keys) {
      if (other[key] != this[key]) {
        return false;
      }
    }
    return true;
  }

  /// A [PbMap] is equal to another [PbMap] with equal key/value
  /// pairs in any order. Then, the `hashCode` is guaranteed to be the same.
  @override
  int get hashCode {
    return _wrappedMap.entries
        .fold(0, (h, entry) => h ^ _HashUtils._hash2(entry.key, entry.value));
  }

  @override
  void clear() {
    if (_isReadonly) {
      throw UnsupportedError('Attempted to change a read-only map field');
    }
    _wrappedMap.clear();
  }

  @override
  Iterable<K> get keys => _wrappedMap.keys;

  @override
  V? remove(Object? key) {
    if (_isReadonly) {
      throw UnsupportedError('Attempted to change a read-only map field');
    }
    return _wrappedMap.remove(key);
  }

  void _mergeEntry(BuilderInfo mapEntryMeta, CodedBufferReader input,
      [ExtensionRegistry? registry]) {
    var length = input.readInt32();
    var oldLimit = input._currentLimit;
    input._currentLimit = input._bufferPos + length;
    final entryFieldSet = _FieldSet(null, mapEntryMeta, null);
    _mergeFromCodedBufferReader(mapEntryMeta, entryFieldSet, input, registry!);
    input.checkLastTagWas(0);
    input._currentLimit = oldLimit;
    var key =
        entryFieldSet._values[0] ?? mapEntryMeta.byIndex[0].makeDefault!();
    var value =
        entryFieldSet._values[1] ?? mapEntryMeta.byIndex[1].makeDefault!();
    _wrappedMap[key] = value;
  }

  void _checkNotNull(Object? val) {
    if (val == null) {
      throw ArgumentError("Can't add a null to a map field");
    }
  }

  PbMap freeze() {
    _isReadonly = true;
    if (_isGroupOrMessage(valueFieldType)) {
      for (var subMessage in values as Iterable<GeneratedMessage>) {
        subMessage.freeze();
      }
    }
    return this;
  }
}
