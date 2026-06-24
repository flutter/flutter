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
  setUp(() {
    renderer.fontCollection.debugResetFallbackFonts();
  });
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

  Future<void> draw(
    String image,
    String text,
    String testName,
    int countLayouts,
    int countPaints,
  ) async {
    WebParagraphProfiler.reset();
    final recorder = PictureRecorder();
    const region = Rect.fromLTWH(0, 0, 1000, 1000);
    final paragraphs = <Paragraph>[];
    for (var i = 0; i < countLayouts; i++) {
      final Paragraph paragraph = timeAction((i == 0 ? 'build.first' : 'build'), () {
        final arialStyle = ParagraphStyle(fontFamily: 'Roboto', fontSize: 20);
        final builder = ParagraphBuilder(arialStyle);
        builder.pushStyle(TextStyle(color: const Color(0xFF000000)));
        builder.addText('$text$i');
        return builder.build();
      });
      paragraphs.add(paragraph);
      timeAction((i == 0 ? 'layout.first' : 'layout'), () {
        paragraph.layout(const ParagraphConstraints(width: 1000));
      });
    }
    for (var j = 0; j < countPaints; ++j) {
      for (final paragraph in paragraphs) {
        final canvas = Canvas(recorder, region);
        canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);
        await timeActionAsync((j == 0 ? 'paint.first' : 'paint'), () async {
          canvas.drawParagraph(paragraph, const Offset(20, 20));
          await drawPictureUsingCurrentRenderer(
            recorder.endRecording(),
          ); // This is a hack to make sure the canvas is flushed
        });
      }
    }

    await matchGoldenFile('web_paragraph.$image.png', region: region);
    WebParagraphProfiler.log();
  }

  test(
    'Dummy test to warm up GPU',
    () async {
      await draw('dummy_text', 'Dummy text', 'Dummy text', 1, 1);
    },
    timeout: Timeout.none,
    skip: true,
  );

  test(
    'Build/Layout/Paint small text',
    () async {
      await draw('small_text', 'Abcdef', 'Small text', 10, 100);
    },
    timeout: Timeout.none,
    skip: true,
  );

  test(
    'Build/Layout/Paint medium text',
    () async {
      await draw('medium_text', 'Abcdef ghijkl mnopqrs tuvwxyz.', 'Medium text', 10, 100);
    },
    timeout: Timeout.none,
    skip: true,
  );

  test(
    'Build/Layout/Paint large text',
    () async {
      await draw(
        'large_text',
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
        10,
        100,
      );
    },
    timeout: Timeout.none,
    skip: true,
  );

  test(
    'Paint text by sizes',
    () async {
      WebParagraphProfiler.reset();
      final recorder = PictureRecorder();
      const region = Rect.fromLTWH(0, 0, 1000, 1000);
      for (var textSize = 10; textSize < 1000; textSize += (textSize == 10 ? 40 : 50)) {
        final Paragraph paragraph = timeAction('build$textSize', () {
          final arialStyle = ParagraphStyle(fontFamily: 'Roboto', fontSize: 20);
          final builder = ParagraphBuilder(arialStyle);
          builder.pushStyle(TextStyle(color: const Color(0xFF000000)));
          builder.addText('0123456789' * (textSize ~/ 10));
          return builder.build();
        });
        timeAction('layout$textSize', () {
          paragraph.layout(const ParagraphConstraints(width: 1000));
        });
        final canvas = Canvas(recorder, region);
        canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);
        await timeActionAsync('paint$textSize', () async {
          canvas.drawParagraph(paragraph, const Offset(20, 20));
          await drawPictureUsingCurrentRenderer(
            recorder.endRecording(),
          ); // This is a hack to make sure the canvas is flushed
        });
      }

      await matchGoldenFile('web_paragraph.text_size.png', region: region);
      WebParagraphProfiler.log();
    },
    timeout: Timeout.none,
    skip: true,
  );

  test('Paragraph print', () async {
    final recorder = PictureRecorder();
    const region = Rect.fromLTWH(0, 0, 1000, 1000);
    final canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);

    final paragraphStyle = ParagraphStyle(
      fontFamily: 'Noto Sans',
      fontSize: 40,
      textDirection: TextDirection.ltr,
      height: 1.0,
    );

    final builder = ParagraphBuilder(paragraphStyle);
    builder.pushStyle(TextStyle(color: const Color(0xFFFF0000)));
    builder.addText('اللغة العربية لغة عالمية غبية');
    builder.pop();

    final Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: double.infinity));
    print('paragraph: ${paragraph.longestLine} ${paragraph.height}');
    canvas.drawParagraph(paragraph, const Offset(20, 20));
    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    final List<Offset> centers = [];
    for (var i = 0; i < 29; i += 1) {
      final GlyphInfo? glyphInfo = paragraph.getGlyphInfoAt(i);
      if (glyphInfo == null) {
        continue;
      }
      final int start = glyphInfo.graphemeClusterCodeUnitRange.start;
      final int end = glyphInfo.graphemeClusterCodeUnitRange.end;
      if (start == end) {
        continue;
      }

      final List<TextBox> boxes = paragraph.getBoxesForRange(
        glyphInfo.graphemeClusterCodeUnitRange.start,
        glyphInfo.graphemeClusterCodeUnitRange.end,
      );
      if (boxes.isNotEmpty) {
        print('getRectsForRange($i: [$start:$end)): ${boxes.length} ${boxes.first.toRect()}');
        for (final box in boxes) {
          centers.add(box.toRect().center);
        }
      } else {
        print('getRectsForRange($i: [$start:$end)): empty');
      }
    }
    for (final point in centers) {
      final TextPosition pos = paragraph.getPositionForOffset(point);
      print(
        'getGlyphPositionAtCoordinate($point): ${pos.offset}, ${pos.affinity == TextAffinity.upstream ? "up" : "down"}',
      );
    }
    for (final point in centers) {
      final GlyphInfo? glyph1 = paragraph.getClosestGlyphInfoForOffset(point.translate(0.2, 0));
      print('getClosestGlyphClusterAt($point)+0.2: $glyph1');
      final GlyphInfo? glyph2 = paragraph.getClosestGlyphInfoForOffset(point.translate(-0.2, 0));
      print('getClosestGlyphClusterAt($point)-0.2: $glyph2');
    }
    await matchGoldenFile('web_paragraph.print.png', region: region);
  }, skip: true);
}
