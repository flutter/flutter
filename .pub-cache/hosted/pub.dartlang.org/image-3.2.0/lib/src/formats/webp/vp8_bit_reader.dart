import '../../util/input_buffer.dart';

class VP8BitReader {
  InputBuffer input;

  // boolean decoder
  late int _range; // current range minus 1. In [127, 254] interval.
  late int _value; // current value
  late int _bits; // number of valid bits left
  bool _eof = false;

  VP8BitReader(this.input) {
    _range = 255 - 1;
    _value = 0;
    _bits = -8; // to load the very first 8bits
  }

  int getValue(int bits) {
    var v = 0;
    while (bits-- > 0) {
      v |= getBit(0x80) << bits;
    }
    return v;
  }

  int getSigned(int v) {
    final split = (_range >> 1);
    final bit = _bitUpdate(split);
    _shift();
    return bit != 0 ? -v : v;
  }

  int getSignedValue(int bits) {
    final value = getValue(bits);
    return get() == 1 ? -value : value;
  }

  int get() => getValue(1);

  int getBit(int prob) {
    final split = (_range * prob) >> 8;
    final bit = _bitUpdate(split);
    if (_range <= 0x7e) {
      _shift();
    }
    return bit;
  }

  int _bitUpdate(int split) {
    // Make sure we have a least BITS bits in 'value_'
    if (_bits < 0) {
      _loadNewBytes();
    }

    final pos = _bits;
    final value = (_value >> pos);
    if (value > split) {
      _range -= split + 1;
      _value -= (split + 1) << pos;
      return 1;
    } else {
      _range = split;
      return 0;
    }
  }

  void _shift() {
    final shift = LOG_2_RANGE[_range];
    _range = NEW_RANGE[_range];
    _bits -= shift;
  }

  void _loadNewBytes() {
    // Read 'BITS' bits at a time if possible.
    if (input.length >= 1) {
      // convert memory type to register type (with some zero'ing!)
      final bits = input.readByte();
      _value = bits | (_value << BITS);
      _bits += (BITS);
    } else {
      _loadFinalBytes(); // no need to be inlined
    }
  }

  void _loadFinalBytes() {
    // Only read 8bits at a time
    if (!input.isEOS) {
      _value = input.readByte() | (_value << 8);
      _bits += 8;
    } else if (!_eof) {
      // These are not strictly needed, but it makes the behaviour
      // consistent for both USE_RIGHT_JUSTIFY and !USE_RIGHT_JUSTIFY.
      _value <<= 8;
      _bits += 8;
      _eof = true;
    }
  }

  static const BITS = 8;

  // Read a bit with proba 'prob'. Speed-critical function!
  static const List<int> LOG_2_RANGE = [
    7,
    6,
    6,
    5,
    5,
    5,
    5,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    3,
    3,
    3,
    3,
    3,
    3,
    3,
    3,
    3,
    3,
    3,
    3,
    3,
    3,
    3,
    3,
    2,
    2,
    2,
    2,
    2,
    2,
    2,
    2,
    2,
    2,
    2,
    2,
    2,
    2,
    2,
    2,
    2,
    2,
    2,
    2,
    2,
    2,
    2,
    2,
    2,
    2,
    2,
    2,
    2,
    2,
    2,
    2,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    0
  ];

  static const List<int> NEW_RANGE = [
    127,
    127,
    191,
    127,
    159,
    191,
    223,
    127,
    143,
    159,
    175,
    191,
    207,
    223,
    239,
    127,
    135,
    143,
    151,
    159,
    167,
    175,
    183,
    191,
    199,
    207,
    215,
    223,
    231,
    239,
    247,
    127,
    131,
    135,
    139,
    143,
    147,
    151,
    155,
    159,
    163,
    167,
    171,
    175,
    179,
    183,
    187,
    191,
    195,
    199,
    203,
    207,
    211,
    215,
    219,
    223,
    227,
    231,
    235,
    239,
    243,
    247,
    251,
    127,
    129,
    131,
    133,
    135,
    137,
    139,
    141,
    143,
    145,
    147,
    149,
    151,
    153,
    155,
    157,
    159,
    161,
    163,
    165,
    167,
    169,
    171,
    173,
    175,
    177,
    179,
    181,
    183,
    185,
    187,
    189,
    191,
    193,
    195,
    197,
    199,
    201,
    203,
    205,
    207,
    209,
    211,
    213,
    215,
    217,
    219,
    221,
    223,
    225,
    227,
    229,
    231,
    233,
    235,
    237,
    239,
    241,
    243,
    245,
    247,
    249,
    251,
    253,
    127
  ];
}
