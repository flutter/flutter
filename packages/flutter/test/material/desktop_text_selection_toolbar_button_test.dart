// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('can press', (WidgetTester tester) async {
    bool pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: DesktopTextSelectionToolbarButton(
            child: const Text('Tap me'),
            onPressed: () {
              pressed = true;
            },
          ),
        ),
      ),
    );

    expect(pressed, false);

    await tester.tap(find.byType(DesktopTextSelectionToolbarButton));
    expect(pressed, true);
  });
}
