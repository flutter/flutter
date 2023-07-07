// See file LICENSE for more information.

library impl.digest.md5;

import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/src/impl/md4_family_digest.dart';
import 'package:pointycastle/src/registry/registry.dart';
import 'package:pointycastle/src/ufixnum.dart';

/// Implementation of MD5 digest
class MD5Digest extends MD4FamilyDigest implements Digest {
  static final FactoryConfig factoryConfig =
      StaticFactoryConfig(Digest, 'MD5', () => MD5Digest());

  static const _DIGEST_LENGTH = 16;

  MD5Digest() : super(Endian.little, 4, 16);

  @override
  final algorithmName = 'MD5';
  @override
  final digestSize = _DIGEST_LENGTH;

  @override
  void resetState() {
    state[0] = 0x67452301;
    state[1] = 0xefcdab89;
    state[2] = 0x98badcfe;
    state[3] = 0x10325476;
  }

  @override
  void processBlock() {
    var a = state[0];
    var b = state[1];
    var c = state[2];
    var d = state[3];

    // Round 1 - F cycle, 16 times.
    a = sum32(crotl32(a + _f(b, c, d) + buffer[0] + 0xd76aa478, _S11), b);
    d = sum32(crotl32(d + _f(a, b, c) + buffer[1] + 0xe8c7b756, _S12), a);
    c = sum32(crotl32(c + _f(d, a, b) + buffer[2] + 0x242070db, _S13), d);
    b = sum32(crotl32(b + _f(c, d, a) + buffer[3] + 0xc1bdceee, _S14), c);
    a = sum32(crotl32(a + _f(b, c, d) + buffer[4] + 0xf57c0faf, _S11), b);
    d = sum32(crotl32(d + _f(a, b, c) + buffer[5] + 0x4787c62a, _S12), a);
    c = sum32(crotl32(c + _f(d, a, b) + buffer[6] + 0xa8304613, _S13), d);
    b = sum32(crotl32(b + _f(c, d, a) + buffer[7] + 0xfd469501, _S14), c);
    a = sum32(crotl32(a + _f(b, c, d) + buffer[8] + 0x698098d8, _S11), b);
    d = sum32(crotl32(d + _f(a, b, c) + buffer[9] + 0x8b44f7af, _S12), a);
    c = sum32(crotl32(c + _f(d, a, b) + buffer[10] + 0xffff5bb1, _S13), d);
    b = sum32(crotl32(b + _f(c, d, a) + buffer[11] + 0x895cd7be, _S14), c);
    a = sum32(crotl32(a + _f(b, c, d) + buffer[12] + 0x6b901122, _S11), b);
    d = sum32(crotl32(d + _f(a, b, c) + buffer[13] + 0xfd987193, _S12), a);
    c = sum32(crotl32(c + _f(d, a, b) + buffer[14] + 0xa679438e, _S13), d);
    b = sum32(crotl32(b + _f(c, d, a) + buffer[15] + 0x49b40821, _S14), c);

    // Round 2 - G cycle, 16 time_S.
    a = sum32(crotl32(a + _g(b, c, d) + buffer[1] + 0xf61e2562, _S21), b);
    d = sum32(crotl32(d + _g(a, b, c) + buffer[6] + 0xc040b340, _S22), a);
    c = sum32(crotl32(c + _g(d, a, b) + buffer[11] + 0x265e5a51, _S23), d);
    b = sum32(crotl32(b + _g(c, d, a) + buffer[0] + 0xe9b6c7aa, _S24), c);
    a = sum32(crotl32(a + _g(b, c, d) + buffer[5] + 0xd62f105d, _S21), b);
    d = sum32(crotl32(d + _g(a, b, c) + buffer[10] + 0x02441453, _S22), a);
    c = sum32(crotl32(c + _g(d, a, b) + buffer[15] + 0xd8a1e681, _S23), d);
    b = sum32(crotl32(b + _g(c, d, a) + buffer[4] + 0xe7d3fbc8, _S24), c);
    a = sum32(crotl32(a + _g(b, c, d) + buffer[9] + 0x21e1cde6, _S21), b);
    d = sum32(crotl32(d + _g(a, b, c) + buffer[14] + 0xc33707d6, _S22), a);
    c = sum32(crotl32(c + _g(d, a, b) + buffer[3] + 0xf4d50d87, _S23), d);
    b = sum32(crotl32(b + _g(c, d, a) + buffer[8] + 0x455a14ed, _S24), c);
    a = sum32(crotl32(a + _g(b, c, d) + buffer[13] + 0xa9e3e905, _S21), b);
    d = sum32(crotl32(d + _g(a, b, c) + buffer[2] + 0xfcefa3f8, _S22), a);
    c = sum32(crotl32(c + _g(d, a, b) + buffer[7] + 0x676f02d9, _S23), d);
    b = sum32(crotl32(b + _g(c, d, a) + buffer[12] + 0x8d2a4c8a, _S24), c);

    // Round 3 - H cycle, 16 time_S.
    a = sum32(crotl32(a + _h(b, c, d) + buffer[5] + 0xfffa3942, _S31), b);
    d = sum32(crotl32(d + _h(a, b, c) + buffer[8] + 0x8771f681, _S32), a);
    c = sum32(crotl32(c + _h(d, a, b) + buffer[11] + 0x6d9d6122, _S33), d);
    b = sum32(crotl32(b + _h(c, d, a) + buffer[14] + 0xfde5380c, _S34), c);
    a = sum32(crotl32(a + _h(b, c, d) + buffer[1] + 0xa4beea44, _S31), b);
    d = sum32(crotl32(d + _h(a, b, c) + buffer[4] + 0x4bdecfa9, _S32), a);
    c = sum32(crotl32(c + _h(d, a, b) + buffer[7] + 0xf6bb4b60, _S33), d);
    b = sum32(crotl32(b + _h(c, d, a) + buffer[10] + 0xbebfbc70, _S34), c);
    a = sum32(crotl32(a + _h(b, c, d) + buffer[13] + 0x289b7ec6, _S31), b);
    d = sum32(crotl32(d + _h(a, b, c) + buffer[0] + 0xeaa127fa, _S32), a);
    c = sum32(crotl32(c + _h(d, a, b) + buffer[3] + 0xd4ef3085, _S33), d);
    b = sum32(crotl32(b + _h(c, d, a) + buffer[6] + 0x04881d05, _S34), c);
    a = sum32(crotl32(a + _h(b, c, d) + buffer[9] + 0xd9d4d039, _S31), b);
    d = sum32(crotl32(d + _h(a, b, c) + buffer[12] + 0xe6db99e5, _S32), a);
    c = sum32(crotl32(c + _h(d, a, b) + buffer[15] + 0x1fa27cf8, _S33), d);
    b = sum32(crotl32(b + _h(c, d, a) + buffer[2] + 0xc4ac5665, _S34), c);

    // Round 4 - K cycle, 16 time_S.
    a = sum32(crotl32(a + _k(b, c, d) + buffer[0] + 0xf4292244, _S41), b);
    d = sum32(crotl32(d + _k(a, b, c) + buffer[7] + 0x432aff97, _S42), a);
    c = sum32(crotl32(c + _k(d, a, b) + buffer[14] + 0xab9423a7, _S43), d);
    b = sum32(crotl32(b + _k(c, d, a) + buffer[5] + 0xfc93a039, _S44), c);
    a = sum32(crotl32(a + _k(b, c, d) + buffer[12] + 0x655b59c3, _S41), b);
    d = sum32(crotl32(d + _k(a, b, c) + buffer[3] + 0x8f0ccc92, _S42), a);
    c = sum32(crotl32(c + _k(d, a, b) + buffer[10] + 0xffeff47d, _S43), d);
    b = sum32(crotl32(b + _k(c, d, a) + buffer[1] + 0x85845dd1, _S44), c);
    a = sum32(crotl32(a + _k(b, c, d) + buffer[8] + 0x6fa87e4f, _S41), b);
    d = sum32(crotl32(d + _k(a, b, c) + buffer[15] + 0xfe2ce6e0, _S42), a);
    c = sum32(crotl32(c + _k(d, a, b) + buffer[6] + 0xa3014314, _S43), d);
    b = sum32(crotl32(b + _k(c, d, a) + buffer[13] + 0x4e0811a1, _S44), c);
    a = sum32(crotl32(a + _k(b, c, d) + buffer[4] + 0xf7537e82, _S41), b);
    d = sum32(crotl32(d + _k(a, b, c) + buffer[11] + 0xbd3af235, _S42), a);
    c = sum32(crotl32(c + _k(d, a, b) + buffer[2] + 0x2ad7d2bb, _S43), d);
    b = sum32(crotl32(b + _k(c, d, a) + buffer[9] + 0xeb86d391, _S44), c);

    state[0] = clip32(state[0] + a);
    state[1] = clip32(state[1] + b);
    state[2] = clip32(state[2] + c);
    state[3] = clip32(state[3] + d);
  }

  // round 1 left rotates
  static const _S11 = 7;
  static const _S12 = 12;
  static const _S13 = 17;
  static const _S14 = 22;

  // round 2 left rotates
  static const _S21 = 5;
  static const _S22 = 9;
  static const _S23 = 14;
  static const _S24 = 20;

  // round 3 left rotates
  static const _S31 = 4;
  static const _S32 = 11;
  static const _S33 = 16;
  static const _S34 = 23;

  // round 4 left rotates
  static const _S41 = 6;
  static const _S42 = 10;
  static const _S43 = 15;
  static const _S44 = 21;

  int _f(int u, int v, int w) => (u & v) | (not32(u) & w);

  int _g(int u, int v, int w) => (u & w) | (v & not32(w));

  int _h(int u, int v, int w) => u ^ v ^ w;

  int _k(int u, int v, int w) => v ^ (u | not32(w));

  @override
  int get byteLength => 64;
}
