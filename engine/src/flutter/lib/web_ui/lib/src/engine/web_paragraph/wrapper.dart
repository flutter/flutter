// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:ui/ui.dart' as ui;

import 'code_unit_flags.dart';
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

  bool _isSoftLineBreak(WebCluster cluster) {
    return _layout.codeUnitFlags.hasFlag(cluster.start, CodeUnitFlag.softLineBreak);
  }

  bool _isHardLineBreak(WebCluster cluster) {
    // The flag is "Hard line break before the codepoint" so we need to test the end of the cluster
    return _layout.codeUnitFlags.hasFlag(cluster.end, CodeUnitFlag.hardLineBreak);
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
        line.consumePendingText();
        line.addHardLineBreak(index);

        // There is a special case: "\n" at the end of the text.
        // The last element of `allClusters` is an artificial EOF cluster,
        // so `_layout.allClusters.length - 2` is the last text cluster.
        // In this special case we will add 2 lines (including an empty trailing line).
        line.build(hasTrailingNewline: index == _layout.allClusters.length - 2);

        if (line.reachedMaxLines()) {
          if (!line.reachedEndOfText()) {
            _layout.paragraph.didExceedMaxLines = true;
          }
          break;
        } else {
          continue;
        }
      } else if (_isSoftLineBreak(cluster) && line.isNotEmpty) {
        // Mark the potential line break and then continue with the current cluster as usual
        if (line.hasLeadingWhitespaces) {
          // There is one case when we have to ignore this soft line break: if we only had whitespaces so far -
          // these are the leading spaces and Flutter wants them to be preserved
          // We need to pretend that these are not whitespaces
        } else {
          line.markSoftLineBreak(index, softHyphen: _layout.softHyphenBefore(index));
        }
      }

      // Check if this is a (trailing) whitespace that does not affect the line width
      if (line._isWhitespace(cluster)) {
        line.consumePendingText();
        // Add the cluster to the current whitespace sequence (empty or not)
        line.addWhitespace(index, widthCluster);
        continue;
      }

      // Check if we exceeded the line width
      if (!line.canFit(widthCluster)) {
        var clusterAdded = false;
        var rescan = false;

        if (line.hasSoftLineBreak) {
          // There was at least one possible line break so we can use it to break the text.
          // If it is a soft hyphen break whose hyphen does not fit, an earlier one is used.
          rescan = line.restoreFallbackBreak();
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

        // Add ellipsis if needed (and correct all the structures accordingly). A line that went
        // back to an earlier break kept room for a hyphen, so it is not an ellipsis line.
        if (!rescan) {
          line.ellipsize(index);
        }
        // Add the line
        line.build(hasTrailingNewline: false);
        if (line.reachedMaxLines()) {
          if (!line.reachedEndOfText()) {
            _layout.paragraph.didExceedMaxLines = true;
          }
          break;
        }

        if (rescan) {
          // The text after the earlier break has break opportunities of its own, so it is
          // scanned again for the next line.
          index = line.start - 1;
          continue;
        }

        if (clusterAdded) {
          continue;
        }
      }

      // This is just a regular cluster, add it as pending text
      line.addPendingText(index, widthCluster);
    }

    // Make sure we didn't miss anything from the text
    assert(line.reachedEndOfText() || line.reachedMaxLines());

    if (!line.reachedMaxLines()) {
      if (_layout.lines.isEmpty && line.hasOnlyWhitespaces) {
        // We have only whitespaces in the whole paragraph
        line._minIntrinsicWidth = line._widthWhitespaces;
        line._longestLine = line._widthWhitespaces;
        line._maxLineWidthWithTrailingSpaces = line._widthWhitespaces;
        line.build(hasTrailingNewline: false);
        // Nothing to ellipsize in this case;
      }
      // Add the last line if there's anything left to add
      else if (line.isNotEmpty) {
        // Treat the end of text as a soft line break
        line.markSoftLineBreak(_layout.allClusters.length - 1);
        line.build(hasTrailingNewline: false);
        // This is the line line with the text that fits in the given width, no need to ellipsize it
      }
    }

    _minIntrinsicWidth = math.max(_minIntrinsicWidth, line._minIntrinsicWidth);
    _longestLine = math.max(_longestLine, line._longestLine);
    _maxLineWidthWithTrailingSpaces = math.max(_longestLine, line._maxLineWidthWithTrailingSpaces);
    _height = line._top;

    _calculateMaxIntrinsicWidth();
  }

  void _calculateMaxIntrinsicWidth() {
    var currentWidth = 0.0;
    for (final WebCluster cluster in _layout.allClusters) {
      if (_isHardLineBreak(cluster)) {
        _maxIntrinsicWidth = math.max(_maxIntrinsicWidth, currentWidth);
        currentWidth = 0.0;
      } else {
        currentWidth += cluster.advance.width;
      }
    }
    _maxIntrinsicWidth = math.max(_maxIntrinsicWidth, currentWidth);
  }
}

class _LineBuilder {
  _LineBuilder(this._layout, this._maxWidth)
    : start = 0,
      _whitespaceStart = 0,
      _whitespaceEnd = 0,
      _newlineEnd = 0,
      _pendingTextEnd = 0,
      _top = 0.0;

  final TextLayout _layout;
  final double _maxWidth;

  double _top;

  // TODO(mdebbar): Make all these properties private, and maybe add getters when necessary.
  int start;

  int _whitespaceStart;
  int _whitespaceEnd;

  int _newlineEnd;

  int _pendingTextEnd;

  double _widthConsumedText = 0.0;
  double _widthWhitespaces = 0.0;
  double _widthPendingText = 0.0;

  double get minIntrinsicWidth => _minIntrinsicWidth;
  double _minIntrinsicWidth = 0.0;

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

  bool get hasHardLineBreak => _newlineEnd > _whitespaceEnd;

  bool get hasLeadingWhitespaces => !hasConsumedText && hasWhitespaces;

  bool get hasOnlyWhitespaces => !hasConsumedText && !hasPendingText && hasWhitespaces;

  bool get hasPendingText {
    final bool result = _pendingTextEnd > _newlineEnd;

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

  // The hyphen drawn if the line ends at the last soft line break, and where that break is.
  SoftHyphen? _breakSoftHyphen;
  int _breakIndex = -1;

  // Whether the last soft line break is at a soft hyphen whose hyphen does not fit.
  bool _isBreakTooWide = false;

  // The line as of the last soft line break that fits, to go back to when the last break
  // is too wide.
  _FallbackBreak? _fallbackBreak;

  /// Whether this line could end with an ellipsis, in which case no room is kept for a hyphen.
  ///
  /// This matches SkParagraph, where the ellipsis wins over the hyphen.
  bool get _mayEllipsize {
    final String? ellipsis = _layout.paragraph.paragraphStyle.ellipsis;
    if (ellipsis == null || ellipsis.isEmpty) {
      return false;
    }
    final int? maxLines = _layout.paragraph.paragraphStyle.maxLines;
    return maxLines == null || _layout.lines.length + 1 >= maxLines;
  }

  void markSoftLineBreak(int index, {SoftHyphen? softHyphen}) {
    // A soft hyphen immediately after whitespace (when there is no pending word before the break)
    // breaks at the preceding whitespace and never draws a hyphen.
    final SoftHyphen? effectiveSoftHyphen = hasPendingText ? softHyphen : null;

    // Like SkParagraph, a break at a soft hyphen only fits if the hyphen fits too.
    // If it does not, the line ends at the last earlier break that fits instead, if there
    // is one; otherwise the hyphen overflows.
    final double reservedWidth = effectiveSoftHyphen == null || _mayEllipsize
        ? 0.0
        : effectiveSoftHyphen.width;
    _isBreakTooWide = reservedWidth > 0.0 && _fallbackBreak != null && !canFit(reservedWidth);

    _hasSoftLineBreak = true;
    _breakSoftHyphen = effectiveSoftHyphen;
    _breakIndex = index;

    if (hasPendingText) {
      assert(_pendingTextEnd == index);
    } else {
      assert(_newlineEnd == index);
    }

    consumePendingText(hyphenWidth: effectiveSoftHyphen?.width ?? 0.0);
    assert(_newlineEnd == index);

    if (!_isBreakTooWide) {
      _fallbackBreak = _FallbackBreak(
        whitespaceStart: _whitespaceStart,
        whitespaceEnd: _whitespaceEnd,
        newlineEnd: _newlineEnd,
        widthConsumedText: _widthConsumedText,
        widthWhitespaces: _widthWhitespaces,
        softHyphen: _breakSoftHyphen,
        breakIndex: _breakIndex,
      );
    }
  }

  /// If the last soft line break is too wide for its hyphen, goes back to the last earlier
  /// break that fits, and returns true. The text after that break must then be scanned again.
  bool restoreFallbackBreak() {
    final _FallbackBreak? fallback = _fallbackBreak;
    if (!_isBreakTooWide || fallback == null) {
      return false;
    }
    _whitespaceStart = fallback.whitespaceStart;
    _whitespaceEnd = fallback.whitespaceEnd;
    _newlineEnd = fallback.newlineEnd;
    _pendingTextEnd = fallback.newlineEnd;
    _widthConsumedText = fallback.widthConsumedText;
    _widthWhitespaces = fallback.widthWhitespaces;
    _widthPendingText = 0.0;
    _breakSoftHyphen = fallback.softHyphen;
    _breakIndex = fallback.breakIndex;
    _isBreakTooWide = false;
    return true;
  }

  /// The hyphen to draw at the end of the line, if the line ends at a soft hyphen break and
  /// has no ellipsis.
  SoftHyphen? get _endingSoftHyphen {
    if (_breakSoftHyphen == null ||
        _whitespaceStart != _breakIndex ||
        hasWhitespaces ||
        hasHardLineBreak ||
        _layout.ellipsisClusters.isNotEmpty) {
      return null;
    }
    return _breakSoftHyphen;
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
    _newlineEnd = index + 1;
    _pendingTextEnd = index + 1;

    _widthWhitespaces += width;

    assert(hasWhitespaces);
  }

  void addHardLineBreak(int index) {
    assert(!hasPendingText);

    _whitespaceEnd = index;
    _newlineEnd = index + 1;
    _pendingTextEnd = index + 1;

    assert(hasHardLineBreak);
  }

  void addPendingText(int index, double width) {
    _pendingTextEnd = index + 1;
    _widthPendingText += width;

    assert(hasPendingText);
  }

  // TODO(mdebbar): Can we inline this in `markSoftLineBreak` and use that everywhere?
  void consumePendingText({double hyphenWidth = 0.0}) {
    if (!hasPendingText) {
      return;
    }

    // Update min intrinsic width. Like CSS min-content, a piece of a word that ends at a soft
    // hyphen counts with its hyphen.
    _minIntrinsicWidth = math.max(_minIntrinsicWidth, _widthPendingText + hyphenWidth);

    _whitespaceStart = _pendingTextEnd;
    _whitespaceEnd = _pendingTextEnd;
    _newlineEnd = _pendingTextEnd;

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
  void build({required bool hasTrailingNewline}) {
    final SoftHyphen? softHyphen = _endingSoftHyphen;
    // Like SkParagraph, the longest line includes the hyphen.
    final double hyphenWidth = softHyphen?.width ?? 0.0;
    _longestLine = math.max(_longestLine, _widthConsumedText + hyphenWidth);
    _maxLineWidthWithTrailingSpaces = math.max(
      _maxLineWidthWithTrailingSpaces,
      _widthConsumedText + _widthWhitespaces + hyphenWidth,
    );

    final int? maxLines = _layout.paragraph.paragraphStyle.maxLines;
    // Check + 1 because this line has not been appended to _layout.lines yet.
    final bool willReachMaxLines = maxLines != null && _layout.lines.length + 1 >= maxLines;
    // This content line is the last line when it hits maxLines or reaches the
    // artificial EOF cluster without a trailing newline.
    final bool isLastLine =
        willReachMaxLines || (!hasTrailingNewline && _newlineEnd == _layout.allClusters.length - 1);
    final double height = _layout.addLine(
      ClusterRange(start: start, end: _whitespaceStart),
      ClusterRange(start: _whitespaceStart, end: _whitespaceEnd),
      ClusterRange(start: _whitespaceEnd, end: _newlineEnd),
      _top,
      isSyntheticEmptyLine: false,
      isLastLine: isLastLine,
      softHyphen: softHyphen,
    );
    _top += height;

    // Flutter wants to have another (synthetic empty) line if \n is the last codepoint in the text
    // so that the caret can be placed on the line after the newline.
    // This synthetic line has no visual glyphs of its own.
    if (hasTrailingNewline) {
      if (!reachedMaxLines()) {
        _top += _layout.addLine(
          ClusterRange(start: _newlineEnd, end: _newlineEnd),
          ClusterRange(start: _newlineEnd, end: _newlineEnd),
          ClusterRange(start: _newlineEnd, end: _newlineEnd),
          _top,
          isSyntheticEmptyLine: true,
          // A trailing newline occurs only at the end of the text, so this
          // synthetic empty line is always the last line of the paragraph.
          isLastLine: true,
        );
      } else {
        _layout.paragraph.didExceedMaxLines = true;
      }
    }
    // Reset the line builder to be ready for the next line.

    _hasSoftLineBreak = false;
    _breakSoftHyphen = null;
    _breakIndex = -1;
    _isBreakTooWide = false;
    _fallbackBreak = null;

    start = _newlineEnd;
    _whitespaceStart = start;
    _whitespaceEnd = start;
    _newlineEnd = start;

    _widthConsumedText = 0.0;
    _widthWhitespaces = 0.0;

    // Leave `pendingTextEnd` and `widthPendingText` untouched so they are used in the next line.
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
        // Not really important. Could go without an ellipsis in this case.
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
      cutOffWidth += widthCluster;
      if (_isWhitespace(cluster)) {
        // We skip whitespaces when cutting off for ellipsis, so just continue
      } else if (canFit(ellipsisSpan.advanceWidth()! - cutOffWidth)) {
        // We can fit the ellipsis now
        _layout.ellipsisClusters = ellipsisSpan.extractClusters();
        break;
      }
      // Remove this cluster, correct the structures and try again
      assert(!hasHardLineBreak);
      clusterIndex -= 1;
      if (clusterIndex >= _newlineEnd) {
        _pendingTextEnd = clusterIndex;
      } else if (clusterIndex >= _whitespaceEnd) {
        _widthPendingText -= widthCluster;
        _pendingTextEnd = clusterIndex;
      } else if (clusterIndex >= _whitespaceStart) {
        _widthWhitespaces -= widthCluster;
        _whitespaceEnd = clusterIndex;
        _newlineEnd = clusterIndex;
      } else {
        _widthConsumedText -= widthCluster;
        _whitespaceStart = clusterIndex;
        _whitespaceEnd = clusterIndex;
        _newlineEnd = clusterIndex;
      }
    }

    return true;
  }

  bool _isWhitespace(WebCluster cluster) {
    return _layout.codeUnitFlags.hasFlag(cluster.start, CodeUnitFlag.whitespace) &&
        !_layout.codeUnitFlags.hasFlag(cluster.end, CodeUnitFlag.hardLineBreak);
  }
}

/// The state of a [_LineBuilder] right after a soft line break.
class _FallbackBreak {
  _FallbackBreak({
    required this.whitespaceStart,
    required this.whitespaceEnd,
    required this.newlineEnd,
    required this.widthConsumedText,
    required this.widthWhitespaces,
    required this.softHyphen,
    required this.breakIndex,
  });

  final int whitespaceStart;
  final int whitespaceEnd;
  final int newlineEnd;
  final double widthConsumedText;
  final double widthWhitespaces;
  final SoftHyphen? softHyphen;
  final int breakIndex;
}
