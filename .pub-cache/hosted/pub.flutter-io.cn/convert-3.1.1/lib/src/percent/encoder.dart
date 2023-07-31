// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library convert.percent.encoder;

import 'dart:convert';

import '../charcodes.dart';

/// The canonical instance of [PercentEncoder].
const percentEncoder = PercentEncoder._();

/// A converter that encodes byte arrays into percent-encoded strings.
///
/// Encodes all bytes other than ASCII letters, decimal digits, or one
/// of `-._~`. This matches the behavior of [Uri.encodeQueryComponent] except
/// that it doesn't encode `0x20` bytes to the `+` character.
///
/// This will throw a [RangeError] if the byte array has any digits that don't
/// fit in the gamut of a byte.
class PercentEncoder extends Converter<List<int>, String> {
  const PercentEncoder._();

  @override
  String convert(List<int> input) => _convert(input, 0, input.length);

  @override
  ByteConversionSink startChunkedConversion(Sink<String> sink) =>
      _PercentEncoderSink(sink);
}

/// A conversion sink for chunked percentadecimal encoding.
class _PercentEncoderSink extends ByteConversionSinkBase {
  /// The underlying sink to which decoded byte arrays will be passed.
  final Sink<String> _sink;

  _PercentEncoderSink(this._sink);

  @override
  void add(List<int> chunk) {
    _sink.add(_convert(chunk, 0, chunk.length));
  }

  @override
  void addSlice(List<int> chunk, int start, int end, bool isLast) {
    RangeError.checkValidRange(start, end, chunk.length);
    _sink.add(_convert(chunk, start, end));
    if (isLast) _sink.close();
  }

  @override
  void close() {
    _sink.close();
  }
}

String _convert(List<int> bytes, int start, int end) {
  var buffer = StringBuffer();

  // A bitwise OR of all bytes in [bytes]. This allows us to check for
  // out-of-range bytes without adding more branches than necessary to the
  // core loop.
  var byteOr = 0;
  for (var i = start; i < end; i++) {
    var byte = bytes[i];
    byteOr |= byte;

    // If the byte is an uppercase letter, convert it to lowercase to check if
    // it's unreserved. This works because uppercase letters in ASCII are
    // exactly `0b100000 = 0x20` less than lowercase letters, so if we ensure
    // that that bit is 1 we ensure that the letter is lowercase.
    var letter = 0x20 | byte;
    if ((letter >= $a && letter <= $z) ||
        (byte >= $0 && byte <= $9) ||
        byte == $dash ||
        byte == $dot ||
        byte == $underscore ||
        byte == $tilde) {
      // Unreserved characters are safe to write as-is.
      buffer.writeCharCode(byte);
      continue;
    }

    buffer.writeCharCode($percent);

    // The bitwise arithmetic here is equivalent to `byte ~/ 16` and `byte % 16`
    // for valid byte values, but is easier for dart2js to optimize given that
    // it can't prove that [byte] will always be positive.
    buffer.writeCharCode(_codeUnitForDigit((byte & 0xF0) >> 4));
    buffer.writeCharCode(_codeUnitForDigit(byte & 0x0F));
  }

  if (byteOr >= 0 && byteOr <= 255) return buffer.toString();

  // If there was an invalid byte, find it and throw an exception.
  for (var i = start; i < end; i++) {
    var byte = bytes[i];
    if (byte >= 0 && byte <= 0xff) continue;
    throw FormatException(
        "Invalid byte ${byte < 0 ? "-" : ""}0x${byte.abs().toRadixString(16)}.",
        bytes,
        i);
  }

  throw StateError('unreachable');
}

/// Returns the ASCII/Unicode code unit corresponding to the hexadecimal digit
/// [digit].
int _codeUnitForDigit(int digit) => digit < 10 ? digit + $0 : digit + $A - 10;
