// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'recorder.dart';

int _counter = 0;

Paragraph _generateParagraph() {
  final ParagraphBuilder builder =
      ParagraphBuilder(ParagraphStyle(fontFamily: 'sans-serif'))
        ..pushStyle(TextStyle(fontSize: 12.0))
        ..addText(
          '$_counter Lorem ipsum dolor sit amet, consectetur adipiscing elit, '
          'sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
        );
  _counter++;
  return builder.build();
}

/// Repeatedly lays out a paragraph using the DOM measurement approach.
///
/// Creates a different paragraph each time in order to avoid hitting the cache.
class BenchTextDomLayout extends RawRecorder {
  BenchTextDomLayout() : super(name: benchmarkName);

  static const String benchmarkName = 'text_dom_layout';

  @override
  void body(Profile profile) {
    final Paragraph paragraph = _generateParagraph();
    profile.record('layout', () {
      paragraph.layout(const ParagraphConstraints(width: double.infinity));
    });
  }
}

/// Repeatedly lays out a paragraph using the DOM measurement approach.
///
/// Uses the same paragraph content to make sure we hit the cache. It doesn't
/// use the same paragraph instance because the layout method will shortcircuit
/// in that case.
class BenchTextDomCachedLayout extends RawRecorder {
  BenchTextDomCachedLayout() : super(name: benchmarkName);

  static const String benchmarkName = 'text_dom_cached_layout';

  final ParagraphBuilder builder =
      ParagraphBuilder(ParagraphStyle(fontFamily: 'sans-serif'))
        ..pushStyle(TextStyle(fontSize: 12.0))
        ..addText(
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit, '
          'sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
        );

  @override
  void body(Profile profile) {
    final Paragraph paragraph = builder.build();
    profile.record('layout', () {
      paragraph.layout(const ParagraphConstraints(width: double.infinity));
    });
  }
}
