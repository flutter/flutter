// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'digest.dart';
import 'hash.dart';
import 'hash_sink.dart';
import 'utils.dart';

/// An implementation of the [SHA-256][rfc] hash function.
///
/// [rfc]: http://tools.ietf.org/html/rfc6234
const Hash sha256 = _Sha256._();

/// An implementation of the [SHA-224][rfc] hash function.
///
/// [rfc]: http://tools.ietf.org/html/rfc6234
const Hash sha224 = _Sha224._();

/// An implementation of the [SHA-256][rfc] hash function.
///
/// [rfc]: http://tools.ietf.org/html/rfc6234
///
/// Use the [sha256] object to perform SHA-256 hashing.
class _Sha256 extends Hash {
  @override
  final int blockSize = 16 * bytesPerWord;

  const _Sha256._();

  @override
  ByteConversionSink startChunkedConversion(Sink<Digest> sink) =>
      ByteConversionSink.from(_Sha256Sink(sink));
}

/// An implementation of the [SHA-224][rfc] hash function.
///
/// [rfc]: http://tools.ietf.org/html/rfc6234
///
///
/// Use the [sha224] object to perform SHA-224 hashing.
class _Sha224 extends Hash {
  @override
  final int blockSize = 16 * bytesPerWord;

  const _Sha224._();

  @override
  ByteConversionSink startChunkedConversion(Sink<Digest> sink) =>
      ByteConversionSink.from(_Sha224Sink(sink));
}

/// Data from a non-linear function that functions as reproducible noise.
const List<int> _noise = [
  0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, //
  0x923f82a4, 0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
  0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786,
  0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
  0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147,
  0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
  0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b,
  0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
  0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a,
  0x5b9cca4f, 0x682e6ff3, 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
  0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
];

abstract class _Sha32BitSink extends HashSink {
  final Uint32List _digest;

  /// The sixteen words from the original chunk, extended to 64 words.
  ///
  /// This is an instance variable to avoid re-allocating, but its data isn't
  /// used across invocations of [updateHash].
  final _extended = Uint32List(64);

  _Sha32BitSink(Sink<Digest> sink, this._digest) : super(sink, 16);

  // The following helper functions are taken directly from
  // http://tools.ietf.org/html/rfc6234.

  int _rotr32(int n, int x) => (x >> n) | ((x << (32 - n)) & mask32);
  int _ch(int x, int y, int z) => (x & y) ^ ((~x & mask32) & z);
  int _maj(int x, int y, int z) => (x & y) ^ (x & z) ^ (y & z);
  int _bsig0(int x) => _rotr32(2, x) ^ _rotr32(13, x) ^ _rotr32(22, x);
  int _bsig1(int x) => _rotr32(6, x) ^ _rotr32(11, x) ^ _rotr32(25, x);
  int _ssig0(int x) => _rotr32(7, x) ^ _rotr32(18, x) ^ (x >> 3);
  int _ssig1(int x) => _rotr32(17, x) ^ _rotr32(19, x) ^ (x >> 10);

  @override
  void updateHash(Uint32List chunk) {
    assert(chunk.length == 16);

    // Prepare message schedule.
    for (var i = 0; i < 16; i++) {
      _extended[i] = chunk[i];
    }
    for (var i = 16; i < 64; i++) {
      _extended[i] = add32(add32(_ssig1(_extended[i - 2]), _extended[i - 7]),
          add32(_ssig0(_extended[i - 15]), _extended[i - 16]));
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

    for (var i = 0; i < 64; i++) {
      var temp1 = add32(add32(h, _bsig1(e)),
          add32(_ch(e, f, g), add32(_noise[i], _extended[i])));
      var temp2 = add32(_bsig0(a), _maj(a, b, c));
      h = g;
      g = f;
      f = e;
      e = add32(d, temp1);
      d = c;
      c = b;
      b = a;
      a = add32(temp1, temp2);
    }

    // Update hash values after iteration.
    _digest[0] = add32(a, _digest[0]);
    _digest[1] = add32(b, _digest[1]);
    _digest[2] = add32(c, _digest[2]);
    _digest[3] = add32(d, _digest[3]);
    _digest[4] = add32(e, _digest[4]);
    _digest[5] = add32(f, _digest[5]);
    _digest[6] = add32(g, _digest[6]);
    _digest[7] = add32(h, _digest[7]);
  }
}

/// The concrete implementation of [Sha256].
///
/// This is separate so that it can extend [HashSink] without leaking additional
/// public members.
class _Sha256Sink extends _Sha32BitSink {
  @override
  Uint32List get digest => _digest;

  // Initial value of the hash parts. First 32 bits of the fractional parts
  // of the square roots of the first 8 prime numbers.
  _Sha256Sink(Sink<Digest> sink)
      : super(
            sink,
            Uint32List.fromList([
              0x6a09e667,
              0xbb67ae85,
              0x3c6ef372,
              0xa54ff53a,
              0x510e527f,
              0x9b05688c,
              0x1f83d9ab,
              0x5be0cd19,
            ]));
}

/// The concrete implementation of [Sha224].
///
/// This is separate so that it can extend [HashSink] without leaking additional
/// public members.
class _Sha224Sink extends _Sha32BitSink {
  @override
  Uint32List get digest => _digest.buffer.asUint32List(0, 7);

  _Sha224Sink(Sink<Digest> sink)
      : super(
            sink,
            Uint32List.fromList([
              0xc1059ed8,
              0x367cd507,
              0x3070dd17,
              0xf70e5939,
              0xffc00b31,
              0x68581511,
              0x64f98fa7,
              0xbefa4fa4,
            ]));
}
