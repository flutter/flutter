// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart' as engine;
import 'package:ui/src/engine/web_paragraph/painter.dart';
import 'package:ui/src/engine/web_paragraph/paragraph.dart';
import 'package:ui/ui.dart';
import 'package:web_engine_tester/golden_tester.dart';

import '../common/test_initialization.dart';
import '../ui/utils.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  setUpUnitTests(withImplicitView: true, setUpTestViewDimensions: false);
  const Rect region = Rect.fromLTWH(0, 0, 500, 500);
  /*
  test('Draw WebParagraph Cache', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);

    final WebParagraphStyle arialStyle = WebParagraphStyle(fontFamily: 'Roboto', fontSize: 20);
    final WebParagraphBuilder builder = WebParagraphBuilder(arialStyle);
    builder.addText(
      'It was the last week of school in Hogwarts, and Professor Quirrell was still alive, barely. '
      "The Defense Professor himself would be in a healer's bed, this day, as he'd been for almost the last week."
      '\n'
      'Hogwarts tradition said that exams were given in the first week of June, '
      'that exam results were released the second week, and that in the third week, '
      'there would be the Leave-Taking Feast on Sunday and the Hogwarts Express '
      'transporting you to London on Monday.'
      '\n'
      "Harry had wondered, a long time ago when he'd first read about that schedule, "
      'just what exactly the students did during the rest of the second week of June, '
      'since "waiting for exam results" '
      "didn't sound like much; and the answer "
      'had surprised him when he'
      'd found out.'
      '\n'
      'But now the second week of June was done as well, and it was Saturday; '
      'there was nothing left of the year but the Leave-Taking Feast on the 14th '
      'and the Hogwarts Express ride on the 15th.'
      '\n'
      'And nothing had been answered.'
      '\n'
      'Nothing had been resolved.'
      '\n'
      "Hermione's killer hadn't been found."
      '\n'
      'Somehow Harry had been thinking that, surely, all the truth would come out '
      'by the end of the school year; like that was the end of a mystery novel '
      "and the mystery's answer had been promised him. Certainly it had to be known "
      "by the time the Defense Professor... died, it couldn't be allowed for Professor Quirrell "
      'to die without knowing the answer, without everything being neatly resolved. '
      'Not exam grades, certainly not death, it was only truth that finished a story...'
      '\n'
      "But unless you bought Draco Malfoy's latest theory that Professor Sprout "
      'had been assigning and grading less homework around the time of Hermione '
      'being framed for attempted murder, thereby proving that Professor Sprout '
      'had been spending her time setting it up, the truth remained unfound.'
      '\n'
      "And instead, like the world had priorities that were more like other people's "
      'way of thinking, the year was going to end with a climactic Quidditch match.',
    );

    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 500));
    final stopwatch = Stopwatch()..start();
    for (int i = 0; i < 100; i++) {
      print('$i: paragraph');
      paragraph.paintOnCanvasKit(canvas as engine.CanvasKitCanvas, const Offset(0, 0));
    }
    print('paintOnCanvasKit() executed in ${stopwatch.elapsed}');
    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph_with_cache.png', region: region);
  });

  test('Draw WebParagraph On Canvas2D', () async {
    final DomHTMLCanvasElement canvas = createDomCanvasElement(width: 500, height: 500);
    domDocument.body!.append(canvas);
    final DomCanvasRenderingContext2D context = canvas.context2D;

    final WebParagraphStyle arialStyle = WebParagraphStyle(fontFamily: 'Roboto', fontSize: 20);
    final WebParagraphBuilder builder = WebParagraphBuilder(arialStyle);
    builder.addText(
      'It was the last week of school in Hogwarts, and Professor Quirrell was still alive, barely. '
      "The Defense Professor himself would be in a healer's bed, this day, as he'd been for almost the last week."
      '\n'
      'Hogwarts tradition said that exams were given in the first week of June, '
      'that exam results were released the second week, and that in the third week, '
      'there would be the Leave-Taking Feast on Sunday and the Hogwarts Express '
      'transporting you to London on Monday.'
      '\n'
      "Harry had wondered, a long time ago when he'd first read about that schedule, "
      'just what exactly the students did during the rest of the second week of June, '
      'since "waiting for exam results" '
      "didn't sound like much; and the answer "
      'had surprised him when he'
      'd found out.'
      '\n'
      'But now the second week of June was done as well, and it was Saturday; '
      'there was nothing left of the year but the Leave-Taking Feast on the 14th '
      'and the Hogwarts Express ride on the 15th.'
      '\n'
      'And nothing had been answered.'
      '\n'
      'Nothing had been resolved.'
      '\n'
      "Hermione's killer hadn't been found."
      '\n'
      'Somehow Harry had been thinking that, surely, all the truth would come out '
      'by the end of the school year; like that was the end of a mystery novel '
      "and the mystery's answer had been promised him. Certainly it had to be known "
      "by the time the Defense Professor... died, it couldn't be allowed for Professor Quirrell "
      'to die without knowing the answer, without everything being neatly resolved. '
      'Not exam grades, certainly not death, it was only truth that finished a story...'
      '\n'
      "But unless you bought Draco Malfoy's latest theory that Professor Sprout "
      'had been assigning and grading less homework around the time of Hermione '
      'being framed for attempted murder, thereby proving that Professor Sprout '
      'had been spending her time setting it up, the truth remained unfound.'
      '\n'
      "And instead, like the world had priorities that were more like other people's "
      'way of thinking, the year was going to end with a climactic Quidditch match.',
    );

    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 500));
    final stopwatch = Stopwatch()..start();

    paragraph.paintOnCanvas2D(canvas, const Offset(0, 0));
    print('paintOnCanvas2D() executed in ${stopwatch.elapsed}');

    await matchGoldenFile('web_paragraph_canvas2d.png', region: region);
  });
*/
  test('Draw WebParagraph Cache', () async {
    final PictureRecorder recorder = PictureRecorder();
    final engine.CanvasKitCanvas canvas = Canvas(recorder, region) as engine.CanvasKitCanvas;
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);

    final ParagraphStyle arialStyle = ParagraphStyle(fontFamily: 'Roboto', fontSize: 20);
    const String text =
        'It was the last week of school in Hogwarts, and Professor Quirrell was still alive, barely. '
        "The Defense Professor himself would be in a healer's bed, this day, as he'd been for almost the last week."
        '\n'
        'Hogwarts tradition said that exams were given in the first week of June, '
        'that exam results were released the second week, and that in the third week, '
        'there would be the Leave-Taking Feast on Sunday and the Hogwarts Express '
        'transporting you to London on Monday.'
        '\n'
        "Harry had wondered, a long time ago when he'd first read about that schedule, "
        'just what exactly the students did during the rest of the second week of June, '
        'since "waiting for exam results" '
        "didn't sound like much; and the answer "
        'had surprised him when he'
        'd found out.'
        '\n'
        'But now the second week of June was done as well, and it was Saturday; '
        'there was nothing left of the year but the Leave-Taking Feast on the 14th '
        'and the Hogwarts Express ride on the 15th.'
        '\n'
        'And nothing had been answered.'
        '\n'
        'Nothing had been resolved.'
        '\n'
        "Hermione's killer hadn't been found."
        '\n'
        'Somehow Harry had been thinking that, surely, all the truth would come out '
        'by the end of the school year; like that was the end of a mystery novel '
        "and the mystery's answer had been promised him. Certainly it had to be known "
        "by the time the Defense Professor... died, it couldn't be allowed for Professor Quirrell "
        'to die without knowing the answer, without everything being neatly resolved. '
        'Not exam grades, certainly not death, it was only truth that finished a story...'
        '\n'
        "But unless you bought Draco Malfoy's latest theory that Professor Sprout "
        'had been assigning and grading less homework around the time of Hermione '
        'being framed for attempted murder, thereby proving that Professor Sprout '
        'had been spending her time setting it up, the truth remained unfound.'
        '\n'
        "And instead, like the world had priorities that were more like other people's "
        'way of thinking, the year was going to end with a climactic Quidditch match.';
    final Stopwatch stopwatch = Stopwatch();
    for (int i = 0; i < 1; i++) {
      final ParagraphBuilder builder = ParagraphBuilder(arialStyle);
      builder.addText('$i:\n');
      builder.addText(text);
      final Paragraph paragraph = builder.build();
      paragraph.layout(const ParagraphConstraints(width: 500));
      stopwatch.start();
      if (paragraph is WebParagraph) {
        paragraph.paint(canvas, Offset.zero);
      } else {
        canvas.drawParagraph(paragraph, Offset.zero);
      }
      stopwatch.stop();
      CanvasKitPainter p = (paragraph as WebParagraph).painter as CanvasKitPainter;
      print('${p.stopwatchpaintOn2D.elapsed}');
      print('${p.stopwatchConvert.elapsed}');
      print('${p.stopwatchpaintOnCanvas.elapsed}');
    }
    final picture = recorder.endRecording();
    print('canvas.drawParagraph*10 executed in ${stopwatch.elapsed}');

    await drawPictureUsingCurrentRenderer(picture);
    await matchGoldenFile('web_paragraph_with_cache.png', region: region);
  });
}
