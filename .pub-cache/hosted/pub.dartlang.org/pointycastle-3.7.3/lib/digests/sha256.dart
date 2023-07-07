// See file LICENSE for more information.

library impl.digest.sha256;

import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/src/impl/md4_family_digest.dart';
import 'package:pointycastle/src/registry/registry.dart';
import 'package:pointycastle/src/ufixnum.dart';

/// Implementation of SHA-256 digest.
class SHA256Digest extends MD4FamilyDigest implements Digest {
  static final FactoryConfig factoryConfig =
      StaticFactoryConfig(Digest, 'SHA-256', () => SHA256Digest());

  static const _DIGEST_LENGTH = 32;

  SHA256Digest() : super(Endian.big, 8, 64);

  @override
  final algorithmName = 'SHA-256';
  @override
  final digestSize = _DIGEST_LENGTH;

  @override
  void resetState() {
    state[0] = 0x6a09e667;
    state[1] = 0xbb67ae85;
    state[2] = 0x3c6ef372;
    state[3] = 0xa54ff53a;
    state[4] = 0x510e527f;
    state[5] = 0x9b05688c;
    state[6] = 0x1f83d9ab;
    state[7] = 0x5be0cd19;
  }

  @override
  void processBlock() {
    // expand 16 word block into 64 word blocks.
    for (var t = 16; t < 64; t++) {
      buffer[t] = clip32(_theta1(buffer[t - 2]) +
          buffer[t - 7] +
          _theta0(buffer[t - 15]) +
          buffer[t - 16]);
    }

    // set up working variables.
    var a = state[0];
    var b = state[1];
    var c = state[2];
    var d = state[3];
    var e = state[4];
    var f = state[5];
    var g = state[6];
    var h = state[7];

    var t = 0;

    for (var i = 0; i < 8; i++) {
      // t = 8 * i
      h = clip32(h + _sum1(e) + _ch(e, f, g) + _k[t] + buffer[t]);
      d = clip32(d + h);
      h = clip32(h + _sum0(a) + _maj(a, b, c));
      ++t;

      // t = 8 * i + 1
      g = clip32(g + _sum1(d) + _ch(d, e, f) + _k[t] + buffer[t]);
      c = clip32(c + g);
      g = clip32(g + _sum0(h) + _maj(h, a, b));
      ++t;

      // t = 8 * i + 2
      f = clip32(f + _sum1(c) + _ch(c, d, e) + _k[t] + buffer[t]);
      b = clip32(b + f);
      f = clip32(f + _sum0(g) + _maj(g, h, a));
      ++t;

      // t = 8 * i + 3
      e = clip32(e + _sum1(b) + _ch(b, c, d) + _k[t] + buffer[t]);
      a = clip32(a + e);
      e = clip32(e + _sum0(f) + _maj(f, g, h));
      ++t;

      // t = 8 * i + 4
      d = clip32(d + _sum1(a) + _ch(a, b, c) + _k[t] + buffer[t]);
      h = clip32(h + d);
      d = clip32(d + _sum0(e) + _maj(e, f, g));
      ++t;

      // t = 8 * i + 5
      c = clip32(c + _sum1(h) + _ch(h, a, b) + _k[t] + buffer[t]);
      g = clip32(g + c);
      c = clip32(c + _sum0(d) + _maj(d, e, f));
      ++t;

      // t = 8 * i + 6
      b = clip32(b + _sum1(g) + _ch(g, h, a) + _k[t] + buffer[t]);
      f = clip32(f + b);
      b = clip32(b + _sum0(c) + _maj(c, d, e));
      ++t;

      // t = 8 * i + 7
      a = clip32(a + _sum1(f) + _ch(f, g, h) + _k[t] + buffer[t]);
      e = clip32(e + a);
      a = clip32(a + _sum0(b) + _maj(b, c, d));
      ++t;
    }

    state[0] = clip32(state[0] + a);
    state[1] = clip32(state[1] + b);
    state[2] = clip32(state[2] + c);
    state[3] = clip32(state[3] + d);
    state[4] = clip32(state[4] + e);
    state[5] = clip32(state[5] + f);
    state[6] = clip32(state[6] + g);
    state[7] = clip32(state[7] + h);
  }

  int _ch(int x, int y, int z) => (x & y) ^ ((~x) & z);

  int _maj(int x, int y, int z) => (x & y) ^ (x & z) ^ (y & z);

  int _sum0(int x) => rotr32(x, 2) ^ rotr32(x, 13) ^ rotr32(x, 22);

  int _sum1(int x) => rotr32(x, 6) ^ rotr32(x, 11) ^ rotr32(x, 25);

  int _theta0(int x) => rotr32(x, 7) ^ rotr32(x, 18) ^ shiftr32(x, 3);

  int _theta1(int x) => rotr32(x, 17) ^ rotr32(x, 19) ^ shiftr32(x, 10);

  /// SHA-256 Constants (represent the first 32 bits of the fractional parts of the cube roots of the
  /// first sixty-four prime numbers)
  static final _k = [
    0x428a2f98,
    0x71374491,
    0xb5c0fbcf,
    0xe9b5dba5,
    0x3956c25b,
    0x59f111f1,
    0x923f82a4,
    0xab1c5ed5,
    0xd807aa98,
    0x12835b01,
    0x243185be,
    0x550c7dc3,
    0x72be5d74,
    0x80deb1fe,
    0x9bdc06a7,
    0xc19bf174,
    0xe49b69c1,
    0xefbe4786,
    0x0fc19dc6,
    0x240ca1cc,
    0x2de92c6f,
    0x4a7484aa,
    0x5cb0a9dc,
    0x76f988da,
    0x983e5152,
    0xa831c66d,
    0xb00327c8,
    0xbf597fc7,
    0xc6e00bf3,
    0xd5a79147,
    0x06ca6351,
    0x14292967,
    0x27b70a85,
    0x2e1b2138,
    0x4d2c6dfc,
    0x53380d13,
    0x650a7354,
    0x766a0abb,
    0x81c2c92e,
    0x92722c85,
    0xa2bfe8a1,
    0xa81a664b,
    0xc24b8b70,
    0xc76c51a3,
    0xd192e819,
    0xd6990624,
    0xf40e3585,
    0x106aa070,
    0x19a4c116,
    0x1e376c08,
    0x2748774c,
    0x34b0bcb5,
    0x391c0cb3,
    0x4ed8aa4a,
    0x5b9cca4f,
    0x682e6ff3,
    0x748f82ee,
    0x78a5636f,
    0x84c87814,
    0x8cc70208,
    0x90befffa,
    0xa4506ceb,
    0xbef9a3f7,
    0xc67178f2
  ];

  @override
  int get byteLength => 64;
}
