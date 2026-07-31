// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:primitive_shape_test/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders primitive shapes', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Take a screenshot of the test canvas widget.
    await expectLater(
      find.byKey(const Key('primitive_shape_canvas')),
      matchesGoldenFile('primitive_shape_canvas_snapshot.png'),
    );
  });
}
