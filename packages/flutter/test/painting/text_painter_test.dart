// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const bool isCanvasKit =
    bool.fromEnvironment('FLUTTER_WEB_USE_SKIA');

void main() {
  test('TextPainter caret test', () {
    final TextPainter painter = TextPainter()
      ..textDirection = TextDirection.ltr;

    String text = 'A';
    painter.text = TextSpan(text: text);
    painter.layout();

    Offset caretOffset = painter.getOffsetForCaret(
      const ui.TextPosition(offset: 0),
      ui.Rect.zero,
    );
    expect(caretOffset.dx, 0);
    caretOffset = painter.getOffsetForCaret(ui.TextPosition(offset: text.length), ui.Rect.zero);
    expect(caretOffset.dx, painter.width);

    // Check that getOffsetForCaret handles a character that is encoded as a
    // surrogate pair.
    text = 'A\u{1F600}';
    painter.text = TextSpan(text: text);
    painter.layout();
    caretOffset = painter.getOffsetForCaret(ui.TextPosition(offset: text.length), ui.Rect.zero);
    expect(caretOffset.dx, painter.width);
    painter.dispose();
  });

  test('TextPainter caret test with WidgetSpan', () {
    // Regression test for https://github.com/flutter/flutter/issues/98458.
    final TextPainter painter = TextPainter()
      ..textDirection = TextDirection.ltr;

    painter.text = const TextSpan(children: <InlineSpan>[
      TextSpan(text: 'before'),
      WidgetSpan(child: Text('widget')),
      TextSpan(text: 'after'),
    ]);
    painter.setPlaceholderDimensions(const <PlaceholderDimensions>[
      PlaceholderDimensions(size: Size(50, 30), baselineOffset: 25, alignment: ui.PlaceholderAlignment.bottom),
    ]);
    painter.layout();
    final Offset caretOffset = painter.getOffsetForCaret(ui.TextPosition(offset: painter.text!.toPlainText().length), ui.Rect.zero);
    expect(caretOffset.dx, painter.width);
    painter.dispose();
  }, skip: isBrowser && !isCanvasKit); // https://github.com/flutter/flutter/issues/56308

  test('TextPainter null text test', () {
    final TextPainter painter = TextPainter()
      ..textDirection = TextDirection.ltr;

    List<TextSpan> children = <TextSpan>[const TextSpan(text: 'B'), const TextSpan(text: 'C')];
    painter.text = TextSpan(children: children);
    painter.layout();

    Offset caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 0), ui.Rect.zero);
    expect(caretOffset.dx, 0);
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 1), ui.Rect.zero);
    expect(caretOffset.dx, painter.width / 2);
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 2), ui.Rect.zero);
    expect(caretOffset.dx, painter.width);

    children = <TextSpan>[];
    painter.text = TextSpan(children: children);
    painter.layout();

    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 0), ui.Rect.zero);
    expect(caretOffset.dx, 0);
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 1), ui.Rect.zero);
    expect(caretOffset.dx, 0);
    painter.dispose();
  });

  test('TextPainter caret emoji test', () {
    final TextPainter painter = TextPainter()
      ..textDirection = TextDirection.ltr;

    // Format: '👩‍<zwj>👩‍<zwj>👦👩‍<zwj>👩‍<zwj>👧‍<zwj>👧👏<modifier>'
    // One three-person family, one four-person family, one clapping hands (medium skin tone).
    const String text = '👩‍👩‍👦👩‍👩‍👧‍👧👏🏽';
    painter.text = const TextSpan(text: text);
    painter.layout(maxWidth: 10000);

    expect(text.length, 23);

    Offset caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 0), ui.Rect.zero);
    expect(caretOffset.dx, 0); // 👩‍
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: text.length), ui.Rect.zero);
    expect(caretOffset.dx, painter.width);

    // Two UTF-16 codepoints per emoji, one codepoint per zwj
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 1), ui.Rect.zero);
    expect(caretOffset.dx, 42); // 👩‍
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 2), ui.Rect.zero);
    expect(caretOffset.dx, 42); // <zwj>
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 3), ui.Rect.zero);
    expect(caretOffset.dx, 42); // 👩‍
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 4), ui.Rect.zero);
    expect(caretOffset.dx, 42); // 👩‍
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 5), ui.Rect.zero);
    expect(caretOffset.dx, 42); // <zwj>
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 6), ui.Rect.zero);
    expect(caretOffset.dx, 42); // 👦
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 7), ui.Rect.zero);
    expect(caretOffset.dx, 42); // 👦
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 8), ui.Rect.zero);
    expect(caretOffset.dx, 42); // 👩‍
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 9), ui.Rect.zero);
    expect(caretOffset.dx, 98); // 👩‍
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 10), ui.Rect.zero);
    expect(caretOffset.dx, 98); // <zwj>
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 11), ui.Rect.zero);
    expect(caretOffset.dx, 98); // 👩‍
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 12), ui.Rect.zero);
    expect(caretOffset.dx, 98); // 👩‍
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 13), ui.Rect.zero);
    expect(caretOffset.dx, 98); // <zwj>
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 14), ui.Rect.zero);
    expect(caretOffset.dx, 98); // 👧‍
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 15), ui.Rect.zero);
    expect(caretOffset.dx, 98); // 👧‍
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 16), ui.Rect.zero);
    expect(caretOffset.dx, 98); // <zwj>
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 17), ui.Rect.zero);
    expect(caretOffset.dx, 98); // 👧
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 18), ui.Rect.zero);
    expect(caretOffset.dx, 98); // 👧
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 19), ui.Rect.zero);
    expect(caretOffset.dx, 98); // 👏
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 20), ui.Rect.zero);
    expect(caretOffset.dx, 98); // 👏
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 21), ui.Rect.zero);
    expect(caretOffset.dx, 98); // <medium skin tone modifier>
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 22), ui.Rect.zero);
    expect(caretOffset.dx, 98); // <medium skin tone modifier>
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 23), ui.Rect.zero);
    expect(caretOffset.dx, 126); // end of string
    painter.dispose();
  }, skip: isBrowser && !isCanvasKit); // https://github.com/flutter/flutter/issues/56308

  test('TextPainter caret center space test', () {
    final TextPainter painter = TextPainter()
      ..textDirection = TextDirection.ltr;

    const String text = 'test text with space at end   ';
    painter.text = const TextSpan(text: text);
    painter.textAlign = TextAlign.center;
    painter.layout();

    Offset caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 0), ui.Rect.zero);
    expect(caretOffset.dx, 21);
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: text.length), ui.Rect.zero);
    // The end of the line is 441, but the width is only 420, so the cursor is
    // stopped there without overflowing.
    expect(caretOffset.dx, painter.width);

    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 1), ui.Rect.zero);
    expect(caretOffset.dx, 35);
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 2), ui.Rect.zero);
    expect(caretOffset.dx, 49);
    painter.dispose();
  }, skip: isBrowser && !isCanvasKit); // https://github.com/flutter/flutter/issues/56308

  test('TextPainter error test', () {
    final TextPainter painter = TextPainter(textDirection: TextDirection.ltr);
    Object? e;
    try {
      painter.paint(MockCanvas(), Offset.zero);
    } catch (exception) {
      e = exception;
    }
    expect(
      e.toString(),
      contains('TextPainter.paint called when text geometry was not yet calculated'),
    );
    painter.dispose();
  });

  test('TextPainter requires textDirection', () {
    final TextPainter painter1 = TextPainter(text: const TextSpan(text: ''));
    expect(() { painter1.layout(); }, throwsAssertionError);
    final TextPainter painter2 = TextPainter(text: const TextSpan(text: ''), textDirection: TextDirection.rtl);
    expect(() { painter2.layout(); }, isNot(throwsException));
  });

  test('TextPainter size test', () {
    final TextPainter painter = TextPainter(
      text: const TextSpan(
        text: 'X',
        style: TextStyle(
          inherit: false,
          fontFamily: 'Ahem',
          fontSize: 123.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    painter.layout();
    expect(painter.size, const Size(123.0, 123.0));
    painter.dispose();
  });

  test('TextPainter textScaleFactor test', () {
    final TextPainter painter = TextPainter(
      text: const TextSpan(
        text: 'X',
        style: TextStyle(
          inherit: false,
          fontFamily: 'Ahem',
          fontSize: 10.0,
        ),
      ),
      textDirection: TextDirection.ltr,
      textScaleFactor: 2.0,
    );
    painter.layout();
    expect(painter.size, const Size(20.0, 20.0));
    painter.dispose();
  });

  test('TextPainter textScaleFactor null style test', () {
    final TextPainter painter = TextPainter(
      text: const TextSpan(
        text: 'X',
      ),
      textDirection: TextDirection.ltr,
      textScaleFactor: 2.0,
    );
    painter.layout();
    expect(painter.size, const Size(28.0, 28.0));
    painter.dispose();
  });

  test('TextPainter default text height is 14 pixels', () {
    final TextPainter painter = TextPainter(
      text: const TextSpan(text: 'x'),
      textDirection: TextDirection.ltr,
    );
    painter.layout();
    expect(painter.preferredLineHeight, 14.0);
    expect(painter.size, const Size(14.0, 14.0));
    painter.dispose();
  });

  test('TextPainter sets paragraph size from root', () {
    final TextPainter painter = TextPainter(
      text: const TextSpan(text: 'x', style: TextStyle(fontSize: 100.0)),
      textDirection: TextDirection.ltr,
    );
    painter.layout();
    expect(painter.preferredLineHeight, 100.0);
    expect(painter.size, const Size(100.0, 100.0));
    painter.dispose();
  });

  test('TextPainter intrinsic dimensions', () {
    const TextStyle style = TextStyle(
      inherit: false,
      fontFamily: 'Ahem',
      fontSize: 10.0,
    );
    TextPainter painter;

    painter = TextPainter(
      text: const TextSpan(
        text: 'X X X',
        style: style,
      ),
      textDirection: TextDirection.ltr,
    );
    painter.layout();
    expect(painter.size, const Size(50.0, 10.0));
    expect(painter.minIntrinsicWidth, 10.0);
    expect(painter.maxIntrinsicWidth, 50.0);
    painter.dispose();

    painter = TextPainter(
      text: const TextSpan(
        text: 'X X X',
        style: style,
      ),
      textDirection: TextDirection.ltr,
      ellipsis: 'e',
    );
    painter.layout();
    expect(painter.size, const Size(50.0, 10.0));
    expect(painter.minIntrinsicWidth, 50.0);
    expect(painter.maxIntrinsicWidth, 50.0);
    painter.dispose();

    painter = TextPainter(
      text: const TextSpan(
        text: 'X X XXXX',
        style: style,
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
    );
    painter.layout();
    expect(painter.size, const Size(80.0, 10.0));
    expect(painter.minIntrinsicWidth, 40.0);
    expect(painter.maxIntrinsicWidth, 80.0);
    painter.dispose();

    painter = TextPainter(
      text: const TextSpan(
        text: 'X X XXXX XX',
        style: style,
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
    );
    painter.layout();
    expect(painter.size, const Size(110.0, 10.0));
    expect(painter.minIntrinsicWidth, 70.0);
    expect(painter.maxIntrinsicWidth, 110.0);
    painter.dispose();

    painter = TextPainter(
      text: const TextSpan(
        text: 'XXXXXXXX XXXX XX X',
        style: style,
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
    );
    painter.layout();
    expect(painter.size, const Size(180.0, 10.0));
    expect(painter.minIntrinsicWidth, 90.0);
    expect(painter.maxIntrinsicWidth, 180.0);
    painter.dispose();

    painter = TextPainter(
      text: const TextSpan(
        text: 'X XX XXXX XXXXXXXX',
        style: style,
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
    );
    painter.layout();
    expect(painter.size, const Size(180.0, 10.0));
    expect(painter.minIntrinsicWidth, 90.0);
    expect(painter.maxIntrinsicWidth, 180.0);
    painter.dispose();
  }, skip: true); // https://github.com/flutter/flutter/issues/13512

  test('TextPainter handles newlines properly', () {
    final TextPainter painter = TextPainter()
      ..textDirection = TextDirection.ltr;

    const double SIZE_OF_A = 14.0; // square size of "a" character
    String text = 'aaa';
    painter.text = TextSpan(text: text);
    painter.layout();

    // getOffsetForCaret in a plain one-line string is the same for either affinity.
    int offset = 0;
    painter.text = TextSpan(text: text);
    painter.layout();
    Offset caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset),
      ui.Rect.zero,
    );
    expect(caretOffset.dx, moreOrLessEquals(SIZE_OF_A * offset, epsilon: 0.0001));
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: ui.TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dx, moreOrLessEquals(SIZE_OF_A * offset, epsilon: 0.0001));
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    offset = 1;
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset),
      ui.Rect.zero,
    );
    expect(caretOffset.dx, moreOrLessEquals(SIZE_OF_A * offset, epsilon: 0.0001));
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: ui.TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dx, moreOrLessEquals(SIZE_OF_A * offset, epsilon: 0.0001));
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    offset = 2;
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset),
      ui.Rect.zero,
    );
    expect(caretOffset.dx, moreOrLessEquals(SIZE_OF_A * offset, epsilon: 0.0001));
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: ui.TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dx, moreOrLessEquals(SIZE_OF_A * offset, epsilon: 0.0001));
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    offset = 3;
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset),
      ui.Rect.zero,
    );
    expect(caretOffset.dx, moreOrLessEquals(SIZE_OF_A * offset, epsilon: 0.0001));
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: ui.TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dx, moreOrLessEquals(SIZE_OF_A * offset, epsilon: 0.0001));
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));

    // For explicit newlines, getOffsetForCaret places the caret at the location
    // indicated by offset regardless of affinity.
    text = '\n\n';
    painter.text = TextSpan(text: text);
    painter.layout();
    offset = 0;
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset),
      ui.Rect.zero,
    );
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: ui.TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    offset = 1;
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset),
      ui.Rect.zero,
    );
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dy, moreOrLessEquals(SIZE_OF_A, epsilon: 0.0001));
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: ui.TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dy, moreOrLessEquals(SIZE_OF_A, epsilon: 0.0001));
    offset = 2;
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset),
      ui.Rect.zero,
    );
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dy, moreOrLessEquals(SIZE_OF_A * 2, epsilon: 0.0001));
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: ui.TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dy, moreOrLessEquals(SIZE_OF_A * 2, epsilon: 0.0001));

    // getOffsetForCaret in an unwrapped string with explicit newlines is the
    // same for either affinity.
    text = '\naaa';
    painter.text = TextSpan(text: text);
    painter.layout();
    offset = 0;
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset),
      ui.Rect.zero,
    );
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: ui.TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    offset = 1;
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset),
      ui.Rect.zero,
    );
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dy, moreOrLessEquals(SIZE_OF_A, epsilon: 0.0001));
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: ui.TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dy, moreOrLessEquals(SIZE_OF_A, epsilon: 0.0001));

    // When text wraps on its own, getOffsetForCaret disambiguates between the
    // end of one line and start of next using affinity.
    text = 'aaaaaaaa'; // Just enough to wrap one character down to second line
    painter.text = TextSpan(text: text);
    painter.layout(maxWidth: 100); // SIZE_OF_A * text.length > 100, so it wraps
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: text.length - 1),
      ui.Rect.zero,
    );
    // When affinity is downstream, cursor is at beginning of second line
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dy, moreOrLessEquals(SIZE_OF_A, epsilon: 0.0001));
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: text.length - 1, affinity: ui.TextAffinity.upstream),
      ui.Rect.zero,
    );
    // When affinity is upstream, cursor is at end of first line
    expect(caretOffset.dx, moreOrLessEquals(98.0, epsilon: 0.0001));
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));

    // When given a string with a newline at the end, getOffsetForCaret puts
    // the cursor at the start of the next line regardless of affinity
    text = 'aaa\n';
    painter.text = TextSpan(text: text);
    painter.layout();
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: text.length),
      ui.Rect.zero,
    );
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dy, moreOrLessEquals(SIZE_OF_A, epsilon: 0.0001));
    offset = text.length;
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dy, moreOrLessEquals(SIZE_OF_A, epsilon: 0.0001));

    // Given a one-line right aligned string, positioning the cursor at offset 0
    // means that it appears at the "end" of the string, after the character
    // that was typed first, at x=0.
    painter.textAlign = TextAlign.right;
    text = 'aaa';
    painter.text = TextSpan(text: text);
    painter.layout();
    offset = 0;
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset),
      ui.Rect.zero,
    );
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    painter.textAlign = TextAlign.left;

    // When given an offset after a newline in the middle of a string,
    // getOffsetForCaret returns the start of the next line regardless of
    // affinity.
    text = 'aaa\naaa';
    painter.text = TextSpan(text: text);
    painter.layout();
    offset = 4;
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset),
      ui.Rect.zero,
    );
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dy, moreOrLessEquals(SIZE_OF_A, epsilon: 0.0001));
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dy, moreOrLessEquals(SIZE_OF_A, epsilon: 0.0001));

    // When given a string with multiple trailing newlines, places the caret
    // in the position given by offset regardless of affinity.
    text = 'aaa\n\n\n';
    offset = 3;
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset),
      ui.Rect.zero,
    );
    expect(caretOffset.dx, moreOrLessEquals(SIZE_OF_A * 3, epsilon: 0.0001));
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dx, moreOrLessEquals(SIZE_OF_A * 3, epsilon: 0.0001));
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));

    offset = 4;
    painter.text = TextSpan(text: text);
    painter.layout();
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset),
      ui.Rect.zero,
    );
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dy, moreOrLessEquals(SIZE_OF_A, epsilon: 0.001));
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dy, moreOrLessEquals(SIZE_OF_A, epsilon: 0.0001));

    offset = 5;
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset),
      ui.Rect.zero,
    );
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dy, moreOrLessEquals(SIZE_OF_A * 2, epsilon: 0.001));
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dy, moreOrLessEquals(SIZE_OF_A * 2, epsilon: 0.0001));

    offset = 6;
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset),
      ui.Rect.zero,
    );
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dy, moreOrLessEquals(SIZE_OF_A * 3, epsilon: 0.0001));

    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dy, moreOrLessEquals(SIZE_OF_A * 3, epsilon: 0.0001));

    // When given a string with multiple leading newlines, places the caret in
    // the position given by offset regardless of affinity.
    text = '\n\n\naaa';
    offset = 3;
    painter.text = TextSpan(text: text);
    painter.layout();
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset),
      ui.Rect.zero,
    );
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dy, moreOrLessEquals(SIZE_OF_A * 3, epsilon: 0.0001));
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dy, moreOrLessEquals(SIZE_OF_A * 3, epsilon: 0.0001));

    offset = 2;
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset),
      ui.Rect.zero,
    );
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dy, moreOrLessEquals(SIZE_OF_A * 2, epsilon: 0.0001));
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dy, moreOrLessEquals(SIZE_OF_A * 2, epsilon: 0.0001));

    offset = 1;
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset),
      ui.Rect.zero,
    );
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dy,moreOrLessEquals(SIZE_OF_A, epsilon: 0.0001));
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dy, moreOrLessEquals(SIZE_OF_A, epsilon: 0.0001));

    offset = 0;
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset),
      ui.Rect.zero,
    );
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    caretOffset = painter.getOffsetForCaret(
      ui.TextPosition(offset: offset, affinity: TextAffinity.upstream),
      ui.Rect.zero,
    );
    expect(caretOffset.dx, moreOrLessEquals(0.0, epsilon: 0.0001));
    expect(caretOffset.dy, moreOrLessEquals(0.0, epsilon: 0.0001));
    painter.dispose();
  });

  test('TextPainter widget span', () {
    final TextPainter painter = TextPainter()
      ..textDirection = TextDirection.ltr;

    const String text = 'test';
    painter.text = const TextSpan(
      text: text,
      children: <InlineSpan>[
        WidgetSpan(child: SizedBox(width: 50, height: 30)),
        TextSpan(text: text),
        WidgetSpan(child: SizedBox(width: 50, height: 30)),
        WidgetSpan(child: SizedBox(width: 50, height: 30)),
        TextSpan(text: text),
        WidgetSpan(child: SizedBox(width: 50, height: 30)),
        WidgetSpan(child: SizedBox(width: 50, height: 30)),
        WidgetSpan(child: SizedBox(width: 50, height: 30)),
        WidgetSpan(child: SizedBox(width: 50, height: 30)),
        WidgetSpan(child: SizedBox(width: 50, height: 30)),
        WidgetSpan(child: SizedBox(width: 50, height: 30)),
        WidgetSpan(child: SizedBox(width: 50, height: 30)),
        WidgetSpan(child: SizedBox(width: 50, height: 30)),
        WidgetSpan(child: SizedBox(width: 50, height: 30)),
        WidgetSpan(child: SizedBox(width: 50, height: 30)),
        WidgetSpan(child: SizedBox(width: 50, height: 30)),
      ],
    );

    // We provide dimensions for the widgets
    painter.setPlaceholderDimensions(const <PlaceholderDimensions>[
      PlaceholderDimensions(size: Size(50, 30), baselineOffset: 25, alignment: ui.PlaceholderAlignment.bottom),
      PlaceholderDimensions(size: Size(50, 30), baselineOffset: 25, alignment: ui.PlaceholderAlignment.bottom),
      PlaceholderDimensions(size: Size(50, 30), baselineOffset: 25, alignment: ui.PlaceholderAlignment.bottom),
      PlaceholderDimensions(size: Size(50, 30), baselineOffset: 25, alignment: ui.PlaceholderAlignment.bottom),
      PlaceholderDimensions(size: Size(50, 30), baselineOffset: 25, alignment: ui.PlaceholderAlignment.bottom),
      PlaceholderDimensions(size: Size(50, 30), baselineOffset: 25, alignment: ui.PlaceholderAlignment.bottom),
      PlaceholderDimensions(size: Size(50, 30), baselineOffset: 25, alignment: ui.PlaceholderAlignment.bottom),
      PlaceholderDimensions(size: Size(50, 30), baselineOffset: 25, alignment: ui.PlaceholderAlignment.bottom),
      PlaceholderDimensions(size: Size(50, 30), baselineOffset: 25, alignment: ui.PlaceholderAlignment.bottom),
      PlaceholderDimensions(size: Size(50, 30), baselineOffset: 25, alignment: ui.PlaceholderAlignment.bottom),
      PlaceholderDimensions(size: Size(50, 30), baselineOffset: 25, alignment: ui.PlaceholderAlignment.bottom),
      PlaceholderDimensions(size: Size(50, 30), baselineOffset: 25, alignment: ui.PlaceholderAlignment.bottom),
      PlaceholderDimensions(size: Size(51, 30), baselineOffset: 25, alignment: ui.PlaceholderAlignment.bottom),
      PlaceholderDimensions(size: Size(50, 30), baselineOffset: 25, alignment: ui.PlaceholderAlignment.bottom),
    ]);

    painter.layout(maxWidth: 500);

    // Now, each of the WidgetSpans will have their own placeholder 'hole'.
    Offset caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 1), ui.Rect.zero);
    expect(caretOffset.dx, 14);
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 4), ui.Rect.zero);
    expect(caretOffset.dx, 56);
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 5), ui.Rect.zero);
    expect(caretOffset.dx, 106);
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 6), ui.Rect.zero);
    expect(caretOffset.dx, 120);
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 10), ui.Rect.zero);
    expect(caretOffset.dx, 212);
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 11), ui.Rect.zero);
    expect(caretOffset.dx, 262);
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 12), ui.Rect.zero);
    expect(caretOffset.dx, 276);
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 13), ui.Rect.zero);
    expect(caretOffset.dx, 290);
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 14), ui.Rect.zero);
    expect(caretOffset.dx, 304);
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 15), ui.Rect.zero);
    expect(caretOffset.dx, 318);
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 16), ui.Rect.zero);
    expect(caretOffset.dx, 368);
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 17), ui.Rect.zero);
    expect(caretOffset.dx, 418);
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 18), ui.Rect.zero);
    expect(caretOffset.dx, 0);
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 19), ui.Rect.zero);
    expect(caretOffset.dx, 50);
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 23), ui.Rect.zero);
    expect(caretOffset.dx, 250);

    expect(painter.inlinePlaceholderBoxes!.length, 14);
    expect(painter.inlinePlaceholderBoxes![0], const TextBox.fromLTRBD(56, 0, 106, 30, TextDirection.ltr));
    expect(painter.inlinePlaceholderBoxes![2], const TextBox.fromLTRBD(212, 0, 262, 30, TextDirection.ltr));
    expect(painter.inlinePlaceholderBoxes![3], const TextBox.fromLTRBD(318, 0, 368, 30, TextDirection.ltr));
    expect(painter.inlinePlaceholderBoxes![4], const TextBox.fromLTRBD(368, 0, 418, 30, TextDirection.ltr));
    expect(painter.inlinePlaceholderBoxes![5], const TextBox.fromLTRBD(418, 0, 468, 30, TextDirection.ltr));
    // line should break here
    expect(painter.inlinePlaceholderBoxes![6], const TextBox.fromLTRBD(0, 30, 50, 60, TextDirection.ltr));
    expect(painter.inlinePlaceholderBoxes![7], const TextBox.fromLTRBD(50, 30, 100, 60, TextDirection.ltr));
    expect(painter.inlinePlaceholderBoxes![10], const TextBox.fromLTRBD(200, 30, 250, 60, TextDirection.ltr));
    expect(painter.inlinePlaceholderBoxes![11], const TextBox.fromLTRBD(250, 30, 300, 60, TextDirection.ltr));
    expect(painter.inlinePlaceholderBoxes![12], const TextBox.fromLTRBD(300, 30, 351, 60, TextDirection.ltr));
    expect(painter.inlinePlaceholderBoxes![13], const TextBox.fromLTRBD(351, 30, 401, 60, TextDirection.ltr));
    painter.dispose();
  }, skip: isBrowser && !isCanvasKit); // https://github.com/flutter/flutter/issues/87540

  // Null values are valid. See https://github.com/flutter/flutter/pull/48346#issuecomment-584839221
  test('TextPainter set TextHeightBehavior null test', () {
    final TextPainter painter = TextPainter()
      ..textDirection = TextDirection.ltr;

    painter.textHeightBehavior = const TextHeightBehavior();
    painter.textHeightBehavior = null;
    painter.dispose();
  });

  test('TextPainter line metrics', () {
    final TextPainter painter = TextPainter()
      ..textDirection = TextDirection.ltr;

    const String text = 'test1\nhello line two really long for soft break\nfinal line 4';
    painter.text = const TextSpan(
      text: text,
    );

    painter.layout(maxWidth: 300);

    expect(painter.text, const TextSpan(text: text));
    expect(painter.preferredLineHeight, 14);

    final List<ui.LineMetrics> lines = painter.computeLineMetrics();

    expect(lines.length, 4);

    expect(lines[0].hardBreak, true);
    expect(lines[1].hardBreak, false);
    expect(lines[2].hardBreak, true);
    expect(lines[3].hardBreak, true);

    expect(lines[0].ascent, 11.199999809265137);
    expect(lines[1].ascent, 11.199999809265137);
    expect(lines[2].ascent, 11.199999809265137);
    expect(lines[3].ascent, 11.199999809265137);

    expect(lines[0].descent, 2.799999952316284);
    expect(lines[1].descent, 2.799999952316284);
    expect(lines[2].descent, 2.799999952316284);
    expect(lines[3].descent, 2.799999952316284);

    expect(lines[0].unscaledAscent, 11.199999809265137);
    expect(lines[1].unscaledAscent, 11.199999809265137);
    expect(lines[2].unscaledAscent, 11.199999809265137);
    expect(lines[3].unscaledAscent, 11.199999809265137);

    expect(lines[0].baseline, 11.200000047683716);
    expect(lines[1].baseline, 25.200000047683716);
    expect(lines[2].baseline, 39.200000047683716);
    expect(lines[3].baseline, 53.200000047683716);

    expect(lines[0].height, 14);
    expect(lines[1].height, 14);
    expect(lines[2].height, 14);
    expect(lines[3].height, 14);

    expect(lines[0].width, 70);
    expect(lines[1].width, 294);
    expect(lines[2].width, 266);
    expect(lines[3].width, 168);

    expect(lines[0].left, 0);
    expect(lines[1].left, 0);
    expect(lines[2].left, 0);
    expect(lines[3].left, 0);

    expect(lines[0].lineNumber, 0);
    expect(lines[1].lineNumber, 1);
    expect(lines[2].lineNumber, 2);
    expect(lines[3].lineNumber, 3);
    painter.dispose();
  }, skip: true); // https://github.com/flutter/flutter/issues/62819

  test('TextPainter caret height and line height', () {
    final TextPainter painter = TextPainter()
      ..textDirection = TextDirection.ltr
      ..strutStyle = const StrutStyle(fontSize: 50.0);

    const String text = 'A';
    painter.text = const TextSpan(text: text, style: TextStyle(height: 1.0));
    painter.layout();

    final double caretHeight = painter.getFullHeightForCaret(
      const ui.TextPosition(offset: 0),
      ui.Rect.zero,
    )!;
    expect(caretHeight, 50.0);
    painter.dispose();
  }, skip: isBrowser && !isCanvasKit); // https://github.com/flutter/flutter/issues/56308

  group('TextPainter line-height', () {
    test('half-leading', () {
      const TextStyle style = TextStyle(
        height: 20,
        fontSize: 1,
        leadingDistribution: TextLeadingDistribution.even,
      );

      final TextPainter painter = TextPainter()
        ..textDirection = TextDirection.ltr
        ..text = const TextSpan(text: 'A', style: style)
        ..layout();

      final Rect glyphBox = painter.getBoxesForSelection(
        const TextSelection(baseOffset: 0, extentOffset: 1),
      ).first.toRect();

      final RelativeRect insets = RelativeRect.fromSize(glyphBox, painter.size);
      // The glyph box is centered.
      expect(insets.top, insets.bottom);
      // The glyph box is exactly 1 logical pixel high.
      expect(insets.top, (20 - 1) / 2);
      painter.dispose();
    });

    test('half-leading with small height', () {
      const TextStyle style = TextStyle(
        height: 0.1,
        fontSize: 10,
        leadingDistribution: TextLeadingDistribution.even,
      );

      final TextPainter painter = TextPainter()
        ..textDirection = TextDirection.ltr
        ..text = const TextSpan(text: 'A', style: style)
        ..layout();

      final Rect glyphBox = painter.getBoxesForSelection(
        const TextSelection(baseOffset: 0, extentOffset: 1),
      ).first.toRect();

      final RelativeRect insets = RelativeRect.fromSize(glyphBox, painter.size);
      // The glyph box is still centered.
      expect(insets.top, insets.bottom);
      // The glyph box is exactly 10 logical pixel high (the height multiplier
      // does not scale the glyph). Negative leading.
      expect(insets.top, (1 - 10) / 2);
      painter.dispose();
    });

    test('half-leading with leading trim', () {
      const TextStyle style = TextStyle(
        height: 0.1,
        fontSize: 10,
        leadingDistribution: TextLeadingDistribution.even,
      );

      final TextPainter painter = TextPainter()
        ..textDirection = TextDirection.ltr
        ..text = const TextSpan(text: 'A', style: style)
        ..textHeightBehavior = const TextHeightBehavior(
            applyHeightToFirstAscent: false,
            applyHeightToLastDescent: false,
          )
        ..layout();

      final Rect glyphBox = painter.getBoxesForSelection(
        const TextSelection(baseOffset: 0, extentOffset: 1),
      ).first.toRect();

      expect(painter.size, glyphBox.size);
      // The glyph box is still centered.
      expect(glyphBox.topLeft, Offset.zero);
      painter.dispose();
    });

    test('TextLeadingDistribution falls back to paragraph style', () {
      const TextStyle style = TextStyle(height: 20, fontSize: 1);
      final TextPainter painter = TextPainter()
        ..textDirection = TextDirection.ltr
        ..text = const TextSpan(text: 'A', style: style)
        ..textHeightBehavior = const TextHeightBehavior(
            leadingDistribution: TextLeadingDistribution.even,
          )
        ..layout();

      final Rect glyphBox = painter.getBoxesForSelection(
        const TextSelection(baseOffset: 0, extentOffset: 1),
      ).first.toRect();

      // Still uses half-leading.
      final RelativeRect insets = RelativeRect.fromSize(glyphBox, painter.size);
      expect(insets.top, insets.bottom);
      expect(insets.top, (20 - 1) / 2);
      painter.dispose();
    });

    test('TextLeadingDistribution does nothing if height multiplier is null', () {
      const TextStyle style = TextStyle(fontSize: 1);
      final TextPainter painter = TextPainter()
        ..textDirection = TextDirection.ltr
        ..text = const TextSpan(text: 'A', style: style)
        ..textHeightBehavior = const TextHeightBehavior(
            leadingDistribution: TextLeadingDistribution.even,
          )
        ..layout();

      final Rect glyphBox = painter.getBoxesForSelection(
        const TextSelection(baseOffset: 0, extentOffset: 1),
      ).first.toRect();

      painter.textHeightBehavior = const TextHeightBehavior();
      painter.layout();

      final Rect newGlyphBox = painter.getBoxesForSelection(
        const TextSelection(baseOffset: 0, extentOffset: 1),
      ).first.toRect();
      expect(glyphBox, newGlyphBox);
      painter.dispose();
    });
  }, skip: isBrowser && !isCanvasKit); // https://github.com/flutter/flutter/issues/87543

  test('TextPainter handles invalid UTF-16', () {
    Object? exception;
    FlutterError.onError = (FlutterErrorDetails details) {
      exception = details.exception;
    };

    final TextPainter painter = TextPainter()
      ..textDirection = TextDirection.ltr;

    const String text = 'Hello\uD83DWorld';
    const double fontSize = 20.0;
    painter.text = const TextSpan(text: text, style: TextStyle(fontSize: fontSize));
    painter.layout();
    // The layout should include one replacement character.
    expect(painter.width, equals(fontSize));
    expect(exception, isNotNull);
    painter.dispose();
  }, skip: kIsWeb); // https://github.com/flutter/flutter/issues/87544

  test('Diacritic', () {
    final TextPainter painter = TextPainter()
      ..textDirection = TextDirection.ltr;

    // Two letters followed by a diacritic
    const String text = 'ฟห้';
    painter.text = const TextSpan(text: text);
    painter.layout();

    final ui.Offset caretOffset = painter.getOffsetForCaret(
        const ui.TextPosition(
            offset: text.length, affinity: TextAffinity.upstream),
        ui.Rect.zero);
    expect(caretOffset.dx, painter.width);
    painter.dispose();
  }, skip: kIsWeb && !isCanvasKit); // https://github.com/flutter/flutter/issues/87545

  test('TextPainter line metrics update after layout', () {
    final TextPainter painter = TextPainter()
      ..textDirection = TextDirection.ltr;

    const String text = 'word1 word2 word3';
    painter.text = const TextSpan(
      text: text,
    );

    painter.layout(maxWidth: 80);

    List<ui.LineMetrics> lines = painter.computeLineMetrics();
    expect(lines.length, 3);

    painter.layout(maxWidth: 1000);

    lines = painter.computeLineMetrics();
    expect(lines.length, 1);
    painter.dispose();
  }, skip: kIsWeb && !isCanvasKit); // https://github.com/flutter/flutter/issues/62819

  test('TextPainter throws with stack trace when accessing text layout', () {
    final TextPainter painter = TextPainter()
      ..text = const TextSpan(text: 'TEXT')
      ..textDirection = TextDirection.ltr;

    FlutterError? exception;
    try {
      painter.getPositionForOffset(Offset.zero);
    } on FlutterError catch (e) {
      exception = e;
    }
    expect(exception?.message, contains('The TextPainter has never been laid out.'));
    exception = null;

    try {
      painter.layout();
      painter.getPositionForOffset(Offset.zero);
    } on FlutterError catch (e) {
      exception = e;
    }

    expect(exception, isNull);
    exception = null;

    try {
      painter.markNeedsLayout();
      painter.getPositionForOffset(Offset.zero);
    } on FlutterError catch (e) {
      exception = e;
    }

    expect(exception?.message, contains('The calls that first invalidated the text layout were:'));
    exception = null;
    painter.dispose();
  });

  test('TextPainter requires layout after providing different placeholder dimensions', () {
    final TextPainter painter = TextPainter()
      ..textDirection = TextDirection.ltr;

    painter.text = const TextSpan(children: <InlineSpan>[
      TextSpan(text: 'before'),
      WidgetSpan(child: Text('widget1')),
      WidgetSpan(child: Text('widget2')),
      WidgetSpan(child: Text('widget3')),
      TextSpan(text: 'after'),
    ]);

    painter.setPlaceholderDimensions(const <PlaceholderDimensions>[
      PlaceholderDimensions(size: Size(30, 30), alignment: ui.PlaceholderAlignment.bottom),
      PlaceholderDimensions(size: Size(40, 30), alignment: ui.PlaceholderAlignment.bottom),
      PlaceholderDimensions(size: Size(50, 30), alignment: ui.PlaceholderAlignment.bottom),
    ]);
    painter.layout();

    painter.setPlaceholderDimensions(const <PlaceholderDimensions>[
      PlaceholderDimensions(size: Size(30, 30), alignment: ui.PlaceholderAlignment.bottom),
      PlaceholderDimensions(size: Size(40, 20), alignment: ui.PlaceholderAlignment.bottom),
      PlaceholderDimensions(size: Size(50, 30), alignment: ui.PlaceholderAlignment.bottom),
    ]);

    Object? e;
    try {
      painter.paint(MockCanvas(), Offset.zero);
    } catch (exception) {
      e = exception;
    }
    expect(
      e.toString(),
      contains('TextPainter.paint called when text geometry was not yet calculated'),
    );
    painter.dispose();
  }, skip: isBrowser && !isCanvasKit); // https://github.com/flutter/flutter/issues/56308

  test('TextPainter does not require layout after providing identical placeholder dimensions', () {
    final TextPainter painter = TextPainter()
      ..textDirection = TextDirection.ltr;

    painter.text = const TextSpan(children: <InlineSpan>[
      TextSpan(text: 'before'),
      WidgetSpan(child: Text('widget1')),
      WidgetSpan(child: Text('widget2')),
      WidgetSpan(child: Text('widget3')),
      TextSpan(text: 'after'),
    ]);

    painter.setPlaceholderDimensions(const <PlaceholderDimensions>[
      PlaceholderDimensions(size: Size(30, 30), alignment: ui.PlaceholderAlignment.bottom),
      PlaceholderDimensions(size: Size(40, 30), alignment: ui.PlaceholderAlignment.bottom),
      PlaceholderDimensions(size: Size(50, 30), alignment: ui.PlaceholderAlignment.bottom),
    ]);
    painter.layout();

    painter.setPlaceholderDimensions(const <PlaceholderDimensions>[
      PlaceholderDimensions(size: Size(30, 30), alignment: ui.PlaceholderAlignment.bottom),
      PlaceholderDimensions(size: Size(40, 30), alignment: ui.PlaceholderAlignment.bottom),
      PlaceholderDimensions(size: Size(50, 30), alignment: ui.PlaceholderAlignment.bottom),
    ]);

    Object? e;
    try {
      painter.paint(MockCanvas(), Offset.zero);
    } catch (exception) {
      e = exception;
    }
    // In tests, paint() will throw an UnimplementedError due to missing drawParagraph method.
    expect(
      e.toString(),
      isNot(contains('TextPainter.paint called when text geometry was not yet calculated')),
    );
    painter.dispose();
  }, skip: isBrowser && !isCanvasKit); // https://github.com/flutter/flutter/issues/56308

  test('TextPainter - debugDisposed', () {
    final TextPainter painter = TextPainter();
    expect(painter.debugDisposed, false);
    painter.dispose();
    expect(painter.debugDisposed, true);
  });
}

class MockCanvas extends Fake implements Canvas {

}
