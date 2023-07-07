// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of protobuf;

class UnknownFieldSet {
  static final UnknownFieldSet emptyUnknownFieldSet = UnknownFieldSet()
    .._markReadOnly();
  final Map<int, UnknownFieldSetField> _fields = <int, UnknownFieldSetField>{};

  UnknownFieldSet();

  UnknownFieldSet._clone(UnknownFieldSet unknownFieldSet) {
    mergeFromUnknownFieldSet(unknownFieldSet);
  }

  UnknownFieldSet clone() => UnknownFieldSet._clone(this);

  bool get isEmpty => _fields.isEmpty;
  bool get isNotEmpty => _fields.isNotEmpty;
  bool _isReadOnly = false;

  Map<int, UnknownFieldSetField> asMap() => Map.from(_fields);

  void clear() {
    _ensureWritable('clear');
    _fields.clear();
  }

  void clearField(int tagNumber) {
    _ensureWritable('clearField');
    _fields.remove(tagNumber);
  }

  UnknownFieldSetField? getField(int tagNumber) => _fields[tagNumber];

  bool hasField(int tagNumber) => _fields.containsKey(tagNumber);

  void addField(int number, UnknownFieldSetField field) {
    _ensureWritable('addField');
    _checkFieldNumber(number);
    _fields[number] = field;
  }

  void mergeField(int number, UnknownFieldSetField field) {
    _ensureWritable('mergeField');
    _getField(number)
      ..varints.addAll(field.varints)
      ..fixed32s.addAll(field.fixed32s)
      ..fixed64s.addAll(field.fixed64s)
      ..lengthDelimited.addAll(field.lengthDelimited)
      ..groups.addAll(field.groups);
  }

  bool mergeFieldFromBuffer(int tag, CodedBufferReader input) {
    _ensureWritable('mergeFieldFromBuffer');
    var number = getTagFieldNumber(tag);
    switch (getTagWireType(tag)) {
      case WIRETYPE_VARINT:
        mergeVarintField(number, input.readInt64());
        return true;
      case WIRETYPE_FIXED64:
        mergeFixed64Field(number, input.readFixed64());
        return true;
      case WIRETYPE_LENGTH_DELIMITED:
        mergeLengthDelimitedField(number, input.readBytes());
        return true;
      case WIRETYPE_START_GROUP:
        var subGroup = input.readUnknownFieldSetGroup(number);
        mergeGroupField(number, subGroup);
        return true;
      case WIRETYPE_END_GROUP:
        return false;
      case WIRETYPE_FIXED32:
        mergeFixed32Field(number, input.readFixed32());
        return true;
      default:
        throw InvalidProtocolBufferException.invalidWireType();
    }
  }

  void mergeFromCodedBufferReader(CodedBufferReader input) {
    _ensureWritable('mergeFromCodedBufferReader');
    while (true) {
      var tag = input.readTag();
      if (tag == 0 || !mergeFieldFromBuffer(tag, input)) {
        break;
      }
    }
  }

  void mergeFromUnknownFieldSet(UnknownFieldSet other) {
    _ensureWritable('mergeFromUnknownFieldSet');
    for (var key in other._fields.keys) {
      mergeField(key, other._fields[key]!);
    }
  }

  void _checkFieldNumber(int number) {
    if (number == 0) {
      throw ArgumentError('Zero is not a valid field number.');
    }
  }

  void mergeFixed32Field(int number, int value) {
    _ensureWritable('mergeFixed32Field');
    _getField(number).addFixed32(value);
  }

  void mergeFixed64Field(int number, Int64 value) {
    _ensureWritable('mergeFixed64Field');
    _getField(number).addFixed64(value);
  }

  void mergeGroupField(int number, UnknownFieldSet value) {
    _ensureWritable('mergeGroupField');
    _getField(number).addGroup(value);
  }

  void mergeLengthDelimitedField(int number, List<int> value) {
    _ensureWritable('mergeLengthDelimitedField');
    _getField(number).addLengthDelimited(value);
  }

  void mergeVarintField(int number, Int64 value) {
    _ensureWritable('mergeVarintField');
    _getField(number).addVarint(value);
  }

  UnknownFieldSetField _getField(int number) {
    _checkFieldNumber(number);
    if (_isReadOnly) assert(_fields.containsKey(number));
    return _fields.putIfAbsent(number, () => UnknownFieldSetField());
  }

  @override
  bool operator ==(other) {
    if (other is! UnknownFieldSet) return false;

    var o = other;
    return _areMapsEqual(o._fields, _fields);
  }

  @override
  int get hashCode {
    var hash = 0;
    _fields.forEach((int number, Object value) {
      hash = 0x1fffffff & ((37 * hash) + number);
      hash = 0x1fffffff & ((53 * hash) + value.hashCode);
    });
    return hash;
  }

  @override
  String toString() => _toString('');

  String _toString(String indent) {
    var stringBuffer = StringBuffer();

    for (var tag in _sorted(_fields.keys)) {
      var field = _fields[tag]!;
      for (var value in field.values) {
        if (value is UnknownFieldSet) {
          stringBuffer
            ..write('$indent$tag: {\n')
            ..write(value._toString('$indent  '))
            ..write('$indent}\n');
        } else {
          stringBuffer.write('$indent$tag: $value\n');
        }
      }
    }

    return stringBuffer.toString();
  }

  void writeToCodedBufferWriter(CodedBufferWriter output) {
    for (var key in _fields.keys) {
      _fields[key]!.writeTo(key, output);
    }
  }

  void _markReadOnly() {
    if (_isReadOnly) return;
    for (var f in _fields.values) {
      f._markReadOnly();
    }
    _isReadOnly = true;
  }

  void _ensureWritable(String methodName) {
    if (_isReadOnly) {
      frozenMessageModificationHandler('UnknownFieldSet', methodName);
    }
  }
}

class UnknownFieldSetField {
  List<List<int>> _lengthDelimited = <List<int>>[];
  List<Int64> _varints = <Int64>[];
  List<int> _fixed32s = <int>[];
  List<Int64> _fixed64s = <Int64>[];
  List<UnknownFieldSet> _groups = <UnknownFieldSet>[];

  List<List<int>> get lengthDelimited => _lengthDelimited;
  List<Int64> get varints => _varints;
  List<int> get fixed32s => _fixed32s;
  List<Int64> get fixed64s => _fixed64s;
  List<UnknownFieldSet> get groups => _groups;

  bool _isReadOnly = false;

  void _markReadOnly() {
    if (_isReadOnly) return;
    _isReadOnly = true;
    _lengthDelimited = List.unmodifiable(_lengthDelimited);
    _varints = List.unmodifiable(_varints);
    _fixed32s = List.unmodifiable(_fixed32s);
    _fixed64s = List.unmodifiable(_fixed64s);
    _groups = List.unmodifiable(_groups);
  }

  @override
  bool operator ==(other) {
    if (other is! UnknownFieldSetField) return false;

    var o = other;
    if (lengthDelimited.length != o.lengthDelimited.length) return false;
    for (var i = 0; i < lengthDelimited.length; i++) {
      if (!_areListsEqual(o.lengthDelimited[i], lengthDelimited[i])) {
        return false;
      }
    }
    if (!_areListsEqual(o.varints, varints)) return false;
    if (!_areListsEqual(o.fixed32s, fixed32s)) return false;
    if (!_areListsEqual(o.fixed64s, fixed64s)) return false;
    if (!_areListsEqual(o.groups, groups)) return false;

    return true;
  }

  @override
  int get hashCode {
    var hash = 0;
    for (final value in lengthDelimited) {
      for (var i = 0; i < value.length; i++) {
        hash = 0x1fffffff & (hash + value[i]);
        hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
        hash = hash ^ (hash >> 6);
      }
      hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
      hash = hash ^ (hash >> 11);
      hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
    }
    for (final value in varints) {
      hash = 0x1fffffff & (hash + (7 * value.hashCode));
    }
    for (final value in fixed32s) {
      hash = 0x1fffffff & (hash + (37 * value.hashCode));
    }
    for (final value in fixed64s) {
      hash = 0x1fffffff & (hash + (53 * value.hashCode));
    }
    for (final value in groups) {
      hash = 0x1fffffff & (hash + value.hashCode);
    }
    return hash;
  }

  List get values => [
        ...lengthDelimited,
        ...varints,
        ...fixed32s,
        ...fixed64s,
        ...groups,
      ];

  void writeTo(int fieldNumber, CodedBufferWriter output) {
    void write(type, value) {
      output.writeField(fieldNumber, type, value);
    }

    write(PbFieldType._REPEATED_UINT64, varints);
    write(PbFieldType._REPEATED_FIXED32, fixed32s);
    write(PbFieldType._REPEATED_FIXED64, fixed64s);
    write(PbFieldType._REPEATED_BYTES, lengthDelimited);
    write(PbFieldType._REPEATED_GROUP, groups);
  }

  void addGroup(UnknownFieldSet value) {
    groups.add(value);
  }

  void addLengthDelimited(List<int> value) {
    lengthDelimited.add(value);
  }

  void addFixed32(int value) {
    fixed32s.add(value);
  }

  void addFixed64(Int64 value) {
    fixed64s.add(value);
  }

  void addVarint(Int64 value) {
    varints.add(value);
  }

  bool hasRequiredFields() => false;

  bool isInitialized() => true;

  int get length => values.length;
}
