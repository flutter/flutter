// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.convert;

// Character constants.
const int _LF = 10;
const int _CR = 13;

/// A [StreamTransformer] that splits a [String] into individual lines.
///
/// A line is terminated by either:
/// * a CR, carriage return: U+000D ('\r')
/// * a LF, line feed (Unix line break): U+000A ('\n') or
/// * a CR+LF sequence (DOS/Windows line break), and
/// * a final non-empty line can be ended by the end of the input.
///
/// The resulting lines do not contain the line terminators.
///
/// Example:
/// ```dart
/// const splitter = LineSplitter();
/// const sampleText =
///     'Dart is: \r an object-oriented \n class-based \n garbage-collected '
///     '\r\n language with C-style syntax \r\n';
///
/// final sampleTextLines = splitter.convert(sampleText);
/// for (var i = 0; i < sampleTextLines.length; i++) {
///   print('$i: ${sampleTextLines[i]}');
/// }
/// // 0: Dart is:
/// // 1:  an object-oriented
/// // 2:  class-based
/// // 3:  garbage-collected
/// // 4:  language with C-style syntax
/// ```
final class LineSplitter extends StreamTransformerBase<String, String> {
  const LineSplitter();

  /// Split [lines] into individual lines.
  ///
  /// If [start] and [end] are provided, only split the contents of
  /// `lines.substring(start, end)`. The [start] and [end] values must
  /// specify a valid sub-range of [lines]
  /// (`0 <= start <= end <= lines.length`).
  static Iterable<String> split(String lines, [int start = 0, int? end]) {
    end = RangeError.checkValidRange(start, end, lines.length);
    return _LineSplitIterable(lines, start, end);
  }

  List<String> convert(String data) {
    var lines = <String>[];
    var end = data.length;
    var sliceStart = 0;
    var char = 0;
    for (var i = 0; i < end; i++) {
      var previousChar = char;
      char = data.codeUnitAt(i);
      if (char != _CR) {
        if (char != _LF) continue;
        if (previousChar == _CR) {
          sliceStart = i + 1;
          continue;
        }
      }
      lines.add(data.substring(sliceStart, i));
      sliceStart = i + 1;
    }
    if (sliceStart < end) {
      lines.add(data.substring(sliceStart, end));
    }
    return lines;
  }

  StringConversionSink startChunkedConversion(Sink<String> sink) {
    return _LineSplitterSink(
        sink is StringConversionSink ? sink : StringConversionSink.from(sink));
  }

  Stream<String> bind(Stream<String> stream) {
    return Stream<String>.eventTransformed(
        stream, (EventSink<String> sink) => _LineSplitterEventSink(sink));
  }
}

class _LineSplitterSink extends StringConversionSink {
  final StringConversionSink _sink;

  /// The carry-over from the previous chunk.
  ///
  /// If the previous slice ended in a line without a line terminator,
  /// then the next slice may continue the line.
  ///
  /// Set to `null` if there is no carry (the previous chunk ended on
  /// a line break).
  /// Set to an empty string if carry-over comes from multiple chunks,
  /// in which case the parts are stored in [_multiCarry].
  String? _carry;

  /// Cache of multiple parts of carry-over.
  ///
  /// If a line is split over multiple chunks, avoid doing
  /// repeated string concatenation, and instead store the chunks
  /// into this stringbuffer.
  ///
  /// Is empty when `_carry` is `null` or a non-empty string.
  StringBuffer? _multiCarry;

  /// Whether to skip a leading LF character from the next slice.
  ///
  /// If the previous slice ended on a CR character, a following LF
  /// would be part of the same line termination, and should be ignored.
  ///
  /// Only `true` when [_carry] is `null`.
  bool _skipLeadingLF = false;

  _LineSplitterSink(this._sink);

  void addSlice(String chunk, int start, int end, bool isLast) {
    end = RangeError.checkValidRange(start, end, chunk.length);
    // If the chunk is empty, it's probably because it's the last one.
    // Handle that here, so we know the range is non-empty below.
    if (start < end) {
      if (_skipLeadingLF) {
        if (chunk.codeUnitAt(start) == _LF) {
          start += 1;
        }
        _skipLeadingLF = false;
      }
      _addLines(chunk, start, end, isLast);
    }
    if (isLast) close();
  }

  void close() {
    var carry = _carry;
    if (carry != null) {
      _sink.add(_useCarry(carry, ""));
    }
    _sink.close();
  }

  void _addLines(String lines, int start, int end, bool isLast) {
    var sliceStart = start;
    var char = 0;
    var carry = _carry;

    for (var i = start; i < end; i++) {
      var previousChar = char;
      char = lines.codeUnitAt(i);
      if (char != _CR) {
        if (char != _LF) continue;
        if (previousChar == _CR) {
          sliceStart = i + 1;
          continue;
        }
      }
      var slice = lines.substring(sliceStart, i);
      if (carry != null) {
        slice = _useCarry(carry, slice); // Resets _carry to `null`.
        carry = null;
      }
      _sink.add(slice);

      sliceStart = i + 1;
    }

    if (sliceStart < end) {
      var endSlice = lines.substring(sliceStart, end);
      if (isLast) {
        // Emit last line instead of carrying it over to the
        // immediately following `close` call.
        if (carry != null) {
          endSlice = _useCarry(carry, endSlice);
        }
        _sink.add(endSlice);
        return;
      }
      if (carry == null) {
        // Common case, this chunk contained at least one line-break.
        _carry = endSlice;
      } else {
        _addCarry(carry, endSlice);
      }
    } else {
      _skipLeadingLF = (char == _CR);
    }
  }

  /// Adds [newCarry] to existing carry-over.
  ///
  /// Always goes into [_multiCarry], we only call here if there
  /// was an existing carry that the new carry needs to be combined with.
  ///
  /// Only happens when a line is spread over more than two chunks.
  /// The [existingCarry] is always the current value of [_carry].
  /// (We pass the existing carry as an argument because we have already
  /// checked that it is non-`null`.)
  void _addCarry(String existingCarry, String newCarry) {
    assert(existingCarry == _carry);
    assert(newCarry.isNotEmpty);
    var multiCarry = _multiCarry ??= StringBuffer();
    if (existingCarry.isNotEmpty) {
      assert(multiCarry.isEmpty);
      multiCarry.write(existingCarry);
      _carry = "";
    }
    multiCarry.write(newCarry);
  }

  /// Consumes and combines existing carry-over with continuation string.
  ///
  /// The [carry] value is always the current value of [_carry],
  /// which is non-`null` when this method is called.
  /// If that value is the empty string, the actual carry-over is stored
  /// in [_multiCarry].
  ///
  /// The [continuation] is only empty if called from [close].
  String _useCarry(String carry, String continuation) {
    assert(carry == _carry);
    _carry = null;
    if (carry.isNotEmpty) {
      return carry + continuation;
    }
    var multiCarry = _multiCarry!;
    multiCarry.write(continuation);
    var result = multiCarry.toString();
    // If it happened once, it may happen again.
    // Keep the string buffer around.
    multiCarry.clear();
    return result;
  }
}

class _LineSplitterEventSink extends _LineSplitterSink
    implements EventSink<String> {
  final EventSink<String> _eventSink;

  _LineSplitterEventSink(EventSink<String> eventSink)
      : _eventSink = eventSink,
        super(StringConversionSink.from(eventSink));

  void addError(Object o, [StackTrace? stackTrace]) {
    _eventSink.addError(o, stackTrace);
  }
}

class _LineSplitIterable extends Iterable<String> {
  final String _source;
  final int _start, _end;
  _LineSplitIterable(this._source, this._start, this._end);
  Iterator<String> get iterator => _LineSplitIterator(_source, _start, _end);
}

class _LineSplitIterator implements Iterator<String> {
  final String _source;
  final int _end;
  int _start;
  int _lineStart = 0;
  int _lineEnd = -1;
  String? _current;
  _LineSplitIterator(this._source, this._start, this._end);

  bool moveNext() {
    _current = null;
    _lineStart = _start;
    _lineEnd = -1;
    var eolLength = 1;
    for (var i = _start; i < _end; i++) {
      var char = _source.codeUnitAt(i);
      if (char != _CR) {
        if (char != _LF) continue;
      } else {
        // Check for CR+LF
        if (i + 1 < _end && _source.codeUnitAt(i + 1) == _LF) {
          eolLength = 2;
        }
      }
      _lineEnd = i;
      _start = i + eolLength;
      return true;
    }
    if (_start < _end) {
      _lineEnd = _end;
      _start = _end;
      return true;
    }
    _start = _end;
    return false;
  }

  // Creates string lazily on first request.
  // Makes it cheaper to do `LineSplitter.split(input).skip(5)...`.
  String get current => _current ??= (_lineEnd >= 0
      ? _source.substring(_lineStart, _lineEnd)
      : (throw StateError("No element")));
}
