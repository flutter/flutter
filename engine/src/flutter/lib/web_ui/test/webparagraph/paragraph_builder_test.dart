// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/ui.dart';

import '../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  setUpUnitTests();

  test('Build paragraph for Flutter Gallery', () {
    final paragraphStyle = ParagraphStyle(fontFamily: 'GoogleSans', fontSize: 20.0);
    final builder = ParagraphBuilder(paragraphStyle);
    final textStyle = TextStyle(fontFamily: 'GoogleSans', fontSize: 20.0);
    builder.pushStyle(textStyle);
    builder.addText('Options');
    builder.pop();
    final Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 1000));
    expect(paragraph.numberOfLines, 1);
    final List<TextBox> boxes = paragraph.getBoxesForRange(0, 7);
    expect(boxes, hasLength(1));
    expect(boxes.first.toRect().width, greaterThan(0));
    expect(boxes.first.toRect().height, greaterThan(0));
  });

  test('Build paragraph without text or style', () {
    final paragraphStyle = ParagraphStyle(fontFamily: 'Arial', fontSize: 50);
    final builder = ParagraphBuilder(paragraphStyle);
    final Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 1000));
    expect(paragraph.numberOfLines, 0);
    expect(paragraph.computeLineMetrics(), isEmpty);
  });

  test('Build paragraph with some text but without a style', () {
    final paragraphStyle = ParagraphStyle(fontFamily: 'Arial', fontSize: 50);
    final builder = ParagraphBuilder(paragraphStyle);
    builder.addText('some ');
    builder.addText('text');
    final Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 1000));

    expect(paragraph.numberOfLines, 1);
    final List<TextBox> boxes = paragraph.getBoxesForRange(0, 9);
    expect(boxes, hasLength(1));
    expect(boxes.first.toRect().width, greaterThan(0));
  });

  test('Build paragraph without any text but with a style', () {
    final paragraphStyle = ParagraphStyle(fontFamily: 'Arial', fontSize: 50);
    final textStyle = TextStyle(fontFamily: 'Roboto', fontSize: 30);
    final builder = ParagraphBuilder(paragraphStyle);
    builder.pushStyle(textStyle);
    final Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 1000));
    expect(paragraph.numberOfLines, 0);
    expect(paragraph.computeLineMetrics(), isEmpty);
  });

  test('Build paragraph with a few styles at the end without any text', () {
    final paragraphStyle = ParagraphStyle(fontFamily: 'Arial', fontSize: 50);
    final textStyle1 = TextStyle(fontFamily: 'Roboto', fontSize: 30);
    final textStyle2 = TextStyle(fontFamily: 'Roboto', fontSize: 35);
    final textStyle3 = TextStyle(fontFamily: 'Roboto', fontSize: 40);
    final textStyle4 = TextStyle(fontFamily: 'Roboto', fontSize: 45);

    final builder = ParagraphBuilder(paragraphStyle);
    builder.pushStyle(textStyle1);
    builder.addText('some ');
    builder.pushStyle(textStyle2);
    builder.pop();
    builder.addText('text');
    builder.pushStyle(textStyle3);
    builder.pushStyle(textStyle4);
    final Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 1000));
    expect(paragraph.numberOfLines, 1);
    final List<TextBox> boxes = paragraph.getBoxesForRange(0, 9);
    expect(boxes, hasLength(1));
  });

  test('Build paragraph with a few styles at the beginning and without some text', () {
    final paragraphStyle = ParagraphStyle(fontFamily: 'Arial', fontSize: 50);
    final textStyle1 = TextStyle(fontFamily: 'Roboto', fontSize: 30);
    final textStyle2 = TextStyle(fontFamily: 'Roboto', fontSize: 35);
    final textStyle3 = TextStyle(fontFamily: 'Roboto', fontSize: 40);

    final builder = ParagraphBuilder(paragraphStyle);
    builder.pushStyle(textStyle1);
    builder.addText('');
    builder.pushStyle(textStyle2);
    builder.pushStyle(textStyle3);
    builder.addText('some text');
    final Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 1000));
    expect(paragraph.numberOfLines, 1);
    final List<TextBox> boxes = paragraph.getBoxesForRange(0, 9);
    expect(boxes, hasLength(1));
  });

  test('Build paragraph with a nested styles [1] [2] [3]', () {
    final paragraphStyle = ParagraphStyle(fontFamily: 'Arial', fontSize: 50);
    final textStyle1 = TextStyle(fontFamily: 'Roboto', fontSize: 20);
    final textStyle2 = TextStyle(fontFamily: 'Roboto', fontSize: 30);
    final textStyle3 = TextStyle(fontFamily: 'Roboto', fontSize: 40);

    final builder = ParagraphBuilder(paragraphStyle);
    builder.pushStyle(textStyle1);
    builder.addText('[1]');
    builder.pop();
    builder.pushStyle(textStyle2);
    builder.addText('[2]');
    builder.pop();
    builder.pushStyle(textStyle3);
    builder.addText('[3]');
    builder.pop();
    final Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 1000));
    expect(paragraph.numberOfLines, 1);

    final Rect box1 = paragraph.getBoxesForRange(0, 3).first.toRect();
    final Rect box2 = paragraph.getBoxesForRange(3, 6).first.toRect();
    final Rect box3 = paragraph.getBoxesForRange(6, 9).first.toRect();

    expect(box2.left, greaterThanOrEqualTo(box1.right - 0.5));
    expect(box3.left, greaterThanOrEqualTo(box2.right - 0.5));
    expect(box2.width, greaterThan(box1.width));
    expect(box3.width, greaterThan(box2.width));
  });

  test('Build paragraph with nested styles [1[2[3]]]', () {
    final paragraphStyle = ParagraphStyle(fontFamily: 'Arial', fontSize: 50);
    final textStyle1 = TextStyle(fontFamily: 'Roboto', fontSize: 20);
    final textStyle2 = TextStyle(fontFamily: 'Roboto', fontSize: 30);
    final textStyle3 = TextStyle(fontFamily: 'Roboto', fontSize: 40);

    final builder = ParagraphBuilder(paragraphStyle);
    builder.pushStyle(textStyle1);
    builder.addText('[1');
    builder.pushStyle(textStyle2);
    builder.addText('[2');
    builder.pushStyle(textStyle3);
    builder.addText('[3]]]');
    final Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 1000));
    expect(paragraph.numberOfLines, 1);

    final Rect box1 = paragraph.getBoxesForRange(0, 2).first.toRect();
    final Rect box2 = paragraph.getBoxesForRange(2, 4).first.toRect();
    final Rect box3 = paragraph.getBoxesForRange(4, 9).first.toRect();

    expect(box2.left, greaterThanOrEqualTo(box1.right - 0.5));
    expect(box3.left, greaterThanOrEqualTo(box2.right - 0.5));
  });

  test('Build paragraph with inherited styles (font name, font size, font weight, font style) [1[2[3]]]', () {
    final paragraphStyle = ParagraphStyle(fontSize: 32);
    final textStyle1 = TextStyle(fontFamily: 'Roboto');
    final textStyle2 = TextStyle(fontSize: 42, fontWeight: FontWeight.bold);
    final textStyle3 = TextStyle(fontSize: 52, fontStyle: FontStyle.italic, fontFamily: 'Arial');

    final builder = ParagraphBuilder(paragraphStyle);
    builder.pushStyle(textStyle1);
    builder.addText('[1');
    builder.pushStyle(textStyle2);
    builder.addText('[2');
    builder.pushStyle(textStyle3);
    builder.addText('[3');
    builder.pop();
    builder.addText(']]]');
    final Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 1000));
    expect(paragraph.numberOfLines, 1);

    final Rect box1 = paragraph.getBoxesForRange(0, 2).first.toRect();
    final Rect box2 = paragraph.getBoxesForRange(2, 4).first.toRect();
    final Rect box3 = paragraph.getBoxesForRange(4, 6).first.toRect();
    final Rect box4 = paragraph.getBoxesForRange(6, 9).first.toRect();

    expect(box2.left, greaterThanOrEqualTo(box1.right - 0.5));
    expect(box3.left, greaterThanOrEqualTo(box2.right - 0.5));
    expect(box4.left, greaterThanOrEqualTo(box3.right - 0.5));
  });

  test('Build paragraph with inherited styles (foreground, background) [1[2[3]]]', () {
    final paragraphStyle = ParagraphStyle(fontFamily: 'Arial', fontSize: 24.0);
    final textStyle1 = TextStyle(foreground: Paint()..color = const Color(0xFF00FF00));
    final textStyle2 = TextStyle(background: Paint()..color = const Color(0xFFFF0000));
    final textStyle3 = TextStyle(foreground: Paint()..color = const Color(0xFF0000FF));

    final builder = ParagraphBuilder(paragraphStyle);
    builder.pushStyle(textStyle1);
    builder.addText('[1');
    builder.pushStyle(textStyle2);
    builder.addText('[2');
    builder.pushStyle(textStyle3);
    builder.addText('[3]]]');
    final Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 1000));
    expect(paragraph.numberOfLines, 1);

    final Rect box1 = paragraph.getBoxesForRange(0, 2).first.toRect();
    final Rect box2 = paragraph.getBoxesForRange(2, 4).first.toRect();
    final Rect box3 = paragraph.getBoxesForRange(4, 9).first.toRect();

    expect(box2.left, greaterThanOrEqualTo(box1.right - 0.5));
    expect(box3.left, greaterThanOrEqualTo(box2.right - 0.5));
  });

  test('Build paragraph with complex nested styles [1[11[111][112]]][2[21[211][212]]]', () {
    final paragraphStyle = ParagraphStyle(fontFamily: 'Arial', fontSize: 50);
    final textStyle1 = TextStyle(fontFamily: 'Roboto', fontSize: 30);
    final textStyle2 = TextStyle(fontFamily: 'Roboto', fontSize: 35);
    final textStyle3 = TextStyle(fontFamily: 'Roboto', fontSize: 40);
    final textStyle4 = TextStyle(fontFamily: 'Roboto', fontSize: 45);
    final builder = ParagraphBuilder(paragraphStyle);

    builder.pushStyle(textStyle1);
    builder.addText('[1');
    builder.pushStyle(textStyle2);
    builder.addText('[11');
    builder.pushStyle(textStyle3);
    builder.addText('[111]');
    builder.pop();
    builder.pushStyle(textStyle4);
    builder.addText('[112]');
    builder.addText(']]');
    builder.pop();
    builder.pop();
    builder.pop();
    builder.pushStyle(textStyle1);
    builder.addText('[2');
    builder.pushStyle(textStyle2);
    builder.addText('[21');
    builder.pushStyle(textStyle3);
    builder.addText('[211]');
    builder.pop();
    builder.pushStyle(textStyle4);
    builder.addText('[212]]]');
    final Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 2000));
    expect(paragraph.numberOfLines, 1);
    final List<TextBox> boxes = paragraph.getBoxesForRange(0, 35);
    expect(boxes.isNotEmpty, isTrue);
  });

  test('Build paragraph with a placeholder', () {
    final paragraphStyle = ParagraphStyle(fontFamily: 'Arial', fontSize: 50);
    final textStyle1 = TextStyle(fontFamily: 'Roboto', fontSize: 10);
    final textStyle2 = TextStyle(fontFamily: 'Roboto', fontSize: 20);
    final textStyle3 = TextStyle(fontFamily: 'Roboto', fontSize: 30);
    final builder = ParagraphBuilder(paragraphStyle);
    builder.pushStyle(textStyle1);
    builder.addText('textStyle1.');
    builder.addText(' ');
    builder.pop();
    builder.pushStyle(textStyle2);
    builder.addText('');
    builder.addPlaceholder(
      20,
      25,
      PlaceholderAlignment.baseline,
      scale: 2.0,
      baselineOffset: 10.0,
      baseline: TextBaseline.ideographic,
    );
    builder.pop();
    builder.pushStyle(textStyle3);
    builder.addText('textStyle3.');
    builder.addText(' ');
    builder.pop();
    builder.pushStyle(textStyle2);
    builder.addPlaceholder(
      40,
      45,
      PlaceholderAlignment.top,
      scale: 4.0,
      baselineOffset: 30.0,
      baseline: TextBaseline.alphabetic,
    );
    builder.pop();
    final Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 1000));

    final List<TextBox> placeholderBoxes = paragraph.getBoxesForPlaceholders();
    expect(placeholderBoxes, hasLength(2));
    expect(placeholderBoxes[0].toRect().width, 20 * 2.0);
    expect(placeholderBoxes[0].toRect().height, 25 * 2.0);
    expect(placeholderBoxes[1].toRect().width, 40 * 4.0);
    expect(placeholderBoxes[1].toRect().height, 45 * 4.0);
  });
}
