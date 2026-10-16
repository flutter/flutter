// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/src/engine/skwasm/skwasm_impl.dart';
import 'package:ui/ui.dart' as ui;

import '../common/fake_asset_manager.dart';
import '../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  setUpUnitTests();

  test('concurrent layout and rasterization preserve glyph metrics', () async {
    // Use a separate typeface for the reference measurements so calculating
    // them neither warms the tested strike cache nor reuses corrupted metrics.
    await ui.loadFontFromList(
      (await fakeAssetManager.load(robotoTestFontUrl)).buffer.asUint8List(),
      fontFamily: 'ReferenceRoboto',
    );
    const frames = 200;
    const paragraphsPerFrame = 24;
    double fontSize(int frame, int index) => 8 + (frame * 0.6180339887 + index * 1.3) % 32;
    String text(int frame, int index) => 'Aliquam $frame neque $index quam';

    ui.Paragraph layout(String family, double size, String text) {
      final builder = ui.ParagraphBuilder(ui.ParagraphStyle(fontFamily: family, fontSize: size))
        ..addText(text);
      return builder.build()..layout(const ui.ParagraphConstraints(width: 1024));
    }

    final reference = <({double width, double height, int lines})>[];
    for (var frame = 0; frame < frames; frame++) {
      for (var index = 0; index < paragraphsPerFrame; index++) {
        final ui.Paragraph paragraph = layout(
          'ReferenceRoboto',
          fontSize(frame, index),
          text(frame, index),
        );
        reference.add((
          width: paragraph.longestLine,
          height: paragraph.height,
          lines: paragraph.numberOfLines,
        ));
        paragraph.dispose();
      }
    }

    final provider = OnscreenCanvasProvider();
    final surface = SkwasmSurface.onscreen(provider);
    try {
      await surface.initialized;
      await surface.setSize(const BitmapSize(1024, 1024));
      for (var frame = 0; frame < frames; frame++) {
        final paragraphs = <ui.Paragraph>[];
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        for (var index = 0; index < paragraphsPerFrame; index++) {
          final ui.Paragraph paragraph = layout(
            'Roboto',
            fontSize(frame, index) + 32,
            'abcdefghijklmnopqrstuvwxyz 0123456789',
          );
          paragraphs.add(paragraph);
          canvas.drawParagraph(paragraph, ui.Offset(0, index * 40.0));
        }
        final ui.Picture picture = recorder.endRecording();
        final Future<void> raster = surface.rasterizeToCanvas(picture);
        try {
          // Dispatch the picture before measuring different font sizes on the
          // main thread. Both threads access the same FreeType face.
          await Future<void>.delayed(Duration.zero);
          for (var index = 0; index < paragraphsPerFrame; index++) {
            final ui.Paragraph paragraph = layout(
              'Roboto',
              fontSize(frame, index),
              text(frame, index),
            );
            try {
              final ({double width, double height, int lines}) expected =
                  reference[frame * paragraphsPerFrame + index];
              final reason = 'frame $frame, paragraph $index';
              expect(paragraph.longestLine, closeTo(expected.width, 0.01), reason: reason);
              expect(paragraph.height, closeTo(expected.height, 0.01), reason: reason);
              expect(paragraph.numberOfLines, expected.lines, reason: reason);
            } finally {
              paragraph.dispose();
            }
          }
        } finally {
          await raster;
          picture.dispose();
          for (final paragraph in paragraphs) {
            paragraph.dispose();
          }
        }
      }
    } finally {
      surface.dispose();
      provider.dispose();
    }
  }, timeout: const Timeout(Duration(minutes: 1)));
}
