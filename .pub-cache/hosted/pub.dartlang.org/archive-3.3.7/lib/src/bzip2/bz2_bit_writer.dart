import '../util/output_stream.dart';

class Bz2BitWriter {
  OutputStream output;

  Bz2BitWriter(this.output);

  void writeByte(int byte) => writeBits(8, byte);

  void writeBytes(List<int> bytes) {
    for (var i = 0; i < bytes.length; ++i) {
      writeBits(8, bytes[i]);
    }
  }

  void writeUint16(int value) {
    writeBits(16, value);
  }

  void writeUint24(int value) {
    writeBits(24, value);
  }

  void writeUint32(int value) {
    writeBits(32, value);
  }

  void writeBits(int numBits, int value) {
    // TODO optimize
    if (_bitPos == 8 && numBits == 8) {
      output.writeByte(value & 0xff);
      return;
    }

    if (_bitPos == 8 && numBits == 16) {
      output.writeByte((value >> 8) & 0xff);
      output.writeByte(value & 0xff);
      return;
    }

    if (_bitPos == 8 && numBits == 24) {
      output.writeByte((value >> 16) & 0xff);
      output.writeByte((value >> 8) & 0xff);
      output.writeByte(value & 0xff);
      return;
    }

    if (_bitPos == 8 && numBits == 32) {
      output.writeByte((value >> 24) & 0xff);
      output.writeByte((value >> 16) & 0xff);
      output.writeByte((value >> 8) & 0xff);
      output.writeByte(value & 0xff);
      return;
    }

    while (numBits > 0) {
      numBits--;
      final b = (value >> numBits) & 0x1;
      _bitBuffer = (_bitBuffer << 1) | b;
      _bitPos--;
      if (_bitPos == 0) {
        output.writeByte(_bitBuffer);
        _bitPos = 8;
        _bitBuffer = 0;
      }
    }
  }

  /// Write any remaining bits from the buffer to the output, padding the
  /// remainder of the byte with 0's.
  void flush() {
    if (_bitPos != 8) {
      writeBits(_bitPos, 0);
    }
  }

  int _bitBuffer = 0;
  int _bitPos = 8;
}
