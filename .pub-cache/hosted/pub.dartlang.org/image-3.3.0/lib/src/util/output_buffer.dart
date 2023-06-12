import 'dart:typed_data';

import 'input_buffer.dart';

class OutputBuffer {
  int length;
  bool bigEndian;

  /// Create a byte buffer for writing.
  OutputBuffer({int? size = _BLOCK_SIZE, this.bigEndian = false})
      : _buffer = Uint8List(size ?? _BLOCK_SIZE),
        length = 0;

  void rewind() {
    length = 0;
  }

  /// Get the resulting bytes from the buffer.
  List<int> getBytes() => Uint8List.view(_buffer.buffer, 0, length);

  /// Clear the buffer.
  void clear() {
    _buffer = Uint8List(_BLOCK_SIZE);
    length = 0;
  }

  /// Write a byte to the end of the buffer.
  void writeByte(int value) {
    if (length == _buffer.length) {
      _expandBuffer();
    }
    _buffer[length++] = value & 0xff;
  }

  /// Write a set of bytes to the end of the buffer.
  void writeBytes(List<int> bytes, [int? len]) {
    len ??= bytes.length;
    while (length + len > _buffer.length) {
      _expandBuffer((length + len) - _buffer.length);
    }
    _buffer.setRange(length, length + len, bytes);
    length += len;
  }

  void writeBuffer(InputBuffer bytes) {
    while (length + bytes.length > _buffer.length) {
      _expandBuffer((length + bytes.length) - _buffer.length);
    }
    _buffer.setRange(length, length + bytes.length, bytes.buffer, bytes.offset);
    length += bytes.length;
  }

  /// Write a 16-bit word to the end of the buffer.
  void writeUint16(int value) {
    if (bigEndian) {
      writeByte((value >> 8) & 0xff);
      writeByte(value & 0xff);
      return;
    }
    writeByte(value & 0xff);
    writeByte((value >> 8) & 0xff);
  }

  /// Write a 32-bit word to the end of the buffer.
  void writeUint32(int value) {
    if (bigEndian) {
      writeByte((value >> 24) & 0xff);
      writeByte((value >> 16) & 0xff);
      writeByte((value >> 8) & 0xff);
      writeByte((value) & 0xff);
      return;
    }
    writeByte((value) & 0xff);
    writeByte((value >> 8) & 0xff);
    writeByte((value >> 16) & 0xff);
    writeByte((value >> 24) & 0xff);
  }

  void writeFloat32(double value) {
    final fb = Float32List(1);
    fb[0] = value;
    final b = Uint8List.view(fb.buffer);
    if (bigEndian) {
      writeByte(b[3]);
      writeByte(b[2]);
      writeByte(b[1]);
      writeByte(b[0]);
      return;
    }
    writeByte(b[0]);
    writeByte(b[1]);
    writeByte(b[2]);
    writeByte(b[3]);
  }

  void writeFloat64(double value) {
    final fb = Float64List(1);
    fb[0] = value;
    final b = Uint8List.view(fb.buffer);
    if (bigEndian) {
      writeByte(b[7]);
      writeByte(b[6]);
      writeByte(b[5]);
      writeByte(b[4]);
      writeByte(b[3]);
      writeByte(b[2]);
      writeByte(b[1]);
      writeByte(b[0]);
      return;
    }
    writeByte(b[0]);
    writeByte(b[1]);
    writeByte(b[2]);
    writeByte(b[3]);
    writeByte(b[4]);
    writeByte(b[5]);
    writeByte(b[6]);
    writeByte(b[7]);
  }

  /// Return the subset of the buffer in the range [start:end].
  /// If [start] or [end] are < 0 then it is relative to the end of the buffer.
  /// If [end] is not specified (or null), then it is the end of the buffer.
  /// This is equivalent to the python list range operator.
  List<int> subset(int start, [int? end]) {
    if (start < 0) {
      start = (length) + start;
    }

    if (end == null) {
      end = length;
    } else if (end < 0) {
      end = length + end;
    }

    return Uint8List.view(_buffer.buffer, start, end - start);
  }

  /// Grow the buffer to accommodate additional data.
  void _expandBuffer([int? required]) {
    final blockSize = (required != null)
        ? required
        : (_buffer.isEmpty)
            ? _BLOCK_SIZE
            : (_buffer.length * 2);
    final newBuffer = Uint8List(_buffer.length + blockSize);
    newBuffer.setRange(0, _buffer.length, _buffer);
    _buffer = newBuffer;
  }

  static const _BLOCK_SIZE = 0x2000; // 8k block-size
  Uint8List _buffer;
}
