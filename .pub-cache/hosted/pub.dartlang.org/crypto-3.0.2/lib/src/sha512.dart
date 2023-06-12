// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'digest.dart';
import 'hash.dart';
// ignore: uri_does_not_exist
import 'sha512_fastsinks.dart' if (dart.library.js) 'sha512_slowsinks.dart';
import 'utils.dart';

/// An implementation of the [SHA-384][rfc] hash function.
///
/// [rfc]: http://tools.ietf.org/html/rfc6234
const Hash sha384 = _Sha384._();

/// An implementation of the [SHA-512][rfc] hash function.
///
/// [rfc]: http://tools.ietf.org/html/rfc6234
const Hash sha512 = _Sha512._();

/// An implementation of the [SHA-512/224][FIPS] hash function.
///
/// [FIPS]: https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.180-4.pdf
const Hash sha512224 = _Sha512224();

/// An implementation of the [SHA-512/256][FIPS] hash function.
///
/// [FIPS]: https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.180-4.pdf
const Hash sha512256 = _Sha512256();

/// An implementation of the [SHA-384][rfc] hash function.
///
/// [rfc]: http://tools.ietf.org/html/rfc6234
///
/// Use the [sha384] object to perform SHA-384 hashing
class _Sha384 extends Hash {
  @override
  final int blockSize = 32 * bytesPerWord;

  const _Sha384._();

  @override
  ByteConversionSink startChunkedConversion(Sink<Digest> sink) =>
      ByteConversionSink.from(Sha384Sink(sink));
}

/// An implementation of the [SHA-512][rfc] hash function.
///
/// [rfc]: http://tools.ietf.org/html/rfc6234
///
/// Use the [sha512] object to perform SHA-512 hashing
class _Sha512 extends Hash {
  @override
  final int blockSize = 32 * bytesPerWord;

  const _Sha512._();

  @override
  ByteConversionSink startChunkedConversion(Sink<Digest> sink) =>
      ByteConversionSink.from(Sha512Sink(sink));
}

/// An implementation of the [SHA-512/224][FIPS] hash function.
///
/// [FIPS]: https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.180-4.pdf
///
/// Use the [sha512224] object to perform SHA-512/224 hashing
class _Sha512224 extends Hash {
  @override
  final int blockSize = 32 * bytesPerWord;

  const _Sha512224();

  @override
  ByteConversionSink startChunkedConversion(Sink<Digest> sink) =>
      ByteConversionSink.from(Sha512224Sink(sink));
}

/// An implementation of the [SHA-512/256][FIPS] hash function.
///
/// [FIPS]: https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.180-4.pdf
///
/// Use the [sha512256] object to perform SHA-512/256 hashing
class _Sha512256 extends Hash {
  @override
  final int blockSize = 32 * bytesPerWord;

  const _Sha512256();

  @override
  ByteConversionSink startChunkedConversion(Sink<Digest> sink) =>
      ByteConversionSink.from(Sha512256Sink(sink));
}
