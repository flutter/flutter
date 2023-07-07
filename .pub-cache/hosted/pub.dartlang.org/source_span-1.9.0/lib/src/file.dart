// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'dart:typed_data';

import 'location.dart';
import 'location_mixin.dart';
import 'span.dart';
import 'span_mixin.dart';
import 'span_with_context.dart';

// Constants to determine end-of-lines.
const int _lf = 10;
const int _cr = 13;

/// A class representing a source file.
///
/// This doesn't necessarily have to correspond to a file on disk, just a chunk
/// of text usually with a URL associated with it.
class SourceFile {
  /// The URL where the source file is located.
  ///
  /// This may be null, indicating that the URL is unknown or unavailable.
  final Uri? url;

  /// An array of offsets for each line beginning in the file.
  ///
  /// Each offset refers to the first character *after* the newline. If the
  /// source file has a trailing newline, the final offset won't actually be in
  /// the file.
  final _lineStarts = <int>[0];

  /// The code points of the characters in the file.
  final Uint32List _decodedChars;

  /// The length of the file in characters.
  int get length => _decodedChars.length;

  /// The number of lines in the file.
  int get lines => _lineStarts.length;

  /// The line that the offset fell on the last time [getLine] was called.
  ///
  /// In many cases, sequential calls to getLine() are for nearby, usually
  /// increasing offsets. In that case, we can find the line for an offset
  /// quickly by first checking to see if the offset is on the same line as the
  /// previous result.
  int? _cachedLine;

  /// This constructor is deprecated.
  ///
  /// Use [new SourceFile.fromString] instead.
  @Deprecated('Will be removed in 2.0.0')
  SourceFile(String text, {url}) : this.decoded(text.runes, url: url);

  /// Creates a new source file from [text].
  ///
  /// [url] may be either a [String], a [Uri], or `null`.
  SourceFile.fromString(String text, {url})
      : this.decoded(text.codeUnits, url: url);

  /// Creates a new source file from a list of decoded code units.
  ///
  /// [url] may be either a [String], a [Uri], or `null`.
  ///
  /// Currently, if [decodedChars] contains characters larger than `0xFFFF`,
  /// they'll be treated as single characters rather than being split into
  /// surrogate pairs. **This behavior is deprecated**. For
  /// forwards-compatibility, callers should only pass in characters less than
  /// or equal to `0xFFFF`.
  SourceFile.decoded(Iterable<int> decodedChars, {url})
      : url = url is String ? Uri.parse(url) : url as Uri?,
        _decodedChars = Uint32List.fromList(decodedChars.toList()) {
    for (var i = 0; i < _decodedChars.length; i++) {
      var c = _decodedChars[i];
      if (c == _cr) {
        // Return not followed by newline is treated as a newline
        final j = i + 1;
        if (j >= _decodedChars.length || _decodedChars[j] != _lf) c = _lf;
      }
      if (c == _lf) _lineStarts.add(i + 1);
    }
  }

  /// Returns a span from [start] to [end] (exclusive).
  ///
  /// If [end] isn't passed, it defaults to the end of the file.
  FileSpan span(int start, [int? end]) {
    end ??= length;
    return _FileSpan(this, start, end);
  }

  /// Returns a location at [offset].
  FileLocation location(int offset) => FileLocation._(this, offset);

  /// Gets the 0-based line corresponding to [offset].
  int getLine(int offset) {
    if (offset < 0) {
      throw RangeError('Offset may not be negative, was $offset.');
    } else if (offset > length) {
      throw RangeError('Offset $offset must not be greater than the number '
          'of characters in the file, $length.');
    }

    if (offset < _lineStarts.first) return -1;
    if (offset >= _lineStarts.last) return _lineStarts.length - 1;

    if (_isNearCachedLine(offset)) return _cachedLine!;

    _cachedLine = _binarySearch(offset) - 1;
    return _cachedLine!;
  }

  /// Returns `true` if [offset] is near [_cachedLine].
  ///
  /// Checks on [_cachedLine] and the next line. If it's on the next line, it
  /// updates [_cachedLine] to point to that.
  bool _isNearCachedLine(int offset) {
    if (_cachedLine == null) return false;
    final cachedLine = _cachedLine!;

    // See if it's before the cached line.
    if (offset < _lineStarts[cachedLine]) return false;

    // See if it's on the cached line.
    if (cachedLine >= _lineStarts.length - 1 ||
        offset < _lineStarts[cachedLine + 1]) {
      return true;
    }

    // See if it's on the next line.
    if (cachedLine >= _lineStarts.length - 2 ||
        offset < _lineStarts[cachedLine + 2]) {
      _cachedLine = cachedLine + 1;
      return true;
    }

    return false;
  }

  /// Binary search through [_lineStarts] to find the line containing [offset].
  ///
  /// Returns the index of the line in [_lineStarts].
  int _binarySearch(int offset) {
    var min = 0;
    var max = _lineStarts.length - 1;
    while (min < max) {
      final half = min + ((max - min) ~/ 2);
      if (_lineStarts[half] > offset) {
        max = half;
      } else {
        min = half + 1;
      }
    }

    return max;
  }

  /// Gets the 0-based column corresponding to [offset].
  ///
  /// If [line] is passed, it's assumed to be the line containing [offset] and
  /// is used to more efficiently compute the column.
  int getColumn(int offset, {int? line}) {
    if (offset < 0) {
      throw RangeError('Offset may not be negative, was $offset.');
    } else if (offset > length) {
      throw RangeError('Offset $offset must be not be greater than the '
          'number of characters in the file, $length.');
    }

    if (line == null) {
      line = getLine(offset);
    } else if (line < 0) {
      throw RangeError('Line may not be negative, was $line.');
    } else if (line >= lines) {
      throw RangeError('Line $line must be less than the number of '
          'lines in the file, $lines.');
    }

    final lineStart = _lineStarts[line];
    if (lineStart > offset) {
      throw RangeError('Line $line comes after offset $offset.');
    }

    return offset - lineStart;
  }

  /// Gets the offset for a [line] and [column].
  ///
  /// [column] defaults to 0.
  int getOffset(int line, [int? column]) {
    column ??= 0;

    if (line < 0) {
      throw RangeError('Line may not be negative, was $line.');
    } else if (line >= lines) {
      throw RangeError('Line $line must be less than the number of '
          'lines in the file, $lines.');
    } else if (column < 0) {
      throw RangeError('Column may not be negative, was $column.');
    }

    final result = _lineStarts[line] + column;
    if (result > length ||
        (line + 1 < lines && result >= _lineStarts[line + 1])) {
      throw RangeError("Line $line doesn't have $column columns.");
    }

    return result;
  }

  /// Returns the text of the file from [start] to [end] (exclusive).
  ///
  /// If [end] isn't passed, it defaults to the end of the file.
  String getText(int start, [int? end]) =>
      String.fromCharCodes(_decodedChars.sublist(start, end));
}

/// A [SourceLocation] within a [SourceFile].
///
/// Unlike the base [SourceLocation], [FileLocation] lazily computes its line
/// and column values based on its offset and the contents of [file].
///
/// A [FileLocation] can be created using [SourceFile.location].
class FileLocation extends SourceLocationMixin implements SourceLocation {
  /// The [file] that `this` belongs to.
  final SourceFile file;

  @override
  final int offset;

  @override
  Uri? get sourceUrl => file.url;

  @override
  int get line => file.getLine(offset);

  @override
  int get column => file.getColumn(offset);

  FileLocation._(this.file, this.offset) {
    if (offset < 0) {
      throw RangeError('Offset may not be negative, was $offset.');
    } else if (offset > file.length) {
      throw RangeError('Offset $offset must not be greater than the number '
          'of characters in the file, ${file.length}.');
    }
  }

  @override
  FileSpan pointSpan() => _FileSpan(file, offset, offset);
}

/// A [SourceSpan] within a [SourceFile].
///
/// Unlike the base [SourceSpan], [FileSpan] lazily computes its line and column
/// values based on its offset and the contents of [file]. [SourceSpan.message]
/// is also able to provide more context then [SourceSpan.message], and
/// [SourceSpan.union] will return a [FileSpan] if possible.
///
/// A [FileSpan] can be created using [SourceFile.span].
abstract class FileSpan implements SourceSpanWithContext {
  /// The [file] that `this` belongs to.
  SourceFile get file;

  @override
  FileLocation get start;

  @override
  FileLocation get end;

  /// Returns a new span that covers both `this` and [other].
  ///
  /// Unlike [union], [other] may be disjoint from `this`. If it is, the text
  /// between the two will be covered by the returned span.
  FileSpan expand(FileSpan other);
}

/// The implementation of [FileSpan].
///
/// This is split into a separate class so that `is _FileSpan` checks can be run
/// to make certain operations more efficient. If we used `is FileSpan`, that
/// would break if external classes implemented the interface.
class _FileSpan extends SourceSpanMixin implements FileSpan {
  @override
  final SourceFile file;

  /// The offset of the beginning of the span.
  ///
  /// [start] is lazily generated from this to avoid allocating unnecessary
  /// objects.
  final int _start;

  /// The offset of the end of the span.
  ///
  /// [end] is lazily generated from this to avoid allocating unnecessary
  /// objects.
  final int _end;

  @override
  Uri? get sourceUrl => file.url;

  @override
  int get length => _end - _start;

  @override
  FileLocation get start => FileLocation._(file, _start);

  @override
  FileLocation get end => FileLocation._(file, _end);

  @override
  String get text => file.getText(_start, _end);

  @override
  String get context {
    final endLine = file.getLine(_end);
    final endColumn = file.getColumn(_end);

    int? endOffset;
    if (endColumn == 0 && endLine != 0) {
      // If [end] is at the very beginning of the line, the span covers the
      // previous newline, so we only want to include the previous line in the
      // context...

      if (length == 0) {
        // ...unless this is a point span, in which case we want to include the
        // next line (or the empty string if this is the end of the file).
        return endLine == file.lines - 1
            ? ''
            : file.getText(
                file.getOffset(endLine), file.getOffset(endLine + 1));
      }

      endOffset = _end;
    } else if (endLine == file.lines - 1) {
      // If the span covers the last line of the file, the context should go all
      // the way to the end of the file.
      endOffset = file.length;
    } else {
      // Otherwise, the context should cover the full line on which [end]
      // appears.
      endOffset = file.getOffset(endLine + 1);
    }

    return file.getText(file.getOffset(file.getLine(_start)), endOffset);
  }

  _FileSpan(this.file, this._start, this._end) {
    if (_end < _start) {
      throw ArgumentError('End $_end must come after start $_start.');
    } else if (_end > file.length) {
      throw RangeError('End $_end must not be greater than the number '
          'of characters in the file, ${file.length}.');
    } else if (_start < 0) {
      throw RangeError('Start may not be negative, was $_start.');
    }
  }

  @override
  int compareTo(SourceSpan other) {
    if (other is! _FileSpan) return super.compareTo(other);

    final result = _start.compareTo(other._start);
    return result == 0 ? _end.compareTo(other._end) : result;
  }

  @override
  SourceSpan union(SourceSpan other) {
    if (other is! FileSpan) return super.union(other);

    final span = expand(other);

    if (other is _FileSpan) {
      if (_start > other._end || other._start > _end) {
        throw ArgumentError('Spans $this and $other are disjoint.');
      }
    } else {
      if (_start > other.end.offset || other.start.offset > _end) {
        throw ArgumentError('Spans $this and $other are disjoint.');
      }
    }

    return span;
  }

  @override
  bool operator ==(other) {
    if (other is! FileSpan) return super == other;
    if (other is! _FileSpan) {
      return super == other && sourceUrl == other.sourceUrl;
    }

    return _start == other._start &&
        _end == other._end &&
        sourceUrl == other.sourceUrl;
  }

  @override
  int get hashCode => Object.hash(_start, _end, sourceUrl);

  /// Returns a new span that covers both `this` and [other].
  ///
  /// Unlike [union], [other] may be disjoint from `this`. If it is, the text
  /// between the two will be covered by the returned span.
  @override
  FileSpan expand(FileSpan other) {
    if (sourceUrl != other.sourceUrl) {
      throw ArgumentError('Source URLs "$sourceUrl" and '
          " \"${other.sourceUrl}\" don't match.");
    }

    if (other is _FileSpan) {
      final start = math.min(_start, other._start);
      final end = math.max(_end, other._end);
      return _FileSpan(file, start, end);
    } else {
      final start = math.min(_start, other.start.offset);
      final end = math.max(_end, other.end.offset);
      return _FileSpan(file, start, end);
    }
  }

  /// See `SourceSpanExtension.subspan`.
  FileSpan subspan(int start, [int? end]) {
    RangeError.checkValidRange(start, end, length);
    if (start == 0 && (end == null || end == length)) return this;
    return file.span(_start + start, end == null ? _end : _start + end);
  }
}

// TODO(#52): Move these to instance methods in the next breaking release.
/// Extension methods on the [FileSpan] API.
extension FileSpanExtension on FileSpan {
  /// See `SourceSpanExtension.subspan`.
  FileSpan subspan(int start, [int? end]) {
    RangeError.checkValidRange(start, end, length);
    if (start == 0 && (end == null || end == length)) return this;

    final startOffset = this.start.offset;
    return file.span(
        startOffset + start, end == null ? this.end.offset : startOffset + end);
  }
}
