// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TextPainter caret test', () {
    final TextPainter painter = TextPainter()
      ..textDirection = TextDirection.ltr;

    String text = 'A';
    painter.text = TextSpan(text: text);
    painter.layout();

    Offset caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 0), ui.Rect.zero);
    expect(caretOffset.dx, 0);
    caretOffset = painter.getOffsetForCaret(ui.TextPosition(offset: text.length), ui.Rect.zero);
    expect(caretOffset.dx, painter.width);

    // Check that getOffsetForCaret handles a character that is encoded as a surrogate pair.
    text = 'A\u{1F600}';
    painter.text = TextSpan(text: text);
    painter.layout();
    caretOffset = painter.getOffsetForCaret(ui.TextPosition(offset: text.length), ui.Rect.zero);
    expect(caretOffset.dx, painter.width);
  });

  test('TextPainter error test', () {
    final TextPainter painter = TextPainter(textDirection: TextDirection.ltr);
    expect(() { painter.paint(null, Offset.zero); }, throwsFlutterError);
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
  });

  test('TextPainter default text height is 14 pixels', () {
    final TextPainter painter = TextPainter(
      text: const TextSpan(text: 'x'),
      textDirection: TextDirection.ltr,
    );
    painter.layout();
    expect(painter.preferredLineHeight, 14.0);
    expect(painter.size, const Size(14.0, 14.0));
  });

  test('TextPainter sets paragraph size from root', () {
    final TextPainter painter = TextPainter(
      text: const TextSpan(text: 'x', style: TextStyle(fontSize: 100.0)),
      textDirection: TextDirection.ltr,
    );
    painter.layout();
    expect(painter.preferredLineHeight, 100.0);
    expect(painter.size, const Size(100.0, 100.0));
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
  }, skip: true); // https://github.com/flutter/flutter/issues/13512

  test('TextPainter handles newlines properly', () {
    final TextPainter painter = TextPainter()
      ..textDirection = TextDirection.ltr;

    String text = 'aaa';
    painter.text = TextSpan(text: text);
    painter.layout();

    Offset caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 0), ui.Rect.zero);
    expect(caretOffset.dx, closeTo(0.0, 0.0001));
    caretOffset = painter.getOffsetForCaret(ui.TextPosition(offset: text.length), ui.Rect.zero);
    expect(caretOffset.dx, painter.width);
    expect(caretOffset.dy, closeTo(0.0, 0.0001));

    // Check that getOffsetForCaret handles a trailing newline when affinity is downstream.
    text = 'aaa\n';
    painter.text = TextSpan(text: text);
    painter.layout();
    caretOffset = painter.getOffsetForCaret(ui.TextPosition(offset: text.length), ui.Rect.zero);
    expect(caretOffset.dx, closeTo(0.0, 0.0001));
    expect(caretOffset.dy, closeTo(14.0, 0.0001));

    // Check that getOffsetForCaret handles a trailing newline when affinity is upstream.
    text = 'aaa\n';
    painter.text = TextSpan(text: text);
    painter.layout();
    caretOffset = painter.getOffsetForCaret(ui.TextPosition(offset: text.length, affinity: TextAffinity.upstream), ui.Rect.zero);
    expect(caretOffset.dx, painter.width);
    expect(caretOffset.dy, closeTo(0.0, 0.0001));

    // Correctly moves through second line with downstream affinity.
    text = 'aaa\naaa';
    painter.text = TextSpan(text: text);
    painter.layout();
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 4), ui.Rect.zero);
    expect(caretOffset.dx, closeTo(0.0, 0.0001));
    expect(caretOffset.dy, closeTo(14.0, 0.0001));

    // Correctly moves through second line with upstream affinity.
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 4, affinity: TextAffinity.upstream), ui.Rect.zero);
    expect(caretOffset.dx, closeTo(42.0, 0.0001));
    expect(caretOffset.dy, closeTo(0.0, 0.0001));

    // Correctly handles multiple trailing newlines.
    text = 'aaa\n\n\n';
    painter.text = TextSpan(text: text);
    painter.layout();
    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 4), ui.Rect.zero);
    expect(caretOffset.dx, closeTo(0.0, 0.0001));
    expect(caretOffset.dy, closeTo(14.0, 0.001));

    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 5), ui.Rect.zero);
    expect(caretOffset.dx, closeTo(0.0, 0.0001));
    expect(caretOffset.dy, closeTo(28.0, 0.001));

    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 6), ui.Rect.zero);
    expect(caretOffset.dx, closeTo(0.0, 0.0001));
    expect(caretOffset.dy, closeTo(42.0, 0.0001));

    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 6, affinity: TextAffinity.upstream), ui.Rect.zero);
    expect(caretOffset.dx, closeTo(0.0, 0.0001));
    expect(caretOffset.dy, closeTo(28.0, 0.0001));

    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 5, affinity: TextAffinity.upstream), ui.Rect.zero);
    expect(caretOffset.dx, closeTo(0.0, 0.0001));
    expect(caretOffset.dy, closeTo(14.0, 0.0001));

    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 4, affinity: TextAffinity.upstream), ui.Rect.zero);
    expect(caretOffset.dx, closeTo(42.0, 0.0001));
    expect(caretOffset.dy, closeTo(0.0, 0.0001));

    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 3, affinity: TextAffinity.upstream), ui.Rect.zero);
    expect(caretOffset.dx, closeTo(42.0, 0.0001));
    expect(caretOffset.dy, closeTo(0.0, 0.0001));

    // Correctly handles multiple leading newlines
    text = '\n\n\naaa';
    painter.text = TextSpan(text: text);
    painter.layout();

    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 3), ui.Rect.zero);
    expect(caretOffset.dx, closeTo(0.0, 0.0001));
    expect(caretOffset.dy, closeTo(42.0, 0.0001));

    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 2), ui.Rect.zero);
    expect(caretOffset.dx, closeTo(0.0, 0.0001));
    expect(caretOffset.dy, closeTo(28.0, 0.0001));

    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 1), ui.Rect.zero);
    expect(caretOffset.dx, closeTo(0.0, 0.0001));
    expect(caretOffset.dy,closeTo(14.0, 0.0001));

    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 0), ui.Rect.zero);
    expect(caretOffset.dx, closeTo(0.0, 0.0001));
    expect(caretOffset.dy, closeTo(0.0, 0.0001));

    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 0, affinity: TextAffinity.upstream), ui.Rect.zero);
    expect(caretOffset.dx, closeTo(0.0, 0.0001));
    expect(caretOffset.dy, closeTo(0.0, 0.0001));

    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 1, affinity: TextAffinity.upstream), ui.Rect.zero);
    expect(caretOffset.dx, closeTo(0.0, 0.0001));
    expect(caretOffset.dy, closeTo(0.0, 0.0001));

    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 2, affinity: TextAffinity.upstream), ui.Rect.zero);
    expect(caretOffset.dx, closeTo(0.0, 0.0001));
    expect(caretOffset.dy, closeTo(14.0, 0.0001));

    caretOffset = painter.getOffsetForCaret(const ui.TextPosition(offset: 3, affinity: TextAffinity.upstream), ui.Rect.zero);
    expect(caretOffset.dx, closeTo(0.0, 0.0001));
    expect(caretOffset.dy, closeTo(28.0, 0.0001));
  });
}
