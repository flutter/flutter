import 'dart:typed_data';

import '../util/input_stream.dart';

// Number of bits used for probabilities.
const _probabilityBitCount = 11;

// Value used for a probability of 1.0.
const _probabilityOne = (1 << _probabilityBitCount);

// Value used for a probability of 0.5.
const _probabilityHalf = _probabilityOne ~/ 2;

// Probability table used with [RangeDecoder].
class RangeDecoderTable {
  // Table of probabilities for each symbol.
  final Uint16List table;

  // Creates a new probability table for [length] elements.
  RangeDecoderTable(int length) : table = Uint16List(length) {
    reset();
  }

  // Reset the table to probabilities of 0.5.
  void reset() {
    table.fillRange(0, table.length, _probabilityHalf);
  }
}

// Implements the LZMA range decoder.
class RangeDecoder {
  // Data being read from.
  late InputStreamBase _input;

  // Mask showing the current bits in [code].
  var range = 0xffffffff;

  // Current code being stored.
  var code = 0;

  // Set the input being read from. Must be set before initializing or reading
  // bits.
  set input(InputStreamBase value) {
    _input = value;
  }

  void reset() {
    range = 0xffffffff;
    code = 0;
  }

  void initialize() {
    code = 0;
    range = 0xffffffff;
    // Skip the first byte, then load four for the initial state.
    _input.skip(1);
    for (var i = 0; i < 4; i++) {
      code = (code << 8 | _input.readByte());
    }
  }

  // Read a single bit from the decoder, using the supplied [index] into a
  // probabilities [table].
  int readBit(RangeDecoderTable table, int index) {
    _load();

    final p = table.table[index];
    final bound = (range >> _probabilityBitCount) * p;
    const moveBits = 5;
    if (code < bound) {
      range = bound;
      final oneMinusP = _probabilityOne - p;
      final shifted = oneMinusP >> moveBits;
      table.table[index] += shifted;
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
      final b = readBit(table, symbolPrefix | value);
      value = ((value << 1) | b) & 0xffffffff;
      symbolPrefix = (symbolPrefix << 1) & 0xffffffff;
    }

    return value;
  }

  // Read a reverse bittree (little endian) of [count] bits from the decoder.
  int readBittreeReverse(RangeDecoderTable table, int count) {
    var value = 0;
    var symbolPrefix = 1;
    for (var i = 0; i < count; i++) {
      final b = readBit(table, symbolPrefix | value);
      value = (value | b << i) & 0xffffffff;
      symbolPrefix = (symbolPrefix << 1) & 0xffffffff;
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
