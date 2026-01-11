// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:ui/ui.dart' as ui;

import 'code_unit_flags.dart';
import 'debug.dart';
import 'layout.dart';
import 'paragraph.dart';

/// Wraps the text by a given width.
class TextWrapper {
  TextWrapper(this._layout);

  final TextLayout _layout;

  double get maxIntrinsicWidth => _maxIntrinsicWidth;
  double _maxIntrinsicWidth = 0.0;

  double get minIntrinsicWidth => _minIntrinsicWidth;
  double _minIntrinsicWidth = 0.0;

  double get longestLine => _longestLine;
  double _longestLine = 0.0;

  double get maxLineWidthWithTrailingSpaces => _maxLineWidthWithTrailingSpaces;
  double _maxLineWidthWithTrailingSpaces = 0.0;

  double get height => _height;
  double _height = 0.0;

  bool _isWhitespace(WebCluster cluster) {
    return _layout.codeUnitFlags.hasFlag(cluster.start, CodeUnitFlag.whitespace);
  }

  bool _isSoftLineBreak(WebCluster cluster) {
    return _layout.codeUnitFlags.hasFlag(cluster.start, CodeUnitFlag.softLineBreak);
  }

  bool _isHardLineBreak(WebCluster cluster) {
    return _layout.codeUnitFlags.hasFlag(cluster.start, CodeUnitFlag.hardLineBreak);
  }

  void breakLines(double maxWidth) {
    // LTR: "words":[startLine:whitespaces.start) "whitespaces":[whitespaces.start:whitespaces.end) "letters":[whitespaces.end:...)
    // RTL: "letters":(...:whitespaces.end] "whitespaces":(whitespaces.end:whitespaces.start] "words":(whitespaces.start:startLine]

    final line = _LineBuilder(_layout, maxWidth);

    var hardLineBreak = false;
    for (var index = 0; index < _layout.allClusters.length - 1; index += 1) {
      final WebCluster cluster = _layout.allClusters[index];
      final double widthCluster = cluster.advance.width;
      hardLineBreak = _isHardLineBreak(cluster);

      if (hardLineBreak) {
        // Break the line and then continue with the current cluster as usual
        WebParagraphDebug.log('isHardLineBreak: $index');

        line.consumePendingText();

        // This is the case when the ellipsis will be added to the empty line; weird...
        line.ellipsize(index);
        line.build(hardLineBreak);
        if (line.reachedMaxLines()) {
          break;
        }
      } else if (_isSoftLineBreak(cluster) && line.isNotEmpty) {
        // Mark the potential line break and then continue with the current cluster as usual
        WebParagraphDebug.log('isSoftLineBreak: $index');
        if (line.hasLeadingWhitespaces) {
          // There is one case when we have to ignore this soft line break: if we only had whitespaces so far -
          // these are the leading spaces and Flutter wants them to be preserved
          // We need to pretend that these are not whitespaces
        } else {
          line.markSoftLineBreak(index);
        }
      }

      // Check if this is a (trailing) whitespace that does not affect the line width
      if (_isWhitespace(cluster)) {
        line.consumePendingText();
        // Add the cluster to the current whitespace sequence (empty or not)
        line.addWhitespace(index, widthCluster);
        continue;
      }

      // Check if we exceeded the line width
      if (!line.canFit(widthCluster)) {
        var clusterAdded = false;

        if (line.hasSoftLineBreak) {
          // There was at least one possible line break so we can use it to break the text
        } else if (line.isNotEmpty) {
          // There was some text without line break, we will have to force-break the text at this cluster.
          assert(!line.hasConsumedText);
          // We possibly have some leading spaces and some text after
          line.consumePendingText();
        } else {
          // We have only one cluster and it's too big to fit the line but we place it anyway
          assert(line.isEmpty);
          line.addPendingText(index, widthCluster);
          line.consumePendingText();
          clusterAdded = true;
        }

        // Add ellipsis if needed (and correct all the structures accordingly)
        line.ellipsize(index);
        // Add the line
        line.build(hardLineBreak);
        if (line.reachedMaxLines()) {
          break;
        }

        if (clusterAdded) {
          continue;
        }
      }

      // This is just a regular cluster, add it as pending text.
      line.addPendingText(index, widthCluster);
    }

    // Make sure we didn't miss anything from the text
    assert(line.reachedEndOfText() || line.reachedMaxLines());

    if (!line.reachedMaxLines()) {
      // Special case: we have only whitespaces in the whole paragraph
      if (_layout.lines.isEmpty && line.hasOnlyWhitespaces) {
        line._maxIntrinsicWidth = line._widthWhitespaces;
        line._minIntrinsicWidth = line._widthWhitespaces;
        line._longestLine = line._widthWhitespaces;
        line._maxLineWidthWithTrailingSpaces = line._widthWhitespaces;
        line.build(hardLineBreak);
        // Nothing to ellipsize in this case;
      }
      // Add the last line if there's anything left to add
      else if (line.isNotEmpty) {
        // Treat the end of text as a soft line break
        line.markSoftLineBreak(_layout.allClusters.length - 1);
        line.build(hardLineBreak);
        // This is the line line with the text that fits in the given width, no need to ellipsize it
      }
    }

    _maxIntrinsicWidth = math.max(_maxIntrinsicWidth, line._maxIntrinsicWidth);
    _minIntrinsicWidth = math.max(_minIntrinsicWidth, line._minIntrinsicWidth);
    _longestLine = math.max(_longestLine, line._longestLine);
    _maxLineWidthWithTrailingSpaces = math.max(_longestLine, line._maxLineWidthWithTrailingSpaces);
    _height = line._top;

    // TODO(jlavrova): Discuss with Mouad
    // Flutter wants to have another (empty) line if \n is the last codepoint in the text
    // This empty line gets in a way of detecting line visual runs (there isn't any)
    /*
    if (hardLineBreak) {
      final emptyClusterRange = ClusterRange(
        start: _layout.textClusters.length - 1,
        end: _layout.textClusters.length - 1,
      );
      _top +=_layout.addLine(emptyClusterRange, 0.0, emptyClusterRange, 0.0, false, _top,);
    }
    */
    /*
    if (WebParagraphDebug.logging) {
      for (int i = 0; i < _layout.lines.length; ++i) {
        final TextLine line = _layout.lines[i];
        final String text = _text.substring(line.textRange.start, line.textRange.end);
        final String whitespaces =
            !line.whitespacesRange.isEmpty ? '${line.whitespacesRange.width}' : 'no';
        final String hardLineBreak = line.hardLineBreak ? 'hardlineBreak' : '';
        WebParagraphDebug.log(
          '$i: "$text" [${line.textRange.start}:${line.textRange.end}) $width $hardLineBreak ($whitespaces trailing whitespaces)',
        );
      }
    }
    */
  }
}

class _LineBuilder {
  _LineBuilder(this._layout, this._maxWidth)
    : start = 0,
      _whitespaceStart = 0,
      _whitespaceEnd = 0,
      _pendingTextEnd = 0,
      _top = 0.0;

  final TextLayout _layout;
  final double _maxWidth;

  double _top;

  // TODO(mdebbar): Make all these properties private, and maybe add getters when necessary.
  int start;

  int _whitespaceStart;
  int _whitespaceEnd;

  int _pendingTextEnd;

  double _widthConsumedText = 0.0;
  double _widthWhitespaces = 0.0;
  double _widthPendingText = 0.0;

  double get minIntrinsicWidth => _minIntrinsicWidth;
  double _minIntrinsicWidth = 0.0;

  double get maxIntrinsicWidth => _maxIntrinsicWidth;
  double _maxIntrinsicWidth = 0.0;

  double get longestLine => _longestLine;
  double _longestLine = 0.0;

  double get maxLineWidthWithTrailingSpaces => _maxLineWidthWithTrailingSpaces;
  double _maxLineWidthWithTrailingSpaces = 0.0;

  double get height => _top;

  bool get isEmpty {
    // When `start` and `pendingTextEnd` are equal, we know there was no text, whitespaces
    // or pending text added to the line.
    final empty = start == _pendingTextEnd;

    if (empty) {
      assert(
        // Check that all widths are zero when the line is empty.
        _widthConsumedText == 0.0 &&
            _widthWhitespaces == 0.0 &&
            _widthPendingText == 0.0 &&
            // Check that there's no text, whitespace, or pending text.
            !hasConsumedText &&
            !hasWhitespaces &&
            !hasPendingText,
      );
    } else {
      // Check that there's some text or whitespace or pending text.
      assert(hasConsumedText || hasWhitespaces || hasPendingText);
    }

    return empty;
  }

  bool get isNotEmpty => !isEmpty;

  bool get hasConsumedText {
    final bool result = _whitespaceStart > start;

    if (!result) {
      // When there's no consumed text, the width is also 0.
      assert(_widthConsumedText == 0.0);
    }

    return result;
  }

  bool get hasWhitespaces {
    final result = _whitespaceStart != _whitespaceEnd;

    if (!result) {
      // When there's no whitespaces, the width of whitespaces is also 0.
      assert(_widthWhitespaces == 0.0);
    }

    return result;
  }

  bool get hasLeadingWhitespaces => !hasConsumedText && hasWhitespaces;

  bool get hasOnlyWhitespaces => !hasConsumedText && !hasPendingText && hasWhitespaces;

  bool get hasPendingText {
    final bool result = _pendingTextEnd > _whitespaceEnd;

    assert(() {
      if (!result) {
        // When there's no pending text, make sure the width of pending text is also 0.
        return _widthPendingText == 0.0;
      }
      return true;
    }());

    return result;
  }

  bool get hasSoftLineBreak => _hasSoftLineBreak;
  bool _hasSoftLineBreak = false;

  void markSoftLineBreak(int index) {
    _hasSoftLineBreak = true;

    if (hasPendingText) {
      assert(_pendingTextEnd == index);
    } else {
      assert(_whitespaceEnd == index);
    }

    consumePendingText();
    assert(_whitespaceEnd == index);
  }

  bool canFit(double extraWidth) {
    return _widthConsumedText + _widthWhitespaces + _widthPendingText + extraWidth <= _maxWidth;
  }

  bool reachedEndOfText() {
    return _pendingTextEnd == _layout.allClusters.length - 1;
  }

  void addWhitespace(int index, double width) {
    assert(!hasPendingText);

    _whitespaceEnd = index + 1;
    _pendingTextEnd = index + 1;

    _widthWhitespaces += width;

    assert(hasWhitespaces);
  }

  void addPendingText(int index, double width) {
    _pendingTextEnd = index + 1;
    _widthPendingText += width;

    assert(hasPendingText);
  }

  // TODO(mdebbar): Can we inline this in `markSoftLineBreak` and use that everywhere?
  void consumePendingText() {
    // Update min intrinsic width.
    _minIntrinsicWidth = math.max(_minIntrinsicWidth, _widthPendingText);

    if (!hasPendingText) {
      return;
    }

    _whitespaceStart = _pendingTextEnd;
    _whitespaceEnd = _pendingTextEnd;

    _widthConsumedText += _widthWhitespaces + _widthPendingText;
    _widthWhitespaces = 0.0;
    _widthPendingText = 0.0;

    assert(!hasWhitespaces);
    assert(!hasPendingText);
  }

  /// Builds a line and adds it to [_layout].
  ///
  /// After calling [build], the line builder instance is ready for the next line.
  ///
  /// Returns the height of the line.
  double build(bool hardLineBreak) {
    // Update max intrinsic width.
    _maxIntrinsicWidth = math.max(_maxIntrinsicWidth, _widthConsumedText);
    _longestLine = math.max(_longestLine, _widthConsumedText);
    _maxLineWidthWithTrailingSpaces = math.max(
      _maxLineWidthWithTrailingSpaces,
      _widthConsumedText + _widthWhitespaces,
    );

    final double height = _layout.addLine(
      ClusterRange(start: start, end: _whitespaceStart),
      ClusterRange(start: _whitespaceStart, end: _whitespaceEnd),
      hardLineBreak,
      _top,
    );

    // Reset the line builder to be ready for the next line.

    _hasSoftLineBreak = false;

    start = _whitespaceEnd;
    _whitespaceStart = start;
    _whitespaceEnd = start;

    _widthConsumedText = 0.0;
    _widthWhitespaces = 0.0;

    // Leave `pendingTextEnd` and `widthPendingText` untouched so they are used in the next line.

    _top += height;

    return height;
  }

  bool reachedMaxLines() {
    final int? maxLines = _layout.paragraph.paragraphStyle.maxLines;
    if (maxLines == null) {
      return false;
    }
    return _layout.lines.length >= maxLines;
  }

  bool ellipsize(int clusterIndex) {
    if (reachedMaxLines()) {
      return false;
    }
    // We need to shape the ellipsis here because only here we know the span/textStyle we ellipsize with
    final String? ellipsis = _layout.paragraph.paragraphStyle.ellipsis;
    if (ellipsis == null || ellipsis.isEmpty) {
      // No ellipsizing needed, but we have reached max lines
      return true;
    }
    // Let's walk backwards and see how many clusters we need to remove to fit the ellipsis in the line
    var cutOffWidth = 0.0;
    while (true) {
      if (clusterIndex <= start) {
        // We have removed all the clusters in this line and still can't fit the ellipsis
        // Not sure what to do in this case
        // TODO(jlavrova): Implement this case
        assert(false, 'Ellipsizing requires removing the whole line, not implemented yet');
        return false;
      }
      final WebCluster cluster = _layout.allClusters[clusterIndex - 1];
      final double widthCluster = cluster.advance.width;
      final ellipsisSpan = TextSpan(
        start: 0,
        end: ellipsis.length,
        style: cluster.style,
        text: ellipsis,
        textDirection: _layout.getEllipsisBidiLevel().isEven
            ? ui.TextDirection.ltr
            : ui.TextDirection.rtl,
      );
      WebParagraphDebug.log(
        'Ellipsize: $clusterIndex $_widthConsumedText $_widthWhitespaces $_widthPendingText - $cutOffWidth - $widthCluster + ${ellipsisSpan.advanceWidth()!} ??? $_maxWidth',
      );
      cutOffWidth += widthCluster;
      if (_isWhitespace(cluster)) {
        // We skip whitespaces when cutting off for ellipsis, so just continue
        WebParagraphDebug.log('Ellipsize: whitespace');
      } else if (canFit(ellipsisSpan.advanceWidth()! - cutOffWidth)) {
        WebParagraphDebug.log('Ellipsize: stop $clusterIndex');
        // We can fit the ellipsis now
        _layout.ellipsisClusters = ellipsisSpan.extractClusters();
        break;
      } else {
        WebParagraphDebug.log('Ellipsize: continue $clusterIndex');
      }
      // Remove this cluster, correct the structures and try again
      clusterIndex -= 1;
      if (clusterIndex >= _whitespaceEnd) {
        WebParagraphDebug.log('Ellipsize: pending text >= $_whitespaceEnd');
        _widthPendingText -= widthCluster;
        _pendingTextEnd = clusterIndex;
      } else if (clusterIndex >= _whitespaceStart) {
        WebParagraphDebug.log('Ellipsize: whitespaces => $_whitespaceStart');
        _widthWhitespaces -= widthCluster;
        _whitespaceEnd = clusterIndex;
      } else {
        WebParagraphDebug.log('Ellipsize: consumed text >= $start');
        _widthConsumedText -= widthCluster;
        _whitespaceStart = clusterIndex;
        _whitespaceEnd = clusterIndex;
      }
    }

    return true;
  }

  bool _isWhitespace(WebCluster cluster) {
    return _layout.codeUnitFlags.hasFlag(cluster.start, CodeUnitFlag.whitespace);
  }
}
