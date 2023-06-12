// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:typed_data/typed_data.dart';

import 'charcodes.dart';

/// The canonical instance of [ChunkedCodingDecoder].
const chunkedCodingDecoder = ChunkedCodingDecoder._();

/// A converter that decodes byte arrays into chunks with size tags.
class ChunkedCodingDecoder extends Converter<List<int>, List<int>> {
  const ChunkedCodingDecoder._();

  @override
  List<int> convert(List<int> input) {
    final sink = _Sink(StreamController());
    final output = sink._decode(input, 0, input.length);
    if (sink._state == _State.end) return output;

    throw FormatException('Input ended unexpectedly.', input, input.length);
  }

  @override
  ByteConversionSink startChunkedConversion(Sink<List<int>> sink) =>
      _Sink(sink);
}

/// A conversion sink for the chunked transfer encoding.
class _Sink extends ByteConversionSinkBase {
  /// The underlying sink to which decoded byte arrays will be passed.
  final Sink<List<int>> _sink;

  /// The current state of the sink's parsing.
  var _state = _State.boundary;

  /// The size of the chunk being parsed.
  ///
  /// Only assigned and used within [_decode].
  late int _size;

  _Sink(this._sink);

  @override
  void add(List<int> chunk) => addSlice(chunk, 0, chunk.length, false);

  @override
  void addSlice(List<int> chunk, int start, int end, bool isLast) {
    RangeError.checkValidRange(start, end, chunk.length);
    final output = _decode(chunk, start, end);
    if (output.isNotEmpty) _sink.add(output);
    if (isLast) _close(chunk, end);
  }

  @override
  void close() => _close();

  /// Like [close], but includes [chunk] and [index] in the [FormatException] if
  /// one is thrown.
  void _close([List<int>? chunk, int? index]) {
    if (_state != _State.end) {
      throw FormatException('Input ended unexpectedly.', chunk, index);
    }

    _sink.close();
  }

  /// Decodes the data in [bytes] from [start] to [end].
  Uint8List _decode(List<int> bytes, int start, int end) {
    /// Throws a [FormatException] if `bytes[start] != $char`. Uses [name] to
    /// describe the character in the exception text.
    void assertCurrentChar(int char, String name) {
      if (bytes[start] != char) {
        throw FormatException('Expected $name.', bytes, start);
      }
    }

    final buffer = Uint8Buffer();
    while (start != end) {
      switch (_state) {
        case _State.boundary:
          _size = _digitForByte(bytes, start);
          _state = _State.size;
          start++;
          break;

        case _State.size:
          if (bytes[start] == $cr) {
            _state = _State.sizeBeforeLF;
          } else {
            // Shift four bits left since a single hex digit contains four bits
            // of information.
            _size = (_size << 4) + _digitForByte(bytes, start);
          }
          start++;
          break;

        case _State.sizeBeforeLF:
          assertCurrentChar($lf, 'LF');
          _state = _size == 0 ? _State.endBeforeCR : _State.body;
          start++;
          break;

        case _State.body:
          final chunkEnd = math.min(end, start + _size);
          buffer.addAll(bytes, start, chunkEnd);
          _size -= chunkEnd - start;
          start = chunkEnd;
          if (_size == 0) _state = _State.bodyBeforeCR;
          break;

        case _State.bodyBeforeCR:
          assertCurrentChar($cr, 'CR');
          _state = _State.bodyBeforeLF;
          start++;
          break;

        case _State.bodyBeforeLF:
          assertCurrentChar($lf, 'LF');
          _state = _State.boundary;
          start++;
          break;

        case _State.endBeforeCR:
          assertCurrentChar($cr, 'CR');
          _state = _State.endBeforeLF;
          start++;
          break;

        case _State.endBeforeLF:
          assertCurrentChar($lf, 'LF');
          _state = _State.end;
          start++;
          break;

        case _State.end:
          throw FormatException('Expected no more data.', bytes, start);
      }
    }
    return buffer.buffer.asUint8List(0, buffer.length);
  }

  /// Returns the hex digit (0 through 15) corresponding to the byte at index
  /// [index] in [bytes].
  ///
  /// If the given byte isn't a hexadecimal ASCII character, throws a
  /// [FormatException].
  int _digitForByte(List<int> bytes, int index) {
    // If the byte is a numeral, get its value. XOR works because 0 in ASCII is
    // `0b110000` and the other numerals come after it in ascending order and
    // take up at most four bits.
    //
    // We check for digits first because it ensures there's only a single branch
    // for 10 out of 16 of the expected cases. We don't count the `digit >= 0`
    // check because branch prediction will always work on it for valid data.
    final byte = bytes[index];
    final digit = $0 ^ byte;
    if (digit <= 9) {
      if (digit >= 0) return digit;
    } else {
      // If the byte is an uppercase letter, convert it to lowercase. This works
      // because uppercase letters in ASCII are exactly `0b100000 = 0x20` less
      // than lowercase letters, so if we ensure that that bit is 1 we ensure
      // that the letter is lowercase.
      final letter = 0x20 | byte;
      if ($a <= letter && letter <= $f) return letter - $a + 10;
    }

    throw FormatException(
        'Invalid hexadecimal byte 0x${byte.toRadixString(16).toUpperCase()}.',
        bytes,
        index);
  }
}

/// An enumeration of states that [_Sink] can exist in when decoded a chunked
/// message.
class _State {
  /// The parser has fully parsed one chunk and is expecting the header for the
  /// next chunk.
  ///
  /// Transitions to [size].
  static const boundary = _State._('boundary');

  /// The parser has parsed at least one digit of the chunk size header, but has
  /// not yet parsed the `CR LF` sequence that indicates the end of that header.
  ///
  /// Transitions to [sizeBeforeLF].
  static const size = _State._('size');

  /// The parser has parsed the chunk size header and the CR character after it,
  /// but not the LF.
  ///
  /// Transitions to [body] or [bodyBeforeCR].
  static const sizeBeforeLF = _State._('size before LF');

  /// The parser has parsed a chunk header and possibly some of the body, but
  /// still needs to consume more bytes.
  ///
  /// Transitions to [bodyBeforeCR].
  static const body = _State._('body');

  // The parser has parsed all the bytes in a chunk body but not the CR LF
  // sequence that follows it.
  //
  // Transitions to [bodyBeforeLF].
  static const bodyBeforeCR = _State._('body before CR');

  // The parser has parsed all the bytes in a chunk body and the CR that follows
  // it, but not the LF after that.
  //
  // Transitions to [bounday].
  static const bodyBeforeLF = _State._('body before LF');

  /// The parser has parsed the final empty chunk but not the CR LF sequence
  /// that follows it.
  ///
  /// Transitions to [endBeforeLF].
  static const endBeforeCR = _State._('end before CR');

  /// The parser has parsed the final empty chunk and the CR that follows it,
  /// but not the LF after that.
  ///
  /// Transitions to [end].
  static const endBeforeLF = _State._('end before LF');

  /// The parser has parsed the final empty chunk as well as the CR LF that
  /// follows, and expects no more data.
  static const end = _State._('end');

  final String _name;

  const _State._(this._name);

  @override
  String toString() => _name;
}
