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
    const ShapeBorder defaultFABShapeM3 = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16.0)));
    const EdgeInsets defaultFABPadding = EdgeInsets.zero;

    testWidgets('Material2 - theme: ThemeData.light(), enabled: true', (WidgetTester tester) async {
      final ThemeData theme = ThemeData.light(useMaterial3: false);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Center(
              child: FloatingActionButton(
                onPressed: () { }, // button.enabled == true
                child: const Icon(Icons.add),
              ),
          ),
        ),
      );

      final ElevatedButton elevatedButton = tester.widget(find.byType(ElevatedButton));
      final BoxConstraints buttonConstraints = BoxConstraints(
        minWidth: elevatedButton.style!.minimumSize!.resolve(enabled)!.width,
        minHeight: elevatedButton.style!.minimumSize!.resolve(enabled)!.height,
        maxWidth: elevatedButton.style!.maximumSize!.resolve(enabled)!.width,
        maxHeight: elevatedButton.style!.maximumSize!.resolve(enabled)!.height,
      );
      expect(elevatedButton.enabled, true);
      expect(elevatedButton.style!.textStyle!.resolve(enabled)!.color, const Color(0xffffffff));
      expect(elevatedButton.style!.backgroundColor!.resolve(enabled), const Color(0xff2196f3));
      expect(elevatedButton.style!.elevation!.resolve(enabled), 6.0);
      expect(elevatedButton.style!.elevation!.resolve(pressed), 12.0);
      expect(elevatedButton.style!.elevation!.resolve(disabled), 6.0);
      expect(buttonConstraints, defaultFABConstraints);
      expect(elevatedButton.style!.padding!.resolve(enabled), defaultFABPadding);
      expect(elevatedButton.style!.shape!.resolve(enabled), defaultFABShape);
      expect(elevatedButton.style!.animationDuration, defaultButtonDuration);
      expect(elevatedButton.style!.tapTargetSize, MaterialTapTargetSize.padded);
    });

    testWidgets('Material3 - theme: ThemeData.light(), enabled: true', (WidgetTester tester) async {
      final ThemeData theme = ThemeData.light(useMaterial3: true);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Center(
            child: FloatingActionButton(
              onPressed: () { }, // button.enabled == true
              child: const Icon(Icons.add),
            ),
          ),
        ),
      );

      final ElevatedButton elevatedButton = tester.widget(find.byType(ElevatedButton));
      final BoxConstraints buttonConstraints = BoxConstraints(
        minWidth: elevatedButton.style!.minimumSize!.resolve(enabled)!.width,
        minHeight: elevatedButton.style!.minimumSize!.resolve(enabled)!.height,
        maxWidth: elevatedButton.style!.maximumSize!.resolve(enabled)!.width,
        maxHeight: elevatedButton.style!.maximumSize!.resolve(enabled)!.height,
      );
      expect(elevatedButton.enabled, true);
      expect(elevatedButton.style!.textStyle!.resolve(enabled)!.color, theme.colorScheme.onPrimaryContainer);
      expect(elevatedButton.style!.backgroundColor!.resolve(enabled), theme.colorScheme.primaryContainer);
      expect(elevatedButton.style!.elevation!.resolve(enabled), 6.0);
      expect(elevatedButton.style!.elevation!.resolve(pressed), 6.0);
      expect(elevatedButton.style!.elevation!.resolve(disabled), 6.0);
      expect(buttonConstraints, defaultFABConstraints);
      expect(elevatedButton.style!.padding!.resolve(enabled), defaultFABPadding);
      expect(elevatedButton.style!.shape!.resolve(enabled), defaultFABShapeM3);
      expect(elevatedButton.style!.animationDuration, defaultButtonDuration);
      expect(elevatedButton.style!.tapTargetSize, MaterialTapTargetSize.padded);
    });

    testWidgets('Material2 - theme: ThemeData.light(), enabled: false', (WidgetTester tester) async {
      final ThemeData theme = ThemeData.light(useMaterial3: false);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Center(
              child: FloatingActionButton(
                onPressed: null, // button.enabled == false
                child: Icon(Icons.add),
              ),
          ),
        ),
      );

      final ElevatedButton elevatedButton = tester.widget(find.byType(ElevatedButton));
      final BoxConstraints buttonConstraints = BoxConstraints(
        minWidth: elevatedButton.style!.minimumSize!.resolve(enabled)!.width,
        minHeight: elevatedButton.style!.minimumSize!.resolve(enabled)!.height,
        maxWidth: elevatedButton.style!.maximumSize!.resolve(enabled)!.width,
        maxHeight: elevatedButton.style!.maximumSize!.resolve(enabled)!.height,
      );
      expect(elevatedButton.enabled, false);
      expect(elevatedButton.style!.textStyle!.resolve(enabled)!.color, const Color(0xffffffff));
      expect(elevatedButton.style!.backgroundColor!.resolve(enabled), const Color(0xff2196f3));
      // // highlightColor, disabled button can't be pressed
      // // splashColor, disabled button doesn't splash
      expect(elevatedButton.style!.elevation!.resolve(enabled), 6.0);
      expect(elevatedButton.style!.elevation!.resolve(pressed), 12.0);
      expect(elevatedButton.style!.elevation!.resolve(disabled), 6.0);
      expect(buttonConstraints, defaultFABConstraints);
      expect(elevatedButton.style!.padding!.resolve(enabled), defaultFABPadding);
      expect(elevatedButton.style!.shape!.resolve(enabled), defaultFABShape);
      expect(elevatedButton.style!.animationDuration, defaultButtonDuration);
      expect(elevatedButton.style!.tapTargetSize, MaterialTapTargetSize.padded);
    });

    testWidgets('Material3 - theme: ThemeData.light(), enabled: false', (WidgetTester tester) async {
      final ThemeData theme = ThemeData.light(useMaterial3: true);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Center(
            child: FloatingActionButton(
              onPressed: null, // button.enabled == false
              child: Icon(Icons.add),
            ),
          ),
        ),
      );

      final ElevatedButton elevatedButton = tester.widget(find.byType(ElevatedButton));
      final BoxConstraints buttonConstraints = BoxConstraints(
        minWidth: elevatedButton.style!.minimumSize!.resolve(disabled)!.width,
        minHeight: elevatedButton.style!.minimumSize!.resolve(disabled)!.height,
        maxWidth: elevatedButton.style!.maximumSize!.resolve(disabled)!.width,
        maxHeight: elevatedButton.style!.maximumSize!.resolve(disabled)!.height,
      );
      expect(elevatedButton.enabled, false);
      expect(elevatedButton.style!.textStyle!.resolve(disabled)!.color, const Color(0xff21005d));
      expect(elevatedButton.style!.backgroundColor!.resolve(disabled), isNull);
      expect(elevatedButton.style!.elevation!.resolve(disabled), 6.0);
      expect(buttonConstraints, defaultFABConstraints);
      expect(elevatedButton.style!.padding!.resolve(disabled), defaultFABPadding);
      expect(elevatedButton.style!.shape!.resolve(disabled), defaultFABShapeM3);
      expect(elevatedButton.style!.animationDuration, defaultButtonDuration);
      expect(elevatedButton.style!.tapTargetSize, MaterialTapTargetSize.padded);
    });
  });
}

const Set<MaterialState> enabled = <MaterialState>{};
const Set<MaterialState> pressed = <MaterialState>{ MaterialState.pressed };
const Set<MaterialState> disabled = <MaterialState>{ MaterialState.disabled };
