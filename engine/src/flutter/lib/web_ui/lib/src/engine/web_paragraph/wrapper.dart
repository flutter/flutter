// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/src/engine.dart' as engine;
import 'package:ui/ui.dart' as ui;

import '../dom.dart';
import 'code_unit_flags.dart';
import 'debug.dart';
import 'layout.dart';
import 'paragraph.dart';

/// Wraps the text by a given width.
class TextWrapper {
  TextWrapper(this._text, this._layout) {
    startNewLine(0, 0.0);
  }

  final String _text;
  final TextLayout _layout;

  int _startLine = 0;

  // Whitespaces always separates text from clusters even if it's empty
  ClusterRange _whitespaces = ClusterRange.empty;

  double _widthText = 0.0; // English: contains all whole words on the line
  double _widthWhitespaces = 0.0;
  double _widthLetters =
      0.0; // English: contains all the letters that didn't make the whole word yet

  bool isWhitespace(ExtendedTextCluster cluster) {
    return _layout.hasFlag(
      ui.TextRange(start: cluster.start, end: cluster.end),
      CodeUnitFlags.kPartOfWhiteSpaceBreak,
    );
  }

  bool isSoftLineBreak(ExtendedTextCluster cluster) {
    return _layout.hasFlag(
      ui.TextRange(start: cluster.start, end: cluster.end),
      CodeUnitFlags.kSoftLineBreakBefore,
    );
  }

  bool isHardLineBreak(ExtendedTextCluster cluster) {
    return _layout.hasFlag(
      ui.TextRange(start: cluster.start, end: cluster.end),
      CodeUnitFlags.kHardLineBreakBefore,
    );
  }

  void startNewLine(int start, double clusterWidth) {
    _startLine = start;
    _whitespaces = ClusterRange(start: start, end: start);
    _widthText = 0.0;
    _widthWhitespaces = 0.0;
    _widthLetters = clusterWidth;
  }

  void breakLines(double width) {
    // "words":[startLine:whitespaces.start) whitespaces:[whitespaces.start:whitespaces.end) "letters":[whitespaces.end:...)

    startNewLine(0, 0.0);

    bool hardLineBreak = false;
    for (int index = 0; index < _layout.textClusters.length; index++) {
      final ExtendedTextCluster cluster = _layout.textClusters[index];
      /*
      final DomRectReadOnly box = this._layout.textMetrics!.getActualBoundingBox(
        cluster.begin,
        cluster.end,
      );
      final List<DomRectReadOnly> rects = this._layout.textMetrics!.getSelectionRects(
        cluster.begin,
        cluster.end,
      );
      */
      // TODO: This is a temporary simplification, needs to be addressed later
      double widthCluster = cluster.size.width;
      hardLineBreak = isHardLineBreak(cluster);
      final softLineBreak = isSoftLineBreak(cluster);

      if (hardLineBreak) {
        // Break the line and then continue with the current cluster as usual
        if (_whitespaces.end < index) {
          // Take letters into account
          _widthText += _widthWhitespaces + _widthLetters;
          _whitespaces.start = index;
          _whitespaces.end = index;
        }
        _layout.lines.add(
          TextLine(
            _layout,
            ClusterRange(start: _startLine, end: _whitespaces.start),
            _widthText,
            ClusterRange(start: _whitespaces.start, end: _whitespaces.end),
            _widthWhitespaces,
            hardLineBreak,
          ),
        );
        // Start a new line
        startNewLine(index, 0.0);
      } else if (isSoftLineBreak(cluster) && index != _startLine) {
        // Mark the potential line break and then continue with the current cluster as usual
        if (_whitespaces.start == _startLine) {
          // There is one case when we have to ignore this soft line break: if we only had whitespaces so far -
          // these are the leading spaces and Flutter wants them to be preserved
          // We need to pretend that these are not whitespaces
        } else {
          if (_whitespaces.end != index) {
            // Line break without whitespaces before, add all collected letters to the text as a word
            _widthText += _widthLetters;
            _whitespaces.start = index;
          }
          // Close the softBreak sequence
          _whitespaces.end = index;
          // Start a new cluster sequence
          _widthLetters = 0.0;
        }
      }

      // Check if we have a (hanging) whitespace which does not affect the line width
      if (isWhitespace(cluster)) {
        if (_whitespaces.end < index) {
          // Start a new (empty) whitespace sequence
          _widthText += _widthWhitespaces + _widthLetters;
          _widthLetters = 0.0;
          _whitespaces = ClusterRange(start: index, end: index);
          _widthWhitespaces = 0.0;
        }
        // Add the cluster to the current whitespace sequence (empty or not)
        _whitespaces.end = index + 1;
        _widthWhitespaces += widthCluster;
        continue;
      }

      // Check if we exceeded the line width
      if (_widthText + _widthWhitespaces + _widthLetters + widthCluster > width) {
        if (_whitespaces.start != _startLine) {
          // There was at least one possible line break so we can use it to break the text
        } else if (index > _startLine) {
          // There was some text without line break, we will have to break the text by cluster
          assert(_widthText == 0.0);
          if (_widthLetters > 0) {
            // We possibly have some leading spaces and some text after
            _widthText = _widthWhitespaces + _widthLetters;
            _widthWhitespaces = 0.0;
            _widthLetters = 0.0;
            _whitespaces.start = index;
            _whitespaces.end = index;
          } else {
            // We only have whitespaces on the line
            _widthText = 0.0;
          }
        } else {
          // We have only one cluster and it's too big to fit the line but we place it anyway
          assert(
            _startLine == index &&
                _widthText == 0.0 &&
                _widthWhitespaces == 0.0 &&
                _widthLetters == 0.0,
          );
          _widthText = widthCluster;
          _whitespaces.start = index + 1;
          _whitespaces.end = index + 1;
          widthCluster = 0.0; // Since we already processed this cluster
        }

        // Add the line
        _layout.lines.add(
          TextLine(
            _layout,
            ClusterRange(start: _startLine, end: _whitespaces.start),
            _widthText,
            ClusterRange(start: _whitespaces.start, end: _whitespaces.end),
            _widthWhitespaces,
            hardLineBreak,
          ),
        );

        // Start a new line but keep the clusters sequence
        startNewLine(_whitespaces.end, _widthLetters);
      }

      // This is just a regular cluster, keep track of it
      _widthLetters += widthCluster;
    }

    // Assume a soft line break at the end of the text
    if (_whitespaces.end != _layout.textClusters.length) {
      // We have letters at the end, make them into a word
      _widthText += _widthWhitespaces;
      _whitespaces = ClusterRange(
        start: _layout.textClusters.length,
        end: _layout.textClusters.length,
      );
      _widthWhitespaces = 0.0;
      _widthText += _widthLetters;
    }

    _layout.lines.add(
      TextLine(
        _layout,
        ClusterRange(start: _startLine, end: _whitespaces.start),
        _widthText,
        ClusterRange(start: _whitespaces.start, end: _whitespaces.end),
        _widthWhitespaces,
        hardLineBreak,
      ),
    );

    if (hardLineBreak) {
      // TODO: Discuss with Mouad
      // Flutter wants to have another (empty) line if \n is the last codepoint in the text
      final emptyText = ClusterRange(
        start: _layout.textClusters.length,
        end: _layout.textClusters.length,
      );
      _layout.lines.add(TextLine(_layout, emptyText, 0.0, emptyText, 0.0, false));
    }

    if (WebParagraphDebug.logging) {
      for (int i = 0; i < _layout.lines.length; ++i) {
        final TextLine line = _layout.lines[i];
        final String text = _text.substring(line.clusterRange.start, line.clusterRange.end);
        final String whitespaces =
            !line.whitespacesRange.isEmpty ? '${line.whitespacesRange.width}' : 'no';
        final String hardLineBreak = line.hardLineBreak ? 'hardlineBreak' : '';
        WebParagraphDebug.log(
          '$i: "$text" [${line.clusterRange.start}:${line.clusterRange.end}) $width $hardLineBreak ($whitespaces trailing whitespaces)',
        );
      }
    }
  }
}
