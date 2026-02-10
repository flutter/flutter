// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show Platform;
import 'dart:ui';

import 'package:test/test.dart';

void main() {
  // Windows/Linux: 96/72 scaling to convert typographic points to logical pixels
  // macOS/iOS/Android: no scaling
  final bool hasFontScaling = Platform.isWindows || Platform.isLinux;
  final double expectedScale = hasFontScaling ? 96.0 / 72.0 : 1.0;

  test('font scale - Ahem paragraph layout dimensions', () {
    const fontSizes = [10.0, 12.0, 16.0, 20.0, 24.0, 32.0, 48.0];
    const text = 'XXXX';
    const charCount = 4;

    for (final fontSize in fontSizes) {
      final builder = ParagraphBuilder(ParagraphStyle(fontFamily: 'Ahem', fontSize: fontSize));
      builder.addText(text);
      final paragraph = builder.build();
      paragraph.layout(const ParagraphConstraints(width: 1000));

      final layoutW = paragraph.maxIntrinsicWidth;
      final expectedW = fontSize * charCount;
      final scale = layoutW / expectedW;

      expect(
        scale,
        closeTo(expectedScale, 0.05),
        reason: 'fontSize $fontSize: expected scale $expectedScale, got $scale',
      );
    }
  });

  test('font scale - Ahem height matches scaled fontSize', () {
    for (final fontSize in <double>[10.0, 20.0, 30.0, 40.0]) {
      final builder = ParagraphBuilder(ParagraphStyle(fontFamily: 'Ahem', fontSize: fontSize));
      builder.addText('X');
      final paragraph = builder.build();
      paragraph.layout(const ParagraphConstraints(width: 400.0));

      final expectedHeight = fontSize * expectedScale;
      expect(
        paragraph.height,
        closeTo(expectedHeight, 1.0),
        reason: 'fontSize $fontSize: expected height $expectedHeight',
      );
    }
  });
}
