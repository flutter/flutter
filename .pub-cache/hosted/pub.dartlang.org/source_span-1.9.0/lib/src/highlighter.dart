// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:path/path.dart' as p;
import 'package:term_glyph/term_glyph.dart' as glyph;

import 'charcode.dart';
import 'colors.dart' as colors;
import 'location.dart';
import 'span.dart';
import 'span_with_context.dart';
import 'utils.dart';

/// A class for writing a chunk of text with a particular span highlighted.
class Highlighter {
  /// The lines to display, including context around the highlighted spans.
  final List<_Line> _lines;

  /// The color to highlight the primary [_Highlight] within its context, or
  /// `null` if it should not be colored.
  final String? _primaryColor;

  /// The color to highlight the secondary [_Highlight]s within their context,
  /// or `null` if they should not be colored.
  final String? _secondaryColor;

  /// The number of characters before the bar in the sidebar.
  final int _paddingBeforeSidebar;

  /// The maximum number of multiline spans that cover any part of a single
  /// line in [_lines].
  final int _maxMultilineSpans;

  /// Whether [_lines] includes lines from multiple different files.
  final bool _multipleFiles;

  /// The buffer to which to write the result.
  final _buffer = StringBuffer();

  /// The number of spaces to render for hard tabs that appear in `_span.text`.
  ///
  /// We don't want to render raw tabs, because they'll mess up our character
  /// alignment.
  static const _spacesPerTab = 4;

  /// Creates a [Highlighter] that will return a string highlighting [span]
  /// within the text of its file when [highlight] is called.
  ///
  /// [color] may either be a [String], a [bool], or `null`. If it's a string,
  /// it indicates an [ANSI terminal color escape][] that should be used to
  /// highlight [span]'s text (for example, `"\u001b[31m"` will color red). If
  /// it's `true`, it indicates that the text should be highlighted using the
  /// default color. If it's `false` or `null`, it indicates that no color
  /// should be used.
  ///
  /// [ANSI terminal color escape]: https://en.wikipedia.org/wiki/ANSI_escape_code#Colors
  Highlighter(SourceSpan span, {color})
      : this._(_collateLines([_Highlight(span, primary: true)]), () {
          if (color == true) return colors.red;
          if (color == false) return null;
          return color as String?;
        }(), null);

  /// Creates a [Highlighter] that will return a string highlighting
  /// [primarySpan] as well as all the spans in [secondarySpans] within the text
  /// of their file when [highlight] is called.
  ///
  /// Each span has an associated label that will be written alongside it. For
  /// [primarySpan] this message is [primaryLabel], and for [secondarySpans] the
  /// labels are the map values.
  ///
  /// If [color] is `true`, this will use [ANSI terminal color escapes][] to
  /// highlight the text. The [primarySpan] will be highlighted with
  /// [primaryColor] (which defaults to red), and the [secondarySpans] will be
  /// highlighted with [secondaryColor] (which defaults to blue). These
  /// arguments are ignored if [color] is `false`.
  ///
  /// [ANSI terminal color escape]: https://en.wikipedia.org/wiki/ANSI_escape_code#Colors
  Highlighter.multiple(SourceSpan primarySpan, String primaryLabel,
      Map<SourceSpan, String> secondarySpans,
      {bool color = false, String? primaryColor, String? secondaryColor})
      : this._(
            _collateLines([
              _Highlight(primarySpan, label: primaryLabel, primary: true),
              for (var entry in secondarySpans.entries)
                _Highlight(entry.key, label: entry.value)
            ]),
            color ? (primaryColor ?? colors.red) : null,
            color ? (secondaryColor ?? colors.blue) : null);

  Highlighter._(this._lines, this._primaryColor, this._secondaryColor)
      : _paddingBeforeSidebar = 1 +
            math.max<int>(
                // In a purely mathematical world, floor(log10(n)) would give the
                // number of digits in n, but floating point errors render that
                // unreliable in practice.
                (_lines.last.number + 1).toString().length,
                // If [_lines] aren't contiguous, we'll write "..." in place of a
                // line number.
                _contiguous(_lines) ? 0 : 3),
        _maxMultilineSpans = _lines
            .map((line) => line.highlights
                .where((highlight) => isMultiline(highlight.span))
                .length)
            .reduce(math.max),
        _multipleFiles = !isAllTheSame(_lines.map((line) => line.url));

  /// Returns whether [lines] contains any adjacent lines from the same source
  /// file that aren't adjacent in the original file.
  static bool _contiguous(List<_Line> lines) {
    for (var i = 0; i < lines.length - 1; i++) {
      final thisLine = lines[i];
      final nextLine = lines[i + 1];
      if (thisLine.number + 1 != nextLine.number &&
          thisLine.url == nextLine.url) {
        return false;
      }
    }
    return true;
  }

  /// Collect all the source lines from the contexts of all spans in
  /// [highlights], and associates them with the highlights that cover them.
  static List<_Line> _collateLines(List<_Highlight> highlights) {
    // Assign spans without URLs opaque Objects as keys. Each such Object will
    // be different, but they can then be used later on to determine which lines
    // came from the same span even if they'd all otherwise have `null` URLs.
    final highlightsByUrl = groupBy<_Highlight, Object>(
        highlights, (highlight) => highlight.span.sourceUrl ?? Object());
    for (var list in highlightsByUrl.values) {
      list.sort((highlight1, highlight2) =>
          highlight1.span.compareTo(highlight2.span));
    }

    return highlightsByUrl.entries.expand((entry) {
      final url = entry.key;
      final highlightsForFile = entry.value;

      // First, create a list of all the lines in the current file that we have
      // context for along with their line numbers.
      final lines = <_Line>[];
      for (var highlight in highlightsForFile) {
        final context = highlight.span.context;
        // If [highlight.span.context] contains lines prior to the one
        // [highlight.span.text] appears on, write those first.
        final lineStart = findLineStart(
            context, highlight.span.text, highlight.span.start.column)!;

        final linesBeforeSpan =
            '\n'.allMatches(context.substring(0, lineStart)).length;

        var lineNumber = highlight.span.start.line - linesBeforeSpan;
        for (var line in context.split('\n')) {
          // Only add a line if it hasn't already been added for a previous span.
          if (lines.isEmpty || lineNumber > lines.last.number) {
            lines.add(_Line(line, lineNumber, url));
          }
          lineNumber++;
        }
      }

      // Next, associate each line with each highlights that covers it.
      final activeHighlights = <_Highlight>[];
      var highlightIndex = 0;
      for (var line in lines) {
        activeHighlights
            .removeWhere((highlight) => highlight.span.end.line < line.number);

        final oldHighlightLength = activeHighlights.length;
        for (var highlight in highlightsForFile.skip(highlightIndex)) {
          if (highlight.span.start.line > line.number) break;
          activeHighlights.add(highlight);
        }
        highlightIndex += activeHighlights.length - oldHighlightLength;

        line.highlights.addAll(activeHighlights);
      }

      return lines;
    }).toList();
  }

  /// Returns the highlighted span text.
  ///
  /// This method should only be called once.
  String highlight() {
    _writeFileStart(_lines.first.url);

    // Each index of this list represents a column after the sidebar that could
    // contain a line indicating an active highlight. If it's `null`, that
    // column is empty; if it contains a highlight, it should be drawn for that column.
    final highlightsByColumn =
        List<_Highlight?>.filled(_maxMultilineSpans, null);

    for (var i = 0; i < _lines.length; i++) {
      final line = _lines[i];
      if (i > 0) {
        final lastLine = _lines[i - 1];
        if (lastLine.url != line.url) {
          _writeSidebar(end: glyph.upEnd);
          _buffer.writeln();
          _writeFileStart(line.url);
        } else if (lastLine.number + 1 != line.number) {
          _writeSidebar(text: '...');
          _buffer.writeln();
        }
      }

      // If a highlight covers the entire first line other than initial
      // whitespace, don't bother pointing out exactly where it begins. Iterate
      // in reverse so that longer highlights (which are sorted after shorter
      // highlights) appear further out, leading to fewer crossed lines.
      for (var highlight in line.highlights.reversed) {
        if (isMultiline(highlight.span) &&
            highlight.span.start.line == line.number &&
            _isOnlyWhitespace(
                line.text.substring(0, highlight.span.start.column))) {
          replaceFirstNull(highlightsByColumn, highlight);
        }
      }

      _writeSidebar(line: line.number);
      _buffer.write(' ');
      _writeMultilineHighlights(line, highlightsByColumn);
      if (highlightsByColumn.isNotEmpty) _buffer.write(' ');

      final primaryIdx =
          line.highlights.indexWhere((highlight) => highlight.isPrimary);
      final primary = primaryIdx == -1 ? null : line.highlights[primaryIdx];

      if (primary != null) {
        _writeHighlightedText(
            line.text,
            primary.span.start.line == line.number
                ? primary.span.start.column
                : 0,
            primary.span.end.line == line.number
                ? primary.span.end.column
                : line.text.length,
            color: _primaryColor);
      } else {
        _writeText(line.text);
      }
      _buffer.writeln();

      // Always write the primary span's indicator first so that it's right next
      // to the highlighted text.
      if (primary != null) _writeIndicator(line, primary, highlightsByColumn);
      for (var highlight in line.highlights) {
        if (highlight.isPrimary) continue;
        _writeIndicator(line, highlight, highlightsByColumn);
      }
    }

    _writeSidebar(end: glyph.upEnd);
    return _buffer.toString();
  }

  /// Writes the beginning of the file highlight for the file with the given
  /// [url] (or opaque object if it comes from a span with a null URL).
  void _writeFileStart(Object url) {
    if (!_multipleFiles || url is! Uri) {
      _writeSidebar(end: glyph.downEnd);
    } else {
      _writeSidebar(end: glyph.topLeftCorner);
      _colorize(() => _buffer.write('${glyph.horizontalLine * 2}>'),
          color: colors.blue);
      _buffer.write(' ${p.prettyUri(url)}');
    }
    _buffer.writeln();
  }

  /// Writes the post-sidebar highlight bars for [line] according to
  /// [highlightsByColumn].
  ///
  /// If [current] is passed, it's the highlight for which an indicator is being
  /// written. If it appears in [highlightsByColumn], a horizontal line is
  /// written from its column to the rightmost column.
  void _writeMultilineHighlights(
      _Line line, List<_Highlight?> highlightsByColumn,
      {_Highlight? current}) {
    // Whether we've written a sidebar indicator for opening a new span on this
    // line, and which color should be used for that indicator's rightward line.
    var openedOnThisLine = false;
    String? openedOnThisLineColor;

    final currentColor = current == null
        ? null
        : current.isPrimary
            ? _primaryColor
            : _secondaryColor;
    var foundCurrent = false;
    for (var highlight in highlightsByColumn) {
      final startLine = highlight?.span.start.line;
      final endLine = highlight?.span.end.line;
      if (current != null && highlight == current) {
        foundCurrent = true;
        assert(startLine == line.number || endLine == line.number);
        _colorize(() {
          _buffer.write(startLine == line.number
              ? glyph.topLeftCorner
              : glyph.bottomLeftCorner);
        }, color: currentColor);
      } else if (foundCurrent) {
        _colorize(() {
          _buffer.write(highlight == null ? glyph.horizontalLine : glyph.cross);
        }, color: currentColor);
      } else if (highlight == null) {
        if (openedOnThisLine) {
          _colorize(() => _buffer.write(glyph.horizontalLine),
              color: openedOnThisLineColor);
        } else {
          _buffer.write(' ');
        }
      } else {
        _colorize(() {
          final vertical = openedOnThisLine ? glyph.cross : glyph.verticalLine;
          if (current != null) {
            _buffer.write(vertical);
          } else if (startLine == line.number) {
            _colorize(() {
              _buffer
                  .write(glyph.glyphOrAscii(openedOnThisLine ? '┬' : '┌', '/'));
            }, color: openedOnThisLineColor);
            openedOnThisLine = true;
            openedOnThisLineColor ??=
                highlight.isPrimary ? _primaryColor : _secondaryColor;
          } else if (endLine == line.number &&
              highlight.span.end.column == line.text.length) {
            _buffer.write(highlight.label == null
                ? glyph.glyphOrAscii('└', '\\')
                : vertical);
          } else {
            _colorize(() {
              _buffer.write(vertical);
            }, color: openedOnThisLineColor);
          }
        }, color: highlight.isPrimary ? _primaryColor : _secondaryColor);
      }
    }
  }

  // Writes [text], with text between [startColumn] and [endColumn] colorized in
  // the same way as [_colorize].
  void _writeHighlightedText(String text, int startColumn, int endColumn,
      {required String? color}) {
    _writeText(text.substring(0, startColumn));
    _colorize(() => _writeText(text.substring(startColumn, endColumn)),
        color: color);
    _writeText(text.substring(endColumn, text.length));
  }

  /// Writes an indicator for where [highlight] starts, ends, or both below
  /// [line].
  ///
  /// This may either add or remove [highlight] from [highlightsByColumn].
  void _writeIndicator(
      _Line line, _Highlight highlight, List<_Highlight?> highlightsByColumn) {
    final color = highlight.isPrimary ? _primaryColor : _secondaryColor;
    if (!isMultiline(highlight.span)) {
      _writeSidebar();
      _buffer.write(' ');
      _writeMultilineHighlights(line, highlightsByColumn, current: highlight);
      if (highlightsByColumn.isNotEmpty) _buffer.write(' ');

      _colorize(() {
        _writeUnderline(line, highlight.span,
            highlight.isPrimary ? '^' : glyph.horizontalLineBold);
        _writeLabel(highlight.label);
      }, color: color);
      _buffer.writeln();
    } else if (highlight.span.start.line == line.number) {
      if (highlightsByColumn.contains(highlight)) return;
      replaceFirstNull(highlightsByColumn, highlight);

      _writeSidebar();
      _buffer.write(' ');
      _writeMultilineHighlights(line, highlightsByColumn, current: highlight);
      _colorize(() => _writeArrow(line, highlight.span.start.column),
          color: color);
      _buffer.writeln();
    } else if (highlight.span.end.line == line.number) {
      final coversWholeLine = highlight.span.end.column == line.text.length;
      if (coversWholeLine && highlight.label == null) {
        replaceWithNull(highlightsByColumn, highlight);
        return;
      }

      _writeSidebar();
      _buffer.write(' ');
      _writeMultilineHighlights(line, highlightsByColumn, current: highlight);

      _colorize(() {
        if (coversWholeLine) {
          _buffer.write(glyph.horizontalLine * 3);
        } else {
          _writeArrow(line, math.max(highlight.span.end.column - 1, 0),
              beginning: false);
        }
        _writeLabel(highlight.label);
      }, color: color);
      _buffer.writeln();
      replaceWithNull(highlightsByColumn, highlight);
    }
  }

  /// Underlines the portion of [line] covered by [span] with repeated instances
  /// of [character].
  void _writeUnderline(_Line line, SourceSpan span, String character) {
    assert(!isMultiline(span));
    assert(line.text.contains(span.text),
        '"${line.text}" should contain "${span.text}"');

    var startColumn = span.start.column;
    var endColumn = span.end.column;

    // Adjust the start and end columns to account for any tabs that were
    // converted to spaces.
    final tabsBefore = _countTabs(line.text.substring(0, startColumn));
    final tabsInside = _countTabs(line.text.substring(startColumn, endColumn));
    startColumn += tabsBefore * (_spacesPerTab - 1);
    endColumn += (tabsBefore + tabsInside) * (_spacesPerTab - 1);

    _buffer
      ..write(' ' * startColumn)
      ..write(character * math.max(endColumn - startColumn, 1));
  }

  /// Write an arrow pointing to column [column] in [line].
  ///
  /// If the arrow points to a tab character, this will point to the beginning
  /// of the tab if [beginning] is `true` and the end if it's `false`.
  void _writeArrow(_Line line, int column, {bool beginning = true}) {
    final tabs =
        _countTabs(line.text.substring(0, column + (beginning ? 0 : 1)));
    _buffer
      ..write(glyph.horizontalLine * (1 + column + tabs * (_spacesPerTab - 1)))
      ..write('^');
  }

  /// Writes a space followed by [label] if [label] isn't `null`.
  void _writeLabel(String? label) {
    if (label != null) _buffer.write(' $label');
  }

  /// Writes a snippet from the source text, converting hard tab characters into
  /// plain indentation.
  void _writeText(String text) {
    for (var char in text.codeUnits) {
      if (char == $tab) {
        _buffer.write(' ' * _spacesPerTab);
      } else {
        _buffer.writeCharCode(char);
      }
    }
  }

  // Writes a sidebar to [buffer] that includes [line] as the line number if
  // given and writes [end] at the end (defaults to [glyphs.verticalLine]).
  //
  // If [text] is given, it's used in place of the line number. It can't be
  // passed at the same time as [line].
  void _writeSidebar({int? line, String? text, String? end}) {
    assert(line == null || text == null);

    // Add 1 to line to convert from computer-friendly 0-indexed line numbers to
    // human-friendly 1-indexed line numbers.
    if (line != null) text = (line + 1).toString();
    _colorize(() {
      _buffer
        ..write((text ?? '').padRight(_paddingBeforeSidebar))
        ..write(end ?? glyph.verticalLine);
    }, color: colors.blue);
  }

  /// Returns the number of hard tabs in [text].
  int _countTabs(String text) {
    var count = 0;
    for (var char in text.codeUnits) {
      if (char == $tab) count++;
    }
    return count;
  }

  /// Returns whether [text] contains only space or tab characters.
  bool _isOnlyWhitespace(String text) {
    for (var char in text.codeUnits) {
      if (char != $space && char != $tab) return false;
    }
    return true;
  }

  /// Colors all text written to [_buffer] during [callback], if colorization is
  /// enabled and [color] is not `null`.
  void _colorize(void Function() callback, {required String? color}) {
    if (_primaryColor != null && color != null) _buffer.write(color);
    callback();
    if (_primaryColor != null && color != null) _buffer.write(colors.none);
  }
}

/// Information about how to highlight a single section of a source file.
class _Highlight {
  /// The section of the source file to highlight.
  ///
  /// This is normalized to make it easier for [Highlighter] to work with.
  final SourceSpanWithContext span;

  /// Whether this is the primary span in the highlight.
  ///
  /// The primary span is highlighted with a different character and colored
  /// differently than non-primary spans.
  final bool isPrimary;

  /// The label to include inline when highlighting [span].
  ///
  /// This helps distinguish clarify what each highlight means when multiple are
  /// used in the same message.
  final String? label;

  _Highlight(SourceSpan span, {this.label, bool primary = false})
      : span = (() {
          var newSpan = _normalizeContext(span);
          newSpan = _normalizeNewlines(newSpan);
          newSpan = _normalizeTrailingNewline(newSpan);
          return _normalizeEndOfLine(newSpan);
        })(),
        isPrimary = primary;

  /// Normalizes [span] to ensure that it's a [SourceSpanWithContext] whose
  /// context actually contains its text at the expected column.
  ///
  /// If it's not already a [SourceSpanWithContext], adjust the start and end
  /// locations' line and column fields so that the highlighter can assume they
  /// match up with the context.
  static SourceSpanWithContext _normalizeContext(SourceSpan span) =>
      span is SourceSpanWithContext &&
              findLineStart(span.context, span.text, span.start.column) != null
          ? span
          : SourceSpanWithContext(
              SourceLocation(span.start.offset,
                  sourceUrl: span.sourceUrl, line: 0, column: 0),
              SourceLocation(span.end.offset,
                  sourceUrl: span.sourceUrl,
                  line: countCodeUnits(span.text, $lf),
                  column: _lastLineLength(span.text)),
              span.text,
              span.text);

  /// Normalizes [span] to replace Windows-style newlines with Unix-style
  /// newlines.
  static SourceSpanWithContext _normalizeNewlines(SourceSpanWithContext span) {
    final text = span.text;
    if (!text.contains('\r\n')) return span;

    var endOffset = span.end.offset;
    for (var i = 0; i < text.length - 1; i++) {
      if (text.codeUnitAt(i) == $cr && text.codeUnitAt(i + 1) == $lf) {
        endOffset--;
      }
    }

    return SourceSpanWithContext(
        span.start,
        SourceLocation(endOffset,
            sourceUrl: span.sourceUrl,
            line: span.end.line,
            column: span.end.column),
        text.replaceAll('\r\n', '\n'),
        span.context.replaceAll('\r\n', '\n'));
  }

  /// Normalizes [span] to remove a trailing newline from `span.context`.
  ///
  /// If necessary, also adjust `span.end` so that it doesn't point past where
  /// the trailing newline used to be.
  static SourceSpanWithContext _normalizeTrailingNewline(
      SourceSpanWithContext span) {
    if (!span.context.endsWith('\n')) return span;

    // If there's a full blank line on the end of [span.context], it's probably
    // significant, so we shouldn't trim it.
    if (span.text.endsWith('\n\n')) return span;

    final context = span.context.substring(0, span.context.length - 1);
    var text = span.text;
    var start = span.start;
    var end = span.end;
    if (span.text.endsWith('\n') && _isTextAtEndOfContext(span)) {
      text = span.text.substring(0, span.text.length - 1);
      if (text.isEmpty) {
        end = start;
      } else {
        end = SourceLocation(span.end.offset - 1,
            sourceUrl: span.sourceUrl,
            line: span.end.line - 1,
            column: _lastLineLength(context));
        start = span.start.offset == span.end.offset ? end : span.start;
      }
    }
    return SourceSpanWithContext(start, end, text, context);
  }

  /// Normalizes [span] so that the end location is at the end of a line rather
  /// than at the beginning of the next line.
  static SourceSpanWithContext _normalizeEndOfLine(SourceSpanWithContext span) {
    if (span.end.column != 0) return span;
    if (span.end.line == span.start.line) return span;

    final text = span.text.substring(0, span.text.length - 1);

    return SourceSpanWithContext(
        span.start,
        SourceLocation(span.end.offset - 1,
            sourceUrl: span.sourceUrl,
            line: span.end.line - 1,
            column: text.length - text.lastIndexOf('\n') - 1),
        text,
        // If the context also ends with a newline, it's possible that we don't
        // have the full context for that line, so we shouldn't print it at all.
        span.context.endsWith('\n')
            ? span.context.substring(0, span.context.length - 1)
            : span.context);
  }

  /// Returns the length of the last line in [text], whether or not it ends in a
  /// newline.
  static int _lastLineLength(String text) {
    if (text.isEmpty) {
      return 0;
    } else if (text.codeUnitAt(text.length - 1) == $lf) {
      return text.length == 1
          ? 0
          : text.length - text.lastIndexOf('\n', text.length - 2) - 1;
    } else {
      return text.length - text.lastIndexOf('\n') - 1;
    }
  }

  /// Returns whether [span]'s text runs all the way to the end of its context.
  static bool _isTextAtEndOfContext(SourceSpanWithContext span) =>
      findLineStart(span.context, span.text, span.start.column)! +
          span.start.column +
          span.length ==
      span.context.length;

  @override
  String toString() {
    final buffer = StringBuffer();
    if (isPrimary) buffer.write('primary ');
    buffer.write('${span.start.line}:${span.start.column}-'
        '${span.end.line}:${span.end.column}');
    if (label != null) buffer.write(' ($label)');
    return buffer.toString();
  }
}

/// A single line of the source file being highlighted.
class _Line {
  /// The text of the line, not including the trailing newline.
  final String text;

  /// The 0-based line number in the source file.
  final int number;

  /// The URL of the source file in which this line appears.
  ///
  /// For lines created from spans without an explicit URL, this is an opaque
  /// object that differs between lines that come from different spans.
  final Object url;

  /// All highlights that cover any portion of this line, in source span order.
  ///
  /// This is populated after the initial line is created.
  final highlights = <_Highlight>[];

  _Line(this.text, this.number, this.url);

  @override
  String toString() => '$number: "$text" (${highlights.join(', ')})';
}
