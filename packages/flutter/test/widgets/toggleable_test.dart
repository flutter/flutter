// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Toggleable exists in widget layer', (WidgetTester tester) async {
    final TestPainter testPainter = TestPainter();
    expect(testPainter, isA<ToggleablePainter>());
    expect(testPainter, isNot(throwsException));
  });
}

class TestPainter extends ToggleablePainter {
  @override
  void paint(Canvas canvas, Size size) {}
}
