// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'digest.dart';
import 'hash.dart';
import 'hash_sink.dart';
import 'utils.dart';

/// An implementation of the [SHA-1][rfc] hash function.
///
/// [rfc]: http://tools.ietf.org/html/rfc3174
const Hash sha1 = _Sha1._();

/// An implementation of the [SHA-1][rfc] hash function.
///
/// [rfc]: http://tools.ietf.org/html/rfc3174
class _Sha1 extends Hash {
  @override
  final int blockSize = 16 * bytesPerWord;

  const _Sha1._();

  @override
  ByteConversionSink startChunkedConversion(Sink<Digest> sink) =>
      ByteConversionSink.from(_Sha1Sink(sink));
}

/// The concrete implementation of [Sha1].
///
/// This is separate so that it can extend [HashSink] without leaking additional
/// public members.
class _Sha1Sink extends HashSink {
  @override
  final digest = Uint32List(5);

  /// The sixteen words from the original chunk, extended to 80 words.
  ///
  /// This is an instance variable to avoid re-allocating, but its data isn't
  /// used across invocations of [updateHash].
  final Uint32List _extended;

  _Sha1Sink(Sink<Digest> sink)
      : _extended = Uint32List(80),
        super(sink, 16) {
    digest[0] = 0x67452301;
    digest[1] = 0xEFCDAB89;
    digest[2] = 0x98BADCFE;
    digest[3] = 0x10325476;
    digest[4] = 0xC3D2E1F0;
  }

  @override
  void updateHash(Uint32List chunk) {
    assert(chunk.length == 16);

    var a = digest[0];
    var b = digest[1];
    var c = digest[2];
    var d = digest[3];
    var e = digest[4];

    for (var i = 0; i < 80; i++) {
      if (i < 16) {
        _extended[i] = chunk[i];
      } else {
        _extended[i] = rotl32(
            _extended[i - 3] ^
                _extended[i - 8] ^
                _extended[i - 14] ^
                _extended[i - 16],
            1);
      }

      var newA = add32(add32(rotl32(a, 5), e), _extended[i]);
      if (i < 20) {
        newA = add32(add32(newA, (b & c) | (~b & d)), 0x5A827999);
      } else if (i < 40) {
        newA = add32(add32(newA, (b ^ c ^ d)), 0x6ED9EBA1);
      } else if (i < 60) {
        newA = add32(add32(newA, (b & c) | (b & d) | (c & d)), 0x8F1BBCDC);
      } else {
        newA = add32(add32(newA, b ^ c ^ d), 0xCA62C1D6);
      }

      e = d;
      d = c;
      c = rotl32(b, 30);
      b = a;
      a = newA & mask32;
    }

    digest[0] = add32(a, digest[0]);
    digest[1] = add32(b, digest[1]);
    digest[2] = add32(c, digest[2]);
    digest[3] = add32(d, digest[3]);
    digest[4] = add32(e, digest[4]);
  }
}
