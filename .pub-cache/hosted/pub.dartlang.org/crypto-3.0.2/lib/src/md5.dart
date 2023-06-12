// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'digest.dart';
import 'hash.dart';
import 'hash_sink.dart';
import 'utils.dart';

/// An implementation of the [MD5][rfc] hash function.
///
/// [rfc]: https://tools.ietf.org/html/rfc1321
///
/// **Warning**: MD5 has known collisions and should only be used when required
/// for backwards compatibility.
const Hash md5 = _MD5._();

/// An implementation of the [MD5][rfc] hash function.
///
/// [rfc]: https://tools.ietf.org/html/rfc1321
///
/// **Warning**: MD5 has known collisions and should only be used when required
/// for backwards compatibility.
///
/// Use the [md5] object to perform MD5 hashing.
class _MD5 extends Hash {
  @override
  final int blockSize = 16 * bytesPerWord;

  const _MD5._();

  @override
  ByteConversionSink startChunkedConversion(Sink<Digest> sink) =>
      ByteConversionSink.from(_MD5Sink(sink));
}

/// Data from a non-linear mathematical function that functions as
/// reproducible noise.
const _noise = [
  0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee, 0xf57c0faf, 0x4787c62a, //
  0xa8304613, 0xfd469501, 0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be,
  0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821, 0xf61e2562, 0xc040b340,
  0x265e5a51, 0xe9b6c7aa, 0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
  0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed, 0xa9e3e905, 0xfcefa3f8,
  0x676f02d9, 0x8d2a4c8a, 0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c,
  0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70, 0x289b7ec6, 0xeaa127fa,
  0xd4ef3085, 0x04881d05, 0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
  0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039, 0x655b59c3, 0x8f0ccc92,
  0xffeff47d, 0x85845dd1, 0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1,
  0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391
];

/// Per-round shift amounts.
const _shiftAmounts = [
  07, 12, 17, 22, 07, 12, 17, 22, 07, 12, 17, 22, 07, 12, 17, 22, 05, 09, 14, //
  20, 05, 09, 14, 20, 05, 09, 14, 20, 05, 09, 14, 20, 04, 11, 16, 23, 04, 11,
  16, 23, 04, 11, 16, 23, 04, 11, 16, 23, 06, 10, 15, 21, 06, 10, 15, 21, 06,
  10, 15, 21, 06, 10, 15, 21
];

/// The concrete implementation of [MD5].
///
/// This is separate so that it can extend [HashSink] without leaking additional
/// public members.
class _MD5Sink extends HashSink {
  @override
  final digest = Uint32List(4);

  _MD5Sink(Sink<Digest> sink) : super(sink, 16, endian: Endian.little) {
    digest[0] = 0x67452301;
    digest[1] = 0xefcdab89;
    digest[2] = 0x98badcfe;
    digest[3] = 0x10325476;
  }

  @override
  void updateHash(Uint32List chunk) {
    assert(chunk.length == 16);

    var a = digest[0];
    var b = digest[1];
    var c = digest[2];
    var d = digest[3];

    int e;
    int f;

    for (var i = 0; i < 64; i++) {
      if (i < 16) {
        e = (b & c) | ((~b & mask32) & d);
        f = i;
      } else if (i < 32) {
        e = (d & b) | ((~d & mask32) & c);
        f = ((5 * i) + 1) % 16;
      } else if (i < 48) {
        e = b ^ c ^ d;
        f = ((3 * i) + 5) % 16;
      } else {
        e = c ^ (b | (~d & mask32));
        f = (7 * i) % 16;
      }

      var temp = d;
      d = c;
      c = b;
      b = add32(
          b,
          rotl32(add32(add32(a, e), add32(_noise[i], chunk[f])),
              _shiftAmounts[i]));
      a = temp;
    }

    digest[0] = add32(a, digest[0]);
    digest[1] = add32(b, digest[1]);
    digest[2] = add32(c, digest[2]);
    digest[3] = add32(d, digest[3]);
  }
}
