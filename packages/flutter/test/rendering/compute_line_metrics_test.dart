// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('RenderParagraph.computeLineMetrics returns valid metrics', () {
    const text = 'Hello world!\nThis is line two.';

    final paragraph = RenderParagraph(const TextSpan(text: text), textDirection: TextDirection.ltr);

    paragraph.layout(const BoxConstraints(maxWidth: 200));

    final List<LineMetrics> metrics = paragraph.computeLineMetrics();

    expect(metrics, isNotEmpty);

    for (final m in metrics) {
      expect(m.lineNumber, greaterThanOrEqualTo(0));
      expect(m.width, greaterThan(0));
      expect(m.height, greaterThan(0));
      expect(m.baseline, greaterThanOrEqualTo(0));
    }
  });
}
