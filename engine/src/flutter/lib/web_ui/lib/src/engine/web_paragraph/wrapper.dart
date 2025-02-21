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
  TextWrapper(this._text, this._layout);

  final String     _text;
  final TextLayout _layout;

  int _startLine = 0;
  int _softBreak = 0;
  int _clusters = 0;
  int _whitespaces = 0;


  double _widthSoftBreak = 0.0;
  double _widthClusters = 0.0;
  double _widthWhitespaces = 0.0;

  void startNewLine(int start) {
    _startLine = start;
    _whitespaces = start;
    _softBreak = start;
    _clusters = start;
    _widthSoftBreak = 0.0;
    _widthClusters = 0.0;
    _widthWhitespaces = 0.0;
  }

  void breakLines(double width) {
    // Indexes on the line:
    // startLine ... [whitespaces ...] softBreak ... clusters

    this.startNewLine(0);

    for (int index = 0; index < _layout.textClusters.length; index++) {
      final WebTextCluster cluster = this._layout.textClusters[index];
      final DomRectReadOnly box = this._layout.textMetrics!.getActualBoundingBox(cluster.begin, cluster.end);
      final List<DomRectReadOnly> rects = this._layout.textMetrics!.getSelectionRects(cluster.begin, cluster.end);
      final double boxWidth = rects[0].width;
      final double sum = _widthSoftBreak + _widthClusters + boxWidth;
      print('Current: ${index} "${_text[index]}":${boxWidth} ${_startLine} < ${_whitespaces} < ${_softBreak} < ${_clusters} ${_widthSoftBreak} + ${_widthClusters} + ${boxWidth} = ${sum} > ${width} (${_widthWhitespaces})');

      if (this._layout.hasFlag(ClusterRange(cluster.begin, cluster.end), CodeUnitFlags.kPartOfWhiteSpaceBreak)) {
        // This is possibly a hanging whitespace that does not increase the line width
        print('Whitespace detected at ${index}');

        // There is one case when we have to ignore this soft line break: if we only had whitespaces so far -
        // these are the leading spaces and Flutter wants them to be preserved
        // We need to pretend that these are not whitespaces
        if (_whitespaces == _startLine) {
          print("Turn whitespaces into regular clusters1");
        } else {
          if (_softBreak < _clusters) {
            // Start whitespaces sequence
            _whitespaces = index;
            _widthWhitespaces = boxWidth;
          } else {
            _widthWhitespaces += boxWidth;
          }

          // Continue with softBreak sequence
          _softBreak = index + 1;
          _widthSoftBreak += _widthClusters + boxWidth;

          // Start a new cluster sequence
          _clusters = index + 1;
          _widthClusters = 0.0;

          continue;
        }
      }

      if (_widthSoftBreak + _widthClusters + boxWidth > width) {
        // The current text cluster does not fit the line
        if (_softBreak != _startLine) {
          // We can break the text by soft line break
          print('Break by softBreak [${_startLine}:${_whitespaces}) + [${_whitespaces}:${_softBreak}) = ${_widthSoftBreak - _widthWhitespaces} + ${_widthWhitespaces}');
          this._layout.lines.add(TextLine(_layout,
                                  ClusterRange(_startLine, _whitespaces),
                                  _widthSoftBreak - _widthWhitespaces,
                                  ClusterRange(_whitespaces, _softBreak),
                                 _widthWhitespaces));
          //this.startNewLine(_softBreak);
          // Keep the clusters sequence
          _startLine = _softBreak;
          _whitespaces = _softBreak;
          _widthSoftBreak = 0.0;
          _widthWhitespaces = 0.0;

        } else if (_clusters != _startLine) {
          // We will have to break the text by cluster
          print('Break by cluster [${_startLine}:${_clusters}) + [${_clusters}:${_clusters}) = ${_widthClusters} + 0.0');
          // There should not be any whitespaces - we have no softBreaks and the line cannot start from whitespaces
          assert(_whitespaces == _softBreak);
          this._layout.lines.add(TextLine(_layout,
                        ClusterRange(_startLine, _clusters),
                        _widthClusters,
                        ClusterRange(_clusters, _clusters),
                        0.0));
          this.startNewLine(_clusters);

        } else {
          // We have only one cluster and it's too big to fit the line.
          // We choose to ignore this case, not clip the cluster and just
          // draw it as the case above
          print('Break by nothing at ${index}: ${_startLine} < ${_whitespaces} < ${_softBreak} < ${_clusters}');
          // There should not be any whitespaces
          assert(_whitespaces == _softBreak);
          this._layout.lines.add(TextLine(_layout,
              ClusterRange(_startLine, _clusters),
              _widthClusters,
              ClusterRange(_clusters, _clusters),
              0.0));
          this.startNewLine(_clusters);
        }
        // Now we can process the current cluster as usual
      }

      // This is just a regular cluster, keep track of it
      if (this._layout.hasFlag(ClusterRange(cluster.begin, cluster.end), CodeUnitFlags.kSoftLineBreakBefore)) {
        print('SoftBreak detected at ${index}');

        // There is one case when we have to ignore this soft line break: if we only had whitespaces so far -
        // these are the leading spaces and Flutter wants them to be preserved
        // We need to pretend that these are not whitespaces
        if (_whitespaces == _startLine) {
          print("Turn whitespaces into regular clusters2");
        } else {
          // Close the softBreak sequence
          _softBreak = index;
        }
      }

      // Start new cluster sequence
      _clusters = index + 1;
      _widthClusters += boxWidth;
    }

    final double sum = _widthSoftBreak + _widthClusters;
    print('LastLine: ${_layout.textClusters.length} "" ${_startLine} < ${_whitespaces} < ${_softBreak} < ${_clusters} ${_widthSoftBreak} + ${_widthClusters} = ${sum} > ${width} (${_widthWhitespaces})');

    // Let's add all we have to the last line
    // Correct all ranges (they have to end just outside of text range)
    if (_clusters > _softBreak) {
      // There are some clusters, so there will be no softBreaks and no whitespaces
      _softBreak = _layout.textClusters.length;
      _widthSoftBreak += _widthClusters;
      _whitespaces = _layout.textClusters.length;
      _widthWhitespaces = 0.0;
    } else if (_whitespaces < _softBreak) {
      // There are some whitespaces (but no clusters!). Keep it as is
      assert(_widthClusters == 0.0);
      _softBreak = _layout.textClusters.length;
    } else {
      // Not sure if we can get here... But there are no whitespaces and no clusters
      _softBreak = _layout.textClusters.length;
      _whitespaces = _layout.textClusters.length;
      assert(_widthWhitespaces == 0.0);
    }

    this._layout.lines.add(TextLine(_layout,
        ClusterRange(_startLine, _whitespaces),
        _widthWhitespaces,
        ClusterRange(_whitespaces, _softBreak),
        _widthSoftBreak -_widthWhitespaces));

    for (int i = 0; i < this._layout.lines.length; ++i) {
      final TextLine line = this._layout.lines[i];
      final String text = _text.substring(line.clusterRange.start, line.clusterRange.end);
      final String whitespaces = line.whitespacesRange.width() > 0 ? '${line.whitespacesRange.width()}' : 'no';
      print('${i}: "${text}" [${line.clusterRange.start}:${line.clusterRange.end}) (${whitespaces} trailing whitespaces)');
    }
  }
}
