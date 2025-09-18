// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
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
  double _minIntrinsicWidth = double.infinity;

  bool isWhitespace(ExtendedTextCluster cluster) {
    return _layout.codeUnitFlags.hasFlag(cluster.globalStart, CodeUnitFlag.whitespace);
  }

  bool isSoftLineBreak(ExtendedTextCluster cluster) {
    return _layout.codeUnitFlags.hasFlag(cluster.globalStart, CodeUnitFlag.softLineBreak);
  }

  bool isHardLineBreak(ExtendedTextCluster cluster) {
    return _layout.codeUnitFlags.hasFlag(cluster.globalStart, CodeUnitFlag.hardLineBreak);
  }

  void breakLines(double maxWidth) {
    // LTR: "words":[startLine:whitespaces.start) "whitespaces":[whitespaces.start:whitespaces.end) "letters":[whitespaces.end:...)
    // RTL: "letters":(...:whitespaces.end] "whitespaces":(whitespaces.end:whitespaces.start] "words":(whitespaces.start:startLine]

    final _LineBuilder line = _LineBuilder(_layout, maxWidth);

    bool hardLineBreak = false;
    for (int index = 0; index < _layout.allClusters.length; index += 1) {
      final ExtendedTextCluster cluster = _layout.allClusters[index];
      final double widthCluster = cluster.advance.width;
      hardLineBreak = isHardLineBreak(cluster);

      if (hardLineBreak) {
        // Break the line and then continue with the current cluster as usual
        WebParagraphDebug.log('isHardLineBreak: $index');

        _minIntrinsicWidth = math.max(_minIntrinsicWidth, line.widthTrailingText);
        line.subsumeTrailingText();

        _maxIntrinsicWidth = math.max(_maxIntrinsicWidth, line.widthText);
        line.build(hardLineBreak);
      } else if (isSoftLineBreak(cluster) && index != line.start) {
        // Mark the potential line break and then continue with the current cluster as usual
        WebParagraphDebug.log('isSoftLineBreak: $index');
        if (line.hasLeadingWhitespaces) {
          // There is one case when we have to ignore this soft line break: if we only had whitespaces so far -
          // these are the leading spaces and Flutter wants them to be preserved
          // We need to pretend that these are not whitespaces
        } else {
          _minIntrinsicWidth = math.max(_minIntrinsicWidth, line.widthTrailingText);
          line.markSoftLineBreak(index);

          // TODO(mdebbar=>jlavrova): Not sure about this one..

          // // Close the softBreak sequence
          // _whitespaces.end = index;
          // // Start a new cluster sequence
          // _widthTrailingText = 0.0;
        }
      }

      // Check if we have a trailing whitespace that does not affect the line width
      if (isWhitespace(cluster)) {
        _minIntrinsicWidth = math.max(_minIntrinsicWidth, line.widthTrailingText);
        line.subsumeTrailingText();
        // Add the cluster to the current whitespace sequence (empty or not)
        line.addWhitespace(index, widthCluster);
        continue;
      }

      // Check if we exceeded the line width
      if (!line.canFit(widthCluster)) {
        bool clusterAdded = false;

        if (line.hasSoftLineBreak) {
          // There was at least one possible line break so we can use it to break the text
        } else if (index > line.start) {
          // There was some text without line break, we will have to force-break the text at this cluster.
          assert(line.widthText == 0.0);
          // TODO(mdebbar): Is this right? Should we update min intrinsic width when we force-break the line?
          _minIntrinsicWidth = math.max(_minIntrinsicWidth, line.widthTrailingText);
          // We possibly have some leading spaces and some text after
          line.subsumeTrailingText();
        } else {
          // We have only one cluster and it's too big to fit the line but we place it anyway
          assert(
            line.start == index &&
                line.widthText == 0.0 &&
                line.widthWhitespaces == 0.0 &&
                line.widthTrailingText == 0.0,
          );
          line.addTrailingText(index, widthCluster);
          line.subsumeTrailingText();
          clusterAdded = true;
        }

        // Add the line
        _maxIntrinsicWidth = math.max(_maxIntrinsicWidth, line.widthText);
        line.build(hardLineBreak);

        if (clusterAdded) {
          continue;
        }
      }

      // This is just a regular cluster, add it as trailing text.
      line.addTrailingText(index, widthCluster);
    }

    // Add the last line if there's anything left to add.
    if (line.start < _layout.allClusters.length) {
      // Treat the end of text as a line break
      _minIntrinsicWidth = math.max(_minIntrinsicWidth, line.widthTrailingText);
      line.markSoftLineBreak(_layout.allClusters.length);

      _maxIntrinsicWidth = math.max(_maxIntrinsicWidth, line.widthText);
      line.build(hardLineBreak);
    }

    // TODO(mdebbar=>jlavrova): Discuss with Mouad
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
      whitespaceStart = 0,
      whitespaceEnd = 0,
      trailingTextEnd = 0,
      _top = 0.0;

  final TextLayout _layout;
  final double _maxWidth;

  double _top;

  int start;

  int whitespaceStart;
  int whitespaceEnd;

  int trailingTextEnd;

  double widthText = 0.0;
  double widthWhitespaces = 0.0;
  double widthTrailingText = 0.0;

  bool get _hasWhitespaces => whitespaceStart != whitespaceEnd;

  bool get hasLeadingWhitespaces => whitespaceStart == start && _hasWhitespaces;
  bool get _hasTrailingText => trailingTextEnd > whitespaceEnd;

  bool _hasSoftLineBreak = false;
  bool get hasSoftLineBreak => _hasSoftLineBreak;

  void markSoftLineBreak(int index) {
    _hasSoftLineBreak = true;

    if (_hasTrailingText) {
      assert(trailingTextEnd == index);
    } else {
      assert(whitespaceEnd == index);
    }

    subsumeTrailingText();
    assert(whitespaceEnd == index);
  }

  bool canFit(double extraWidth) {
    return widthText + widthWhitespaces + widthTrailingText + extraWidth <= _maxWidth;
  }

  void addWhitespace(int index, double width) {
    assert(!_hasTrailingText);

    whitespaceEnd = index + 1;
    trailingTextEnd = index + 1;

    widthWhitespaces += width;

    assert(_hasWhitespaces);
  }

  void addTrailingText(int index, double width) {
    trailingTextEnd = index + 1;
    widthTrailingText += width;

    assert(_hasTrailingText);
  }

  // TODO(mdebbar): Can we inline this in `markSoftLineBreak` and use that everywhere?
  void subsumeTrailingText() {
    if (!_hasTrailingText) {
      return;
    }

    whitespaceStart = trailingTextEnd;
    whitespaceEnd = trailingTextEnd;

    widthText += widthWhitespaces + widthTrailingText;
    widthWhitespaces = 0.0;
    widthTrailingText = 0.0;

    assert(!_hasWhitespaces);
    assert(!_hasTrailingText);
  }

  /// Builds a line and adds it to [_layout].
  ///
  /// After calling [build], the line builder instance is ready for the next line.
  ///
  /// Returns the height of the line.
  double build(bool hardLineBreak) {
    final double height = _layout.addLine(
      ClusterRange(start: start, end: whitespaceStart),
      ClusterRange(start: whitespaceStart, end: whitespaceEnd),
      hardLineBreak,
      _top,
    );

    // Reset the line builder to be ready for the next line.

    _hasSoftLineBreak = false;

    start = whitespaceEnd;
    whitespaceStart = start;
    whitespaceEnd = start;

    widthText = 0.0;
    widthWhitespaces = 0.0;

    // Leave `trailingTextEnd` and `widthTrailingText` untouched so they are used in the next line.

    _top += height;

    return height;
  }
}
