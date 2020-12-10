// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manual_tests/overlay_geometry.dart' as overlay_geometry;

void main() {
  testWidgets('Overlay geometry smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: overlay_geometry.OverlayGeometryApp()));
    expect(find.byType(overlay_geometry.Marker), findsNothing);
    await tester.tap(find.text('Card 3'));
    await tester.pump();
    expect(find.byType(overlay_geometry.Marker), findsNWidgets(3));
    final double y = tester.getTopLeft(find.byType(overlay_geometry.Marker).first).dy;
    await tester.fling(find.text('Card 3'), const Offset(0.0, -100.0), 100.0);
    await tester.pump();
    expect(find.byType(overlay_geometry.Marker), findsNWidgets(3));
    expect(tester.getTopLeft(find.byType(overlay_geometry.Marker).first).dy, lessThan(y));
  });
}
