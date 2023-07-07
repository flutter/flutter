// See file LICENSE for more information.

library impl.digest.md2;

import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/src/impl/base_digest.dart';
import 'package:pointycastle/src/registry/registry.dart';

/// Implementation of MD2 as outlined in RFC1319 by B.Kaliski from RSA Laboratories April 1992
class MD2Digest extends BaseDigest {
  static final FactoryConfig factoryConfig =
      StaticFactoryConfig(Digest, 'MD2', () => MD2Digest());

  static const _DIGEST_LENGTH = 16;

  /* X buffer */
  final _x = Uint8List(48);
  int _xOff = 0;

  /* M buffer */
  final _m = Uint8List(16);
  int _mOff = 0;

  /* check sum */
  final _c = Uint8List(16);
  // ignore: unused_field
  int _cOff = 0;

  @override
  String get algorithmName => 'MD2';

  @override
  int get digestSize => _DIGEST_LENGTH;

  @override
  void reset() {
    _xOff = 0;
    _x.fillRange(0, _x.length, 0);

    _mOff = 0;
    _m.fillRange(0, _m.length, 0);

    _cOff = 0;
    _c.fillRange(0, _c.length, 0);
  }

  @override
  void updateByte(int inp) {
    _m[_mOff++] = inp;

    if (_mOff == 16) {
      _processCheckSum(_m);
      _processBlock(_m);
      _mOff = 0;
    }
  }

  @override
  void update(Uint8List inp, int inpOff, int len) {
    // fill the current word
    while ((_mOff != 0) && (len > 0)) {
      updateByte(inp[inpOff]);
      inpOff++;
      len--;
    }

    // process whole words.
    while (len > 16) {
      _m.setRange(0, 16, inp.sublist(inpOff));
      _processCheckSum(_m);
      _processBlock(_m);
      len -= 16;
      inpOff += 16;
    }

    // load in the remainder.
    while (len > 0) {
      updateByte(inp[inpOff]);
      inpOff++;
      len--;
    }
  }

  @override
  int doFinal(Uint8List? out, int? outOff) {
    // add padding
    var paddingByte = _m.length - _mOff;
    for (var i = _mOff; i < _m.length; i++) {
      _m[i] = paddingByte;
    }

    //do final check sum
    _processCheckSum(_m);

    // do final block process
    _processBlock(_m);

    _processBlock(_c);

    out!.setRange(outOff!, outOff + 16, _x.sublist(_xOff));

    reset();

    return _DIGEST_LENGTH;
  }

  void _processBlock(Uint8List m) {
    for (var i = 0; i < 16; i++) {
      _x[i + 16] = m[i];
      _x[i + 32] = m[i] ^ _x[i];
    }

    // encrypt block
    var t = 0;

    for (var j = 0; j < 18; j++) {
      for (var k = 0; k < 48; k++) {
        t = _x[k] ^= _s[t];
        t = t & 0xff;
      }
      t = (t + j) % 256;
    }
  }

  void _processCheckSum(Uint8List m) {
    var L = _c[15];
    for (var i = 0; i < 16; i++) {
      _c[i] ^= _s[(m[i] ^ L) & 0xff];
      L = _c[i];
    }
  }

  // 256-byte random permutation constructed from the digits of PI
  static final _s = [
    41,
    46,
    67,
    201,
    162,
    216,
    124,
    1,
    61,
    54,
    84,
    161,
    236,
    240,
    6,
    19,
    98,
    167,
    5,
    243,
    192,
    199,
    115,
    140,
    152,
    147,
    43,
    217,
    188,
    76,
    130,
    202,
    30,
    155,
    87,
    60,
    253,
    212,
    224,
    22,
    103,
    66,
    111,
    24,
    138,
    23,
    229,
    18,
    190,
    78,
    196,
    214,
    218,
    158,
    222,
    73,
    160,
    251,
    245,
    142,
    187,
    47,
    238,
    122,
    169,
    104,
    121,
    145,
    21,
    178,
    7,
    63,
    148,
    194,
    16,
    137,
    11,
    34,
    95,
    33,
    128,
    127,
    93,
    154,
    90,
    144,
    50,
    39,
    53,
    62,
    204,
    231,
    191,
    247,
    151,
    3,
    255,
    25,
    48,
    179,
    72,
    165,
    181,
    209,
    215,
    94,
    146,
    42,
    172,
    86,
    170,
    198,
    79,
    184,
    56,
    210,
    150,
    164,
    125,
    182,
    118,
    252,
    107,
    226,
    156,
    116,
    4,
    241,
    69,
    157,
    112,
    89,
    100,
    113,
    135,
    32,
    134,
    91,
    207,
    101,
    230,
    45,
    168,
    2,
    27,
    96,
    37,
    173,
    174,
    176,
    185,
    246,
    28,
    70,
    97,
    105,
    52,
    64,
    126,
    15,
    85,
    71,
    163,
    35,
    221,
    81,
    175,
    58,
    195,
    92,
    249,
    206,
    186,
    197,
    234,
    38,
    44,
    83,
    13,
    110,
    133,
    40,
    132,
    9,
    211,
    223,
    205,
    244,
    65,
    129,
    77,
    82,
    106,
    220,
    55,
    200,
    108,
    193,
    171,
    250,
    36,
    225,
    123,
    8,
    12,
    189,
    177,
    74,
    120,
    136,
    149,
    139,
    227,
    99,
    232,
    109,
    233,
    203,
    213,
    254,
    59,
    0,
    29,
    57,
    242,
    239,
    183,
    14,
    102,
    88,
    208,
    228,
    166,
    119,
    114,
    248,
    235,
    117,
    75,
    10,
    49,
    68,
    80,
    180,
    143,
    237,
    31,
    26,
    219,
    153,
    141,
    51,
    159,
    17,
    131,
    20
  ];

  @override
  int get byteLength => 16;
}
