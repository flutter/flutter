// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui';

import 'recorder.dart';
import 'test_data.dart';

/// Draws 9 screens worth of text in a 3x3 grid with only the middle cell
/// appearing on the visible screen:
///
///     +-------------+-------------+-------------+
///     |             |             |             |
///     |  invisible  |  invisible  |  invisible  |
///     |             |             |             |
///     +-----------------------------------------+
///     |             |             |             |
///     |  invisible  |   visible   |  invisible  |
///     |             |             |             |
///     +-----------------------------------------+
///     |             |             |             |
///     |  invisible  |  invisible  |  invisible  |
///     |             |             |             |
///     +-------------+-------------+-------------+
///
/// This reproduces the bug where we render more than visible causing
/// performance issues: https://github.com/flutter/flutter/issues/48516
class BenchTextOutOfPictureBounds extends RawRecorder {
  BenchTextOutOfPictureBounds() : super(name: benchmarkName) {
    const Color red = Color.fromARGB(255, 255, 0, 0);
    const Color green = Color.fromARGB(255, 0, 255, 0);

    // We don't want paragraph generation and layout to pollute benchmark numbers.
    singleLineParagraphs = _generateParagraphs(
      paragraphCount: 500,
      minWordCountPerParagraph: 2,
      maxWordCountPerParagraph: 5,
      color: red,
    );
    multiLineParagraphs = _generateParagraphs(
      paragraphCount: 50,
      minWordCountPerParagraph: 30,
      maxWordCountPerParagraph: 50,
      color: green,
    );
  }

  // Use hard-coded seed to make sure the data is stable across benchmark runs.
  static final math.Random _random = math.Random(0);

  static const String benchmarkName = 'text_out_of_picture_bounds';

  List<Paragraph> singleLineParagraphs;
  List<Paragraph> multiLineParagraphs;

  @override
  void onDrawFrame(SceneBuilder sceneBuilder) {
    final PictureRecorder pictureRecorder = PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Size screenSize = window.physicalSize;
    const double padding = 10.0;

    // Fills a single cell with random text.
    void fillCellWithText(List<Paragraph> textSource) {
      canvas.save();
      double topOffset = 0;
      while (topOffset < screenSize.height) {
        final Paragraph paragraph =
            textSource[_random.nextInt(textSource.length)];

        // Give it enough space to make sure it ends up being a single-line paragraph.
        paragraph.layout(ParagraphConstraints(width: screenSize.width / 2));

        canvas.drawParagraph(paragraph, Offset.zero);
        canvas.translate(0, paragraph.height + padding);
        topOffset += paragraph.height + padding;
      }
      canvas.restore();
    }

    // Starting with the top-left cell, fill every cell with text.
    canvas.translate(-screenSize.width, -screenSize.height);
    for (int row = 0; row < 3; row++) {
      canvas.save();
      for (int col = 0; col < 3; col++) {
        canvas.drawRect(
          Offset.zero & screenSize,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0,
        );
        // Fill single-line text.
        fillCellWithText(singleLineParagraphs);

        // Fill multi-line text.
        canvas.save();
        canvas.translate(screenSize.width / 2, 0);
        fillCellWithText(multiLineParagraphs);
        canvas.restore();

        // Shift to next column.
        canvas.translate(screenSize.width, 0);
      }

      // Undo horizontal shift.
      canvas.restore();

      // Shift to next row.
      canvas.translate(0, screenSize.height);
    }

    final Picture picture = pictureRecorder.endRecording();
    sceneBuilder.pushOffset(0.0, 0.0);
    sceneBuilder.addPicture(Offset.zero, picture);
    sceneBuilder.pop();
  }

  /// Generates strings and builds pre-laid out paragraphs to be used by the
  /// benchmark.
  List<Paragraph> _generateParagraphs({
    int paragraphCount,
    int minWordCountPerParagraph,
    int maxWordCountPerParagraph,
    Color color,
  }) {
    final List<Paragraph> strings = <Paragraph>[];
    int wordPointer = 0; // points to the next word in lipsum to extract
    for (int i = 0; i < paragraphCount; i++) {
      final int wordCount = minWordCountPerParagraph +
          _random.nextInt(maxWordCountPerParagraph - minWordCountPerParagraph);
      final List<String> string = <String>[];
      for (int j = 0; j < wordCount; j++) {
        string.add(lipsum[wordPointer]);
        wordPointer = (wordPointer + 1) % lipsum.length;
      }

      final ParagraphBuilder builder =
          ParagraphBuilder(ParagraphStyle(fontFamily: 'sans-serif'))
            ..pushStyle(TextStyle(color: color, fontSize: 18.0))
            ..addText(string.join(' '))
            ..pop();
      final Paragraph paragraph = builder.build();

      // Fill half the screen.
      paragraph
          .layout(ParagraphConstraints(width: window.physicalSize.width / 2));
      strings.add(paragraph);
    }
    return strings;
  }
}
