// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'dart:math';
import 'dart:ui';

import 'package:meta/meta.dart';

import 'recorder.dart';

const String chars = '1234567890'
    'abcdefghijklmnopqrstuvwxyz'
    'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    '!@#%^&()[]{}<>,./?;:"`~-_=+|';

String _randomize(String text) {
  return text.replaceAllMapped(
    '*',
    // Passing a seed so the results are reproducible.
    (_) => chars[Random(0).nextInt(chars.length)],
  );
}

class ParagraphGenerator {
  int _counter = 0;

  /// Randomizes the given [text] and creates a paragraph with a unique
  /// font-size so that the engine doesn't reuse a cached ruler.
  Paragraph generate(
    String text, {
    int maxLines,
    bool hasEllipsis = false,
  }) {
    final ParagraphBuilder builder = ParagraphBuilder(ParagraphStyle(
      fontFamily: 'sans-serif',
      maxLines: maxLines,
      ellipsis: hasEllipsis ? '...' : null,
    ))
      // Start from a font-size of 8.0 and go up by 0.01 each time.
      ..pushStyle(TextStyle(fontSize: 8.0 + _counter * 0.01))
      ..addText(_randomize(text));
    _counter++;
    return builder.build();
  }
}

/// Sends a platform message to the web engine to enable/disable the usage of
/// the new canvas-based text measurement implementation.
void _useCanvasText(bool useCanvasText) {
  js_util.callMethod(
    html.window,
    '_flutter_internal_update_experiment',
    <dynamic>['useCanvasText', useCanvasText],
  );
}

/// Repeatedly lays out a paragraph using the DOM measurement approach.
///
/// Creates a different paragraph each time in order to avoid hitting the cache.
class BenchTextLayout extends RawRecorder {
  BenchTextLayout({@required this.useCanvas})
      : super(name: useCanvas ? canvasBenchmarkName : domBenchmarkName);

  static const String domBenchmarkName = 'text_dom_layout';
  static const String canvasBenchmarkName = 'text_canvas_layout';

  final ParagraphGenerator generator = ParagraphGenerator();

  /// Whether to use the new canvas-based text measurement implementation.
  final bool useCanvas;

  static const String singleLineText = '*** ** ****';
  static const String multiLineText = '*** ****** **** *** ******** * *** '
      '******* **** ********** *** ******* '
      '**** ***** *** ******** *** ********* '
      '** * *** ******* ***********';

  @override
  void body(Profile profile) {
    _useCanvasText(useCanvas);

    recordParagraphOperations(
      profile: profile,
      paragraph: generator.generate(singleLineText),
      text: singleLineText,
      keyPrefix: 'single_line',
      maxWidth: 800.0,
    );

    recordParagraphOperations(
      profile: profile,
      paragraph: generator.generate(multiLineText),
      text: multiLineText,
      keyPrefix: 'multi_line',
      maxWidth: 200.0,
    );

    recordParagraphOperations(
      profile: profile,
      paragraph: generator.generate(multiLineText, maxLines: 2),
      text: multiLineText,
      keyPrefix: 'max_lines',
      maxWidth: 200.0,
    );

    recordParagraphOperations(
      profile: profile,
      paragraph: generator.generate(multiLineText, hasEllipsis: true),
      text: multiLineText,
      keyPrefix: 'ellipsis',
      maxWidth: 200.0,
    );

    _useCanvasText(null);
  }

  void recordParagraphOperations({
    @required Profile profile,
    @required Paragraph paragraph,
    @required String text,
    @required String keyPrefix,
    @required double maxWidth,
  }) {
    profile.record('$keyPrefix.layout', () {
      paragraph.layout(ParagraphConstraints(width: maxWidth));
    });
    profile.record('$keyPrefix.getBoxesForRange', () {
      for (int start = 0; start < text.length; start += 3) {
        for (int end = start + 1; end < text.length; end *= 2) {
          paragraph.getBoxesForRange(start, end);
        }
      }
    });
    profile.record('$keyPrefix.getPositionForOffset', () {
      for (double dx = 0.0; dx < paragraph.width; dx += 10.0) {
        for (double dy = 0.0; dy < paragraph.height; dy += 10.0) {
          paragraph.getPositionForOffset(Offset(dx, dy));
        }
      }
    });
  }
}

/// Repeatedly lays out a paragraph using the DOM measurement approach.
///
/// Uses the same paragraph content to make sure we hit the cache. It doesn't
/// use the same paragraph instance because the layout method will shortcircuit
/// in that case.
class BenchTextCachedLayout extends RawRecorder {
  BenchTextCachedLayout({@required this.useCanvas})
      : super(name: useCanvas ? canvasBenchmarkName : domBenchmarkName);

  static const String domBenchmarkName = 'text_dom_cached_layout';
  static const String canvasBenchmarkName = 'text_canvas_cached_layout';

  /// Whether to use the new canvas-based text measurement implementation.
  final bool useCanvas;

  final ParagraphBuilder builder =
      ParagraphBuilder(ParagraphStyle(fontFamily: 'sans-serif'))
        ..pushStyle(TextStyle(fontSize: 12.0))
        ..addText(
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit, '
          'sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
        );

  @override
  void body(Profile profile) {
    _useCanvasText(useCanvas);
    final Paragraph paragraph = builder.build();
    profile.record('layout', () {
      paragraph.layout(const ParagraphConstraints(width: double.infinity));
    });
    _useCanvasText(null);
  }
}
