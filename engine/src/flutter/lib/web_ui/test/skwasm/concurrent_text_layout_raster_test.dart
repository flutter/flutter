// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart' show renderer;
import 'package:ui/ui.dart' as ui;

import '../common/rendering.dart';
import '../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

const int _maxFrames = 200;
const Duration _maxTestTime = Duration(seconds: 10);
const int _paragraphsPerFrame = 24;
const int _spansPerParagraph = 3;

const List<String> _fontFamilies = <String>['Roboto', 'RobotoVariable', 'Ahem'];
const List<ui.FontWeight> _fontWeights = <ui.FontWeight>[
  ui.FontWeight.w100,
  ui.FontWeight.w300,
  ui.FontWeight.w400,
  ui.FontWeight.w500,
  ui.FontWeight.w700,
  ui.FontWeight.w900,
];

Future<void> testMain() async {
  setUpUnitTests(withImplicitView: true, setUpTestViewDimensions: false);

  // Advanced by an irrational stride so fractional font sizes never repeat,
  // forcing a fresh SkStrike for every span.
  double fontSizeSeed = 0;

  List<ui.Paragraph> buildAndLayoutParagraphs(int frame) {
    final paragraphs = <ui.Paragraph>[];
    for (var i = 0; i < _paragraphsPerFrame; i++) {
      final builder = ui.ParagraphBuilder(ui.ParagraphStyle());
      for (var span = 0; span < _spansPerParagraph; span++) {
        fontSizeSeed += 0.6180339887;
        builder.pushStyle(
          ui.TextStyle(
            color: const ui.Color(0xFF000000),
            fontFamily: _fontFamilies[(i + span) % _fontFamilies.length],
            fontSize: 8.0 + (fontSizeSeed % 32.0),
            fontWeight: _fontWeights[(frame + i + span) % _fontWeights.length],
            fontStyle: (frame + i + span).isEven ? ui.FontStyle.normal : ui.FontStyle.italic,
          ),
        );
        builder.addText('Quick zephyrs blow 0123456789 frame $frame paragraph $i span $span. ');
        builder.pop();
      }
      final ui.Paragraph paragraph = builder.build();
      paragraph.layout(const ui.ParagraphConstraints(width: 400));
      paragraphs.add(paragraph);
    }
    return paragraphs;
  }

  ui.Picture recordPicture(List<ui.Paragraph> paragraphs) {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, const ui.Rect.fromLTWH(0, 0, 500, 500));
    canvas.drawColor(const ui.Color(0xFFFFFFFF), ui.BlendMode.src);
    var offset = 0.0;
    for (final paragraph in paragraphs) {
      canvas.drawParagraph(paragraph, ui.Offset(0, offset));
      offset += 20.0;
    }
    return recorder.endRecording();
  }

  test('concurrent text layout and rasterization does not corrupt the heap', () async {
    List<ui.Paragraph> paragraphs = buildAndLayoutParagraphs(0);
    final stopwatch = Stopwatch()..start();
    var frame = 0;
    while (frame < _maxFrames && stopwatch.elapsed < _maxTestTime) {
      frame++;

      final ui.Picture picture = recordPicture(paragraphs);
      final sceneBuilder = ui.SceneBuilder();
      sceneBuilder.addPicture(ui.Offset.zero, picture);

      // Kick off rasterization unawaited, then yield once so the render
      // message reaches the raster thread.
      final Future<void> renderFuture = renderScene(sceneBuilder.build());
      await Future<void>.delayed(Duration.zero);

      // Lay out the next frame's paragraphs while the raster thread is
      // rasterizing this one — the concurrent strike cache access under test.
      final List<ui.Paragraph> nextParagraphs = buildAndLayoutParagraphs(frame);

      await renderFuture;

      // Disposing exercises the concurrent teardown path of
      // https://github.com/flutter/flutter/issues/184858.
      for (final paragraph in paragraphs) {
        paragraph.dispose();
      }
      picture.dispose();
      paragraphs = nextParagraphs;

      // Shrink and re-grow the GPU resource cache so purging runs against
      // in-flight rasterization.
      if (frame % 16 == 0) {
        renderer.resourceCacheMaxBytes = frame % 32 == 0 ? 1024 * 1024 : 64 * 1024 * 1024;
      }
    }

    for (final paragraph in paragraphs) {
      paragraph.dispose();
    }

    // Completing without a RuntimeError or hang is the pass condition.
    expect(frame, greaterThan(0));
  }, timeout: const Timeout(Duration(minutes: 2)));
}
