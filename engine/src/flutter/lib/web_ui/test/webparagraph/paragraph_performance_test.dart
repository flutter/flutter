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

Future<void> testMain() async {
  WebParagraphProfiler.register();
  setUpUnitTests(withImplicitView: true, setUpTestViewDimensions: false);

  Future<void> draw(String image, String text, String testName, int count) async {
    WebParagraphProfiler.reset();
    final recorder = PictureRecorder();
    const region = Rect.fromLTWH(0, 0, 1000, 1000);
    final canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);
    for (var i = 0; i < count; i++) {
      final Paragraph paragraph = timeAction('build', () {
        final arialStyle = ParagraphStyle(fontFamily: 'Roboto', fontSize: 20);
        final builder = ParagraphBuilder(arialStyle);
        builder.pushStyle(TextStyle(color: const Color(0xFF000000)));
        builder.addText('$text$i.');
        return builder.build();
      });
      timeAction('layout', () {
        paragraph.layout(const ParagraphConstraints(width: 1000));
      });
      timeAction('paint', () {
        canvas.drawParagraph(paragraph, Offset.zero);
      });
    }
    await drawPictureUsingCurrentRenderer(recorder.endRecording());
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
    await draw('mediumText', 'Abcdef ghijkl mnopqrs tuvwxyz.', 'Medium text', 10);
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
  }, timeout: Timeout.none, solo: true);
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
