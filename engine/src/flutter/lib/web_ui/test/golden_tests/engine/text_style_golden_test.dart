// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/ui.dart';
import 'package:ui/src/engine.dart';

import 'scuba.dart';

void main() async {
  final EngineScubaTester scuba = await EngineScubaTester.initialize(
    viewportSize: const Size(800, 800),
  );

  void drawLetterAndWordSpacing(EngineCanvas canvas) {
    Offset offset = Offset.zero;

    for (double spacing = 0; spacing < 15; spacing += 5) {
      canvas.drawParagraph(
        paragraph('HelloWorld',
            textStyle: TextStyle(
                color: const Color(0xFF000000),
                decoration: TextDecoration.none,
                fontFamily: 'Arial',
                fontSize: 30,
                letterSpacing: spacing)),
        offset,
      );
      offset = offset.translate(0, 40);
    }
    for (double spacing = 0; spacing < 30; spacing += 10) {
      final TextStyle textStyle = TextStyle(
          color: const Color(0xFF00FF00),
          decoration: TextDecoration.none,
          fontFamily: 'Arial',
          fontSize: 30,
          wordSpacing: spacing);
      canvas.drawParagraph(
        paragraph('Hello World', textStyle: textStyle, maxWidth: 600),
        offset,
      );
      offset = offset.translate(0, 40);
    }
  }

  testEachCanvas('draws text with letter/word spacing', (EngineCanvas canvas) {
    drawLetterAndWordSpacing(canvas);
    return scuba.diffCanvasScreenshot(
        canvas, 'paint_bounds_for_text_style_letter_spacing');
  });

  void drawTextDecorationStyle(EngineCanvas canvas) {
    final List<TextDecorationStyle> decorationStyles = <TextDecorationStyle>[
      TextDecorationStyle.solid,
      TextDecorationStyle.double,
      TextDecorationStyle.dotted,
      TextDecorationStyle.dashed,
      TextDecorationStyle.wavy,
    ];

    Offset offset = Offset.zero;

    for (TextDecorationStyle decorationStyle in decorationStyles) {
      final TextStyle textStyle = TextStyle(
        color: const Color.fromRGBO(50, 50, 255, 1.0),
        decoration: TextDecoration.underline,
        decorationStyle: decorationStyle,
        decorationColor: const Color.fromRGBO(50, 50, 50, 1.0),
        fontFamily: 'Arial',
        fontSize: 30,
      );
      canvas.drawParagraph(
        paragraph('Hello World', textStyle: textStyle, maxWidth: 600),
        offset,
      );
      offset = offset.translate(0, 40);
    }
  }

  testEachCanvas('draws text decoration style', (EngineCanvas canvas) {
    drawTextDecorationStyle(canvas);
    return scuba.diffCanvasScreenshot(
        canvas, 'paint_bounds_for_text_decorationStyle');
  });

  void drawTextDecoration(EngineCanvas canvas) {
    final List<TextDecoration> decorations = <TextDecoration>[
      TextDecoration.overline,
      TextDecoration.underline,
      TextDecoration.combine(<TextDecoration>[
        TextDecoration.underline,
        TextDecoration.lineThrough
      ]),
      TextDecoration.combine(
          <TextDecoration>[TextDecoration.underline, TextDecoration.overline]),
      TextDecoration.combine(
          <TextDecoration>[TextDecoration.overline, TextDecoration.lineThrough])
    ];

    Offset offset = Offset.zero;

    for (TextDecoration decoration in decorations) {
      final TextStyle textStyle = TextStyle(
        color: const Color.fromRGBO(50, 50, 255, 1.0),
        decoration: decoration,
        decorationStyle: TextDecorationStyle.solid,
        decorationColor: const Color.fromRGBO(255, 160, 0, 1.0),
        fontFamily: 'Arial',
        fontSize: 20,
      );
      canvas.drawParagraph(
        paragraph(
          'Hello World $decoration',
          textStyle: textStyle,
          maxWidth: 600,
        ),
        offset,
      );
      offset = offset.translate(0, 40);
    }
  }

  testEachCanvas('draws text decoration', (EngineCanvas canvas) {
    drawTextDecoration(canvas);
    return scuba.diffCanvasScreenshot(
        canvas, 'paint_bounds_for_text_decoration');
  });

  void drawTextWithBackground(EngineCanvas canvas) {
    // Single-line text.
    canvas.drawParagraph(
      paragraph(
        'Hello World',
        maxWidth: 600,
        textStyle: TextStyle(
          color: const Color.fromRGBO(0, 0, 0, 1.0),
          background: Paint()..color = const Color.fromRGBO(255, 50, 50, 1.0),
          fontFamily: 'Arial',
          fontSize: 30,
        ),
      ),
      Offset.zero,
    );

    // Multi-line text.
    canvas.drawParagraph(
      paragraph(
        'Multi line Hello World paragraph',
        maxWidth: 200,
        textStyle: TextStyle(
          color: const Color.fromRGBO(0, 0, 0, 1.0),
          background: Paint()..color = const Color.fromRGBO(50, 50, 255, 1.0),
          fontFamily: 'Arial',
          fontSize: 30,
        ),
      ),
      const Offset(0, 40),
    );
  }

  testEachCanvas('draws text with a background', (EngineCanvas canvas) {
    drawTextWithBackground(canvas);
    return scuba.diffCanvasScreenshot(canvas, 'text_background');
  });
}
