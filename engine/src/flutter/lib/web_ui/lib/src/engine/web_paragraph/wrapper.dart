// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import 'paragraph.dart';
import 'layout.dart';
import 'code_unit_flags.dart';

/// Wraps the text by a given width.
class TextWrapper {
  TextWrapper(this._text, this._layout) {
    this.startNewLine(0, 0.0);
  }

  final String     _text;
  final TextLayout _layout;

  int _startLine = 0;
  // Whitespaces always separates text from clusters even if it's empty
  ClusterRange _whitespaces = ClusterRange(0, 0);

  double _widthText = 0.0;        // English: contains all whole words on the line
  double _widthWhitespaces = 0.0;
  double _widthLetters = 0.0;     // English: contains all the letters that didn't make the whole word yet

  bool isWhitespace(WebTextCluster cluster) {
    return this._layout.hasFlag(ClusterRange(cluster.begin, cluster.end), CodeUnitFlags.kPartOfWhiteSpaceBreak);
  }

  bool isLineBreak(WebTextCluster cluster) {
    return this._layout.hasFlag(ClusterRange(cluster.begin, cluster.end), CodeUnitFlags.kSoftLineBreakBefore);
  }

  void startNewLine(int start, double clusterWidth) {
    _startLine = start;
    _whitespaces = ClusterRange(start, start);
    _widthText = 0.0;
    _widthWhitespaces = 0.0;
    _widthLetters = clusterWidth;
  }

  void breakLines(double width) {
    // "words":[startLine:whitespaces.start) whitespaces:[whitespaces.start:whitespaces.end) "letters":[whitespaces.end:...)

    this.startNewLine(0, 0.0);

    for (int index = 0; index < _layout.textClusters.length; index++) {

      final WebTextCluster cluster = this._layout.textClusters[index];
      final DomRectReadOnly box = this._layout.textMetrics!.getActualBoundingBox(cluster.begin, cluster.end);
      final List<DomRectReadOnly> rects = this._layout.textMetrics!.getSelectionRects(cluster.begin, cluster.end);
      final double widthCluster = rects[0].width;

      if (isWhitespace(cluster)) {
        // This is (possibly) a hanging whitespace that does not increase the actual line width
        // The current cluster is a part of a whitespace sequence but not a leading whitespaces
        if (_whitespaces.end < index) {
          // All the widths
          _widthText += (_widthWhitespaces + _widthLetters);
          _widthLetters = 0.0;
          // Start a new whitespaces sequence
          _whitespaces = ClusterRange(index, index);
          _widthWhitespaces = 0.0;
        }
        // Continue the current whitespaces sequence
        _whitespaces.end = index + 1;
        _widthWhitespaces += widthCluster;
        continue;
      }

      if (_widthText + _widthWhitespaces + _widthLetters + widthCluster > width) {
        // The current text cluster does not fit the line
        if (_whitespaces.start != _startLine) {
          // There was at least one possible line break so we can use it to break the text
          this._layout.lines.add(TextLine(_layout,
                                  ClusterRange(_startLine, _whitespaces.start),
                                  _widthText,
                                  ClusterRange(_whitespaces.start, _whitespaces.end),
                                 _widthWhitespaces));

          // Start a new line but keep the clusters sequence
          this.startNewLine(_whitespaces.end, _widthLetters);
         } else if (_whitespaces.start == _startLine) {
          // There was not a single line break detected
          // There should be only "letters" and possibly whitespaces before which we are going to treat as regular text
          assert(_widthText == 0.0);
          // There was not a single line break, we will have to break the text by cluster
          this._layout.lines.add(TextLine(_layout,
                        ClusterRange(_startLine, index),
                        _widthWhitespaces + _widthLetters,
                        ClusterRange(index, index),
                        0.0));
          // Start a new line with the current cluster as a cluster sequence
          this.startNewLine(index, 0);
         } else {
          // We have only one cluster and it's too big to fit the line.
          // We choose to ignore this case, not clip the cluster and just draw it
          // There should not be any whitespaces
          assert(_startLine == index && _widthText == 0.0 && _widthWhitespaces == 0.0 && _widthLetters == 0.0);
          this._layout.lines.add(TextLine(_layout,
              ClusterRange(_startLine, index + 1),
              widthCluster,
              ClusterRange(index + 1, index + 1),
              0.0));
          this.startNewLine(index + 1, 0.0);
          // We already processed the current cluster (the only one on the line)
          continue;
        }
        // At this point we have a new line and can process the current cluster as usual
      }

      // This is just a regular cluster, keep track of it
      if (isLineBreak(cluster) && index != _startLine) {
        // We ignore a line break at the very beginning of the line
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

      // Continue with the current cluster sequence
      _widthLetters += widthCluster;
    }

    // Assume a soft line break at the end of the text
    if (_whitespaces.end != _layout.textClusters.length) {
      // We have letters at the end, make them into a word
      _widthText += _widthWhitespaces;
      _whitespaces = ClusterRange(_layout.textClusters.length, _layout.textClusters.length);
      _widthWhitespaces = 0.0;
      _widthText += _widthLetters;
    }

    this._layout.lines.add(TextLine(_layout,
      ClusterRange(_startLine, _whitespaces.start),
      _widthText,
      ClusterRange(_whitespaces.start, _whitespaces.end),
      _widthWhitespaces));
    /*
    for (int i = 0; i < this._layout.lines.length; ++i) {
      final TextLine line = this._layout.lines[i];
      final String text = _text.substring(line.clusterRange.start, line.clusterRange.end);
      final String whitespaces = line.whitespacesRange.width() > 0 ? '${line.whitespacesRange.width()}' : 'no';
      print('${i}: "${text}" [${line.clusterRange.start}:${line.clusterRange.end}) ${width} (${whitespaces} trailing whitespaces)');
    }
    */
  }
}
