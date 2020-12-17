// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12
import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

const ui.Color white = ui.Color(0xFFFFFFFF);
const ui.Color black = ui.Color(0xFF000000);
const ui.Color red = ui.Color(0xFFFF0000);
const ui.Color green = ui.Color(0xFF00FF00);
const ui.Color blue = ui.Color(0xFF0000FF);

final EngineParagraphStyle ahemStyle = EngineParagraphStyle(
  fontFamily: 'ahem',
  fontSize: 10,
);

ui.ParagraphConstraints constrain(double width) {
  return ui.ParagraphConstraints(width: width);
}

CanvasParagraph rich(
  EngineParagraphStyle style,
  void Function(CanvasParagraphBuilder) callback,
) {
  final CanvasParagraphBuilder builder = CanvasParagraphBuilder(style);
  callback(builder);
  return builder.build();
}

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() async {
  await ui.webOnlyInitializeTestDomRenderer();

  group('$CanvasParagraph.getBoxesForRange', () {
    test('return empty list for invalid ranges', () {
      final CanvasParagraph paragraph = rich(ahemStyle, (builder) {
        builder.addText('Lorem ipsum');
      })
        ..layout(constrain(double.infinity));

      expect(paragraph.getBoxesForRange(-1, 0), <ui.TextBox>[]);
      expect(paragraph.getBoxesForRange(0, 0), <ui.TextBox>[]);
      expect(paragraph.getBoxesForRange(11, 11), <ui.TextBox>[]);
      expect(paragraph.getBoxesForRange(11, 12), <ui.TextBox>[]);
      expect(paragraph.getBoxesForRange(4, 3), <ui.TextBox>[]);
    });

    test('handles single-line multi-span paragraphs', () {
      final CanvasParagraph paragraph = rich(ahemStyle, (builder) {
        builder.pushStyle(EngineTextStyle.only(color: blue));
        builder.addText('Lorem ');
        builder.pushStyle(EngineTextStyle.only(color: green));
        builder.addText('ipsum ');
        builder.pop();
        builder.addText('.');
      })
        ..layout(constrain(double.infinity));

      // Within the first span "Lorem ".

      expect(
        // "or"
        paragraph.getBoxesForRange(1, 3),
        <ui.TextBox>[
          box(10, 0, 30, 10),
        ],
      );
      expect(
        // "Lorem"
        paragraph.getBoxesForRange(0, 5),
        <ui.TextBox>[
          box(0, 0, 50, 10),
        ],
      );
      // Make sure the trailing space is also included in the box.
      expect(
        // "Lorem "
        paragraph.getBoxesForRange(0, 6),
        <ui.TextBox>[
          box(0, 0, 60, 10),
        ],
      );

      // Within the second span "ipsum ".

      expect(
        // "psum"
        paragraph.getBoxesForRange(7, 11),
        <ui.TextBox>[
          box(70, 0, 110, 10),
        ],
      );
      expect(
        // "um "
        paragraph.getBoxesForRange(9, 12),
        <ui.TextBox>[
          box(90, 0, 120, 10),
        ],
      );

      // Across the two spans "Lorem " and "ipsum ".

      expect(
        // "rem ipsum"
        paragraph.getBoxesForRange(2, 11),
        <ui.TextBox>[
          box(20, 0, 60, 10),
          box(60, 0, 110, 10),
        ],
      );

      // Across all spans "Lorem ", "ipsum ", ".".

      expect(
        // "Lorem ipsum."
        paragraph.getBoxesForRange(0, 13),
        <ui.TextBox>[
          box(0, 0, 60, 10),
          box(60, 0, 120, 10),
          box(120, 0, 130, 10),
        ],
      );
    });

    test('handles multi-line single-span paragraphs', () {
      final CanvasParagraph paragraph = rich(ahemStyle, (builder) {
        builder.addText('Lorem ipsum dolor sit');
      })
        ..layout(constrain(90.0));

      // Lines:
      //   "Lorem "
      //   "ipsum "
      //   "dolor sit"

      // Within the first line "Lorem ".

      expect(
        // "or"
        paragraph.getBoxesForRange(1, 3),
        <ui.TextBox>[
          box(10, 0, 30, 10),
        ],
      );
      // Make sure the trailing space at the end of line is also included in the
      // box.
      expect(
        // "Lorem "
        paragraph.getBoxesForRange(0, 6),
        <ui.TextBox>[
          box(0, 0, 60, 10),
        ],
      );

      // Within the second line "ipsum ".

      expect(
        // "psum "
        paragraph.getBoxesForRange(7, 12),
        <ui.TextBox>[
          box(10, 10, 60, 20),
        ],
      );

      // Across all lines.

      expect(
        //    "em "
        // "ipsum "
        // "dolor s"
        paragraph.getBoxesForRange(3, 19),
        <ui.TextBox>[
          box(30, 0, 60, 10),
          box(0, 10, 60, 20),
          box(0, 20, 70, 30),
        ],
      );
    });

    test('handles multi-line multi-span paragraphs', () {
      final CanvasParagraph paragraph = rich(ahemStyle, (builder) {
        builder.pushStyle(EngineTextStyle.only(color: blue));
        builder.addText('Lorem ipsum ');
        builder.pushStyle(EngineTextStyle.only(color: green));
        builder.addText('dolor ');
        builder.pop();
        builder.addText('sit');
      })
        ..layout(constrain(90.0));

      // Lines:
      //   "Lorem "
      //   "ipsum "
      //   "dolor sit"

      // Within the first line "Lorem ".

      expect(
        // "ore"
        paragraph.getBoxesForRange(1, 4),
        <ui.TextBox>[
          box(10, 0, 40, 10),
        ],
      );
      expect(
        // "Lorem "
        paragraph.getBoxesForRange(0, 6),
        <ui.TextBox>[
          box(0, 0, 60, 10),
        ],
      );

      // Within the second line "ipsum ".

      expect(
        // "psum "
        paragraph.getBoxesForRange(7, 12),
        <ui.TextBox>[
          box(10, 10, 60, 20),
        ],
      );

      // Within the third line "dolor sit" which is made of 2 spans.

      expect(
        // "lor sit"
        paragraph.getBoxesForRange(14, 21),
        <ui.TextBox>[
          box(20, 20, 60, 30),
          box(60, 20, 90, 30),
        ],
      );

      // Across all lines.

      expect(
        //    "em "
        // "ipsum "
        // "dolor s"
        paragraph.getBoxesForRange(3, 19),
        <ui.TextBox>[
          box(30, 0, 60, 10),
          box(0, 10, 60, 20),
          box(0, 20, 60, 30),
          box(60, 20, 70, 30),
        ],
      );
    });

    test('handles spans with varying heights/baselines', () {
      final CanvasParagraph paragraph = rich(ahemStyle, (builder) {
        builder.pushStyle(EngineTextStyle.only(fontSize: 20.0));
        // width = 20.0 * 6 = 120.0
        // baseline = 20.0 * 80% = 16.0
        builder.addText('Lorem ');
        builder.pushStyle(EngineTextStyle.only(fontSize: 40.0));
        // width = 40.0 * 6 = 240.0
        // baseline = 40.0 * 80% = 32.0
        builder.addText('ipsum ');
        builder.pushStyle(EngineTextStyle.only(fontSize: 10.0));
        // width = 10.0 * 6 = 60.0
        // baseline = 10.0 * 80% = 8.0
        builder.addText('dolor ');
        builder.pushStyle(EngineTextStyle.only(fontSize: 30.0));
        // width = 30.0 * 4 = 120.0
        // baseline = 30.0 * 80% = 24.0
        builder.addText('sit ');
        builder.pushStyle(EngineTextStyle.only(fontSize: 20.0));
        // width = 20.0 * 4 = 80.0
        // baseline = 20.0 * 80% = 16.0
        builder.addText('amet');
      })
        ..layout(constrain(420.0));

      // Lines:
      //   "Lorem ipsum dolor " (width: 420, height: 40, baseline: 32)
      //   "sit amet"           (width: 200, height: 30, baseline: 24)

      expect(
        // "em ipsum dol"
        paragraph.getBoxesForRange(3, 15),
        <ui.TextBox>[
          box(60, 16, 120, 36),
          box(120, 0, 360, 40),
          box(360, 24, 390, 34),
        ],
      );

      expect(
        // "sum dolor "
        // "sit amet"
        paragraph.getBoxesForRange(8, 26),
        <ui.TextBox>[
          box(200, 0, 360, 40),
          box(360, 24, 420, 34),
          box(0, 40, 120, 70),
          box(120, 48, 200, 68),
        ],
      );
    });
  });
}

/// Shortcut to create a [ui.TextBox] with an optional [ui.TextDirection].
ui.TextBox box(
  double left,
  double top,
  double right,
  double bottom, [
  ui.TextDirection direction = ui.TextDirection.ltr,
]) {
  return ui.TextBox.fromLTRBD(left, top, right, bottom, direction);
}
