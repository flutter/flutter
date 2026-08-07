// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:engine_integration_golden_test/primitive_shape_main.dart' as primitive_shape;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders primitive shapes', (WidgetTester tester) async {
    await tester.pumpWidget(const primitive_shape.PrimitiveShapeApp());
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const Key('primitive_shape_canvas')),
      matchesGoldenFile('primitive_shape_canvas_snapshot.png'),
    );
  });
}
