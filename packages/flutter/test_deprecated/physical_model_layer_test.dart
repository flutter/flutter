// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('RenderPhysicalModel creates a PhysicalModelLayer', (WidgetTester tester) async {
    expect(const bool.fromEnvironment('flutter.deprecated.physical_model_layer'), true);

    for (final MaterialType type in MaterialType.values) {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Material(
            type: type,
            child: const Text('Hello, World'),
          )),
        ),
      );
    }

    expect(tester.layers.whereType<PhysicalModelLayer>, hasLength(2));
  });
}
