// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

void main() {
  testWidgets('InkSparkle renders with sparkles', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Theme(
            data: ThemeData(splashFactory: InkSparkle.splashFactory),
            child: ElevatedButton(
              child: const Text('Sparkle!'),
              onPressed: () { },
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Sparkle!'));
    await tester.pumpAndSettle(const Duration(milliseconds: 30));

    // TODO(clocksmith): add golden.
  });
}
