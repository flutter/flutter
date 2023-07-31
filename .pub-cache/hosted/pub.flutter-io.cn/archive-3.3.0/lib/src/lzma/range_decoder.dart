import 'dart:typed_data';

import '../util/input_stream.dart';

// Number of bits used for probabilities.
const int _probabilityBitCount = 11;

// Value used for a probability of 1.0.
const int _probabilityOne = (1 << _probabilityBitCount);

// Value used for a probability of 0.5.
const int _probabilityHalf = _probabilityOne ~/ 2;

// Probability table used with [RangeDecoder].
class RangeDecoderTable {
  // Table of probabilities for each symbol.
  final Uint16List table;

  // Creates a new probability table for [length] elemets.
  RangeDecoderTable(int length) : table = Uint16List(length) {
    reset();
  }

  // Reset the table to probabibilities of 0.5.
  void reset() {
    table.fillRange(0, table.length, _probabilityHalf);
  }
}

// Implements the LZMA range decoder.
class RangeDecoder {
  // Data being read from.
  late final InputStreamBase _input;

  // True once initialization bytes have been loaded.
  var _initialized = false;

  // Mask showing the current bits in [code].
  var range = 0xffffffff;

  // Current code being stored.
  var code = 0;

  // Set the input being read from. Must be set before initializing or reading bits.
  set input(InputStreamBase value) => _input = value;

  // Read a single bit from the decoder, using the supplied [index] into a probabilities [table].
  int readBit(RangeDecoderTable table, int index) {
    if (!_initialized) {
      // Skip the first byte, then load four for the initial state.
      _input.skip(1);
      for (var i = 0; i < 4; i++) {
        code = (code << 8 | _input.readByte());
      }
      _initialized = true;
    }

    _load();

    var p = table.table[index];
    var bound = (range >> _probabilityBitCount) * p;
    const moveBits = 5;
    if (code < bound) {
      range = bound;
      table.table[index] += (_probabilityOne - p) >> moveBits;
      return 0;
    } else {
      range -= bound;
      code -= bound;
      table.table[index] -= p >> moveBits;
      return 1;
    }
  }

  // Read a bittree (big endian) of [count] bits from the decoder.
  int readBittree(RangeDecoderTable table, int count) {
    var value = 0;
    var symbolPrefix = 1;
    for (var i = 0; i < count; i++) {
      var b = readBit(table, symbolPrefix | value);
      value = (value << 1) | b;
      symbolPrefix <<= 1;
    }

    return value;
  }

  // Read a reverse bittree (little endian) of [count] bits from the decoder.
  int readBittreeReverse(RangeDecoderTable table, int count) {
    var value = 0;
    var symbolPrefix = 1;
    for (var i = 0; i < count; i++) {
      var b = readBit(table, symbolPrefix | value);
      value |= b << i;
      symbolPrefix <<= 1;
    }

    return value;
  }

  // Read [count] bits directly from the decoder.
  int readDirect(int count) {
    var value = 0;
    for (var i = 0; i < count; i++) {
      _load();
      range >>= 1;
      code -= range;
      value <<= 1;
      if (code & 0x80000000 != 0) {
        code += range;
      } else {
        value++;
      }
    }

    return value;
  }

  // Load a byte if we can fit it.
  void _load() {
    const topValue = 1 << 24;
    if (range < topValue) {
      range <<= 8;
      code = (code << 8) | _input.readByte();
    }
  }
}
