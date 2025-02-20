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
  int _endSoftBreak = 0;
  int _endCluster = 0;
  int _endWhitespaces = 0;


  double _widthSoftBreak = 0.0;
  double _widthCluster = 0.0;
  double _widthWhitespaces = 0.0;

  void startNewLine(int start) {
    _startLine = start;
    _endSoftBreak = start;
    _endCluster = start;
    _endWhitespaces = start;
    _widthSoftBreak = 0.0;
    _widthCluster = 0.0;
    _widthWhitespaces = 0.0;
  }

  void breakLines(double width) {
    this.startNewLine(0);

    for (int index = 0; index < _layout.textClusters.length; index++) {
      final WebTextCluster cluster = this._layout.textClusters[index];
      final DomRectReadOnly box = this._layout.textMetrics!.getActualBoundingBox(
        cluster.begin,
        cluster.end,
      );

      if (this._layout.hasFlag(ClusterRange(cluster.begin, cluster.end), CodeUnitFlags.kPartOfWhiteSpaceBreak)) {
        // This is possibly a hanging whitespace that does not increase the line width
        _endWhitespaces = index;
        _widthWhitespaces += box.width;
        continue;
      }


      if (_widthSoftBreak + _widthCluster + _widthWhitespaces + box.width > width) {
        // The current cluster does not fit the line
        if (_endSoftBreak != _startLine) {
          // We can break the text by soft line break
          this._layout.lines.add(TextLine(_layout,
                                  ClusterRange(_startLine, _endSoftBreak),
                                  _widthSoftBreak,
                                  ClusterRange(_endCluster, _endWhitespaces),
                                  _widthWhitespaces));
        } else if (_endCluster != _startLine) {
          // We will have to break the text by cluster
          this._layout.lines.add(TextLine(_layout,
                        ClusterRange(_startLine, _endCluster),
                        _widthCluster,
                        ClusterRange(_endCluster, _endWhitespaces),
                        _widthWhitespaces));
        } else {
          // We have only one cluster and it's too big to fit the line.
          // We choose to ignore this case, not clip the cluster and just
          // draw it as the case above
          this._layout.lines.add(TextLine(_layout,
              ClusterRange(_startLine, _endCluster),
              _widthCluster,
              ClusterRange(_endCluster, _endWhitespaces),
              _widthWhitespaces));
        }
        // Let's reset all the counters
        this.startNewLine(index);
        // Now we can process the current cluster as usual
      }

      // Line is not full, just increment all the counters accordingly
      if (this._layout.hasFlag(ClusterRange(cluster.begin, cluster.end), CodeUnitFlags.kSoftLineBreakBefore)) {
        // We have soft line break BEFORE the current cluster
        _endSoftBreak = index;
        _widthSoftBreak = _widthCluster;
      }
      // We have a cluster break by default
      if (this._layout.hasFlag(ClusterRange(cluster.begin, cluster.end), CodeUnitFlags.kPartOfWhiteSpaceBreak)) {
        // We have whitespaces, assuming it's hanging whitespaces for now
        _endWhitespaces = index + 1;
        _widthWhitespaces += box.width;
      } else {
        // This is just a regular cluster, keep track of it
        _endCluster = index + 1;
        _widthCluster += box.width;
      }
    }

    // Let's add all we have to the last line
    if (_endWhitespaces > _startLine) {
      this._layout.lines.add(TextLine(_layout,
          ClusterRange(_startLine, _endCluster),
          _widthCluster,
          ClusterRange(_endCluster, _endWhitespaces),
          _widthWhitespaces));
    }

    for (int i = 0; i < this._layout.lines.length; ++i) {
      final TextLine line = this._layout.lines[i];
      final String text = _text.substring(line.clusterRange.start, line.clusterRange.end);
      print('${i}: "${text}" [${line.clusterRange.start}:${line.clusterRange.end}) (${line.whitespacesRange.width()} whitespaces)');
    }
  }
}
