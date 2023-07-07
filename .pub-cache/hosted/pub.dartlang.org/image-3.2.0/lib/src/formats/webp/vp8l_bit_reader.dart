import 'dart:typed_data';

import '../../image_exception.dart';
import '../../util/input_buffer.dart';

class VP8LBitReader {
  int bitPos = 0;

  VP8LBitReader(this._input) {
    _buffer8 = Uint8List.view(_buffer.buffer);
    _buffer8[0] = _input.readByte();
    _buffer8[1] = _input.readByte();
    _buffer8[2] = _input.readByte();
    _buffer8[3] = _input.readByte();
    _buffer8[4] = _input.readByte();
    _buffer8[5] = _input.readByte();
    _buffer8[6] = _input.readByte();
    _buffer8[7] = _input.readByte();
  }

  // Return the prefetched bits, so they can be looked up.
  int prefetchBits() {
    var b2 = 0;
    if (bitPos < 32) {
      b2 = (_buffer[0] >> bitPos) +
          ((_buffer[1] & BIT_MASK[bitPos]) * (BIT_MASK[32 - bitPos] + 1));
    } else if (bitPos == 32) {
      b2 = _buffer[1];
    } else {
      b2 = _buffer[1] >> (bitPos - 32);
    }
    return b2;
  }

  bool get isEOS => (_input.isEOS && bitPos >= LBITS);

  // Advances the read buffer by 4 bytes to make room for reading next 32 bits.
  void fillBitWindow() {
    if (bitPos >= WBITS) {
      _shiftBytes();
    }
  }

  // Reads the specified number of bits from Read Buffer.
  int readBits(int numBits) {
    // Flag an error if end_of_stream or n_bits is more than allowed limit.
    if (!isEOS && numBits < MAX_NUM_BIT_READ) {
      //final value = (buffer >> bitPos) & BIT_MASK[numBits];
      final value = prefetchBits() & BIT_MASK[numBits];
      bitPos += numBits;
      _shiftBytes();
      return value;
    } else {
      throw ImageException('Not enough data in input.');
    }
  }

  // If not at EOS, reload up to LBITS byte-by-byte
  void _shiftBytes() {
    while (bitPos >= 8 && !_input.isEOS) {
      final b = _input.readByte();
      // buffer >>= 8
      _buffer[0] = (_buffer[0] >> 8) + ((_buffer[1] & 0xff) * 0x1000000);
      _buffer[1] >>= 8;
      // buffer |= b << (LBITS - 8)
      _buffer[1] |= b * 0x1000000;
      bitPos -= 8;
    }
  }

  final InputBuffer _input;
  final _buffer = Uint32List(2);
  late Uint8List _buffer8;

  // The number of bytes used for the bit buffer.
  static const VALUE_SIZE = 8;
  static const MAX_NUM_BIT_READ = 25;

  // Number of bits prefetched.
  static const LBITS = 64;

  // Minimum number of bytes needed after fillBitWindow.
  static const WBITS = 32;

  // Number of bytes needed to store WBITS bits.
  static const LOG8_WBITS = 4;

  static const List<int> BIT_MASK = [
    0,
    1,
    3,
    7,
    15,
    31,
    63,
    127,
    255,
    511,
    1023,
    2047,
    4095,
    8191,
    16383,
    32767,
    65535,
    131071,
    262143,
    524287,
    1048575,
    2097151,
    4194303,
    8388607,
    16777215,
    33554431,
    67108863,
    134217727,
    268435455,
    536870911,
    1073741823,
    2147483647,
    4294967295
  ];
}
