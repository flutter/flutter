// See file LICENSE for more information.

library impl.digest.sha1;

import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/src/impl/md4_family_digest.dart';
import 'package:pointycastle/src/registry/registry.dart';
import 'package:pointycastle/src/ufixnum.dart';

/// Implementation of SHA-1 digest
class SHA1Digest extends MD4FamilyDigest implements Digest {
  static final FactoryConfig factoryConfig =
      StaticFactoryConfig(Digest, 'SHA-1', () => SHA1Digest());

  static const _DIGEST_LENGTH = 20;

  SHA1Digest() : super(Endian.big, 5, 80);

  @override
  final algorithmName = 'SHA-1';
  @override
  final digestSize = _DIGEST_LENGTH;

  @override
  void resetState() {
    state[0] = 0x67452301;
    state[1] = 0xefcdab89;
    state[2] = 0x98badcfe;
    state[3] = 0x10325476;
    state[4] = 0xc3d2e1f0;
  }

  @override
  void processBlock() {
    // expand 16 word block into 80 word block.
    for (var i = 16; i < 80; i++) {
      var t = buffer[i - 3] ^ buffer[i - 8] ^ buffer[i - 14] ^ buffer[i - 16];
      buffer[i] = rotl32(t, 1);
    }

    // set up working variables.
    var A = state[0];
    var B = state[1];
    var C = state[2];
    var D = state[3];
    var E = state[4];

    var idx = 0;

    // round 1
    for (var j = 0; j < 4; j++) {
      E = clip32(E + rotl32(A, 5) + _f(B, C, D) + buffer[idx++] + _Y1);
      B = rotl32(B, 30);

      D = clip32(D + rotl32(E, 5) + _f(A, B, C) + buffer[idx++] + _Y1);
      A = rotl32(A, 30);

      C = clip32(C + rotl32(D, 5) + _f(E, A, B) + buffer[idx++] + _Y1);
      E = rotl32(E, 30);

      B = clip32(B + rotl32(C, 5) + _f(D, E, A) + buffer[idx++] + _Y1);
      D = rotl32(D, 30);

      A = clip32(A + rotl32(B, 5) + _f(C, D, E) + buffer[idx++] + _Y1);
      C = rotl32(C, 30);
    }

    // round 2
    for (var j = 0; j < 4; j++) {
      E = clip32(E + rotl32(A, 5) + _h(B, C, D) + buffer[idx++] + _Y2);
      B = rotl32(B, 30);

      D = clip32(D + rotl32(E, 5) + _h(A, B, C) + buffer[idx++] + _Y2);
      A = rotl32(A, 30);

      C = clip32(C + rotl32(D, 5) + _h(E, A, B) + buffer[idx++] + _Y2);
      E = rotl32(E, 30);

      B = clip32(B + rotl32(C, 5) + _h(D, E, A) + buffer[idx++] + _Y2);
      D = rotl32(D, 30);

      A = clip32(A + rotl32(B, 5) + _h(C, D, E) + buffer[idx++] + _Y2);
      C = rotl32(C, 30);
    }

    // round 3
    for (var j = 0; j < 4; j++) {
      E = clip32(E + rotl32(A, 5) + _g(B, C, D) + buffer[idx++] + _Y3);
      B = rotl32(B, 30);

      D = clip32(D + rotl32(E, 5) + _g(A, B, C) + buffer[idx++] + _Y3);
      A = rotl32(A, 30);

      C = clip32(C + rotl32(D, 5) + _g(E, A, B) + buffer[idx++] + _Y3);
      E = rotl32(E, 30);

      B = clip32(B + rotl32(C, 5) + _g(D, E, A) + buffer[idx++] + _Y3);
      D = rotl32(D, 30);

      A = clip32(A + rotl32(B, 5) + _g(C, D, E) + buffer[idx++] + _Y3);
      C = rotl32(C, 30);
    }

    // round 4
    for (var j = 0; j < 4; j++) {
      E = clip32(E + rotl32(A, 5) + _h(B, C, D) + buffer[idx++] + _Y4);
      B = rotl32(B, 30);

      D = clip32(D + rotl32(E, 5) + _h(A, B, C) + buffer[idx++] + _Y4);
      A = rotl32(A, 30);

      C = clip32(C + rotl32(D, 5) + _h(E, A, B) + buffer[idx++] + _Y4);
      E = rotl32(E, 30);

      B = clip32(B + rotl32(C, 5) + _h(D, E, A) + buffer[idx++] + _Y4);
      D = rotl32(D, 30);

      A = clip32(A + rotl32(B, 5) + _h(C, D, E) + buffer[idx++] + _Y4);
      C = rotl32(C, 30);
    }

    state[0] = clip32(state[0] + A);
    state[1] = clip32(state[1] + B);
    state[2] = clip32(state[2] + C);
    state[3] = clip32(state[3] + D);
    state[4] = clip32(state[4] + E);
  }

  // Additive constants
  static const _Y1 = 0x5a827999;
  static const _Y2 = 0x6ed9eba1;
  static const _Y3 = 0x8f1bbcdc;
  static const _Y4 = 0xca62c1d6;

  int _f(int u, int v, int w) => ((u & v) | ((~u) & w));

  int _h(int u, int v, int w) => (u ^ v ^ w);

  int _g(int u, int v, int w) => ((u & v) | (u & w) | (v & w));

  @override
  int get byteLength => 64;
}
