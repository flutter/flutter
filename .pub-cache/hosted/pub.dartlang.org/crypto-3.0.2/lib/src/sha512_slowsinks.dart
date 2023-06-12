// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'digest.dart';
import 'hash_sink.dart';

/// Data from a non-linear function that functions as reproducible noise.
///
/// [rfc]: https://tools.ietf.org/html/rfc6234#section-5.2
final _noise32 = Uint32List.fromList([
  0x428a2f98, 0xd728ae22, 0x71374491, 0x23ef65cd, //
  0xb5c0fbcf, 0xec4d3b2f, 0xe9b5dba5, 0x8189dbbc,
  0x3956c25b, 0xf348b538, 0x59f111f1, 0xb605d019,
  0x923f82a4, 0xaf194f9b, 0xab1c5ed5, 0xda6d8118,
  0xd807aa98, 0xa3030242, 0x12835b01, 0x45706fbe,
  0x243185be, 0x4ee4b28c, 0x550c7dc3, 0xd5ffb4e2,
  0x72be5d74, 0xf27b896f, 0x80deb1fe, 0x3b1696b1,
  0x9bdc06a7, 0x25c71235, 0xc19bf174, 0xcf692694,
  0xe49b69c1, 0x9ef14ad2, 0xefbe4786, 0x384f25e3,
  0x0fc19dc6, 0x8b8cd5b5, 0x240ca1cc, 0x77ac9c65,
  0x2de92c6f, 0x592b0275, 0x4a7484aa, 0x6ea6e483,
  0x5cb0a9dc, 0xbd41fbd4, 0x76f988da, 0x831153b5,
  0x983e5152, 0xee66dfab, 0xa831c66d, 0x2db43210,
  0xb00327c8, 0x98fb213f, 0xbf597fc7, 0xbeef0ee4,
  0xc6e00bf3, 0x3da88fc2, 0xd5a79147, 0x930aa725,
  0x06ca6351, 0xe003826f, 0x14292967, 0x0a0e6e70,
  0x27b70a85, 0x46d22ffc, 0x2e1b2138, 0x5c26c926,
  0x4d2c6dfc, 0x5ac42aed, 0x53380d13, 0x9d95b3df,
  0x650a7354, 0x8baf63de, 0x766a0abb, 0x3c77b2a8,
  0x81c2c92e, 0x47edaee6, 0x92722c85, 0x1482353b,
  0xa2bfe8a1, 0x4cf10364, 0xa81a664b, 0xbc423001,
  0xc24b8b70, 0xd0f89791, 0xc76c51a3, 0x0654be30,
  0xd192e819, 0xd6ef5218, 0xd6990624, 0x5565a910,
  0xf40e3585, 0x5771202a, 0x106aa070, 0x32bbd1b8,
  0x19a4c116, 0xb8d2d0c8, 0x1e376c08, 0x5141ab53,
  0x2748774c, 0xdf8eeb99, 0x34b0bcb5, 0xe19b48a8,
  0x391c0cb3, 0xc5c95a63, 0x4ed8aa4a, 0xe3418acb,
  0x5b9cca4f, 0x7763e373, 0x682e6ff3, 0xd6b2b8a3,
  0x748f82ee, 0x5defb2fc, 0x78a5636f, 0x43172f60,
  0x84c87814, 0xa1f0ab72, 0x8cc70208, 0x1a6439ec,
  0x90befffa, 0x23631e28, 0xa4506ceb, 0xde82bde9,
  0xbef9a3f7, 0xb2c67915, 0xc67178f2, 0xe372532b,
  0xca273ece, 0xea26619c, 0xd186b8c7, 0x21c0c207,
  0xeada7dd6, 0xcde0eb1e, 0xf57d4f7f, 0xee6ed178,
  0x06f067aa, 0x72176fba, 0x0a637dc5, 0xa2c898a6,
  0x113f9804, 0xbef90dae, 0x1b710b35, 0x131c471b,
  0x28db77f5, 0x23047d84, 0x32caab7b, 0x40c72493,
  0x3c9ebe0a, 0x15c9bebc, 0x431d67c4, 0x9c100d4c,
  0x4cc5d4be, 0xcb3e42b6, 0x597f299c, 0xfc657e2a,
  0x5fcb6fab, 0x3ad6faec, 0x6c44198c, 0x4a475817,
]);

abstract class _Sha64BitSink extends HashSink {
  int get digestBytes;

  @override
  Uint32List get digest {
    return Uint32List.view(_digest.buffer, 0, digestBytes);
  }

  // Initial value of the hash parts. First 64 bits of the fractional parts
  // of the square roots of the ninth through sixteenth prime numbers.
  final Uint32List _digest;

  /// The sixteen words from the original chunk, extended to 64 words.
  ///
  /// This is an instance variable to avoid re-allocating, but its data isn't
  /// used across invocations of [updateHash].
  final _extended = Uint32List(160);

  _Sha64BitSink(Sink<Digest> sink, this._digest)
      : super(sink, 32, signatureBytes: 16);
  // The following helper functions are taken directly from
  // http://tools.ietf.org/html/rfc6234.

  void _shr(
      int bits, Uint32List word, int offset, Uint32List ret, int offsetR) {
    ret[0 + offsetR] =
        ((bits < 32) && (bits >= 0)) ? (word[0 + offset] >> (bits)) : 0;
    ret[1 + offsetR] = (bits > 32)
        ? (word[0 + offset] >> (bits - 32))
        : (bits == 32)
            ? word[0 + offset]
            : (bits >= 0)
                ? ((word[0 + offset] << (32 - bits)) |
                    (word[1 + offset] >> bits))
                : 0;
  }

  void _shl(
      int bits, Uint32List word, int offset, Uint32List ret, int offsetR) {
    ret[0 + offsetR] = (bits > 32)
        ? (word[1 + offset] << (bits - 32))
        : (bits == 32)
            ? word[1 + offset]
            : (bits >= 0)
                ? ((word[0 + offset] << bits) |
                    (word[1 + offset] >> (32 - bits)))
                : 0;
    ret[1 + offsetR] =
        ((bits < 32) && (bits >= 0)) ? (word[1 + offset] << bits) : 0;
  }

  void _or(Uint32List word1, int offset1, Uint32List word2, int offset2,
      Uint32List ret, int offsetR) {
    ret[0 + offsetR] = word1[0 + offset1] | word2[0 + offset2];
    ret[1 + offsetR] = word1[1 + offset1] | word2[1 + offset2];
  }

  void _xor(Uint32List word1, int offset1, Uint32List word2, int offset2,
      Uint32List ret, int offsetR) {
    ret[0 + offsetR] = word1[0 + offset1] ^ word2[0 + offset2];
    ret[1 + offsetR] = word1[1 + offset1] ^ word2[1 + offset2];
  }

  void _add(Uint32List word1, int offset1, Uint32List word2, int offset2,
      Uint32List ret, int offsetR) {
    ret[1 + offsetR] = (word1[1 + offset1] + word2[1 + offset2]);
    ret[0 + offsetR] = word1[0 + offset1] +
        word2[0 + offset2] +
        (ret[1 + offsetR] < word1[1 + offset1] ? 1 : 0);
  }

  void _addTo2(Uint32List word1, int offset1, Uint32List word2, int offset2) {
    int _addTemp;
    _addTemp = word1[1 + offset1];
    word1[1 + offset1] += word2[1 + offset2];
    word1[0 + offset1] +=
        word2[0 + offset2] + (word1[1 + offset1] < _addTemp ? 1 : 0);
  }

  static const _rotrIndex1 = 0;
  static const _rotrIndex2 = _rotrIndex1 + 2;
  static const _sigIndex1 = _rotrIndex2 + 2;
  static const _sigIndex2 = _sigIndex1 + 2;
  static const _sigIndex3 = _sigIndex2 + 2;
  static const _sigIndex4 = _sigIndex3 + 2;
  static const _aIndex = _sigIndex4 + 2;
  static const _bIndex = _aIndex + 2;
  static const _cIndex = _bIndex + 2;
  static const _dIndex = _cIndex + 2;
  static const _eIndex = _dIndex + 2;
  static const _fIndex = _eIndex + 2;
  static const _gIndex = _fIndex + 2;
  static const _hIndex = _gIndex + 2;
  static const _tmp1 = _hIndex + 2;
  static const _tmp2 = _tmp1 + 2;
  static const _tmp3 = _tmp2 + 2;
  static const _tmp4 = _tmp3 + 2;
  static const _tmp5 = _tmp4 + 2;
  final _nums = Uint32List(12 + 16 + 10);

  // SHA rotate   ((word >> bits) | (word << (64-bits)))
  void _rotr(
      int bits, Uint32List word, int offset, Uint32List ret, int offsetR) {
    _shr(bits, word, offset, _nums, _rotrIndex1);
    _shl(64 - bits, word, offset, _nums, _rotrIndex2);
    _or(_nums, _rotrIndex1, _nums, _rotrIndex2, ret, offsetR);
  }

  void _bsig0(Uint32List word, int offset, Uint32List ret, int offsetR) {
    _rotr(28, word, offset, _nums, _sigIndex1);
    _rotr(34, word, offset, _nums, _sigIndex2);
    _rotr(39, word, offset, _nums, _sigIndex3);
    _xor(_nums, _sigIndex2, _nums, _sigIndex3, _nums, _sigIndex4);
    _xor(_nums, _sigIndex1, _nums, _sigIndex4, ret, offsetR);
  }

  void _bsig1(Uint32List word, int offset, Uint32List ret, int offsetR) {
    _rotr(14, word, offset, _nums, _sigIndex1);
    _rotr(18, word, offset, _nums, _sigIndex2);
    _rotr(41, word, offset, _nums, _sigIndex3);
    _xor(_nums, _sigIndex2, _nums, _sigIndex3, _nums, _sigIndex4);
    _xor(_nums, _sigIndex1, _nums, _sigIndex4, ret, offsetR);
  }

  void _ssig0(Uint32List word, int offset, Uint32List ret, int offsetR) {
    _rotr(1, word, offset, _nums, _sigIndex1);
    _rotr(8, word, offset, _nums, _sigIndex2);
    _shr(7, word, offset, _nums, _sigIndex3);
    _xor(_nums, _sigIndex2, _nums, _sigIndex3, _nums, _sigIndex4);
    _xor(_nums, _sigIndex1, _nums, _sigIndex4, ret, offsetR);
  }

  void _ssig1(Uint32List word, int offset, Uint32List ret, int offsetR) {
    _rotr(19, word, offset, _nums, _sigIndex1);
    _rotr(61, word, offset, _nums, _sigIndex2);
    _shr(6, word, offset, _nums, _sigIndex3);
    _xor(_nums, _sigIndex2, _nums, _sigIndex3, _nums, _sigIndex4);
    _xor(_nums, _sigIndex1, _nums, _sigIndex4, ret, offsetR);
  }

  void _ch(Uint32List x, int offsetX, Uint32List y, int offsetY, Uint32List z,
      int offsetZ, Uint32List ret, int offsetR) {
    ret[0 + offsetR] =
        ((x[0 + offsetX] & (y[0 + offsetY] ^ z[0 + offsetZ])) ^ z[0 + offsetZ]);
    ret[1 + offsetR] =
        ((x[1 + offsetX] & (y[1 + offsetY] ^ z[1 + offsetZ])) ^ z[1 + offsetZ]);
  }

  void _maj(Uint32List x, int offsetX, Uint32List y, int offsetY, Uint32List z,
      int offsetZ, Uint32List ret, int offsetR) {
    ret[0 + offsetR] = ((x[0 + offsetX] & (y[0 + offsetY] | z[0 + offsetZ])) |
        (y[0 + offsetY] & z[0 + offsetZ]));
    ret[1 + offsetR] = ((x[1 + offsetX] & (y[1 + offsetY] | z[1 + offsetZ])) |
        (y[1 + offsetY] & z[1 + offsetZ]));
  }

  @override
  void updateHash(Uint32List chunk) {
    assert(chunk.length == 32);

    // Prepare message schedule.
    for (var i = 0; i < 32; i++) {
      _extended[i] = chunk[i];
    }

    for (var i = 32; i < 160; i += 2) {
      _ssig1(_extended, i - 2 * 2, _nums, _tmp1);
      _add(_nums, _tmp1, _extended, i - 7 * 2, _nums, _tmp2);
      _ssig0(_extended, i - 15 * 2, _nums, _tmp1);
      _add(_nums, _tmp1, _extended, i - 16 * 2, _nums, _tmp3);
      _add(_nums, _tmp2, _nums, _tmp3, _extended, i);
    }

    // Shuffle around the bits.
    _nums.setRange(_aIndex, _hIndex + 2, _digest);

    for (var i = 0; i < 160; i += 2) {
      // temp1 = H + SHA512_SIGMA1(E) + SHA_Ch(E,F,G) + K[t] + W[t];
      _bsig1(_nums, _eIndex, _nums, _tmp1);
      _add(_nums, _hIndex, _nums, _tmp1, _nums, _tmp2);
      _ch(_nums, _eIndex, _nums, _fIndex, _nums, _gIndex, _nums, _tmp3);
      _add(_nums, _tmp2, _nums, _tmp3, _nums, _tmp4);
      _add(_noise32, i, _extended, i, _nums, _tmp5);
      _add(_nums, _tmp4, _nums, _tmp5, _nums, _tmp1);

      // temp2 = SHA512_SIGMA0(A) + SHA_Maj(A,B,C);
      _bsig0(_nums, _aIndex, _nums, _tmp3);
      _maj(_nums, _aIndex, _nums, _bIndex, _nums, _cIndex, _nums, _tmp4);
      _add(_nums, _tmp3, _nums, _tmp4, _nums, _tmp2);

      _nums[_hIndex] = _nums[_gIndex];
      _nums[_hIndex + 1] = _nums[_gIndex + 1];
      _nums[_gIndex] = _nums[_fIndex];
      _nums[_gIndex + 1] = _nums[_fIndex + 1];
      _nums[_fIndex] = _nums[_eIndex];
      _nums[_fIndex + 1] = _nums[_eIndex + 1];
      _add(_nums, _dIndex, _nums, _tmp1, _nums, _eIndex);
      _nums[_dIndex] = _nums[_cIndex];
      _nums[_dIndex + 1] = _nums[_cIndex + 1];
      _nums[_cIndex] = _nums[_bIndex];
      _nums[_cIndex + 1] = _nums[_bIndex + 1];
      _nums[_bIndex] = _nums[_aIndex];
      _nums[_bIndex + 1] = _nums[_aIndex + 1];

      _add(_nums, _tmp1, _nums, _tmp2, _nums, _aIndex);
    }

    // Update hash values after iteration.
    _addTo2(_digest, 0, _nums, _aIndex);
    _addTo2(_digest, 2, _nums, _bIndex);
    _addTo2(_digest, 4, _nums, _cIndex);
    _addTo2(_digest, 6, _nums, _dIndex);
    _addTo2(_digest, 8, _nums, _eIndex);
    _addTo2(_digest, 10, _nums, _fIndex);
    _addTo2(_digest, 12, _nums, _gIndex);
    _addTo2(_digest, 14, _nums, _hIndex);
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
            Uint32List.fromList([
              0xcbbb9d5d,
              0xc1059ed8,
              0x629a292a,
              0x367cd507,
              0x9159015a,
              0x3070dd17,
              0x152fecd8,
              0xf70e5939,
              0x67332667,
              0xffc00b31,
              0x8eb44a87,
              0x68581511,
              0xdb0c2e0d,
              0x64f98fa7,
              0x47b5481d,
              0xbefa4fa4,
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
            Uint32List.fromList([
              // Initial value of the hash parts. First 64 bits of the fractional
              // parts of the square roots of the first eight prime numbers.
              0x6a09e667, 0xf3bcc908,
              0xbb67ae85, 0x84caa73b,
              0x3c6ef372, 0xfe94f82b,
              0xa54ff53a, 0x5f1d36f1,
              0x510e527f, 0xade682d1,
              0x9b05688c, 0x2b3e6c1f,
              0x1f83d9ab, 0xfb41bd6b,
              0x5be0cd19, 0x137e2179,
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
            Uint32List.fromList([
              // FIPS 180-4, Section 5.3.6.1
              0x8c3d37c8, 0x19544da2,
              0x73e19966, 0x89dcd4d6,
              0x1dfab7ae, 0x32ff9c82,
              0x679dd514, 0x582f9fcf,
              0x0f6d2b69, 0x7bd44da8,
              0x77e36f73, 0x04c48942,
              0x3f9d85a8, 0x6a1d36c8,
              0x1112e6ad, 0x91d692a1,
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
            Uint32List.fromList([
              // FIPS 180-4, Section 5.3.6.2
              0x22312194, 0xfc2bf72c,
              0x9f555fa3, 0xc84c64c2,
              0x2393b86b, 0x6f53b151,
              0x96387719, 0x5940eabd,
              0x96283ee2, 0xa88effe3,
              0xbe5e1e25, 0x53863992,
              0x2b0199fc, 0x2c85b8aa,
              0x0eb72ddc, 0x81c52ca2,
            ]));
}
