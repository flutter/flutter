// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine/web_paragraph/paragraph.dart';
import 'package:ui/ui.dart';
import 'package:web_engine_tester/golden_tester.dart';

import '../common/test_initialization.dart';
import '../ui/utils.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

const int count = 1000;

Future<void> testMain() async {
  setUpUnitTests(withImplicitView: true, setUpTestViewDimensions: false);
  const Rect region = Rect.fromLTWH(0, 0, 500, 500);

  test('First paint small text', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);

    final ParagraphStyle arialStyle = ParagraphStyle(fontFamily: 'Roboto', fontSize: 20);

    final paintWatch = Stopwatch();
    Duration fillAllLines = Duration.zero;
    Duration transferToImageBitmap = Duration.zero;
    Duration makeImageFromImageBitmap = Duration.zero;
    Duration drawImage = Duration.zero;

    for (int i = 0; i < count; i++) {
      final ParagraphBuilder builder = ParagraphBuilder(arialStyle);
      builder.addText('Small text.$i');
      final Paragraph paragraph = builder.build();
      paragraph.layout(const ParagraphConstraints(width: 500));
      paintWatch.start();
      if (paragraph is WebParagraph) {
        paragraph.paint(canvas, Offset.zero);
        final (Duration d1, Duration d2, Duration d3, Duration d4) = paragraph.getPaintDurations();
        fillAllLines += d1;
        transferToImageBitmap += d2;
        makeImageFromImageBitmap += d3;
        drawImage += d4;
      } else {
        canvas.drawParagraph(paragraph, Offset.zero);
      }
      paintWatch.stop();
    }
    final endRecording = paintWatch.elapsed;
    final picture = recorder.endRecording();
    print(
      'First paint("Small text.#N") * $count executed in $endRecording + ${paintWatch.elapsed - endRecording}',
    );
    print('fillAllLines: $fillAllLines');
    print('transferToImageBitmap: $transferToImageBitmap');
    print('makeImageFromImageBitmap: $makeImageFromImageBitmap');
    print('drawImage: $drawImage');
    await drawPictureUsingCurrentRenderer(picture);
    await matchGoldenFile('paragraph_first_paint_small_text.png', region: region);
  });

  test('First paint medium text', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);

    final ParagraphStyle arialStyle = ParagraphStyle(fontFamily: 'Roboto', fontSize: 20);

    final paintWatch = Stopwatch();
    Duration fillAllLines = Duration.zero;
    Duration transferToImageBitmap = Duration.zero;
    Duration makeImageFromImageBitmap = Duration.zero;
    Duration drawImage = Duration.zero;

    for (int i = 0; i < count; i++) {
      final ParagraphBuilder builder = ParagraphBuilder(arialStyle);
      builder.addText(
        'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz.$i',
      );
      final Paragraph paragraph = builder.build();
      paragraph.layout(const ParagraphConstraints(width: 500));
      paintWatch.start();
      if (paragraph is WebParagraph) {
        paragraph.paint(canvas, Offset.zero);
        final (Duration d1, Duration d2, Duration d3, Duration d4) = paragraph.getPaintDurations();
        fillAllLines += d1;
        transferToImageBitmap += d2;
        makeImageFromImageBitmap += d3;
        drawImage += d4;
      } else {
        canvas.drawParagraph(paragraph, Offset.zero);
      }
      paintWatch.stop();
    }
    final endRecording = paintWatch.elapsed;
    final picture = recorder.endRecording();
    print(
      'First paint("{Medium text.}*#N") * $count executed in $endRecording + ${paintWatch.elapsed - endRecording}',
    );
    print('fillAllLines: $fillAllLines');
    print('transferToImageBitmap: $transferToImageBitmap');
    print('makeImageFromImageBitmap: $makeImageFromImageBitmap');
    print('drawImage: $drawImage');
    await drawPictureUsingCurrentRenderer(picture);
    await matchGoldenFile('paragraph_first_paint_medium_text.png', region: region);
  });

  test('First paint large text', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);

    final ParagraphStyle arialStyle = ParagraphStyle(fontFamily: 'Roboto', fontSize: 20);

    final paintWatch = Stopwatch();
    Duration fillAllLines = Duration.zero;
    Duration transferToImageBitmap = Duration.zero;
    Duration makeImageFromImageBitmap = Duration.zero;
    Duration drawImage = Duration.zero;

    for (int i = 0; i < count; i++) {
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
        'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz.$i',
      );
      final Paragraph paragraph = builder.build();
      paragraph.layout(const ParagraphConstraints(width: 500));
      paintWatch.start();
      if (paragraph is WebParagraph) {
        paragraph.paint(canvas, Offset.zero);
        final (Duration d1, Duration d2, Duration d3, Duration d4) = paragraph.getPaintDurations();
        fillAllLines += d1;
        transferToImageBitmap += d2;
        makeImageFromImageBitmap += d3;
        drawImage += d4;
      } else {
        canvas.drawParagraph(paragraph, Offset.zero);
      }
      paintWatch.stop();
    }
    final endRecording = paintWatch.elapsed;
    final picture = recorder.endRecording();
    print(
      'First paint("{Large text.}*#N") * $count executed in $endRecording + ${paintWatch.elapsed - endRecording}',
    );
    print('fillAllLines: $fillAllLines');
    print('transferToImageBitmap: $transferToImageBitmap');
    print('makeImageFromImageBitmap: $makeImageFromImageBitmap');
    print('drawImage: $drawImage');
    await drawPictureUsingCurrentRenderer(picture);
    await matchGoldenFile('paragraph_first_paint_large_text.png', region: region);
  });

  test('Subsequent paint small text', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);

    final ParagraphStyle arialStyle = ParagraphStyle(fontFamily: 'Roboto', fontSize: 20);
    final ParagraphBuilder builder = ParagraphBuilder(arialStyle);
    builder.addText('Small text.');
    final Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 500));
    if (paragraph is WebParagraph) {
      paragraph.paint(canvas, Offset.zero);
    } else {
      canvas.drawParagraph(paragraph, Offset.zero);
    }
    final paintWatch = Stopwatch()..start();
    Duration fillAllLines = Duration.zero;
    Duration transferToImageBitmap = Duration.zero;
    Duration makeImageFromImageBitmap = Duration.zero;
    Duration drawImage = Duration.zero;
    for (int i = 0; i < count; i++) {
      if (paragraph is WebParagraph) {
        paragraph.paint(canvas, Offset.zero);
        final (Duration d1, Duration d2, Duration d3, Duration d4) = paragraph.getPaintDurations();
        fillAllLines += d1;
        transferToImageBitmap += d2;
        makeImageFromImageBitmap += d3;
        drawImage += d4;
      } else {
        canvas.drawParagraph(paragraph, Offset.zero);
      }
    }
    final endRecording = paintWatch.elapsed;
    final picture = recorder.endRecording();
    paintWatch.stop();
    print(
      'Subsequent paint("Small text.") * $count executed in $endRecording + ${paintWatch.elapsed - endRecording}',
    );
    print('fillAllLines: $fillAllLines');
    print('transferToImageBitmap: $transferToImageBitmap');
    print('makeImageFromImageBitmap: $makeImageFromImageBitmap');
    print('drawImage: $drawImage');
    await drawPictureUsingCurrentRenderer(picture);
    await matchGoldenFile('paragraph_subsequent_paint_small_text.png', region: region);
  });

  test('Subsequent paint medium text', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);

    final ParagraphStyle arialStyle = ParagraphStyle(fontFamily: 'Roboto', fontSize: 20);
    final ParagraphBuilder builder = ParagraphBuilder(arialStyle);
    builder.addText(
      'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz.',
    );
    final Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 500));
    if (paragraph is WebParagraph) {
      paragraph.paint(canvas, Offset.zero);
    } else {
      canvas.drawParagraph(paragraph, Offset.zero);
    }
    final paintWatch = Stopwatch()..start();
    Duration fillAllLines = Duration.zero;
    Duration transferToImageBitmap = Duration.zero;
    Duration makeImageFromImageBitmap = Duration.zero;
    Duration drawImage = Duration.zero;
    for (int i = 0; i < count; i++) {
      if (paragraph is WebParagraph) {
        paragraph.paint(canvas, Offset.zero);
        final (Duration d1, Duration d2, Duration d3, Duration d4) = paragraph.getPaintDurations();
        fillAllLines += d1;
        transferToImageBitmap += d2;
        makeImageFromImageBitmap += d3;
        drawImage += d4;
      } else {
        canvas.drawParagraph(paragraph, Offset.zero);
      }
    }
    final endRecording = paintWatch.elapsed;
    final picture = recorder.endRecording();
    paintWatch.stop();
    print(
      'Subsequent paint("{Medium text.}*") * $count executed in $endRecording + ${paintWatch.elapsed - endRecording}',
    );
    print('fillAllLines: $fillAllLines');
    print('transferToImageBitmap: $transferToImageBitmap');
    print('makeImageFromImageBitmap: $makeImageFromImageBitmap');
    print('drawImage: $drawImage');
    await drawPictureUsingCurrentRenderer(picture);
    await matchGoldenFile('paragraph_subsequent_paint_medium_text.png', region: region);
  });

  test('Subsequent paint large text', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);

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
    paragraph.layout(const ParagraphConstraints(width: 500));
    if (paragraph is WebParagraph) {
      paragraph.paint(canvas, Offset.zero);
    } else {
      canvas.drawParagraph(paragraph, Offset.zero);
    }
    final paintWatch = Stopwatch()..start();
    Duration fillAllLines = Duration.zero;
    Duration transferToImageBitmap = Duration.zero;
    Duration makeImageFromImageBitmap = Duration.zero;
    Duration drawImage = Duration.zero;
    for (int i = 0; i < count; i++) {
      if (paragraph is WebParagraph) {
        paragraph.paint(canvas, Offset.zero);
        final (Duration d1, Duration d2, Duration d3, Duration d4) = paragraph.getPaintDurations();
        fillAllLines += d1;
        transferToImageBitmap += d2;
        makeImageFromImageBitmap += d3;
        drawImage += d4;
      } else {
        canvas.drawParagraph(paragraph, Offset.zero);
      }
    }
    final endRecording = paintWatch.elapsed;
    final picture = recorder.endRecording();
    paintWatch.stop();
    print(
      'Subsequent paint("{Large text.}*") * $count executed in $endRecording + ${paintWatch.elapsed - endRecording}',
    );
    print('fillAllLines: $fillAllLines');
    print('transferToImageBitmap: $transferToImageBitmap');
    print('makeImageFromImageBitmap: $makeImageFromImageBitmap');
    print('drawImage: $drawImage');
    await drawPictureUsingCurrentRenderer(picture);
    await matchGoldenFile('paragraph_subsequent_paint_large_text.png', region: region);
  });
}
