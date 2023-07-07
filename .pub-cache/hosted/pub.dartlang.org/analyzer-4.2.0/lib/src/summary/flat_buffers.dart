// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

/// Reader of lists of boolean values.
///
/// The returned unmodifiable lists lazily read values on access.
class BoolListReader extends Reader<List<bool>> {
  const BoolListReader();

  @override
  int get size => 4;

  @override
  List<bool> read(BufferContext bc, int offset) =>
      _FbBoolList(bc, bc.derefObject(offset));
}

/// The reader of booleans.
class BoolReader extends Reader<bool> {
  const BoolReader() : super();

  @override
  int get size => 1;

  @override
  bool read(BufferContext bc, int offset) => bc._getInt8(offset) != 0;
}

/// Buffer with data and some context about it.
class BufferContext {
  final ByteData _buffer;

  factory BufferContext.fromBytes(List<int> byteList) {
    Uint8List uint8List = _asUint8List(byteList);
    ByteData buf = ByteData.view(uint8List.buffer, uint8List.offsetInBytes);
    return BufferContext._(buf);
  }

  BufferContext._(this._buffer);

  int derefObject(int offset) {
    return offset + _getUint32(offset);
  }

  Uint8List _asUint8LIst(int offset, int length) =>
      _buffer.buffer.asUint8List(_buffer.offsetInBytes + offset, length);

  double _getFloat64(int offset) => _buffer.getFloat64(offset, Endian.little);

  int _getInt32(int offset) => _buffer.getInt32(offset, Endian.little);

  int _getInt8(int offset) => _buffer.getInt8(offset);

  int _getUint16(int offset) => _buffer.getUint16(offset, Endian.little);

  int _getUint32(int offset) => _buffer.getUint32(offset, Endian.little);

  int _getUint8(int offset) => _buffer.getUint8(offset);

  /// If the [byteList] is already a [Uint8List] return it.
  /// Otherwise return a [Uint8List] copy of the [byteList].
  static Uint8List _asUint8List(List<int> byteList) {
    if (byteList is Uint8List) {
      return byteList;
    } else {
      return Uint8List.fromList(byteList);
    }
  }
}

/// Class that helps building flat buffers.
class Builder {
  final int initialSize;

  /// The list of field tails, reused by [_VTable] instances.
  final Int32List _reusedFieldTails = Int32List(1024);

  /// The list of field offsets, reused by [_VTable] instances.
  final Int32List _reusedFieldOffsets = Int32List(1024);

  /// The list of existing VTable(s).
  final List<_VTable> _vTables = <_VTable>[];

  late ByteData _buf;

  /// The maximum alignment that has been seen so far.  If [_buf] has to be
  /// reallocated in the future (to insert room at its start for more bytes) the
  /// reallocation will need to be a multiple of this many bytes.
  late int _maxAlign;

  /// The number of bytes that have been written to the buffer so far.  The
  /// most recently written byte is this many bytes from the end of [_buf].
  late int _tail;

  /// The location of the end of the current table, measured in bytes from the
  /// end of [_buf], or `null` if a table is not currently being built.
  late int _currentTableEndTail;

  _VTable? _currentVTable;

  /// Map containing all strings that have been written so far.  This allows us
  /// to avoid duplicating strings.
  final Map<String, Offset<String>> _strings = <String, Offset<String>>{};

  Builder({this.initialSize = 1024}) {
    reset();
  }

  /// Add the [field] with the given boolean [value].  The field is not added if
  /// the [value] is equal to [def].  Booleans are stored as 8-bit fields with
  /// `0` for `false` and `1` for `true`.
  void addBool(int field, bool? value, [bool? def]) {
    _ensureCurrentVTable();
    if (value != null && value != def) {
      int size = 1;
      _prepare(size, 1);
      _trackField(field);
      _buf.setInt8(_buf.lengthInBytes - _tail, value ? 1 : 0);
    }
  }

  /// Add the [field] with the given 64-bit float [value].
  void addFloat64(int field, double? value, [double? def]) {
    _ensureCurrentVTable();
    if (value != null && value != def) {
      int size = 8;
      _prepare(size, 1);
      _trackField(field);
      _setFloat64AtTail(_buf, _tail, value);
    }
  }

  /// Add the [field] with the given 32-bit signed integer [value].  The field
  /// is not added if the [value] is equal to [def].
  void addInt32(int field, int? value, [int? def]) {
    _ensureCurrentVTable();
    if (value != null && value != def) {
      int size = 4;
      _prepare(size, 1);
      _trackField(field);
      _setInt32AtTail(_buf, _tail, value);
    }
  }

  /// Add the [field] with the given 8-bit signed integer [value].  The field is
  /// not added if the [value] is equal to [def].
  void addInt8(int field, int? value, [int? def]) {
    _ensureCurrentVTable();
    if (value != null && value != def) {
      int size = 1;
      _prepare(size, 1);
      _trackField(field);
      _buf.setInt8(_buf.lengthInBytes - _tail, value);
    }
  }

  /// Add the [field] referencing an object with the given [offset].
  void addOffset(int field, Offset? offset) {
    _ensureCurrentVTable();
    if (offset != null) {
      _prepare(4, 1);
      _trackField(field);
      _setUint32AtTail(_buf, _tail, _tail - offset._tail);
    }
  }

  /// Add the [field] with the given 32-bit unsigned integer [value].  The field
  /// is not added if the [value] is equal to [def].
  void addUint32(int field, int? value, [int? def]) {
    _ensureCurrentVTable();
    if (value != null && value != def) {
      int size = 4;
      _prepare(size, 1);
      _trackField(field);
      _setUint32AtTail(_buf, _tail, value);
    }
  }

  /// Add the [field] with the given 8-bit unsigned integer [value].  The field
  /// is not added if the [value] is equal to [def].
  void addUint8(int field, int? value, [int? def]) {
    _ensureCurrentVTable();
    if (value != null && value != def) {
      int size = 1;
      _prepare(size, 1);
      _trackField(field);
      _setUint8AtTail(_buf, _tail, value);
    }
  }

  /// End the current table and return its offset.
  Offset endTable() {
    if (_currentVTable == null) {
      throw StateError('Start a table before ending it.');
    }
    // Prepare for writing the VTable.
    _prepare(4, 1);
    int tableTail = _tail;
    // Prepare the size of the current table.
    _currentVTable!.tableSize = tableTail - _currentTableEndTail;
    // Prepare the VTable to use for the current table.
    int? vTableTail;
    {
      _currentVTable!.computeFieldOffsets(tableTail);
      // Try to find an existing compatible VTable.
      for (int i = 0; i < _vTables.length; i++) {
        _VTable vTable = _vTables[i];
        if (_currentVTable!.canUseExistingVTable(vTable)) {
          vTableTail = vTable.tail;
          break;
        }
      }
      // Write a new VTable.
      if (vTableTail == null) {
        _currentVTable!.takeFieldOffsets();
        _prepare(2, _currentVTable!.numOfUint16);
        vTableTail = _tail;
        _currentVTable!.tail = vTableTail;
        _currentVTable!.output(_buf, _buf.lengthInBytes - _tail);
        _vTables.add(_currentVTable!);
      }
    }
    // Set the VTable offset.
    _setInt32AtTail(_buf, tableTail, vTableTail - tableTail);
    // Done with this table.
    _currentVTable = null;
    return Offset(tableTail);
  }

  /// Finish off the creation of the buffer.  The given [offset] is used as the
  /// root object offset, and usually references directly or indirectly every
  /// written object.  If [fileIdentifier] is specified (and not `null`), it is
  /// interpreted as a 4-byte Latin-1 encoded string that should be placed at
  /// bytes 4-7 of the file.
  Uint8List finish(Offset offset, [String? fileIdentifier]) {
    _prepare(max(4, _maxAlign), fileIdentifier == null ? 1 : 2);
    int alignedTail = _tail + ((-_tail) % _maxAlign);
    _setUint32AtTail(_buf, alignedTail, alignedTail - offset._tail);
    if (fileIdentifier != null) {
      for (int i = 0; i < 4; i++) {
        _setUint8AtTail(
            _buf, alignedTail - 4 - i, fileIdentifier.codeUnitAt(i));
      }
    }
    return _buf.buffer.asUint8List(_buf.lengthInBytes - alignedTail);
  }

  /// This is a low-level method, it should not be invoked by clients.
  Uint8List lowFinish() {
    int alignedTail = _tail + ((-_tail) % _maxAlign);
    return _buf.buffer.asUint8List(_buf.lengthInBytes - alignedTail);
  }

  /// This is a low-level method, it should not be invoked by clients.
  void lowReset() {
    _buf = ByteData(initialSize);
    _maxAlign = 1;
    _tail = 0;
  }

  /// This is a low-level method, it should not be invoked by clients.
  void lowWriteUint32(int value) {
    _prepare(4, 1);
    _setUint32AtTail(_buf, _tail, value);
  }

  /// This is a low-level method, it should not be invoked by clients.
  void lowWriteUint8(int value) {
    _prepare(1, 1);
    _buf.setUint8(_buf.lengthInBytes - _tail, value);
  }

  /// Reset the builder and make it ready for filling a new buffer.
  void reset() {
    _buf = ByteData(initialSize);
    _maxAlign = 1;
    _tail = 0;
    _currentVTable = null;
  }

  /// Start a new table.  Must be finished with [endTable] invocation.
  void startTable() {
    if (_currentVTable != null) {
      throw StateError('Inline tables are not supported.');
    }
    _currentVTable = _VTable(_reusedFieldTails, _reusedFieldOffsets);
    _currentTableEndTail = _tail;
  }

  /// Write the given list of [values].
  Offset writeList(List<Offset> values) {
    _ensureNoVTable();
    _prepare(4, 1 + values.length);
    Offset result = Offset(_tail);
    int tail = _tail;
    _setUint32AtTail(_buf, tail, values.length);
    tail -= 4;
    for (Offset value in values) {
      _setUint32AtTail(_buf, tail, tail - value._tail);
      tail -= 4;
    }
    return result;
  }

  /// Write the given list of boolean [values].
  Offset writeListBool(List<bool> values) {
    int bitLength = values.length;
    int padding = (-bitLength) % 8;
    int byteLength = (bitLength + padding) ~/ 8;
    // Prepare the backing Uint8List.
    Uint8List bytes = Uint8List(byteLength + 1);
    // Record every bit.
    int byteIndex = 0;
    int byte = 0;
    int mask = 1;
    for (int bitIndex = 0; bitIndex < bitLength; bitIndex++) {
      if (bitIndex != 0 && (bitIndex % 8 == 0)) {
        bytes[byteIndex++] = byte;
        byte = 0;
        mask = 1;
      }
      if (values[bitIndex]) {
        byte |= mask;
      }
      mask <<= 1;
    }
    // Write the last byte, even if it may be on the padding.
    bytes[byteIndex] = byte;
    // Write the padding length.
    bytes[byteLength] = padding;
    // Write as a Uint8 list.
    return writeListUint8(bytes);
  }

  /// Write the given list of 64-bit float [values].
  Offset writeListFloat64(List<double> values) {
    _ensureNoVTable();
    _prepare(8, 1 + values.length);
    Offset result = Offset(_tail);
    int tail = _tail;
    _setUint32AtTail(_buf, tail, values.length);
    tail -= 8;
    for (double value in values) {
      _setFloat64AtTail(_buf, tail, value);
      tail -= 8;
    }
    return result;
  }

  /// Write the given list of signed 32-bit integer [values].
  Offset writeListInt32(List<int> values) {
    _ensureNoVTable();
    _prepare(4, 1 + values.length);
    Offset result = Offset(_tail);
    int tail = _tail;
    _setUint32AtTail(_buf, tail, values.length);
    tail -= 4;
    for (int value in values) {
      _setInt32AtTail(_buf, tail, value);
      tail -= 4;
    }
    return result;
  }

  /// Write the given list of unsigned 32-bit integer [values].
  Offset writeListUint32(List<int> values) {
    _ensureNoVTable();
    _prepare(4, 1 + values.length);
    Offset result = Offset(_tail);
    int tail = _tail;
    _setUint32AtTail(_buf, tail, values.length);
    tail -= 4;
    for (int value in values) {
      _setUint32AtTail(_buf, tail, value);
      tail -= 4;
    }
    return result;
  }

  /// Write the given list of unsigned 8-bit integer [values].
  Offset writeListUint8(List<int> values) {
    _ensureNoVTable();
    _prepare(4, 1, additionalBytes: values.length);
    Offset result = Offset(_tail);
    int tail = _tail;
    _setUint32AtTail(_buf, tail, values.length);
    tail -= 4;
    for (int value in values) {
      _setUint8AtTail(_buf, tail, value);
      tail -= 1;
    }
    return result;
  }

  /// Write the given string [value] and return its [Offset].
  Offset<String> writeString(String value) {
    _ensureNoVTable();
    return _strings.putIfAbsent(value, () {
      // TODO(scheglov) optimize for ASCII strings
      List<int> bytes = utf8.encode(value);
      int length = bytes.length;
      _prepare(4, 1, additionalBytes: length);
      Offset<String> result = Offset(_tail);
      _setUint32AtTail(_buf, _tail, length);
      int offset = _buf.lengthInBytes - _tail + 4;
      for (int i = 0; i < length; i++) {
        _buf.setUint8(offset++, bytes[i]);
      }
      return result;
    });
  }

  /// Throw an exception if there is not currently a vtable.
  void _ensureCurrentVTable() {
    if (_currentVTable == null) {
      throw StateError('Start a table before adding values.');
    }
  }

  /// Throw an exception if there is currently a vtable.
  void _ensureNoVTable() {
    if (_currentVTable != null) {
      throw StateError(
          'Cannot write a non-scalar value while writing a table.');
    }
  }

  /// Prepare for writing the given [count] of scalars of the given [size].
  /// Additionally allocate the specified [additionalBytes]. Update the current
  /// tail pointer to point at the allocated space.
  void _prepare(int size, int count, {int additionalBytes = 0}) {
    // Update the alignment.
    if (_maxAlign < size) {
      _maxAlign = size;
    }
    // Prepare amount of required space.
    int dataSize = size * count + additionalBytes;
    int alignDelta = (-(_tail + dataSize)) % size;
    int bufSize = alignDelta + dataSize;
    // Ensure that we have the required amount of space.
    {
      int oldCapacity = _buf.lengthInBytes;
      if (_tail + bufSize > oldCapacity) {
        int desiredNewCapacity = (oldCapacity + bufSize) * 2;
        int deltaCapacity = desiredNewCapacity - oldCapacity;
        deltaCapacity += (-deltaCapacity) % _maxAlign;
        int newCapacity = oldCapacity + deltaCapacity;
        ByteData newBuf = ByteData(newCapacity);
        newBuf.buffer
            .asUint8List()
            .setAll(deltaCapacity, _buf.buffer.asUint8List());
        _buf = newBuf;
      }
    }
    // Update the tail pointer.
    _tail += bufSize;
  }

  /// Record the offset of the given [field].
  void _trackField(int field) {
    _currentVTable!.addField(field, _tail);
  }

  static void _setFloat64AtTail(ByteData buf, int tail, double x) {
    buf.setFloat64(buf.lengthInBytes - tail, x, Endian.little);
  }

  static void _setInt32AtTail(ByteData buf, int tail, int x) {
    buf.setInt32(buf.lengthInBytes - tail, x, Endian.little);
  }

  static void _setUint32AtTail(ByteData buf, int tail, int x) {
    buf.setUint32(buf.lengthInBytes - tail, x, Endian.little);
  }

  static void _setUint8AtTail(ByteData buf, int tail, int x) {
    buf.setUint8(buf.lengthInBytes - tail, x);
  }
}

/// The reader of lists of 64-bit float values.
///
/// The returned unmodifiable lists lazily read values on access.
class Float64ListReader extends Reader<List<double>> {
  const Float64ListReader();

  @override
  int get size => 4;

  @override
  List<double> read(BufferContext bc, int offset) =>
      _FbFloat64List(bc, bc.derefObject(offset));
}

/// The reader of 64-bit floats.
class Float64Reader extends Reader<double> {
  const Float64Reader() : super();

  @override
  int get size => 8;

  @override
  double read(BufferContext bc, int offset) => bc._getFloat64(offset);
}

/// The reader of signed 32-bit integers.
class Int32Reader extends Reader<int> {
  const Int32Reader() : super();

  @override
  int get size => 4;

  @override
  int read(BufferContext bc, int offset) => bc._getInt32(offset);
}

/// The reader of 8-bit signed integers.
class Int8Reader extends Reader<int> {
  const Int8Reader() : super();

  @override
  int get size => 1;

  @override
  int read(BufferContext bc, int offset) => bc._getInt8(offset);
}

/// The reader of lists of objects.
///
/// The returned unmodifiable lists lazily read objects on access.
class ListReader<E> extends Reader<List<E>> {
  final Reader<E> _elementReader;

  const ListReader(this._elementReader);

  @override
  int get size => 4;

  @override
  List<E> read(BufferContext bc, int offset) =>
      _FbGenericList<E>(_elementReader, bc, bc.derefObject(offset));
}

/// The offset from the end of the buffer to a serialized object of the type
/// [T].
class Offset<T> {
  final int _tail;

  Offset(this._tail);
}

/// Object that can read a value at a [BufferContext].
abstract class Reader<T> {
  const Reader();

  /// The size of the value in bytes.
  int get size;

  /// Read the value at the given [offset] in [bc].
  T read(BufferContext bc, int offset);

  /// Read the value of the given [field] in the given [object].
  T vTableGet(BufferContext object, int offset, int field, T defaultValue) {
    return vTableGetOrNull(object, offset, field) ?? defaultValue;
  }

  /// Read the value of the given [field] in the given [object].
  T? vTableGetOrNull(BufferContext object, int offset, int field) {
    int vTableSOffset = object._getInt32(offset);
    int vTableOffset = offset - vTableSOffset;
    int vTableSize = object._getUint16(vTableOffset);
    int vTableFieldOffset = (1 + 1 + field) * 2;
    if (vTableFieldOffset < vTableSize) {
      int fieldOffsetInObject =
          object._getUint16(vTableOffset + vTableFieldOffset);
      if (fieldOffsetInObject != 0) {
        return read(object, offset + fieldOffsetInObject);
      }
    }
    return null;
  }
}

/// The reader of string values.
class StringReader extends Reader<String> {
  const StringReader() : super();

  @override
  int get size => 4;

  @override
  String read(BufferContext bc, int offset) {
    int strOffset = bc.derefObject(offset);
    int length = bc._getUint32(strOffset);
    Uint8List bytes = bc._asUint8LIst(strOffset + 4, length);
    if (_isLatin(bytes)) {
      return String.fromCharCodes(bytes);
    }
    return utf8.decode(bytes);
  }

  static bool _isLatin(Uint8List bytes) {
    int length = bytes.length;
    for (int i = 0; i < length; i++) {
      if (bytes[i] > 127) {
        return false;
      }
    }
    return true;
  }
}

/// An abstract reader for tables.
abstract class TableReader<T> extends Reader<T> {
  const TableReader();

  @override
  int get size => 4;

  /// Return the object at [offset].
  T createObject(BufferContext bc, int offset);

  @override
  T read(BufferContext bc, int offset) {
    int objectOffset = bc.derefObject(offset);
    return createObject(bc, objectOffset);
  }
}

/// Reader of lists of unsigned 32-bit integer values.
///
/// The returned unmodifiable lists lazily read values on access.
class Uint32ListReader extends Reader<List<int>> {
  const Uint32ListReader();

  @override
  int get size => 4;

  @override
  List<int> read(BufferContext bc, int offset) =>
      _FbUint32List(bc, bc.derefObject(offset));
}

/// The reader of unsigned 32-bit integers.
class Uint32Reader extends Reader<int> {
  const Uint32Reader() : super();

  @override
  int get size => 4;

  @override
  int read(BufferContext bc, int offset) => bc._getUint32(offset);
}

/// Reader of lists of unsigned 8-bit integer values.
///
/// The returned unmodifiable lists lazily read values on access.
class Uint8ListReader extends Reader<List<int>> {
  const Uint8ListReader();

  @override
  int get size => 4;

  @override
  List<int> read(BufferContext bc, int offset) =>
      _FbUint8List(bc, bc.derefObject(offset));
}

/// The reader of unsigned 8-bit integers.
class Uint8Reader extends Reader<int> {
  const Uint8Reader() : super();

  @override
  int get size => 1;

  @override
  int read(BufferContext bc, int offset) => bc._getUint8(offset);
}

/// List of booleans backed by 8-bit unsigned integers.
class _FbBoolList with ListMixin<bool> implements List<bool> {
  final BufferContext bc;
  final int offset;
  int? _length;

  _FbBoolList(this.bc, this.offset);

  @override
  int get length {
    if (_length == null) {
      int byteLength = bc._getUint32(offset);
      _length = (byteLength - 1) * 8 - _getByte(byteLength - 1);
    }
    return _length!;
  }

  @override
  set length(int i) => throw StateError('Attempt to modify immutable list');

  @override
  bool operator [](int i) {
    int index = i ~/ 8;
    int mask = 1 << i % 8;
    return _getByte(index) & mask != 0;
  }

  @override
  void operator []=(int i, bool e) =>
      throw StateError('Attempt to modify immutable list');

  int _getByte(int index) => bc._getUint8(offset + 4 + index);
}

/// The list backed by 64-bit values - Uint64 length and Float64.
class _FbFloat64List extends _FbList<double> {
  _FbFloat64List(super.bc, super.offset);

  @override
  double operator [](int i) {
    return bc._getFloat64(offset + 8 + 8 * i);
  }
}

/// List backed by a generic object which may have any size.
class _FbGenericList<E> extends _FbList<E> {
  final Reader<E> elementReader;

  List<E?>? _items;

  _FbGenericList(this.elementReader, BufferContext bp, int offset)
      : super(bp, offset);

  @override
  E operator [](int i) {
    _items ??= List<E?>.filled(length, null);
    E? item = _items![i];
    if (item == null) {
      item = elementReader.read(bc, offset + 4 + elementReader.size * i);
      _items![i] = item;
    }
    return item!;
  }
}

/// The base class for immutable lists read from flat buffers.
abstract class _FbList<E> with ListMixin<E> implements List<E> {
  final BufferContext bc;
  final int offset;
  int? _length;

  _FbList(this.bc, this.offset);

  @override
  int get length {
    return _length ??= bc._getUint32(offset);
  }

  @override
  set length(int i) => throw StateError('Attempt to modify immutable list');

  @override
  void operator []=(int i, E e) =>
      throw StateError('Attempt to modify immutable list');
}

/// List backed by 32-bit unsigned integers.
class _FbUint32List extends _FbList<int> {
  _FbUint32List(super.bc, super.offset);

  @override
  int operator [](int i) {
    return bc._getUint32(offset + 4 + 4 * i);
  }
}

/// List backed by 8-bit unsigned integers.
class _FbUint8List extends _FbList<int> {
  _FbUint8List(super.bc, super.offset);

  @override
  int operator [](int i) {
    return bc._getUint8(offset + 4 + i);
  }
}

/// Class that describes the structure of a table.
class _VTable {
  final Int32List _reusedFieldTails;
  final Int32List _reusedFieldOffsets;

  /// The number of fields in [_reusedFieldTails].
  int _fieldCount = 0;

  /// The private copy of [_reusedFieldOffsets], which is made only when we
  /// find that this table is unique.
  Int32List? _fieldOffsets;

  /// The size of the table that uses this VTable.
  int? tableSize;

  /// The tail of this VTable.  It is used to share the same VTable between
  /// multiple tables of identical structure.
  int? tail;

  _VTable(this._reusedFieldTails, this._reusedFieldOffsets);

  int get numOfUint16 => 1 + 1 + _fieldCount;

  void addField(int field, int offset) {
    while (_fieldCount <= field) {
      _reusedFieldTails[_fieldCount++] = -1;
    }
    _reusedFieldTails[field] = offset;
  }

  /// Return `true` if the [existing] VTable can be used instead of this.
  bool canUseExistingVTable(_VTable existing) {
    assert(tail == null);
    assert(existing.tail != null);
    if (tableSize == existing.tableSize &&
        _fieldCount == existing._fieldCount) {
      for (int i = 0; i < _fieldCount; i++) {
        if (_reusedFieldOffsets[i] != existing._fieldOffsets![i]) {
          return false;
        }
      }
      return true;
    }
    return false;
  }

  /// Fill the [_reusedFieldOffsets] field.
  void computeFieldOffsets(int tableTail) {
    for (int i = 0; i < _fieldCount; ++i) {
      int fieldTail = _reusedFieldTails[i];
      _reusedFieldOffsets[i] = fieldTail == -1 ? 0 : tableTail - fieldTail;
    }
  }

  /// Outputs this VTable to [buf], which is is expected to be aligned to 16-bit
  /// and have at least [numOfUint16] 16-bit words available.
  void output(ByteData buf, int bufOffset) {
    // VTable size.
    buf.setUint16(bufOffset, numOfUint16 * 2, Endian.little);
    bufOffset += 2;
    // Table size.
    buf.setUint16(bufOffset, tableSize!, Endian.little);
    bufOffset += 2;
    // Field offsets.
    for (int fieldOffset in _fieldOffsets!) {
      buf.setUint16(bufOffset, fieldOffset, Endian.little);
      bufOffset += 2;
    }
  }

  /// Fill the [_fieldOffsets] field.
  void takeFieldOffsets() {
    assert(_fieldOffsets == null);
    _fieldOffsets = Int32List(_fieldCount);
    for (int i = 0; i < _fieldCount; ++i) {
      _fieldOffsets![i] = _reusedFieldOffsets[i];
    }
  }
}
