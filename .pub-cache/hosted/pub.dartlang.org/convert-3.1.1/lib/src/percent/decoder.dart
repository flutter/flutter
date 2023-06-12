// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library convert.percent.decoder;

import 'dart:convert';

import 'package:typed_data/typed_data.dart';

import '../charcodes.dart';
import '../utils.dart';

/// The canonical instance of [PercentDecoder].
const percentDecoder = PercentDecoder._();

const _lastPercent = -1;

/// A converter that decodes percent-encoded strings into byte arrays.
///
/// To be maximally flexible, this will decode any percent-encoded byte and
/// will allow any non-percent-encoded byte other than `%`. By default, it
/// interprets `+` as `0x2B` rather than `0x20` as emitted by
/// [Uri.encodeQueryComponent].
///
/// This will throw a [FormatException] if the input string has an incomplete
/// percent-encoding, or if it contains non-ASCII code units.
class PercentDecoder extends Converter<String, List<int>> {
  const PercentDecoder._();

  @override
  List<int> convert(String input) {
    var buffer = Uint8Buffer();
    var lastDigit = _decode(input.codeUnits, 0, input.length, buffer);

    if (lastDigit != null) {
      throw FormatException(
          'Input ended with incomplete encoded byte.', input, input.length);
    }

    return buffer.buffer.asUint8List(0, buffer.length);
  }

  @override
  StringConversionSink startChunkedConversion(Sink<List<int>> sink) =>
      _PercentDecoderSink(sink);
}

/// A conversion sink for chunked percent-encoded decoding.
class _PercentDecoderSink extends StringConversionSinkBase {
  /// The underlying sink to which decoded byte arrays will be passed.
  final Sink<List<int>> _sink;

  /// The trailing digit from the previous string.
  ///
  /// This is `null` if the previous string ended with a complete
  /// percent-encoded byte or a literal character. It's [_lastPercent] if the
  /// most recent string ended with `%`. Otherwise, the most recent string ended
  /// with a `%` followed by a hexadecimal digit, and this is that digit. Since
  /// it's the most significant digit, it's always a multiple of 16.
  int? _lastDigit;

  _PercentDecoderSink(this._sink);

  @override
  void addSlice(String string, int start, int end, bool isLast) {
    RangeError.checkValidRange(start, end, string.length);

    if (start == end) {
      if (isLast) _close(string, end);
      return;
    }

    var buffer = Uint8Buffer();
    var codeUnits = string.codeUnits;
    if (_lastDigit == _lastPercent) {
      _lastDigit = 16 * digitForCodeUnit(codeUnits, start);
      start++;

      if (start == end) {
        if (isLast) _close(string, end);
        return;
      }
    }

    if (_lastDigit != null) {
      buffer.add(_lastDigit! + digitForCodeUnit(codeUnits, start));
      start++;
    }

    _lastDigit = _decode(codeUnits, start, end, buffer);

    _sink.add(buffer.buffer.asUint8List(0, buffer.length));
    if (isLast) _close(string, end);
  }

  @override
  ByteConversionSink asUtf8Sink(bool allowMalformed) =>
      _PercentDecoderByteSink(_sink);

  @override
  void close() => _close();

  /// Like [close], but includes [string] and [index] in the [FormatException]
  /// if one is thrown.
  void _close([String? string, int? index]) {
    if (_lastDigit != null) {
      throw FormatException(
          'Input ended with incomplete encoded byte.', string, index);
    }

    _sink.close();
  }
}

/// A conversion sink for chunked percent-encoded decoding from UTF-8 bytes.
class _PercentDecoderByteSink extends ByteConversionSinkBase {
  /// The underlying sink to which decoded byte arrays will be passed.
  final Sink<List<int>> _sink;

  /// The trailing digit from the previous string.
  ///
  /// This is `null` if the previous string ended with a complete
  /// percent-encoded byte or a literal character. It's [_lastPercent] if the
  /// most recent string ended with `%`. Otherwise, the most recent string ended
  /// with a `%` followed by a hexadecimal digit, and this is that digit. Since
  /// it's the most significant digit, it's always a multiple of 16.
  int? _lastDigit;

  _PercentDecoderByteSink(this._sink);

  @override
  void add(List<int> chunk) => addSlice(chunk, 0, chunk.length, false);

  @override
  void addSlice(List<int> chunk, int start, int end, bool isLast) {
    RangeError.checkValidRange(start, end, chunk.length);

    if (start == end) {
      if (isLast) _close(chunk, end);
      return;
    }

    var buffer = Uint8Buffer();
    if (_lastDigit == _lastPercent) {
      _lastDigit = 16 * digitForCodeUnit(chunk, start);
      start++;

      if (start == end) {
        if (isLast) _close(chunk, end);
        return;
      }
    }

    if (_lastDigit != null) {
      buffer.add(_lastDigit! + digitForCodeUnit(chunk, start));
      start++;
    }

    _lastDigit = _decode(chunk, start, end, buffer);

    _sink.add(buffer.buffer.asUint8List(0, buffer.length));
    if (isLast) _close(chunk, end);
  }

  @override
  void close() => _close();

  /// Like [close], but includes [chunk] and [index] in the [FormatException]
  /// if one is thrown.
  void _close([List<int>? chunk, int? index]) {
    if (_lastDigit != null) {
      throw FormatException(
          'Input ended with incomplete encoded byte.', chunk, index);
    }

    _sink.close();
  }
}

/// Decodes [codeUnits] and writes the result into [buffer].
///
/// This reads from [codeUnits] between [start] and [end]. It writes
/// the result into [buffer] starting at [end].
///
/// If there's a leftover digit at the end of the decoding, this returns that
/// digit. Otherwise it returns `null`.
int? _decode(List<int> codeUnits, int start, int end, Uint8Buffer buffer) {
  // A bitwise OR of all code units in [codeUnits]. This allows us to check for
  // out-of-range code units without adding more branches than necessary to the
  // core loop.
  var codeUnitOr = 0;

  // The beginning of the current slice of adjacent non-% characters. We can add
  // all of these to the buffer at once.
  var sliceStart = start;
  for (var i = start; i < end; i++) {
    // First, loop through non-% characters.
    var codeUnit = codeUnits[i];
    if (codeUnits[i] != $percent) {
      codeUnitOr |= codeUnit;
      continue;
    }

    // We found a %. The slice from `sliceStart` to `i` represents characters
    // than can be copied to the buffer as-is.
    if (i > sliceStart) {
      _checkForInvalidCodeUnit(codeUnitOr, codeUnits, sliceStart, i);
      buffer.addAll(codeUnits, sliceStart, i);
    }

    // Now decode the percent-encoded byte and add it as well.
    i++;
    if (i >= end) return _lastPercent;

    var firstDigit = digitForCodeUnit(codeUnits, i);
    i++;
    if (i >= end) return 16 * firstDigit;

    var secondDigit = digitForCodeUnit(codeUnits, i);
    buffer.add(16 * firstDigit + secondDigit);

    // The next iteration will look for non-% characters again.
    sliceStart = i + 1;
  }

  if (end > sliceStart) {
    _checkForInvalidCodeUnit(codeUnitOr, codeUnits, sliceStart, end);
    if (start == sliceStart) {
      buffer.addAll(codeUnits);
    } else {
      buffer.addAll(codeUnits, sliceStart, end);
    }
  }

  return null;
}

void _checkForInvalidCodeUnit(
    int codeUnitOr, List<int> codeUnits, int start, int end) {
  if (codeUnitOr >= 0 && codeUnitOr <= 0x7f) return;

  for (var i = start; i < end; i++) {
    var codeUnit = codeUnits[i];
    if (codeUnit >= 0 && codeUnit <= 0x7f) continue;
    throw FormatException(
        'Non-ASCII code unit '
        "U+${codeUnit.toRadixString(16).padLeft(4, '0')}",
        codeUnits,
        i);
  }
}
