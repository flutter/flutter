// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_api_samples/painting/axis_direction/axis_direction_left.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Example app has AxisDirection.left', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.ExampleApp(),
    );

    final RenderViewport viewport = tester.renderObject(find.byType(Viewport));
    expect(find.text('AxisDirection.left'), findsOneWidget);
    expect(find.text('Axis.horizontal'), findsOneWidget);
    expect(find.text('GrowthDirection.forward'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsNWidgets(2));
    expect(viewport.axisDirection, AxisDirection.left);
  });
}
