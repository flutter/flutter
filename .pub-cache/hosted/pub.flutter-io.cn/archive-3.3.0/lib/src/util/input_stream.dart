import 'dart:convert';
import 'dart:typed_data';
import 'byte_order.dart';

abstract class InputStreamBase {
  ///  The current read position relative to the start of the buffer.
  int get position;

  set position(int v);

  /// How many bytes are left in the stream.
  int get length;

  /// Is the current position at the end of the stream?
  bool get isEOS;

  /// Asynchronously closes the input stream.
  Future<void> close() async {}

  /// Reset to the beginning of the stream.
  void reset();

  /// Rewind the read head of the stream by the given number of bytes.
  void rewind([int length = 1]);

  /// Move the read position by [count] bytes.
  void skip(int length);

  /// Read [count] bytes from an [offset] of the current read position, without
  /// moving the read position.
  InputStreamBase peekBytes(int count, [int offset = 0]);

  /// Read a single byte.
  int readByte();

  /// Read [count] bytes from the stream.
  InputStreamBase readBytes(int count);

  InputStreamBase subset([int? position, int? length]);

  /// Read a null-terminated string, or if [len] is provided, that number of
  /// bytes returned as a string.
  String readString({int? size, bool utf8 = true});

  /// Read a 16-bit word from the stream.
  int readUint16();

  /// Read a 24-bit word from the stream.
  int readUint24();

  /// Read a 32-bit word from the stream.
  int readUint32();

  /// Read a 64-bit word form the stream.
  int readUint64();

  Uint8List toUint8List();
}

/// A buffer that can be read as a stream of bytes
class InputStream extends InputStreamBase {
  List<int> buffer;
  int offset;
  int start;
  int byteOrder;

  /// Create a InputStream for reading from a List<int>
  InputStream(dynamic data,
      {this.byteOrder = LITTLE_ENDIAN, this.start = 0, int? length})
      : buffer = data is TypedData
            ? Uint8List.view(
                data.buffer, data.offsetInBytes, data.lengthInBytes)
            : data is List<int>
                ? data
                : List<int>.from(data as Iterable<dynamic>),
        offset = start {
    _length = length ?? buffer.length;
  }

  /// Create a copy of [other].
  InputStream.from(InputStream other)
      : buffer = other.buffer,
        offset = other.offset,
        start = other.start,
        _length = other._length,
        byteOrder = other.byteOrder;

  ///  The current read position relative to the start of the buffer.
  @override
  int get position => offset - start;

  @override
  set position(int v) { offset = start + v; }

  /// How many bytes are left in the stream.
  @override
  int get length => _length - (offset - start);

  /// Is the current position at the end of the stream?
  @override
  bool get isEOS => offset >= (start + _length);

  /// Reset to the beginning of the stream.
  @override
  void reset() {
    offset = start;
  }

  @override
  Future<void> close() async {
    buffer = <int>[];
    _length = 0;
  }

  /// Rewind the read head of the stream by the given number of bytes.
  @override
  void rewind([int length = 1]) {
    offset -= length;
    if (offset < 0) {
      offset = 0;
    }
  }

  /// Access the buffer relative from the current position.
  int operator [](int index) => buffer[offset + index];

  /// Return a InputStream to read a subset of this stream.  It does not
  /// move the read position of this stream.  [position] is specified relative
  /// to the start of the buffer.  If [position] is not specified, the current
  /// read position is used. If [length] is not specified, the remainder of this
  /// stream is used.
  @override
  InputStreamBase subset([int? position, int? length]) {
    if (position == null) {
      position = offset;
    } else {
      position += start;
    }

    if (length == null || length < 0) {
      length = _length - (position - start);
    }

    return InputStream(buffer,
        byteOrder: byteOrder, start: position, length: length);
  }

  /// Returns the position of the given [value] within the buffer, starting
  /// from the current read position with the given [offset].  The position
  /// returned is relative to the start of the buffer, or -1 if the [value]
  /// was not found.
  int indexOf(int value, [int offset = 0]) {
    for (var i = this.offset + offset, end = this.offset + length;
        i < end;
        ++i) {
      if (buffer[i] == value) {
        return i - start;
      }
    }
    return -1;
  }

  /// Read [count] bytes from an [offset] of the current read position, without
  /// moving the read position.
  @override
  InputStreamBase peekBytes(int count, [int offset = 0]) {
    return subset((this.offset - start) + offset, count);
  }

  /// Move the read position by [count] bytes.
  @override
  void skip(int count) {
    offset += count;
  }

  /// Read a single byte.
  @override
  int readByte() {
    return buffer[offset++];
  }

  /// Read [count] bytes from the stream.
  @override
  InputStreamBase readBytes(int count) {
    final bytes = subset(offset - start, count);
    offset += bytes.length;
    return bytes as InputStream;
  }

  /// Read a null-terminated string, or if [len] is provided, that number of
  /// bytes returned as a string.
  @override
  String readString({int? size, bool utf8 = true}) {
    if (size == null) {
      final codes = <int>[];
      if (isEOS) {
        return '';
      }
      while (!isEOS) {
        final c = readByte();
        if (c == 0) {
          break;
        }
        codes.add(c);
      }
      return utf8
          ? Utf8Decoder().convert(codes)
          : String.fromCharCodes(codes);
    }

    final s = readBytes(size);
    final bytes = s.toUint8List();
    try {
      final str =
        utf8 ? Utf8Decoder().convert(bytes) : String.fromCharCodes(bytes);
      return str;
    } catch (err) {
      // If the string is not a valid UTF8 string, decode it as character codes.
      return String.fromCharCodes(bytes);
    }

  }

  /// Read a 16-bit word from the stream.
  @override
  int readUint16() {
    final b1 = buffer[offset++] & 0xff;
    final b2 = buffer[offset++] & 0xff;
    if (byteOrder == BIG_ENDIAN) {
      return (b1 << 8) | b2;
    }
    return (b2 << 8) | b1;
  }

  /// Read a 24-bit word from the stream.
  @override
  int readUint24() {
    final b1 = buffer[offset++] & 0xff;
    final b2 = buffer[offset++] & 0xff;
    final b3 = buffer[offset++] & 0xff;
    if (byteOrder == BIG_ENDIAN) {
      return b3 | (b2 << 8) | (b1 << 16);
    }
    return b1 | (b2 << 8) | (b3 << 16);
  }

  /// Read a 32-bit word from the stream.
  @override
  int readUint32() {
    final b1 = buffer[offset++] & 0xff;
    final b2 = buffer[offset++] & 0xff;
    final b3 = buffer[offset++] & 0xff;
    final b4 = buffer[offset++] & 0xff;
    if (byteOrder == BIG_ENDIAN) {
      return (b1 << 24) | (b2 << 16) | (b3 << 8) | b4;
    }
    return (b4 << 24) | (b3 << 16) | (b2 << 8) | b1;
  }

  /// Read a 64-bit word form the stream.
  @override
  int readUint64() {
    final b1 = buffer[offset++] & 0xff;
    final b2 = buffer[offset++] & 0xff;
    final b3 = buffer[offset++] & 0xff;
    final b4 = buffer[offset++] & 0xff;
    final b5 = buffer[offset++] & 0xff;
    final b6 = buffer[offset++] & 0xff;
    final b7 = buffer[offset++] & 0xff;
    final b8 = buffer[offset++] & 0xff;
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
  Uint8List toUint8List() {
    var len = length;
    if (buffer is Uint8List) {
      final b = buffer as Uint8List;
      if ((offset + len) > b.length) {
        len = b.length - offset;
      }
      final bytes = Uint8List.view(b.buffer, b.offsetInBytes + offset, len);
      return bytes;
    }
    var end = offset + len;
    if (end > buffer.length) {
      end = buffer.length;
    }
    return Uint8List.fromList(buffer.sublist(offset, end));
  }

  late int _length;
}
