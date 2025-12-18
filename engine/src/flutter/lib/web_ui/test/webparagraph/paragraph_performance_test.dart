// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart';
import 'package:web_engine_tester/golden_tester.dart';

import '../common/test_initialization.dart';
import '../ui/utils.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

typedef AsyncAction<R> = Future<R> Function();

Future<R> timeActionAsync<R>(String name, AsyncAction<R> action) async {
  if (!Profiler.isBenchmarkMode) {
    return action();
  } else {
    final stopwatch = Stopwatch()..start();
    final R result = await action();
    stopwatch.stop();
    Profiler.instance.benchmark(name, stopwatch.elapsedMicroseconds.toDouble());
    return result;
  }
}

Future<void> testMain() async {
  WebParagraphProfiler.register();
  setUpUnitTests(withImplicitView: true, setUpTestViewDimensions: false);

  Future<void> draw(String image, String text, String testName, int count) async {
    WebParagraphProfiler.reset();
    final recorder = PictureRecorder();
    const region = Rect.fromLTWH(0, 0, 1000, 1000);
    for (var i = 0; i < count; i++) {
      final canvas = Canvas(recorder, region);
      canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);
      final Paragraph paragraph = timeAction('build', () {
        final arialStyle = ParagraphStyle(fontFamily: 'Roboto', fontSize: 20);
        final builder = ParagraphBuilder(arialStyle);
        builder.pushStyle(TextStyle(color: const Color(0xFF000000)));
        builder.addText('$text$i.');
        return builder.build();
      });
      if (paragraph is WebParagraph && i == 0) {
        // This is a pure temporary solution because the current dumb glyphId does not containt font information
        paragraph.resetGlyphCache();
      }
      timeAction('layout', () {
        paragraph.layout(const ParagraphConstraints(width: 100));
      });
      await timeActionAsync('paint', () async {
        canvas.drawParagraph(paragraph, Offset.zero);
        await drawPictureUsingCurrentRenderer(
          recorder.endRecording(),
        ); // This is a hack to make sure the canvas is flushed
      });
    }
    await matchGoldenFile('$image$count.png', region: region);
    WebParagraphProfiler.log();
  }

  test('Build/Layout/Paint small text', () async {
    //final recorder = PictureRecorder();
    //const region = Rect.fromLTWH(0, 0, 1000, 1000);
    //final canvas = Canvas(recorder, region);
    //canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);
    await draw('smallText', 'Abcdef', 'Small text', 100);
    //await drawPictureUsingCurrentRenderer(recorder.endRecording());
    //await matchGoldenFile('smallText.png', region: region);
  }, timeout: Timeout.none);

  test('Build/Layout/Paint medium text', () async {
    //final recorder = PictureRecorder();
    //const region = Rect.fromLTWH(0, 0, 1000, 1000);
    //final canvas = Canvas(recorder, region);
    //canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);
    await draw('mediumText', 'Abcdef ghijkl mnopqrs tuvwxyz.', 'Medium text', 50);
    //await drawPictureUsingCurrentRenderer(recorder.endRecording());
    //await matchGoldenFile('mediumText.png', region: region);
  }, timeout: Timeout.none);

  test('Build/Layout/Paint large text', () async {
    //final recorder = PictureRecorder();
    //const region = Rect.fromLTWH(0, 0, 1000, 2000);
    //final canvas = Canvas(recorder, region);
    //canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);
    await draw(
      'largeText',
      'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
          'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
          'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
          'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
          'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
          'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
          'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
          'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
          'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
          'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
          'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
          'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
          'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
          'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
          'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
          'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
          'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
          'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
          'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
          'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
          'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
          'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
          'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
          'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz',
      'Large text',
      1,
    );
    //await drawPictureUsingCurrentRenderer(recorder.endRecording());
    //await matchGoldenFile('largeText.png', region: region);
  }, timeout: Timeout.none);
  /*
  test('Subsequent layout small text no cache', () async {
    final ParagraphStyle arialStyle = ParagraphStyle(fontFamily: 'Roboto', fontSize: 20);
    final ParagraphBuilder builder = ParagraphBuilder(arialStyle);
    builder.addText('Small text.');
    final Paragraph paragraph = builder.build();
    final layoutWatch = Stopwatch()..start();
    for (int i = 0; i < count; i++) {
      paragraph.layout(ParagraphConstraints(width: 495 + (i.isEven ? 0 : 5)));
    }
    layoutWatch.stop();
    print('layout("Small text#N") * $count executed in ${layoutWatch.elapsed}');
  });

  test('Subsequent layout medium text no cache', () async {
    final ParagraphStyle arialStyle = ParagraphStyle(fontFamily: 'Roboto', fontSize: 20);
    final ParagraphBuilder builder = ParagraphBuilder(arialStyle);
    builder.addText(
      'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz.',
    );
    final Paragraph paragraph = builder.build();
    final layoutWatch = Stopwatch()..start();
    for (int i = 0; i < count; i++) {
      paragraph.layout(ParagraphConstraints(width: 495 + (i.isEven ? 0 : 5)));
    }
    layoutWatch.stop();
    print('layout("{Medium text}*#N") * $count executed in ${layoutWatch.elapsed}');
  });

  test('Subsequent large medium text no cache', () async {
    final ParagraphStyle arialStyle = ParagraphStyle(fontFamily: 'Roboto', fontSize: 20);
    final ParagraphBuilder builder = ParagraphBuilder(arialStyle);
    builder.addText(
      'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
      'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
      'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
      'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
      'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
      'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
      'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
      'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
      'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
      'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
      'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
      'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
      'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
      'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
      'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
      'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
      'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
      'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
      'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
      'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
      'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
      'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
      'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
      'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz.',
    );
    final Paragraph paragraph = builder.build();
    final layoutWatch = Stopwatch()..start();
    for (int i = 0; i < count; i++) {
      paragraph.layout(ParagraphConstraints(width: 495 + (i.isEven ? 0 : 5)));
    }
    layoutWatch.stop();
    print('layout("{Large text}*#N") * $count executed in ${layoutWatch.elapsed}');
  });
*/
}
