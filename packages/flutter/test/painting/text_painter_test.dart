// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test("TextPainter caret test", () {
    TextPainter painter = new TextPainter();

    String text = 'A';
    painter.text = new TextSpan(text: text);
    painter.layout();

    Offset caretOffset = painter.getOffsetForCaret(new ui.TextPosition(offset: 0), ui.Rect.zero);
    expect(caretOffset.dx, 0);
    caretOffset = painter.getOffsetForCaret(new ui.TextPosition(offset: text.length), ui.Rect.zero);
    expect(caretOffset.dx, painter.width);

    // Check that getOffsetForCaret handles a character that is encoded as a surrogate pair.
    text = 'A\u{1F600}';
    painter.text = new TextSpan(text: text);
    painter.layout();
    caretOffset = painter.getOffsetForCaret(new ui.TextPosition(offset: text.length), ui.Rect.zero);
    expect(caretOffset.dx, painter.width);
  });

  test("TextPainter error test", () {
    TextPainter painter = new TextPainter();
    expect(() { painter.paint(null, Offset.zero); }, throwsFlutterError);
  });
}
