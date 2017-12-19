// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';


void main() {
  group('PhysicalShape', () {
    testWidgets('properties', (WidgetTester tester) async {
      await tester.pumpWidget(
        const PhysicalShape(
          shape: const CircleBorder(),
          elevation: 2.0,
          color: const Color(0xFF0000FF),
          shadowColor: const Color(0xFF00FF00),
          textDirection: TextDirection.ltr,
        )
      );
      final RenderPhysicalShape renderObject = tester.renderObject(find.byType(PhysicalShape));
      expect(renderObject.shape, const CircleBorder());
      expect(renderObject.color, const Color(0xFF0000FF));
      expect(renderObject.shadowColor, const Color(0xFF00FF00));
      expect(renderObject.elevation, 2.0);
      expect(renderObject.textDirection, TextDirection.ltr);
    });

    testWidgets('overrides directionality', (WidgetTester tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.rtl,
          child: const PhysicalShape(
            shape: const CircleBorder(),
            color: const Color(0xFF0000FF),
            textDirection: TextDirection.ltr,
          ),
        ),
      );
      final RenderPhysicalShape renderObject = tester.renderObject(find.byType(PhysicalShape));
      expect(renderObject.textDirection, TextDirection.ltr);
    });

    testWidgets('inherits directionality', (WidgetTester tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.rtl,
          child: const PhysicalShape(
            shape: const CircleBorder(),
            color: const Color(0xFF0000FF),
          ),
        ),
      );
      final RenderPhysicalShape renderObject = tester.renderObject(find.byType(PhysicalShape));
      expect(renderObject.textDirection, TextDirection.rtl);
    });
  });

}
