// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

void main() {
  setUp(() {
    debugResetSemanticsIdCounter();
  });

  testWidgets('OutlineButton defaults', (WidgetTester tester) async {
    final Finder rawButtonMaterial = find.descendant(
      of: find.byType(OutlineButton),
      matching: find.byType(Material),
    );

    // Enabled OutlineButton
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: OutlineButton(
          onPressed: () { },
          child: const Text('button'),
        ),
      ),
    );
    Material material = tester.widget<Material>(rawButtonMaterial);
    expect(material.animationDuration, const Duration(milliseconds: 75));
    expect(material.borderOnForeground, true);
    expect(material.borderRadius, null);
    expect(material.clipBehavior, Clip.none);
    expect(material.color, const Color(0x00000000));
    expect(material.elevation, 0.0);
    expect(material.shadowColor, const Color(0xff000000));
    expect(material.textStyle.color, const Color(0xdd000000));
    expect(material.textStyle.fontFamily, 'Roboto');
    expect(material.textStyle.fontSize, 14);
    expect(material.textStyle.fontWeight, FontWeight.w500);
    expect(material.type, MaterialType.button);

    final Offset center = tester.getCenter(find.byType(OutlineButton));
    await tester.startGesture(center);
    await tester.pumpAndSettle();

    // No change vs enabled and not pressed.
    material = tester.widget<Material>(rawButtonMaterial);
    expect(material.animationDuration, const Duration(milliseconds: 75));
    expect(material.borderOnForeground, true);
    expect(material.borderRadius, null);
    expect(material.clipBehavior, Clip.none);
    expect(material.color, const Color(0x00000000));
    expect(material.elevation, 0.0);
    expect(material.shadowColor, const Color(0xff000000));
    expect(material.textStyle.color, const Color(0xdd000000));
    expect(material.textStyle.fontFamily, 'Roboto');
    expect(material.textStyle.fontSize, 14);
    expect(material.textStyle.fontWeight, FontWeight.w500);
    expect(material.type, MaterialType.button);

    // Disabled OutlineButton
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: OutlineButton(
          onPressed: null,
          child: Text('button'),
        ),
      ),
    );
    material = tester.widget<Material>(rawButtonMaterial);
    expect(material.animationDuration, const Duration(milliseconds: 75));
    expect(material.borderOnForeground, true);
    expect(material.borderRadius, null);
    expect(material.clipBehavior, Clip.none);
    expect(material.color, const Color(0x00000000));
    expect(material.elevation, 0.0);
    expect(material.shadowColor, const Color(0xff000000));
    expect(material.textStyle.color, const Color(0x61000000));
    expect(material.textStyle.fontFamily, 'Roboto');
    expect(material.textStyle.fontSize, 14);
    expect(material.textStyle.fontWeight, FontWeight.w500);
    expect(material.type, MaterialType.button);
  });

  testWidgets('Do buttons work with hover', (WidgetTester tester) async {
    const Color hoverColor = Color(0xff001122);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: OutlineButton(
          hoverColor: hoverColor,
          onPressed: () { },
          child: const Text('button'),
        ),
      ),
    );

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    await gesture.moveTo(tester.getCenter(find.byType(OutlineButton)));
    await tester.pumpAndSettle();
    final RenderObject inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) => object.runtimeType.toString() == '_RenderInkFeatures');
    expect(inkFeatures, paints..rect(color: hoverColor));

    gesture.removePointer();
  });

  testWidgets('Do buttons work with focus', (WidgetTester tester) async {
    const Color focusColor = Color(0xff001122);

    final FocusNode focusNode = FocusNode(debugLabel: 'OutlineButton Node');
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: OutlineButton(
          focusColor: focusColor,
          focusNode: focusNode,
          onPressed: () { },
          child: const Text('button'),
        ),
      ),
    );

    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    focusNode.requestFocus();
    await tester.pumpAndSettle();

    final RenderObject inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) => object.runtimeType.toString() == '_RenderInkFeatures');
    expect(inkFeatures, paints..rect(color: focusColor));
  });
}
