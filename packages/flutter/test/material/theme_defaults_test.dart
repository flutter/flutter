// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const Duration defaultButtonDuration = Duration(milliseconds: 200);

void main() {
  group('FloatingActionButton', () {
    const BoxConstraints defaultFABConstraints = BoxConstraints.tightFor(width: 56.0, height: 56.0);
    const ShapeBorder defaultFABShape = CircleBorder();
    const EdgeInsets defaultFABPadding = EdgeInsets.zero;

    testWidgets('theme: ThemeData.light(), enabled: true', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Center(
              child: FloatingActionButton(
                onPressed: () { }, // button.enabled == true
                child: const Icon(Icons.add),
              ),
          ),
        ),
      );

      final RawMaterialButton raw = tester.widget<RawMaterialButton>(find.byType(RawMaterialButton));
      expect(raw.enabled, true);
      expect(raw.textStyle!.color, const Color(0xffffffff));
      expect(raw.fillColor, const Color(0xff2196f3));
      expect(raw.elevation, 6.0);
      expect(raw.highlightElevation, 12.0);
      expect(raw.disabledElevation, 6.0);
      expect(raw.constraints, defaultFABConstraints);
      expect(raw.padding, defaultFABPadding);
      expect(raw.shape, defaultFABShape);
      expect(raw.animationDuration, defaultButtonDuration);
      expect(raw.materialTapTargetSize, MaterialTapTargetSize.padded);
    });

    testWidgets('theme: ThemeData.light(), enabled: false', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Center(
              child: FloatingActionButton(
                onPressed: null, // button.enabled == false
                child: Icon(Icons.add),
              ),
          ),
        ),
      );

      final RawMaterialButton raw = tester.widget<RawMaterialButton>(find.byType(RawMaterialButton));
      expect(raw.enabled, false);
      expect(raw.textStyle!.color, const Color(0xffffffff));
      expect(raw.fillColor, const Color(0xff2196f3));
      // highlightColor, disabled button can't be pressed
      // splashColor, disabled button doesn't splash
      expect(raw.elevation, 6.0);
      expect(raw.highlightElevation, 12.0);
      expect(raw.disabledElevation, 6.0);
      expect(raw.constraints, defaultFABConstraints);
      expect(raw.padding, defaultFABPadding);
      expect(raw.shape, defaultFABShape);
      expect(raw.animationDuration, defaultButtonDuration);
      expect(raw.materialTapTargetSize, MaterialTapTargetSize.padded);
    });
  });
}
