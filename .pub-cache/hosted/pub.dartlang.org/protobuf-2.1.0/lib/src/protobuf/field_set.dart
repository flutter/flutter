// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of protobuf;

typedef FrozenMessageErrorHandler = void Function(String messageName,
    [String? methodName]);

void defaultFrozenMessageModificationHandler(String messageName,
    [String? methodName]) {
  if (methodName != null) {
    throw UnsupportedError(
        'Attempted to call $methodName on a read-only message ($messageName)');
  }
  throw UnsupportedError(
      'Attempted to change a read-only message ($messageName)');
}

/// Invoked when an attempt is made to modify a frozen message.
///
/// This handler can log the attempt, throw an exception, or ignore the attempt
/// altogether.
///
/// If the handler returns normally, the modification is allowed, and execution
/// proceeds as if the message was writable.
FrozenMessageErrorHandler _frozenMessageModificationHandler =
    defaultFrozenMessageModificationHandler;
FrozenMessageErrorHandler get frozenMessageModificationHandler =>
    _frozenMessageModificationHandler;
set frozenMessageModificationHandler(FrozenMessageErrorHandler value) {
  _hashCodesCanBeMemoized = false;
  _frozenMessageModificationHandler = value;
}

/// Indicator for whether the FieldSet hashCodes can be memoized.
///
/// HashCode memoization relies on the [defaultFrozenMessageModificationHandler]
/// behavior--that is, after freezing, field set values can't ever be changed.
/// This keeps track of whether an application has ever modified the
/// [FrozenMessageErrorHandler] used, not allowing hashCodes to be memoized if
/// it ever changed.
bool _hashCodesCanBeMemoized = true;

/// All the data in a GeneratedMessage.
///
/// These fields and methods are in a separate class to avoid
/// polymorphic access due to inheritance. This turns out to
/// be faster when compiled to JavaScript.
class _FieldSet {
  final GeneratedMessage? _message;
  final EventPlugin? _eventPlugin;

  /// The value of each non-extension field in a fixed-length array.
  /// The index of a field can be found in [FieldInfo.index].
  /// A null entry indicates that the field has no value.
  final List _values;

  /// Contains all the extension fields, or null if there aren't any.
  _ExtensionFieldSet? _extensions;

  /// Contains all the unknown fields, or null if there aren't any.
  UnknownFieldSet? _unknownFields;

  /// Encodes whether `this` has been frozen, and if so, also memoizes the
  /// hash code.
  ///
  /// Will always be a `bool` or `int`.
  ///
  /// If the message is mutable: `false`
  /// If the message is frozen and no hash code has been computed: `true`
  /// If the message is frozen and a hash code has been computed: the hash
  /// code as an `int`.
  Object _frozenState = false;

  /// The [BuilderInfo] for the [GeneratedMessage] this [_FieldSet] belongs to.
  ///
  /// WARNING: Avoid calling this for any performance critical code, instead
  /// obtain the [BuilderInfo] on the call site.
  BuilderInfo get _meta => _message!.info_;

  /// Returns the value of [_frozenState] as if it were a boolean indicator
  /// for whether `this` is read-only (has been frozen).
  ///
  /// If the value is not a `bool`, then it must contain the memoized hash code
  /// value, in which case the proto must be read-only.
  bool get _isReadOnly => _frozenState is bool ? _frozenState as bool : true;

  /// Returns the value of [_frozenState] if it contains the pre-computed value
  /// of the hashCode for the frozen field sets.
  ///
  /// Computing the hashCode of a proto object can be very expensive for large
  /// protos. Frozen protos don't allow any mutations, which means the contents
  /// of the field set should be stable.
  ///
  /// If [_frozenState] contains a boolean, the hashCode hasn't been memoized,
  /// so it will return null.
  int? get _memoizedHashCode =>
      _frozenState is int ? _frozenState as int : null;

  // Maps a oneof decl index to the tag number which is currently set. If the
  // index is not present, the oneof field is unset.
  final Map<int, int>? _oneofCases;

  _FieldSet(this._message, BuilderInfo meta, this._eventPlugin)
      : _values = _makeValueList(meta.byIndex.length),
        _oneofCases = meta.oneofs.isEmpty ? null : <int, int>{};

  static List _makeValueList(int length) {
    if (length == 0) return _zeroList;
    return List.filled(length, null, growable: false);
  }

  // Use a fixed length list and not a constant list to ensure that _values
  // always has the same implementation type.
  static final List _zeroList = [];

  // Metadata about multiple fields

  String get _messageName => _meta.qualifiedMessageName;
  bool get _hasRequiredFields => _meta.hasRequiredFields;

  /// The FieldInfo for each non-extension field.
  Iterable<FieldInfo> get _infos => _meta.fieldInfo.values;

  /// The FieldInfo for each non-extension field in tag order.
  Iterable<FieldInfo> get _infosSortedByTag => _meta.sortedByTag;

  /// Returns true if we should send events to the plugin.
  bool get _hasObservers => _eventPlugin != null && _eventPlugin!.hasObservers;

  bool get _hasExtensions => _extensions != null;
  bool get _hasUnknownFields => _unknownFields != null;

  _ExtensionFieldSet _ensureExtensions() {
    if (!_hasExtensions) _extensions = _ExtensionFieldSet(this);
    return _extensions!;
  }

  UnknownFieldSet _ensureUnknownFields() {
    if (_unknownFields == null) {
      if (_isReadOnly) return UnknownFieldSet.emptyUnknownFieldSet;
      _unknownFields = UnknownFieldSet();
    }
    return _unknownFields!;
  }

  // Metadata about single fields

  /// Returns FieldInfo for a non-extension field, or null if not found.
  FieldInfo? _nonExtensionInfo(BuilderInfo meta, int? tagNumber) =>
      meta.fieldInfo[tagNumber];

  /// Returns FieldInfo for a non-extension field.
  FieldInfo _nonExtensionInfoByIndex(int index) => _meta.byIndex[index];

  /// Returns the FieldInfo for a regular or extension field.
  /// throws ArgumentException if no info is found.
  FieldInfo _ensureInfo(int tagNumber) {
    var fi = _getFieldInfoOrNull(tagNumber);
    if (fi != null) return fi;
    throw ArgumentError('tag $tagNumber not defined in $_messageName');
  }

  /// Returns the FieldInfo for a regular or extension field.
  FieldInfo? _getFieldInfoOrNull(int tagNumber) {
    var fi = _nonExtensionInfo(_meta, tagNumber);
    if (fi != null) return fi;
    if (!_hasExtensions) return null;
    return _extensions!._getInfoOrNull(tagNumber);
  }

  void _markReadOnly() {
    if (_isReadOnly) return;
    _frozenState = true;
    for (var field in _meta.sortedByTag) {
      if (field.isRepeated) {
        final entries = _values[field.index!];
        if (entries == null) continue;
        if (field.isGroupOrMessage) {
          for (var subMessage in entries as List<GeneratedMessage>) {
            subMessage.freeze();
          }
        }
        _values[field.index!] = entries.toFrozenPbList();
      } else if (field.isMapField) {
        PbMap? map = _values[field.index!];
        if (map == null) continue;
        _values[field.index!] = map.freeze();
      } else if (field.isGroupOrMessage) {
        final entry = _values[field.index!];
        if (entry != null) {
          (entry as GeneratedMessage).freeze();
        }
      }
    }
    if (_hasExtensions) {
      _ensureExtensions()._markReadOnly();
    }

    if (_hasUnknownFields) {
      _ensureUnknownFields()._markReadOnly();
    }
  }

  void _ensureWritable() {
    if (_isReadOnly) frozenMessageModificationHandler(_messageName);
  }

  // Single-field operations

  /// Gets a field with full error-checking.
  ///
  /// Works for both extended and non-extended fields.
  /// Creates repeated fields (unless read-only).
  /// Suitable for public API.
  dynamic _getField(int tagNumber) {
    var fi = _nonExtensionInfo(_meta, tagNumber);
    if (fi != null) {
      var value = _values[fi.index!];
      if (value != null) return value;
      return _getDefault(fi);
    }
    if (_hasExtensions) {
      var fi = _extensions!._getInfoOrNull(tagNumber);
      if (fi != null) {
        return _extensions!._getFieldOrDefault(fi);
      }
    }
    throw ArgumentError('tag $tagNumber not defined in $_messageName');
  }

  dynamic _getDefault(FieldInfo fi) {
    if (!fi.isRepeated) return fi.makeDefault!();
    if (_isReadOnly) return fi.readonlyDefault;

    // TODO(skybrian) we could avoid this by generating another
    // method for repeated fields:
    //   msg.mutableFoo().add(123);
    var value = fi._createRepeatedField(_message!);
    _setNonExtensionFieldUnchecked(_meta, fi, value);
    return value;
  }

  List<T> _getDefaultList<T>(FieldInfo<T> fi) {
    assert(fi.isRepeated);
    if (_isReadOnly) return fi.readonlyDefault;

    // TODO(skybrian) we could avoid this by generating another
    // method for repeated fields:
    //   msg.mutableFoo().add(123);
    var value = fi._createRepeatedFieldWithType<T>(_message!);
    _setNonExtensionFieldUnchecked(_meta, fi, value);
    return value;
  }

  Map<K, V> _getDefaultMap<K, V>(MapFieldInfo<K, V> fi) {
    assert(fi.isMapField);

    if (_isReadOnly) {
      return PbMap<K, V>.unmodifiable(
          PbMap<K, V>(fi.keyFieldType, fi.valueFieldType));
    }

    var value = fi._createMapField(_message!);
    _setNonExtensionFieldUnchecked(_meta, fi, value);
    return value;
  }

  dynamic _getFieldOrNullByTag(int tagNumber) {
    var fi = _getFieldInfoOrNull(tagNumber);
    if (fi == null) return null;
    return _getFieldOrNull(fi);
  }

  /// Returns the field's value or null if not set.
  ///
  /// Works for both extended and non-extend fields.
  /// Works for both repeated and non-repeated fields.
  dynamic _getFieldOrNull(FieldInfo fi) {
    if (fi.index != null) return _values[fi.index!];
    if (!_hasExtensions) return null;
    return _extensions!._getFieldOrNull(fi as Extension<dynamic>);
  }

  bool _hasField(int tagNumber) {
    var fi = _nonExtensionInfo(_meta, tagNumber);
    if (fi != null) return _$has(fi.index!);
    if (!_hasExtensions) return false;
    return _extensions!._hasField(tagNumber);
  }

  void _clearField(int? tagNumber) {
    _ensureWritable();
    final meta = _meta;
    var fi = _nonExtensionInfo(meta, tagNumber);
    if (fi != null) {
      // clear a non-extension field
      if (_hasObservers) _eventPlugin!.beforeClearField(fi);
      _values[fi.index!] = null;

      if (meta.oneofs.containsKey(fi.tagNumber)) {
        _oneofCases!.remove(meta.oneofs[fi.tagNumber]);
      }

      var oneofIndex = meta.oneofs[fi.tagNumber];
      if (oneofIndex != null) _oneofCases![oneofIndex] = 0;
      return;
    }

    if (_hasExtensions) {
      var fi = _extensions!._getInfoOrNull(tagNumber);
      if (fi != null) {
        _extensions!._clearField(fi);
        return;
      }
    }

    // neither a regular field nor an extension.
    // TODO(skybrian) throw?
  }

  /// Sets a non-repeated field with error-checking.
  ///
  /// Works for both extended and non-extended fields.
  /// Suitable for public API.
  void _setField(int tagNumber, Object value) {
    ArgumentError.checkNotNull(value, 'value');

    final meta = _meta;
    var fi = _nonExtensionInfo(meta, tagNumber);
    if (fi == null) {
      if (!_hasExtensions) {
        throw ArgumentError('tag $tagNumber not defined in $_messageName');
      }
      _extensions!._setField(tagNumber, value);
      return;
    }

    if (fi.isRepeated) {
      throw ArgumentError(_setFieldFailedMessage(
          fi, value, 'repeating field (use get + .add())'));
    }
    _validateField(fi, value);
    _setNonExtensionFieldUnchecked(meta, fi, value);
  }

  /// Sets a non-repeated field without validating it.
  ///
  /// Works for both extended and non-extended fields.
  /// Suitable for decoders that do their own validation.
  void _setFieldUnchecked(BuilderInfo meta, FieldInfo fi, value) {
    ArgumentError.checkNotNull(fi, 'fi');
    assert(!fi.isRepeated);
    if (fi.index == null) {
      _ensureExtensions()
        .._addInfoUnchecked(fi as Extension<dynamic>)
        .._setFieldUnchecked(fi, value);
    } else {
      _setNonExtensionFieldUnchecked(meta, fi, value);
    }
  }

  /// Returns the list to use for adding to a repeated field.
  ///
  /// Works for both extended and non-extended fields.
  /// Creates and stores the repeated field if it doesn't exist.
  /// If it's an extension and the list doesn't exist, validates and stores it.
  /// Suitable for decoders.
  List<T?> _ensureRepeatedField<T>(BuilderInfo meta, FieldInfo<T> fi) {
    assert(!_isReadOnly);
    assert(fi.isRepeated);
    if (fi.index == null) {
      return _ensureExtensions()._ensureRepeatedField(fi as Extension<T>);
    }
    var value = _getFieldOrNull(fi);
    if (value != null) return value as List<T>;

    var newValue = fi._createRepeatedField(_message!);
    _setNonExtensionFieldUnchecked(meta, fi, newValue);
    return newValue;
  }

  PbMap<K, V> _ensureMapField<K, V>(BuilderInfo meta, MapFieldInfo<K, V> fi) {
    assert(!_isReadOnly);
    assert(fi.isMapField);
    assert(fi.index != null); // Map fields are not allowed to be extensions.

    var value = _getFieldOrNull(fi);
    if (value != null) return value as PbMap<K, V>;

    var newValue = fi._createMapField(_message!);
    _setNonExtensionFieldUnchecked(meta, fi, newValue);
    return newValue as PbMap<K, V>;
  }

  /// Sets a non-extended field and fires events.
  void _setNonExtensionFieldUnchecked(BuilderInfo meta, FieldInfo fi, value) {
    var tag = fi.tagNumber;
    var oneofIndex = meta.oneofs[tag];
    if (oneofIndex != null) {
      _clearField(_oneofCases![oneofIndex]);
      _oneofCases![oneofIndex] = tag;
    }

    // It is important that the callback to the observers is not moved to the
    // beginning of this method but happens just before the value is set.
    // Otherwise the observers will be notified about 'clearField' and
    // 'setField' events in an incorrect order.
    if (_hasObservers) {
      _eventPlugin!.beforeSetField(fi, value);
    }
    _values[fi.index!] = value;
  }

  // Generated method implementations

  /// The implementation of a generated getter.
  T _$get<T>(int index, T? defaultValue) {
    var value = _values[index];
    if (value != null) return value as T;
    if (defaultValue != null) return defaultValue;
    return _getDefault(_nonExtensionInfoByIndex(index)) as T;
  }

  /// The implementation of a generated getter for a default value determined by
  /// the field definition value. Common case for submessages. dynamic type
  /// pushes the type check to the caller.
  dynamic _$getND(int index) {
    var value = _values[index];
    if (value != null) return value;
    return _getDefault(_nonExtensionInfoByIndex(index));
  }

  T _$ensure<T>(int index) {
    if (!_$has(index)) {
      dynamic value = _nonExtensionInfoByIndex(index).subBuilder!();
      _$set(index, value);
      return value;
    }
    // The implicit downcast at the return is always correct by construction
    // from the protoc generator. See `GeneratedMessage.$_getN` for details.
    return _$getND(index);
  }

  /// The implementation of a generated getter for repeated fields.
  List<T> _$getList<T>(int index) {
    var value = _values[index];
    if (value != null) return value as List<T>;
    return _getDefaultList<T>(_nonExtensionInfoByIndex(index) as FieldInfo<T>);
  }

  /// The implementation of a generated getter for map fields.
  Map<K, V> _$getMap<K, V>(GeneratedMessage parentMessage, int index) {
    var value = _values[index];
    if (value != null) return value as Map<K, V>;
    return _getDefaultMap<K, V>(
        _nonExtensionInfoByIndex(index) as MapFieldInfo<K, V>);
  }

  /// The implementation of a generated getter for `bool` fields.
  bool _$getB(int index, bool? defaultValue) {
    var value = _values[index];
    if (value == null) {
      if (defaultValue != null) return defaultValue;
      value = _getDefault(_nonExtensionInfoByIndex(index));
    }
    return value;
  }

  /// The implementation of a generated getter for `bool` fields that default to
  /// `false`.
  bool _$getBF(int index) {
    var value = _values[index];
    if (value == null) return false;
    return value;
  }

  /// The implementation of a generated getter for int fields.
  int _$getI(int index, int? defaultValue) {
    var value = _values[index];
    if (value == null) {
      if (defaultValue != null) return defaultValue;
      value = _getDefault(_nonExtensionInfoByIndex(index));
    }
    return value;
  }

  /// The implementation of a generated getter for `int` fields (int32, uint32,
  /// fixed32, sfixed32) that default to `0`.
  int _$getIZ(int index) {
    var value = _values[index];
    if (value == null) return 0;
    return value;
  }

  /// The implementation of a generated getter for String fields.
  String _$getS(int index, String? defaultValue) {
    var value = _values[index];
    if (value == null) {
      if (defaultValue != null) return defaultValue;
      value = _getDefault(_nonExtensionInfoByIndex(index));
    }
    return value;
  }

  /// The implementation of a generated getter for String fields that default to
  /// the empty string.
  String _$getSZ(int index) {
    var value = _values[index];
    if (value == null) return '';
    return value;
  }

  /// The implementation of a generated getter for Int64 fields.
  Int64 _$getI64(int index) {
    var value = _values[index];
    value ??= _getDefault(_nonExtensionInfoByIndex(index));
    return value;
  }

  /// The implementation of a generated 'has' method.
  bool _$has(int index) {
    var value = _values[index];
    if (value == null) return false;
    if (value is List) return value.isNotEmpty;
    return true;
  }

  /// The implementation of a generated setter.
  ///
  /// In production, does no validation other than a null check.
  /// Only handles non-repeated, non-extension fields.
  /// Also, doesn't handle enums or messages which need per-type validation.
  void _$set(int index, Object? value) {
    assert(!_nonExtensionInfoByIndex(index).isRepeated);
    assert(_$check(index, value));
    _ensureWritable();
    if (value == null) {
      _$check(index, value); // throw exception for null value
    }
    if (_hasObservers) {
      _eventPlugin!.beforeSetField(_nonExtensionInfoByIndex(index), value);
    }
    final meta = _meta;
    var tag = meta.byIndex[index].tagNumber;
    var oneofIndex = meta.oneofs[tag];

    if (oneofIndex != null) {
      _clearField(_oneofCases![oneofIndex]);
      _oneofCases![oneofIndex] = tag;
    }
    _values[index] = value;
  }

  bool _$check(int index, var newValue) {
    _validateField(_nonExtensionInfoByIndex(index), newValue);
    return true; // Allows use in an assertion.
  }

  // Bulk operations reading or writing multiple fields

  void _clear() {
    _ensureWritable();
    if (_unknownFields != null) {
      _unknownFields!.clear();
    }

    if (_hasObservers) {
      for (var fi in _infos) {
        if (_values[fi.index!] != null) {
          _eventPlugin!.beforeClearField(fi);
        }
      }
      if (_hasExtensions) {
        for (var key in _extensions!._tagNumbers) {
          var fi = _extensions!._getInfoOrNull(key)!;
          _eventPlugin!.beforeClearField(fi);
        }
      }
    }
    if (_values.isNotEmpty) _values.fillRange(0, _values.length, null);
    if (_hasExtensions) _extensions!._clearValues();
  }

  bool _equals(_FieldSet o) {
    if (_meta != o._meta) return false;
    for (var i = 0; i < _values.length; i++) {
      if (!_equalFieldValues(_values[i], o._values[i])) return false;
    }

    if (!_hasExtensions || !_extensions!._hasValues) {
      // Check if other extensions are logically empty.
      // (Don't create them unnecessarily.)
      if (o._hasExtensions && o._extensions!._hasValues) {
        return false;
      }
    } else {
      if (!_extensions!._equalValues(o._extensions)) return false;
    }

    if (_unknownFields == null || _unknownFields!.isEmpty) {
      // Check if other unknown fields is logically empty.
      // (Don't create them unnecessarily.)
      if (o._unknownFields != null && o._unknownFields!.isNotEmpty) {
        return false;
      }
    } else {
      // Check if the other unknown fields has the same fields.
      if (_unknownFields != o._unknownFields) return false;
    }

    return true;
  }

  bool _equalFieldValues(left, right) {
    if (left != null && right != null) return _deepEquals(left, right);

    var val = left ?? right;

    // Two uninitialized fields are equal.
    if (val == null) return true;

    // One field is null. We are comparing an initialized field
    // with its default value.

    // An empty repeated field is the same as uninitialized.
    // This is because accessing a repeated field automatically creates it.
    // We don't want reading a field to change equality comparisons.
    if (val is List && val.isEmpty) return true;

    // An empty map field is the same as uninitialized.
    // This is because accessing a map field automatically creates it.
    // We don't want reading a field to change equality comparisons.
    if (val is Map && val.isEmpty) return true;

    // For now, initialized and uninitialized fields are different.
    // TODO(skybrian) consider other cases; should we compare with the
    // default value or not?
    return false;
  }

  /// Calculates a hash code based on the contents of the protobuf.
  ///
  /// The hash may change when any field changes (recursively).
  /// Therefore, protobufs used as map keys shouldn't be changed.
  ///
  /// If the protobuf contents have been frozen, and the
  /// [FrozenMessageErrorHandler] has not been changed from the default
  /// behavior, the hashCode can be memoized to speed up performance.
  int get _hashCode {
    if (_hashCodesCanBeMemoized && _memoizedHashCode != null) {
      return _memoizedHashCode!;
    }

    // Hash with descriptor.
    var hash = _HashUtils._combine(0, _meta.hashCode);

    // Hash with non-extension fields.
    final values = _values;
    for (final fi in _infosSortedByTag) {
      final value = values[fi.index!];
      if (value == null) continue;
      hash = _hashField(hash, fi, value);
    }

    // Hash with extension fields.
    if (_hasExtensions) {
      final extensions = _extensions!;
      final sortedByTagNumbers = _sorted(extensions._tagNumbers);
      for (final tagNumber in sortedByTagNumbers) {
        final fi = extensions._getInfoOrNull(tagNumber)!;
        hash = _hashField(hash, fi, extensions._getFieldOrNull(fi));
      }
    }

    // Hash with unknown fields.
    hash = _HashUtils._combine(hash, _unknownFields?.hashCode ?? 0);

    if (_isReadOnly && _hashCodesCanBeMemoized) {
      _frozenState = hash;
    }
    return hash;
  }

  // Hashes the value of one field (recursively).
  static int _hashField(int hash, FieldInfo fi, value) {
    if (value is List && value.isEmpty) {
      return hash; // It's either repeated or an empty byte array.
    }

    if (value is Map && value.isEmpty) {
      return hash;
    }

    hash = _HashUtils._combine(hash, fi.tagNumber);
    if (_isBytes(fi.type)) {
      // Bytes are represented as a List<int> (Usually with byte-data).
      // We special case that to match our equality semantics.
      hash = _HashUtils._combine(hash, _HashUtils._hashObjects(value));
    } else if (!_isEnum(fi.type)) {
      hash = _HashUtils._combine(hash, value.hashCode);
    } else if (fi.isRepeated) {
      hash = _HashUtils._combine(
          hash, _HashUtils._hashObjects(value.map((enm) => enm.value)));
    } else {
      ProtobufEnum enm = value;
      hash = _HashUtils._combine(hash, enm.value);
    }

    return hash;
  }

  void writeString(StringBuffer out, String indent) {
    void renderValue(key, value) {
      if (value is GeneratedMessage) {
        out.write('$indent$key: {\n');
        value._fieldSet.writeString(out, '$indent  ');
        out.write('$indent}\n');
      } else if (value is MapEntry) {
        out.write('$indent$key: {${value.key} : ${value.value}} \n');
      } else {
        out.write('$indent$key: $value\n');
      }
    }

    void writeFieldValue(fieldValue, String name) {
      if (fieldValue == null) return;
      if (fieldValue is PbListBase) {
        for (var value in fieldValue) {
          renderValue(name, value);
        }
      } else if (fieldValue is PbMap) {
        for (var entry in fieldValue.entries) {
          renderValue(name, entry);
        }
      } else {
        renderValue(name, fieldValue);
      }
    }

    for (var fi in _infosSortedByTag) {
      writeFieldValue(_values[fi.index!],
          fi.name == '' ? fi.tagNumber.toString() : fi.name);
    }

    if (_hasExtensions) {
      _extensions!._info.keys.toList()
        ..sort()
        ..forEach((int tagNumber) => writeFieldValue(
            _extensions!._values[tagNumber],
            '[${_extensions!._info[tagNumber]!.name}]'));
    }
    if (_hasUnknownFields) {
      out.write(_unknownFields.toString());
    } else {
      out.write(UnknownFieldSet().toString());
    }
  }

  /// Merges the contents of the [other] into this message.
  ///
  /// Singular fields that are set in [other] overwrite the corresponding fields
  /// in this message. Repeated fields are appended. Singular sub-messages are
  /// recursively merged.
  void _mergeFromMessage(_FieldSet other) {
    // TODO(https://github.com/google/protobuf.dart/issues/60): Recognize
    // when `this` and [other] are the same protobuf (e.g. from cloning). In
    // this case, we can merge the non-extension fields without field lookups or
    // validation checks.

    for (var fi in other._infosSortedByTag) {
      var value = other._values[fi.index!];
      if (value != null) _mergeField(fi, value, isExtension: false);
    }
    if (other._hasExtensions) {
      var others = other._extensions!;
      for (var tagNumber in others._tagNumbers) {
        var extension = others._getInfoOrNull(tagNumber)!;
        var value = others._getFieldOrNull(extension);
        _mergeField(extension, value, isExtension: true);
      }
    }

    if (other._hasUnknownFields) {
      _ensureUnknownFields().mergeFromUnknownFieldSet(other._unknownFields!);
    }
  }

  void _mergeField(FieldInfo otherFi, fieldValue, {bool? isExtension}) {
    final tagNumber = otherFi.tagNumber;

    // Determine the FieldInfo to use.
    // Don't allow regular fields to be overwritten by extensions.
    final meta = _meta;
    var fi = _nonExtensionInfo(meta, tagNumber);
    if (fi == null && isExtension!) {
      // This will overwrite any existing extension field info.
      fi = otherFi;
    }

    var mustClone = _isGroupOrMessage(otherFi.type);

    if (fi!.isMapField) {
      var f = fi as MapFieldInfo<dynamic, dynamic>;
      mustClone = _isGroupOrMessage(f.valueFieldType);
      var map = f._ensureMapField(meta, this) as PbMap<dynamic, dynamic>;
      if (mustClone) {
        for (MapEntry entry in fieldValue.entries) {
          map[entry.key] = (entry.value as GeneratedMessage).deepCopy();
        }
      } else {
        map.addAll(fieldValue);
      }
      return;
    }

    if (fi.isRepeated) {
      if (mustClone) {
        // fieldValue must be a PbListBase of GeneratedMessage.
        PbListBase<GeneratedMessage> pbList = fieldValue;
        var repeatedFields = fi._ensureRepeatedField(meta, this);
        for (var i = 0; i < pbList.length; ++i) {
          repeatedFields.add(pbList[i].deepCopy());
        }
      } else {
        // fieldValue must be at least a PbListBase.
        PbListBase pbList = fieldValue;
        fi._ensureRepeatedField(meta, this).addAll(pbList);
      }
      return;
    }

    if (otherFi.isGroupOrMessage) {
      final currentFi = isExtension!
          ? _ensureExtensions()._getFieldOrNull(fi as Extension<dynamic>)
          : _values[fi.index!];

      if (currentFi == null) {
        fieldValue = (fieldValue as GeneratedMessage).deepCopy();
      } else {
        fieldValue = currentFi..mergeFromMessage(fieldValue);
      }
    }

    if (isExtension!) {
      _ensureExtensions()
          ._setFieldAndInfo(fi as Extension<dynamic>, fieldValue);
    } else {
      _validateField(fi, fieldValue);
      _setNonExtensionFieldUnchecked(meta, fi, fieldValue);
    }
  }

  // Error-checking

  /// Checks the value for a field that's about to be set.
  void _validateField(FieldInfo fi, var newValue) {
    _ensureWritable();
    var message = _getFieldError(fi.type, newValue);
    if (message != null) {
      throw ArgumentError(_setFieldFailedMessage(fi, newValue, message));
    }
  }

  String _setFieldFailedMessage(FieldInfo fi, var value, String detail) {
    return 'Illegal to set field ${fi.name} (${fi.tagNumber}) of $_messageName'
        ' to value ($value): $detail';
  }

  bool _hasRequiredValues() {
    if (!_hasRequiredFields) return true;
    for (var fi in _infos) {
      var value = _values[fi.index!];
      if (!fi._hasRequiredValues(value)) return false;
    }
    return _hasRequiredExtensionValues();
  }

  bool _hasRequiredExtensionValues() {
    if (!_hasExtensions) return true;
    for (var fi in _extensions!._infos) {
      var value = _extensions!._getFieldOrNull(fi);
      if (!fi._hasRequiredValues(value)) return false;
    }
    return true; // No problems found.
  }

  /// Adds the path to each uninitialized field to the list.
  void _appendInvalidFields(List<String> problems, String prefix) {
    if (!_hasRequiredFields) return;
    for (var fi in _infos) {
      var value = _values[fi.index!];
      fi._appendInvalidFields(problems, value, prefix);
    }
    // TODO(skybrian): search extensions as well
    // https://github.com/google/protobuf.dart/issues/46
  }

  /// Makes a shallow copy of all values from [original] to this.
  ///
  /// Map fields and repeated fields are copied.
  void _shallowCopyValues(_FieldSet original) {
    _values.setRange(0, original._values.length, original._values);
    final info = _meta;
    for (var index = 0; index < info.byIndex.length; index++) {
      var fieldInfo = info.byIndex[index];
      if (fieldInfo.isMapField) {
        PbMap? map = _values[index];
        if (map != null) {
          _values[index] = (fieldInfo as MapFieldInfo)
              ._createMapField(_message!)
            ..addAll(map);
        }
      } else if (fieldInfo.isRepeated) {
        PbListBase? list = _values[index];
        if (list != null) {
          _values[index] = fieldInfo._createRepeatedField(_message!)
            ..addAll(list);
        }
      }
    }

    if (original._hasExtensions) {
      _ensureExtensions()._shallowCopyValues(original._extensions!);
    }

    if (original._hasUnknownFields) {
      _ensureUnknownFields()._fields.addAll(original._unknownFields!._fields);
    }

    _oneofCases?.addAll(original._oneofCases!);
  }
}
