// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'chunk.dart';
import 'dart_formatter.dart';
import 'debug.dart' as debug;
import 'line_splitting/line_splitter.dart';

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
      this._blockIndentation, this._blockCache);

  /// Gets the results of formatting the child block of [chunk] at starting
  /// [column].
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
  /// When we format the function expression's body, [column] will be 2, not 4.
  FormatResult formatBlock(BlockChunk chunk, int column) {
    var key = _BlockKey(chunk, column);

    // Use the cached one if we have it.
    var cached = _blockCache[key];
    if (cached != null) return cached;

    var writer = LineWriter._(
        chunk.children, _lineEnding, pageWidth, column, _blockCache);
    return _blockCache[key] = writer.writeLines();
  }

  /// Takes all of the chunks and divides them into sublists and line splits
  /// each list.
  ///
  /// Since this is linear and line splitting is worse it's good to feed the
  /// line splitter smaller lists of chunks when possible.
  FormatResult writeLines({bool isCompilationUnit = false}) {
    // Now that we know what hard splits there will be, break the chunks into
    // independently splittable lines.
    var totalCost = 0;
    var start = 0;

    for (var i = 0; i < _chunks.length; i++) {
      var chunk = _chunks[i];
      if (!chunk.canDivide) continue;

      totalCost += _completeLine(start, i);
      start = i;
    }

    if (start < _chunks.length) {
      totalCost += _completeLine(start, _chunks.length);
    }

    // Be a good citizen, end with a newline.
    if (isCompilationUnit) _buffer.write(_lineEnding);

    return FormatResult(
        _buffer.toString(), totalCost, _selectionStart, _selectionEnd);
  }

  /// Takes the chunks from [start] to [end], removes them, and runs the
  /// [LineSplitter] on them.
  int _completeLine(int start, int end) {
    var chunks = _chunks.sublist(start, end);

    if (debug.traceLineWriter) {
      debug.log(debug.green('\nWriting:'));
      debug.dumpChunks(0, chunks);
      debug.log();
    }

    // Run the line splitter.
    var splitter = LineSplitter(this, chunks, _blockIndentation);
    var splits = splitter.apply();

    // Write each chunk with the appropriate splits between them.
    for (var i = 0; i < chunks.length; i++) {
      var chunk = chunks[i];

      // Write the block chunk's children first.
      if (chunk is BlockChunk) {
        if (!splits.shouldSplitAt(i)) {
          // This block didn't split (which implies none of the child blocks
          // of that block split either, recursively), so write them all inline.
          _writeChunksUnsplit(chunk);
        } else {
          _buffer.write(_lineEnding);

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

      if (splits.shouldSplitAt(i)) {
        // Don't write an initial single newline at the beginning of the output.
        // If this is for a block, then the newline will be written before
        // writing the block. If it's the top level output, then it shouldn't
        // have an extra leading newline.
        if (_buffer.isNotEmpty) {
          _buffer.write(_lineEnding);
          if (chunk.isDouble) _buffer.write(_lineEnding);
        }

        _buffer.write(' ' * (splits.getColumn(i)));
      } else {
        if (chunk.spaceWhenUnsplit) _buffer.write(' ');
      }

      _writeChunk(chunk);
    }

    return splits.cost;
  }

  /// Writes the block chunks of [block] (and any child chunks of them,
  /// recursively) without any splitting.
  void _writeChunksUnsplit(BlockChunk block) {
    for (var chunk in block.children) {
      if (chunk.spaceWhenUnsplit) _buffer.write(' ');
      _writeChunk(chunk);

      // Recurse into the block.
      if (chunk is BlockChunk) _writeChunksUnsplit(chunk);
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
