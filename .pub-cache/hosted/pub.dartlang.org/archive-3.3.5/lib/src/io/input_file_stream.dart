import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import '../util/archive_exception.dart';
import '../util/byte_order.dart';
import '../util/input_stream.dart';

class FileHandle {
  final String _path;
  RandomAccessFile? _file;
  int _position;
  late int _length;

  FileHandle(this._path)
  : _file = File(_path).openSync()
  , _position = 0 {
    _length = _file!.lengthSync();
  }

  String get path => _path;

  int get position => _position;

  set position(int p) {
    if (_file == null || p == _position) {
      return;
    }
    _position = p;
    _file!.setPositionSync(p);
  }

  int get length => _length;

  bool get isOpen => _file != null;

  Future<void> close() async {
    if (_file == null) {
      return;
    }
    var fp = _file;
    _file = null;
    _position = 0;
    await fp!.close();
  }

  void open() {
    if (_file != null) {
      return;
    }

    _file = File(_path).openSync();
    _position = 0;
  }

  int readInto(Uint8List buffer, [int? end]) {
    if (_file == null) {
      open();
    }
    final size = _file!.readIntoSync(buffer, 0, end);
    _position += size;
    return size;
  }
}

class InputFileStream extends InputStreamBase {
  final String path;
  final FileHandle _file;
  final int byteOrder;
  int _fileOffset = 0;
  int _fileSize = 0;
  late Uint8List _buffer;
  int _position = 0;
  int _bufferSize = 0;
  int _bufferPosition = 0;

  static const int kDefaultBufferSize = 4096;

  InputFileStream(this.path,
      {this.byteOrder = LITTLE_ENDIAN, int bufferSize = kDefaultBufferSize})
      : _file = FileHandle(path) {
    _fileSize = _file.length;
    // Don't have a buffer bigger than the file itself.
    // Also, make sure it's at least 8 bytes, so reading a 64-bit value doesn't
    // have to deal with buffer overflow.
    bufferSize = max(min(bufferSize, _fileSize), 8);
    _buffer = Uint8List(min(bufferSize, 8));
    _readBuffer();
  }

  InputFileStream.clone(InputFileStream other, {int? position, int? length})
    : path = other.path
    , _file = other._file
    , byteOrder = other.byteOrder
    , _fileOffset = other._fileOffset + (position ?? 0)
    , _fileSize = length ?? other._fileSize
    , _buffer = Uint8List(kDefaultBufferSize) {
    _readBuffer();
  }

  @override
  Future<void> close() async {
    await _file.close();
    _fileSize = 0;
    _position = 0;
  }

  @override
  int get length => _fileSize;

  @override
  int get position => _position;

  @override
  set position(int v) {
    if (v < _position) {
      rewind(_position - v);
    } else if (v > _position) {
      skip(v - _position);
    }
  }

  @override
  bool get isEOS => _position >= _fileSize;

  int get bufferSize => _bufferSize;

  int get bufferPosition => _bufferPosition;

  int get bufferRemaining => _bufferSize - _bufferPosition;

  int get fileRemaining => _fileSize - _position;

  @override
  void reset() {
    _position = 0;
    _readBuffer();
  }

  @override
  void skip(int length) {
    if ((_bufferPosition + length) < _bufferSize) {
      _bufferPosition += length;
      _position += length;
    } else {
      _position += length;
      _readBuffer();
    }
  }

  @override
  InputStreamBase subset([int? position, int? length]) {
    return InputFileStream.clone(this, position:position, length:length);
  }

  /// Read [count] bytes from an [offset] of the current read position, without
  /// moving the read position.
  @override
  InputStreamBase peekBytes(int count, [int offset = 0]) {
    return subset(_position + offset, count);
  }

  @override
  void rewind([int length = 1]) {
    if ((_bufferPosition - length) < 0) {
      _position = max(_position - length, 0);
      _readBuffer();
      return;
    }
    _bufferPosition -= length;
    _position -= length;
  }

  @override
  int readByte() {
    if (isEOS) {
      return 0;
    }
    if (_bufferPosition >= _bufferSize) {
      _readBuffer();
    }
    if (_bufferPosition >= _bufferSize) {
      return 0;
    }
    _position++;
    return _buffer[_bufferPosition++] & 0xff;
  }

  /// Read a 16-bit word from the stream.
  @override
  int readUint16() {
    var b1 = 0;
    var b2 = 0;
    if ((_bufferPosition + 2) < _bufferSize) {
      b1 = _buffer[_bufferPosition++] & 0xff;
      b2 = _buffer[_bufferPosition++] & 0xff;
      _position += 2;
    } else {
      b1 = readByte();
      b2 = readByte();
    }
    if (byteOrder == BIG_ENDIAN) {
      return (b1 << 8) | b2;
    }
    return (b2 << 8) | b1;
  }

  /// Read a 24-bit word from the stream.
  @override
  int readUint24() {
    var b1 = 0;
    var b2 = 0;
    var b3 = 0;
    if ((_bufferPosition + 3) < _bufferSize) {
      b1 = _buffer[_bufferPosition++] & 0xff;
      b2 = _buffer[_bufferPosition++] & 0xff;
      b3 = _buffer[_bufferPosition++] & 0xff;
      _position += 3;
    } else {
      b1 = readByte();
      b2 = readByte();
      b3 = readByte();
    }

    if (byteOrder == BIG_ENDIAN) {
      return b3 | (b2 << 8) | (b1 << 16);
    }
    return b1 | (b2 << 8) | (b3 << 16);
  }

  /// Read a 32-bit word from the stream.
  @override
  int readUint32() {
    var b1 = 0;
    var b2 = 0;
    var b3 = 0;
    var b4 = 0;
    if ((_bufferPosition + 4) < _bufferSize) {
      b1 = _buffer[_bufferPosition++] & 0xff;
      b2 = _buffer[_bufferPosition++] & 0xff;
      b3 = _buffer[_bufferPosition++] & 0xff;
      b4 = _buffer[_bufferPosition++] & 0xff;
      _position += 4;
    } else {
      b1 = readByte();
      b2 = readByte();
      b3 = readByte();
      b4 = readByte();
    }

    if (byteOrder == BIG_ENDIAN) {
      return (b1 << 24) | (b2 << 16) | (b3 << 8) | b4;
    }
    return (b4 << 24) | (b3 << 16) | (b2 << 8) | b1;
  }

  /// Read a 64-bit word form the stream.
  @override
  int readUint64() {
    var b1 = 0;
    var b2 = 0;
    var b3 = 0;
    var b4 = 0;
    var b5 = 0;
    var b6 = 0;
    var b7 = 0;
    var b8 = 0;
    if ((_bufferPosition + 8) < _bufferSize) {
      b1 = _buffer[_bufferPosition++] & 0xff;
      b2 = _buffer[_bufferPosition++] & 0xff;
      b3 = _buffer[_bufferPosition++] & 0xff;
      b4 = _buffer[_bufferPosition++] & 0xff;
      b5 = _buffer[_bufferPosition++] & 0xff;
      b6 = _buffer[_bufferPosition++] & 0xff;
      b7 = _buffer[_bufferPosition++] & 0xff;
      b8 = _buffer[_bufferPosition++] & 0xff;
      _position += 8;
    } else {
      b1 = readByte();
      b2 = readByte();
      b3 = readByte();
      b4 = readByte();
      b5 = readByte();
      b6 = readByte();
      b7 = readByte();
      b8 = readByte();
    }

    if (byteOrder == BIG_ENDIAN) {
      return (b1 << 56) |
          (b2 << 48) |
          (b3 << 40) |
          (b4 << 32) |
          (b5 << 24) |
          (b6 << 16) |
          (b7 << 8) |
          b8;
    }
    return (b8 << 56) |
        (b7 << 48) |
        (b6 << 40) |
        (b5 << 32) |
        (b4 << 24) |
        (b3 << 16) |
        (b2 << 8) |
        b1;
  }

  @override
  InputStreamBase readBytes(int count) {
    count = min(count, fileRemaining);
    final bytes = InputFileStream.clone(this, position: _position,
        length: count);
    skip(count);
    return bytes;
  }

  @override
  Uint8List toUint8List() {
    if (isEOS) {
      return Uint8List(0);
    }
    var length = fileRemaining;
    final bytes = Uint8List(length);
    _file.position = _fileOffset + _position;
    final readBytes = _file.readInto(bytes);
    skip(length);
    if (readBytes != bytes.length) {
      bytes.length = readBytes;
    }
    return bytes;
  }

  /// Read a null-terminated string, or if [len] is provided, that number of
  /// bytes returned as a string.
  @override
  String readString({int? size, bool utf8 = true}) {
    if (size == null) {
      final codes = <int>[];
      while (!isEOS) {
        var c = readByte();
        if (c == 0) {
          return utf8
              ? Utf8Decoder().convert(codes)
              : String.fromCharCodes(codes);
        }
        codes.add(c);
      }
      throw ArchiveException('EOF reached without finding string terminator');
    }

    final s = readBytes(size);
    final bytes = s.toUint8List();
    final str = utf8
        ? Utf8Decoder().convert(bytes)
        : String.fromCharCodes(bytes);
    return str;
  }

  void _readBuffer() {
    _bufferPosition = 0;
    _file.position = _fileOffset + _position;
    _bufferSize = _file.readInto(_buffer, _buffer.length);
  }
}
