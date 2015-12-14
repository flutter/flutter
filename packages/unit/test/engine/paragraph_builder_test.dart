// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:test/test.dart';

void main() {
  test("Should be able to build and layout a paragraph", () {
    ParagraphBuilder builder = new ParagraphBuilder();
    builder.addText('Hello');
    Paragraph paragraph = builder.build(new ParagraphStyle());
    expect(paragraph, isNotNull);

    paragraph.minWidth = 0.0;
    paragraph.maxWidth = 800.0;
    paragraph.minHeight = 0.0;
    paragraph.maxHeight = 600.0;

    paragraph.layout();
    expect(paragraph.width, isNonZero);
    expect(paragraph.height, isNonZero);
  });
}
