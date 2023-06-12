import 'dart:convert';
import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/crypto/crc32.dart';
import 'package:hive/src/object/hive_list_impl.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:hive/src/util/extensions.dart';
import 'package:meta/meta.dart';

/// Not part of public API
class BinaryWriterImpl extends BinaryWriter {
  static const _initBufferSize = 4096;

  final TypeRegistryImpl _typeRegistry;
  Uint8List _buffer = Uint8List(_initBufferSize);

  ByteData? _byteDataInstance;

  int _offset = 0;

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  ByteData get _byteData {
    _byteDataInstance ??= ByteData.view(_buffer.buffer);
    return _byteDataInstance!;
  }

  /// Not part of public API
  BinaryWriterImpl(TypeRegistry typeRegistry)
      : _typeRegistry = typeRegistry as TypeRegistryImpl;

  /// Not part of public API
  @visibleForTesting
  BinaryWriterImpl.withBuffer(this._buffer, this._typeRegistry);

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void _reserveBytes(int count) {
    if (_buffer.length - _offset < count) {
      _increaseBufferSize(count);
    }
  }

  void _increaseBufferSize(int count) {
// We will create a list in the range of 2-4 times larger than required.
    var newSize = _pow2roundup((_offset + count) * 2);
    var newBuffer = Uint8List(newSize);
    newBuffer.setRange(0, _offset, _buffer);
    _buffer = newBuffer;
    _byteDataInstance = null;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void _addBytes(List<int> bytes) {
    ArgumentError.checkNotNull(bytes);

    var length = bytes.length;
    _reserveBytes(length);
    _buffer.setRange(_offset, _offset + length, bytes);
    _offset += length;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeByte(int byte) {
    ArgumentError.checkNotNull(byte);

    _reserveBytes(1);
    _buffer[_offset++] = byte;
  }

  @override
  void writeWord(int value) {
    ArgumentError.checkNotNull(value);

    _reserveBytes(2);
    _buffer[_offset++] = value;
    _buffer[_offset++] = value >> 8;
  }

  @override
  void writeInt32(int value) {
    ArgumentError.checkNotNull(value);

    _reserveBytes(4);
    _byteData.setInt32(_offset, value, Endian.little);
    _offset += 4;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeUint32(int value) {
    ArgumentError.checkNotNull(value);

    _reserveBytes(4);
    _buffer.writeUint32(_offset, value);
    _offset += 4;
  }

  @override
  void writeInt(int value) {
    writeDouble(value.toDouble());
  }

  @override
  void writeDouble(double value) {
    ArgumentError.checkNotNull(value);

    _reserveBytes(8);
    _byteData.setFloat64(_offset, value, Endian.little);
    _offset += 8;
  }

  @override
  void writeBool(bool value) {
    ArgumentError.checkNotNull(value);

    writeByte(value ? 1 : 0);
  }

  @override
  void writeString(
    String value, {
    bool writeByteCount = true,
    Converter<String, List<int>> encoder = BinaryWriter.utf8Encoder,
  }) {
    ArgumentError.checkNotNull(value);

    var bytes = encoder.convert(value);
    if (writeByteCount) {
      writeUint32(bytes.length);
    }
    _addBytes(bytes);
  }

  @override
  void writeByteList(List<int> bytes, {bool writeLength = true}) {
    ArgumentError.checkNotNull(bytes);

    if (writeLength) {
      writeUint32(bytes.length);
    }
    _addBytes(bytes);
  }

  @override
  void writeIntList(List<int> list, {bool writeLength = true}) {
    ArgumentError.checkNotNull(list);

    var length = list.length;
    if (writeLength) {
      writeUint32(length);
    }
    _reserveBytes(length * 8);
    var byteData = _byteData;
    for (var i = 0; i < length; i++) {
      byteData.setFloat64(_offset, list[i].toDouble(), Endian.little);
      _offset += 8;
    }
  }

  @override
  void writeDoubleList(List<double> list, {bool writeLength = true}) {
    ArgumentError.checkNotNull(list);

    var length = list.length;
    if (writeLength) {
      writeUint32(length);
    }
    _reserveBytes(length * 8);
    var byteData = _byteData;
    for (var i = 0; i < length; i++) {
      byteData.setFloat64(_offset, list[i], Endian.little);
      _offset += 8;
    }
  }

  @override
  void writeBoolList(List<bool> list, {bool writeLength = true}) {
    ArgumentError.checkNotNull(list);

    var length = list.length;
    if (writeLength) {
      writeUint32(length);
    }
    _reserveBytes(length);
    for (var i = 0; i < length; i++) {
      _buffer[_offset++] = list[i] ? 1 : 0;
    }
  }

  @override
  void writeStringList(
    List<String> list, {
    bool writeLength = true,
    Converter<String, List<int>> encoder = BinaryWriter.utf8Encoder,
  }) {
    ArgumentError.checkNotNull(list);

    if (writeLength) {
      writeUint32(list.length);
    }
    for (var str in list) {
      var strBytes = encoder.convert(str);
      writeUint32(strBytes.length);
      _addBytes(strBytes);
    }
  }

  @override
  void writeList(List list, {bool writeLength = true}) {
    ArgumentError.checkNotNull(list);

    if (writeLength) {
      writeUint32(list.length);
    }
    for (var i = 0; i < list.length; i++) {
      write(list[i]);
    }
  }

  @override
  void writeMap(Map<dynamic, dynamic> map, {bool writeLength = true}) {
    ArgumentError.checkNotNull(map);

    if (writeLength) {
      writeUint32(map.length);
    }
    for (var key in map.keys) {
      write(key);
      write(map[key]);
    }
  }

  /// Not part of public API
  void writeKey(dynamic key) {
    ArgumentError.checkNotNull(key);

    if (key is String) {
      writeByte(FrameKeyType.utf8StringT);
      var bytes = BinaryWriter.utf8Encoder.convert(key);
      writeByte(bytes.length);
      _addBytes(bytes);
    } else {
      writeByte(FrameKeyType.uintT);
      writeUint32(key as int);
    }
  }

  @override
  void writeHiveList(HiveList list, {bool writeLength = true}) {
    ArgumentError.checkNotNull(list);

    if (writeLength) {
      writeUint32(list.length);
    }
    var boxName = (list as HiveListImpl).boxName;
    writeByte(boxName.length);
    _addBytes(boxName.codeUnits);
    for (var obj in list) {
      writeKey(obj.key);
    }
  }

  /// Not part of public API
  int writeFrame(Frame frame, {HiveCipher? cipher}) {
    ArgumentError.checkNotNull(frame);

    var startOffset = _offset;
    _reserveBytes(4);
    _offset += 4; // reserve bytes for length

    writeKey(frame.key);

    if (!frame.deleted) {
      if (cipher == null) {
        write(frame.value);
      } else {
        writeEncrypted(frame.value, cipher);
      }
    }

    var frameLength = _offset - startOffset + 4;
    _buffer.writeUint32(startOffset, frameLength);

    var crc = Crc32.compute(
      _buffer,
      offset: startOffset,
      length: frameLength - 4,
      crc: cipher?.calculateKeyCrc() ?? 0,
    );
    writeUint32(crc);

    return frameLength;
  }

  @override
  void write<T>(T value, {bool writeTypeId = true}) {
    if (value == null) {
      if (writeTypeId) {
        writeByte(FrameValueType.nullT);
      }
    } else if (value is int) {
      if (writeTypeId) {
        writeByte(FrameValueType.intT);
      }
      writeInt(value);
    } else if (value is double) {
      if (writeTypeId) {
        writeByte(FrameValueType.doubleT);
      }
      writeDouble(value);
    } else if (value is bool) {
      if (writeTypeId) {
        writeByte(FrameValueType.boolT);
      }
      writeBool(value);
    } else if (value is String) {
      if (writeTypeId) {
        writeByte(FrameValueType.stringT);
      }
      writeString(value);
    } else if (value is List) {
      _writeList(value, writeTypeId: writeTypeId);
    } else if (value is Map) {
      if (writeTypeId) {
        writeByte(FrameValueType.mapT);
      }
      writeMap(value);
    } else {
      var resolved = _typeRegistry.findAdapterForValue(value);
      if (resolved == null) {
        throw HiveError('Cannot write, unknown type: ${value.runtimeType}. '
            'Did you forget to register an adapter?');
      }
      if (writeTypeId) {
        writeByte(resolved.typeId);
      }
      resolved.adapter.write(this, value);
    }
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void _writeList(List value, {bool writeTypeId = true}) {
    if (value is HiveList) {
      if (writeTypeId) {
        writeByte(FrameValueType.hiveListT);
      }
      writeHiveList(value);
    } else if (value.contains(null)) {
      if (writeTypeId) {
        writeByte(FrameValueType.listT);
      }
      writeList(value);
    } else if (value is Uint8List) {
      if (writeTypeId) {
        writeByte(FrameValueType.byteListT);
      }
      writeByteList(value);
    } else if (value is List<int>) {
      if (writeTypeId) {
        writeByte(FrameValueType.intListT);
      }
      writeIntList(value);
    } else if (value is List<double>) {
      if (writeTypeId) {
        writeByte(FrameValueType.doubleListT);
      }
      writeDoubleList(value);
    } else if (value is List<bool>) {
      if (writeTypeId) {
        writeByte(FrameValueType.boolListT);
      }
      writeBoolList(value);
    } else if (value is List<String>) {
      if (writeTypeId) {
        writeByte(FrameValueType.stringListT);
      }
      writeStringList(value);
    } else {
      if (writeTypeId) {
        writeByte(FrameValueType.listT);
      }
      writeList(value);
    }
  }

  /// Not part of public API
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeEncrypted(dynamic value, HiveCipher cipher,
      {bool writeTypeId = true}) {
    var valueWriter = BinaryWriterImpl(_typeRegistry)
      ..write(value, writeTypeId: writeTypeId);
    var inp = valueWriter._buffer;
    var inpLength = valueWriter._offset;

    _reserveBytes(cipher.maxEncryptedSize(inp));

    var len = cipher.encrypt(inp, 0, inpLength, _buffer, _offset);

    _offset += len;
  }

  /// Not part of public API
  Uint8List toBytes() {
    return Uint8List.view(_buffer.buffer, 0, _offset);
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  static int _pow2roundup(int x) {
    assert(x > 0);
    --x;
    x |= x >> 1;
    x |= x >> 2;
    x |= x >> 4;
    x |= x >> 8;
    x |= x >> 16;
    return x + 1;
  }
}
