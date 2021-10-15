// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const ShapeBorder defaultButtonShape = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(2.0)));
const EdgeInsets defaultButtonPadding = EdgeInsets.only(left: 16.0, right: 16.0);
const BoxConstraints defaultButtonConstraints = BoxConstraints(minWidth: 88.0, minHeight: 36.0);
const Duration defaultButtonDuration = Duration(milliseconds: 200);

void main() {
  group('RaisedButton', () {
    testWidgets('theme: ThemeData.light(), enabled: true', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Center(
            child: RaisedButton(
              onPressed: () { }, // button.enabled == true
              child: const Text('button'),
            ),
          ),
        ),
      );

      final RawMaterialButton raw = tester.widget<RawMaterialButton>(find.byType(RawMaterialButton));
      expect(raw.textStyle!.color, const Color(0xdd000000));
      expect(raw.fillColor, const Color(0xffe0e0e0));
      expect(raw.highlightColor, const Color(0x29000000)); // Was Color(0x66bcbcbc)
      expect(raw.splashColor, const Color(0x1f000000)); // Was Color(0x66c8c8c8)
      expect(raw.elevation, 2.0);
      expect(raw.highlightElevation, 8.0);
      expect(raw.disabledElevation, 0.0);
      expect(raw.constraints, defaultButtonConstraints);
      expect(raw.padding, defaultButtonPadding);
      expect(raw.shape, defaultButtonShape);
      expect(raw.animationDuration, defaultButtonDuration);
      expect(raw.materialTapTargetSize, MaterialTapTargetSize.padded);
    });

    testWidgets('theme: ThemeData.light(), enabled: false', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Center(
            child: RaisedButton(
              onPressed: null, // button.enabled == false
              child: Text('button'),
            ),
          ),
        ),
      );

      final RawMaterialButton raw = tester.widget<RawMaterialButton>(find.byType(RawMaterialButton));
      expect(raw.textStyle!.color, const Color(0x61000000));
      expect(raw.fillColor, const Color(0x61000000));
      // highlightColor, disabled button can't be pressed
      // splashColor, disabled button doesn't splash
      expect(raw.elevation, 2.0);
      expect(raw.highlightElevation, 8.0);
      expect(raw.disabledElevation, 0.0);
      expect(raw.constraints, defaultButtonConstraints);
      expect(raw.padding, defaultButtonPadding);
      expect(raw.shape, defaultButtonShape);
      expect(raw.animationDuration, defaultButtonDuration);
      expect(raw.materialTapTargetSize, MaterialTapTargetSize.padded);
    });
  });

  group('FlatButton', () {
    testWidgets('theme: ThemeData.light(), enabled: true', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Center(
            child: FlatButton(
              onPressed: () { }, // button.enabled == true
              child: const Text('button'),
            ),
          ),
        ),
      );

      final RawMaterialButton raw = tester.widget<RawMaterialButton>(find.byType(RawMaterialButton));
      expect(raw.textStyle!.color, const Color(0xdd000000));
      expect(raw.fillColor, null);
      expect(raw.highlightColor, const Color(0x29000000)); // Was Color(0x66bcbcbc)
      expect(raw.splashColor, const Color(0x1f000000)); // Was Color(0x66c8c8c8)
      expect(raw.elevation, 0.0);
      expect(raw.highlightElevation, 0.0);
      expect(raw.disabledElevation, 0.0);
      expect(raw.constraints, defaultButtonConstraints);
      expect(raw.padding, defaultButtonPadding);
      expect(raw.shape, defaultButtonShape);
      expect(raw.animationDuration, defaultButtonDuration);
      expect(raw.materialTapTargetSize, MaterialTapTargetSize.padded);
    });

    testWidgets('theme: ThemeData.light(), enabled: false', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Center(
            child: FlatButton(
              onPressed: null, // button.enabled == false
              child: Text('button'),
            ),
          ),
        ),
      );

      final RawMaterialButton raw = tester.widget<RawMaterialButton>(find.byType(RawMaterialButton));
      expect(raw.textStyle!.color, const Color(0x61000000));
      expect(raw.fillColor, null);
      // highlightColor, disabled button can't be pressed
      // splashColor, disabled button doesn't splash
      expect(raw.elevation, 0.0);
      expect(raw.highlightElevation, 0.0);
      expect(raw.disabledElevation, 0.0);
      expect(raw.constraints, defaultButtonConstraints);
      expect(raw.padding, defaultButtonPadding);
      expect(raw.shape, defaultButtonShape);
      expect(raw.animationDuration, const Duration(milliseconds: 200));
      expect(raw.materialTapTargetSize, MaterialTapTargetSize.padded);
    });
  });

  group('OutlineButton', () {
    testWidgets('theme: ThemeData.light(), enabled: true, highlightElevation: 2.0', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Center(
            child: OutlineButton(
              onPressed: () { }, // button.enabled == true
              // Causes the button to be filled with the theme's canvasColor
              // instead of Colors.transparent before the button material's
              // elevation is animated to 2.0.
              highlightElevation: 2.0,
              child: const Text('button'),
            ),
          ),
        ),
      );

      final RawMaterialButton raw = tester.widget<RawMaterialButton>(find.byType(RawMaterialButton));
      expect(raw.textStyle!.color, const Color(0xdd000000));
      expect(raw.fillColor, const Color(0x00fafafa));
      expect(raw.highlightColor, const Color(0x29000000)); // Was Color(0x66bcbcbc)
      expect(raw.splashColor, const Color(0x1f000000)); // Was Color(0x66c8c8c8)
      expect(raw.elevation, 0.0);
      expect(raw.highlightElevation, 0.0);
      expect(raw.disabledElevation, 0.0);
      expect(raw.constraints, defaultButtonConstraints);
      expect(raw.padding, defaultButtonPadding);
      // animationDuration can't be configured by the theme/constructor
      expect(raw.materialTapTargetSize, MaterialTapTargetSize.padded);
    });

    testWidgets('theme: ThemeData.light(), enabled: true', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Center(
            child: OutlineButton(
              onPressed: () { }, // button.enabled == true
              child: const Text('button'),
            ),
          ),
        ),
      );

      final RawMaterialButton raw = tester.widget<RawMaterialButton>(find.byType(RawMaterialButton));
      expect(raw.textStyle!.color, const Color(0xdd000000));
      expect(raw.fillColor, Colors.transparent);
      expect(raw.highlightColor, const Color(0x29000000)); // Was Color(0x66bcbcbc)
      expect(raw.splashColor, const Color(0x1f000000)); // Was Color(0x66c8c8c8)
      expect(raw.elevation, 0.0);
      expect(raw.highlightElevation, 0.0);
      expect(raw.disabledElevation, 0.0);
      expect(raw.constraints, defaultButtonConstraints);
      expect(raw.padding, defaultButtonPadding);
      // animationDuration can't be configured by the theme/constructor
      expect(raw.materialTapTargetSize, MaterialTapTargetSize.padded);
    });

    testWidgets('theme: ThemeData.light(), enabled: false', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Center(
            child: OutlineButton(
              onPressed: null, // button.enabled == false
              child: Text('button'),
            ),
          ),
        ),
      );

      final RawMaterialButton raw = tester.widget<RawMaterialButton>(find.byType(RawMaterialButton));
      expect(raw.textStyle!.color, const Color(0x61000000));
      expect(raw.fillColor, const Color(0x00000000));
      // highlightColor, disabled button can't be pressed
      // splashColor, disabled button doesn't splash
      expect(raw.elevation, 0.0);
      expect(raw.highlightElevation, 0.0);
      expect(raw.disabledElevation, 0.0);
      expect(raw.constraints, defaultButtonConstraints);
      expect(raw.padding, defaultButtonPadding);
      // animationDuration can't be configured by the theme/constructor
      expect(raw.materialTapTargetSize, MaterialTapTargetSize.padded);
    });
  });

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
