// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('paints.circle is not affected by mutated colors', (WidgetTester tester) async {
    final Key customPaintKey = UniqueKey();
    Widget buildApp({required bool enabled}) {
      return MaterialApp(
        home: Scaffold(
          body: Center(child: CustomPaint(key: customPaintKey, painter: _MutantPainter())),
        ),
      );
    }

    await tester.pumpWidget(buildApp(enabled: true));

    // Selected and enabled.
    await tester.pumpAndSettle();
    expect(
      Material.of(tester.element(find.byKey(customPaintKey))),
      paints..circle(color: Colors.red),
    );
  });
}

class _MutantPainter extends ChangeNotifier implements CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = Colors.red;

    canvas.drawCircle(Offset.zero, 10.0, paint);

    // Mutate paint after drawing.
    paint.color = Colors.blue;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

  @override
  bool? hitTest(Offset position) => null;

  @override
  SemanticsBuilderCallback? get semanticsBuilder => null;

  @override
  bool shouldRebuildSemantics(covariant CustomPainter oldDelegate) => true;
}
