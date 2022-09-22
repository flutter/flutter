// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

RenderBox getMaterialBox(WidgetTester tester) {
  return tester.firstRenderObject<RenderBox>(
    find.descendant(
      of: find.byType(RawChip),
      matching: find.byType(CustomPaint),
    ),
  );
}

Material getMaterial(WidgetTester tester) {
  return tester.widget<Material>(
    find.descendant(
      of: find.byType(RawChip),
      matching: find.byType(Material),
    ),
  );
}

DefaultTextStyle getLabelStyle(WidgetTester tester, String labelText) {
  return tester.widget(
    find.ancestor(
      of: find.text(labelText),
      matching: find.byType(DefaultTextStyle),
    ).first,
  );
}

/// Adds the basic requirements for a Chip.
Widget wrapForChip({
  required Widget child,
  TextDirection textDirection = TextDirection.ltr,
  double textScaleFactor = 1.0,
  Brightness brightness = Brightness.light,
}) {
  return MaterialApp(
    theme: ThemeData(brightness: brightness),
    home: Directionality(
      textDirection: textDirection,
      child: MediaQuery(
        data: MediaQueryData.fromWindow(WidgetsBinding.instance.window).copyWith(textScaleFactor: textScaleFactor),
        child: Material(child: child),
      ),
    ),
  );
}

void checkChipMaterialClipBehavior(WidgetTester tester, Clip clipBehavior) {
  final Iterable<Material> materials = tester.widgetList<Material>(find.byType(Material));
  // There should be two Material widgets, first Material is from the "_wrapForChip" and
  // last Material is from the "RawChip".
  expect(materials.length, 2);
  // The last Material from `RawChip` should have the clip behavior.
  expect(materials.last.clipBehavior, clipBehavior);
}

void main() {
  testWidgets('ChoiceChip defaults', (WidgetTester tester) async {
    Widget buildFrame(Brightness brightness) {
      return MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: const Scaffold(
          body: Center(
            child: ChoiceChip(
              label: Text('Chip A'),
              selected: true,
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildFrame(Brightness.light));
    expect(getMaterialBox(tester), paints..rrect(color: const Color(0x3d000000)));
    expect(tester.getSize(find.byType(ChoiceChip)), const Size(108.0, 48.0));
    expect(getMaterial(tester).color, null);
    expect(getMaterial(tester).elevation, 0);
    expect(getMaterial(tester).shape, const StadiumBorder());
    expect(getLabelStyle(tester, 'Chip A').style.color?.value, 0xde000000);

    await tester.pumpWidget(buildFrame(Brightness.dark));
    await tester.pumpAndSettle(); // Theme transition animation
    expect(getMaterialBox(tester), paints..rrect(color: const Color(0x3dffffff)));
    expect(tester.getSize(find.byType(ChoiceChip)), const Size(108.0, 48.0));
    expect(getMaterial(tester).color, null);
    expect(getMaterial(tester).elevation, 0);
    expect(getMaterial(tester).shape, const StadiumBorder());
    expect(getLabelStyle(tester, 'Chip A').style.color?.value, 0xdeffffff);
  });

  testWidgets('ChoiceChip can be tapped', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: ChoiceChip(
            selected: false,
            label: Text('choice chip'),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ChoiceChip));
    expect(tester.takeException(), null);
  });

  testWidgets('ChoiceChip clipBehavior properly passes through to the Material', (WidgetTester tester) async {
    const Text label = Text('label');
    await tester.pumpWidget(wrapForChip(child: const ChoiceChip(label: label, selected: false)));
    checkChipMaterialClipBehavior(tester, Clip.none);

    await tester.pumpWidget(wrapForChip(child: const ChoiceChip(label: label, selected: false, clipBehavior: Clip.antiAlias)));
    checkChipMaterialClipBehavior(tester, Clip.antiAlias);
  });

  testWidgets('ChoiceChip passes iconTheme property to RawChip', (WidgetTester tester) async {
    const IconThemeData iconTheme = IconThemeData(color: Colors.red);
    await tester.pumpWidget(wrapForChip(
      child: const ChoiceChip(
      label: Text('Test'),
      selected: true,
      iconTheme: iconTheme,
    )));
    final RawChip rawChip = tester.widget(find.byType(RawChip));
    expect(rawChip.iconTheme, iconTheme);
  });
}
