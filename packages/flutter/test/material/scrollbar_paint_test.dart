// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import '../rendering/mock_canvas.dart';

void main() {
  testWidgets('Viewport2 basic test', (WidgetTester tester) async {
    await tester.pumpWidget(new Scrollbar(
      child: new SingleChildScrollView(
        child: const SizedBox(width: 4000.0, height: 4000.0),
      ),
    ));
    expect(find.byType(Scrollbar), isNot(paints..rect()));
    await tester.fling(find.byType(SingleChildScrollView), const Offset(0.0, -10.0), 10.0);
    expect(find.byType(Scrollbar), paints..rect());
  });
}
