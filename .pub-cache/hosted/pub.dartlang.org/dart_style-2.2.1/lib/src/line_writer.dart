// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'chunk.dart';
import 'dart_formatter.dart';
import 'debug.dart' as debug;
import 'line_splitting/line_splitter.dart';
import 'whitespace.dart';

/// Given a series of chunks, splits them into lines and writes the result to
/// a buffer.
class LineWriter {
  final _buffer = StringBuffer();

  final List<Chunk> _chunks;

  final String _lineEnding;

  /// The number of characters allowed in a single line.
  final int pageWidth;

  /// The number of characters of additional indentation to apply to each line.
  ///
  /// This is used when formatting blocks to get the output into the right
  /// column based on where the block appears.
  final int _blockIndentation;

  /// The cache of blocks that have already been formatted.
  final Map<_BlockKey, FormatResult> _blockCache;

  /// The offset in [_buffer] where the selection starts in the formatted code.
  ///
  /// This will be `null` if there is no selection or the writer hasn't reached
  /// the beginning of the selection yet.
  int? _selectionStart;

  /// The offset in [_buffer] where the selection ends in the formatted code.
  ///
  /// This will be `null` if there is no selection or the writer hasn't reached
  /// the end of the selection yet.
  int? _selectionEnd;

  /// The number of characters that have been written to the output.
  int get length => _buffer.length;

  LineWriter(DartFormatter formatter, this._chunks)
      : _lineEnding = formatter.lineEnding!,
        pageWidth = formatter.pageWidth,
        _blockIndentation = 0,
        _blockCache = {};

  /// Creates a line writer for a block.
  LineWriter._(this._chunks, this._lineEnding, this.pageWidth,
      this._blockIndentation, this._blockCache) {
    // There is always a newline after the opening delimiter.
    _buffer.write(_lineEnding);
  }

  /// Gets the results of formatting the child block of [chunk] at with
  /// starting [column].
  ///
  /// If that block has already been formatted, reuses the results.
  ///
  /// The column is the column for the delimiters. The contents of the block
  /// are always implicitly one level deeper than that.
  ///
  ///     main() {
  ///       function(() {
  ///         block;
  ///       });
  ///     }
  ///
  /// When we format the anonymous lambda, [column] will be 2, not 4.
  FormatResult formatBlock(Chunk chunk, int column) {
    var key = _BlockKey(chunk, column);

    // Use the cached one if we have it.
    var cached = _blockCache[key];
    if (cached != null) return cached;

    var writer = LineWriter._(
        chunk.block.chunks, _lineEnding, pageWidth, column, _blockCache);

    // TODO(rnystrom): Passing in an initial indent here is hacky. The
    // LineWriter ensures all but the first chunk have a block indent, and this
    // handles the first chunk. Do something cleaner.
    var result = writer.writeLines(chunk.block.indent ? Indent.block : 0,
        flushLeft: chunk.flushLeft);
    return _blockCache[key] = result;
  }

  /// Takes all of the chunks and divides them into sublists and line splits
  /// each list.
  ///
  /// Since this is linear and line splitting is worse it's good to feed the
  /// line splitter smaller lists of chunks when possible.
  FormatResult writeLines(int firstLineIndent,
      {bool isCompilationUnit = false, bool flushLeft = false}) {
    // Now that we know what hard splits there will be, break the chunks into
    // independently splittable lines.
    var newlines = 0;
    var indent = firstLineIndent;
    var totalCost = 0;
    var start = 0;

    for (var i = 0; i < _chunks.length; i++) {
      var chunk = _chunks[i];
      if (!chunk.canDivide) continue;

      totalCost +=
          _completeLine(newlines, indent, start, i + 1, flushLeft: flushLeft);

      // Get ready for the next line.
      newlines = chunk.isDouble ? 2 : 1;
      indent = chunk.indent!;
      flushLeft = chunk.flushLeft;
      start = i + 1;
    }

    if (start < _chunks.length) {
      totalCost += _completeLine(newlines, indent, start, _chunks.length,
          flushLeft: flushLeft);
    }

    // Be a good citizen, end with a newline.
    if (isCompilationUnit) _buffer.write(_lineEnding);

    return FormatResult(
        _buffer.toString(), totalCost, _selectionStart, _selectionEnd);
  }

  /// Takes the chunks from [start] to [end] with leading [indent], removes
  /// them, and runs the [LineSplitter] on them.
  int _completeLine(int newlines, int indent, int start, int end,
      {required bool flushLeft}) {
    // Write the newlines required by the previous line.
    for (var j = 0; j < newlines; j++) {
      _buffer.write(_lineEnding);
    }

    var chunks = _chunks.sublist(start, end);

    if (debug.traceLineWriter) {
      debug.log(debug.green('\nWriting:'));
      debug.dumpChunks(0, chunks);
      debug.log();
    }

    // Run the line splitter.
    var splitter = LineSplitter(this, chunks, _blockIndentation, indent,
        flushLeft: flushLeft);
    var splits = splitter.apply();

    // Write the indentation of the first line.
    if (!flushLeft) {
      _buffer.write(' ' * (indent + _blockIndentation));
    }

    // Write each chunk with the appropriate splits between them.
    for (var i = 0; i < chunks.length; i++) {
      var chunk = chunks[i];
      _writeChunk(chunk);

      if (chunk.isBlock) {
        if (!splits.shouldSplitAt(i)) {
          // This block didn't split (which implies none of the child blocks
          // of that block split either, recursively), so write them all inline.
          _writeChunksUnsplit(chunk);
        } else {
          // Include the formatted block contents.
          var block = formatBlock(chunk, splits.getColumn(i));

          // If this block contains one of the selection markers, tell the
          // writer where it ended up in the final output.
          if (block.selectionStart != null) {
            _selectionStart = length + block.selectionStart!;
          }

          if (block.selectionEnd != null) {
            _selectionEnd = length + block.selectionEnd!;
          }

          _buffer.write(block.text);
        }
      }

      if (i == chunks.length - 1) {
        // Don't write trailing whitespace after the last chunk.
      } else if (splits.shouldSplitAt(i)) {
        _buffer.write(_lineEnding);
        if (chunk.isDouble) _buffer.write(_lineEnding);

        _buffer.write(' ' * (splits.getColumn(i)));
      } else {
        if (chunk.spaceWhenUnsplit) _buffer.write(' ');
      }
    }

    return splits.cost;
  }

  /// Writes the block chunks of [chunk] (and any child chunks of them,
  /// recursively) without any splitting.
  void _writeChunksUnsplit(Chunk chunk) {
    if (!chunk.isBlock) return;

    for (var blockChunk in chunk.block.chunks) {
      _writeChunk(blockChunk);

      if (blockChunk.spaceWhenUnsplit) _buffer.write(' ');

      // Recurse into the block.
      _writeChunksUnsplit(blockChunk);
    }
  }

  /// Writes [chunk] to the output and updates the selection if the chunk
  /// contains a selection marker.
  void _writeChunk(Chunk chunk) {
    if (chunk.selectionStart != null) {
      _selectionStart = length + chunk.selectionStart!;
    }

    if (chunk.selectionEnd != null) {
      _selectionEnd = length + chunk.selectionEnd!;
    }

    _buffer.write(chunk.text);
  }
}

/// Key type for the formatted block cache.
///
/// To cache formatted blocks, we just need to know which block it is (the
/// index of its parent chunk) and how far it was indented when we formatted it
/// (the starting column).
class _BlockKey {
  /// The index of the chunk in the surrounding chunk list that contains this
  /// block.
  final Chunk chunk;

  /// The absolute zero-based column number where the block starts.
  final int column;

  _BlockKey(this.chunk, this.column);

  @override
  bool operator ==(other) {
    if (other is! _BlockKey) return false;
    return chunk == other.chunk && column == other.column;
  }

  @override
  int get hashCode => chunk.hashCode ^ column.hashCode;
}

/// The result of formatting a series of chunks.
class FormatResult {
  /// The resulting formatted text, including newlines and leading whitespace
  /// to reach the proper column.
  final String text;

  /// The numeric cost of the chosen solution.
  final int cost;

  /// Where in the resulting buffer the selection starting point should appear
  /// if it was contained within this split list of chunks.
  ///
  /// Otherwise, this is `null`.
  final int? selectionStart;

  /// Where in the resulting buffer the selection end point should appear if it
  /// was contained within this split list of chunks.
  ///
  /// Otherwise, this is `null`.
  final int? selectionEnd;

  FormatResult(this.text, this.cost, this.selectionStart, this.selectionEnd);
}
