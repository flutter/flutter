// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'digest.dart';
import 'hash_sink.dart';

abstract class _Sha64BitSink extends HashSink {
  int get digestBytes;

  @override
  Uint32List get digest {
    var unordered = _digest.buffer.asUint32List();
    var ordered = Uint32List(digestBytes);
    for (var i = 0; i < digestBytes; i++) {
      ordered[i] = unordered[i + (i.isEven ? 1 : -1)];
    }
    return ordered;
  }

  // Initial value of the hash parts. First 64 bits of the fractional parts
  // of the square roots of the ninth through sixteenth prime numbers.
  final Uint64List _digest;

  /// The sixteen words from the original chunk, extended to 64 words.
  ///
  /// This is an instance variable to avoid re-allocating, but its data isn't
  /// used across invocations of [updateHash].
  final _extended = Uint64List(80);

  _Sha64BitSink(Sink<Digest> sink, this._digest)
      : super(sink, 32, signatureBytes: 16);
  // The following helper functions are taken directly from
  // http://tools.ietf.org/html/rfc6234.

  static int _rotr64(int n, int x) => _shr64(n, x) | (x << (64 - n));
  static int _shr64(int n, int x) => (x >> n) & ~(-1 << (64 - n));

  static int _ch(int x, int y, int z) => (x & y) ^ (~x & z);
  static int _maj(int x, int y, int z) => (x & y) ^ (x & z) ^ (y & z);
  static int _bsig0(int x) => _rotr64(28, x) ^ _rotr64(34, x) ^ _rotr64(39, x);
  static int _bsig1(int x) => _rotr64(14, x) ^ _rotr64(18, x) ^ _rotr64(41, x);
  static int _ssig0(int x) => _rotr64(1, x) ^ _rotr64(8, x) ^ _shr64(7, x);
  static int _ssig1(int x) => _rotr64(19, x) ^ _rotr64(61, x) ^ _shr64(6, x);

  @override
  void updateHash(Uint32List chunk) {
    assert(chunk.length == 32);

    // Prepare message schedule.
    for (var i = 0, x = 0; i < 32; i += 2, x++) {
      _extended[x] = (chunk[i] << 32) | chunk[i + 1];
    }

    for (var t = 16; t < 80; t++) {
      _extended[t] = _ssig1(_extended[t - 2]) +
          _extended[t - 7] +
          _ssig0(_extended[t - 15]) +
          _extended[t - 16];
    }

    // Shuffle around the bits.
    var a = _digest[0];
    var b = _digest[1];
    var c = _digest[2];
    var d = _digest[3];
    var e = _digest[4];
    var f = _digest[5];
    var g = _digest[6];
    var h = _digest[7];

    for (var i = 0; i < 80; i++) {
      var temp1 = h + _bsig1(e) + _ch(e, f, g) + _noise64[i] + _extended[i];
      var temp2 = _bsig0(a) + _maj(a, b, c);
      h = g;
      g = f;
      f = e;
      e = d + temp1;
      d = c;
      c = b;
      b = a;
      a = temp1 + temp2;
    }

    // Update hash values after iteration.
    _digest[0] += a;
    _digest[1] += b;
    _digest[2] += c;
    _digest[3] += d;
    _digest[4] += e;
    _digest[5] += f;
    _digest[6] += g;
    _digest[7] += h;
  }
}

/// The concrete implementation of [Sha384].
///
/// This is separate so that it can extend [HashSink] without leaking additional
/// public members.
class Sha384Sink extends _Sha64BitSink {
  @override
  final digestBytes = 12;

  Sha384Sink(Sink<Digest> sink)
      : super(
            sink,
            Uint64List.fromList([
              0xcbbb9d5dc1059ed8,
              0x629a292a367cd507,
              0x9159015a3070dd17,
              0x152fecd8f70e5939,
              0x67332667ffc00b31,
              0x8eb44a8768581511,
              0xdb0c2e0d64f98fa7,
              0x47b5481dbefa4fa4,
            ]));
}

/// The concrete implementation of [Sha512].
///
/// This is separate so that it can extend [HashSink] without leaking additional
/// public members.
class Sha512Sink extends _Sha64BitSink {
  @override
  final digestBytes = 16;

  Sha512Sink(Sink<Digest> sink)
      : super(
            sink,
            Uint64List.fromList([
              // Initial value of the hash parts. First 64 bits of the fractional
              // parts of the square roots of the first eight prime numbers.
              0x6a09e667f3bcc908,
              0xbb67ae8584caa73b,
              0x3c6ef372fe94f82b,
              0xa54ff53a5f1d36f1,
              0x510e527fade682d1,
              0x9b05688c2b3e6c1f,
              0x1f83d9abfb41bd6b,
              0x5be0cd19137e2179,
            ]));
}

/// The concrete implementation of [Sha512/224].
///
/// This is separate so that it can extend [HashSink] without leaking additional
/// public members.
class Sha512224Sink extends _Sha64BitSink {
  @override
  final digestBytes = 7;

  Sha512224Sink(Sink<Digest> sink)
      : super(
            sink,
            Uint64List.fromList([
              // FIPS 180-4, Section 5.3.6.1
              0x8c3d37c819544da2,
              0x73e1996689dcd4d6,
              0x1dfab7ae32ff9c82,
              0x679dd514582f9fcf,
              0x0f6d2b697bd44da8,
              0x77e36f7304c48942,
              0x3f9d85a86a1d36c8,
              0x1112e6ad91d692a1,
            ]));
}

/// The concrete implementation of [Sha512/256].
///
/// This is separate so that it can extend [HashSink] without leaking additional
/// public members.
class Sha512256Sink extends _Sha64BitSink {
  @override
  final digestBytes = 8;

  Sha512256Sink(Sink<Digest> sink)
      : super(
            sink,
            Uint64List.fromList([
              // FIPS 180-4, Section 5.3.6.2
              0x22312194fc2bf72c,
              0x9f555fa3c84c64c2,
              0x2393b86b6f53b151,
              0x963877195940eabd,
              0x96283ee2a88effe3,
              0xbe5e1e2553863992,
              0x2b0199fc2c85b8aa,
              0x0eb72ddc81c52ca2,
            ]));
}

final _noise64 = Uint64List.fromList([
  0x428a2f98d728ae22,
  0x7137449123ef65cd,
  0xb5c0fbcfec4d3b2f,
  0xe9b5dba58189dbbc,
  0x3956c25bf348b538,
  0x59f111f1b605d019,
  0x923f82a4af194f9b,
  0xab1c5ed5da6d8118,
  0xd807aa98a3030242,
  0x12835b0145706fbe,
  0x243185be4ee4b28c,
  0x550c7dc3d5ffb4e2,
  0x72be5d74f27b896f,
  0x80deb1fe3b1696b1,
  0x9bdc06a725c71235,
  0xc19bf174cf692694,
  0xe49b69c19ef14ad2,
  0xefbe4786384f25e3,
  0x0fc19dc68b8cd5b5,
  0x240ca1cc77ac9c65,
  0x2de92c6f592b0275,
  0x4a7484aa6ea6e483,
  0x5cb0a9dcbd41fbd4,
  0x76f988da831153b5,
  0x983e5152ee66dfab,
  0xa831c66d2db43210,
  0xb00327c898fb213f,
  0xbf597fc7beef0ee4,
  0xc6e00bf33da88fc2,
  0xd5a79147930aa725,
  0x06ca6351e003826f,
  0x142929670a0e6e70,
  0x27b70a8546d22ffc,
  0x2e1b21385c26c926,
  0x4d2c6dfc5ac42aed,
  0x53380d139d95b3df,
  0x650a73548baf63de,
  0x766a0abb3c77b2a8,
  0x81c2c92e47edaee6,
  0x92722c851482353b,
  0xa2bfe8a14cf10364,
  0xa81a664bbc423001,
  0xc24b8b70d0f89791,
  0xc76c51a30654be30,
  0xd192e819d6ef5218,
  0xd69906245565a910,
  0xf40e35855771202a,
  0x106aa07032bbd1b8,
  0x19a4c116b8d2d0c8,
  0x1e376c085141ab53,
  0x2748774cdf8eeb99,
  0x34b0bcb5e19b48a8,
  0x391c0cb3c5c95a63,
  0x4ed8aa4ae3418acb,
  0x5b9cca4f7763e373,
  0x682e6ff3d6b2b8a3,
  0x748f82ee5defb2fc,
  0x78a5636f43172f60,
  0x84c87814a1f0ab72,
  0x8cc702081a6439ec,
  0x90befffa23631e28,
  0xa4506cebde82bde9,
  0xbef9a3f7b2c67915,
  0xc67178f2e372532b,
  0xca273eceea26619c,
  0xd186b8c721c0c207,
  0xeada7dd6cde0eb1e,
  0xf57d4f7fee6ed178,
  0x06f067aa72176fba,
  0x0a637dc5a2c898a6,
  0x113f9804bef90dae,
  0x1b710b35131c471b,
  0x28db77f523047d84,
  0x32caab7b40c72493,
  0x3c9ebe0a15c9bebc,
  0x431d67c49c100d4c,
  0x4cc5d4becb3e42b6,
  0x597f299cfc657e2a,
  0x5fcb6fab3ad6faec,
  0x6c44198c4a475817,
]);
