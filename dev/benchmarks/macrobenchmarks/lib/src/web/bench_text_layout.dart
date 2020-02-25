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
class BenchTextDomLayout extends RawRecorder {
  BenchTextDomLayout() : super(name: benchmarkName);

  static const String benchmarkName = 'text_dom_layout';

  Paragraph paragraph;

  @override
  void setUp() {
    paragraph = _generateParagraph();
  }

  @override
  void tearDown() {
    paragraph = null;
  }

  @override
  void body() {
    paragraph.layout(ParagraphConstraints(width: double.infinity));
  }
}

/// Repeatedly lays out a paragraph using the DOM measurement approach.
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

  Paragraph paragraph;

  @override
  void setUp() {
    // Create a new paragraph for each run, but use the same builder so the
    // generated paragraphs are all the same (and so they get cached by the
    // measurement service).
    paragraph = builder.build();
  }

  @override
  void tearDown() {
    paragraph = null;
  }

  @override
  void body() {
    paragraph.layout(ParagraphConstraints(width: double.infinity));
  }
}
