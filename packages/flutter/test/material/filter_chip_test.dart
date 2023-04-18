// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

/// Adds the basic requirements for a Chip.
Widget wrapForChip({
  required final Widget child,
  final TextDirection textDirection = TextDirection.ltr,
  final double textScaleFactor = 1.0,
  final Brightness brightness = Brightness.light,
}) {
  return MaterialApp(
    theme: ThemeData(brightness: brightness),
    home: Directionality(
      textDirection: textDirection,
      child: MediaQuery(
        data: MediaQueryData(textScaleFactor: textScaleFactor),
        child: Material(child: child),
      ),
    ),
  );
}

Future<void> pumpCheckmarkChip(
  final WidgetTester tester, {
  required final Widget chip,
  final Color? themeColor,
  final Brightness brightness = Brightness.light,
}) async {
  await tester.pumpWidget(
    wrapForChip(
      brightness: brightness,
      child: Builder(
        builder: (final BuildContext context) {
          final ChipThemeData chipTheme = ChipTheme.of(context);
          return ChipTheme(
            data: themeColor == null ? chipTheme : chipTheme.copyWith(
              checkmarkColor: themeColor,
            ),
            child: chip,
          );
        },
      ),
    ),
  );
}

Widget selectedFilterChip({ final Color? checkmarkColor }) {
  return FilterChip(
    label: const Text('InputChip'),
    selected: true,
    showCheckmark: true,
    checkmarkColor: checkmarkColor,
    onSelected: (final bool _) { },
  );
}

void expectCheckmarkColor(final Finder finder, final Color color) {
  expect(
    finder,
    paints
      // Physical model path
      ..path()
      // The first layer that is painted is the selection overlay. We do not care
      // how it is painted but it has to be added it to this pattern so that the
      // check mark can be checked next.
      ..rrect()
      // The second layer that is painted is the check mark.
      ..path(color: color),
  );
}

void checkChipMaterialClipBehavior(final WidgetTester tester, final Clip clipBehavior) {
  final Iterable<Material> materials = tester.widgetList<Material>(find.byType(Material));
  // There should be two Material widgets, first Material is from the "_wrapForChip" and
  // last Material is from the "RawChip".
  expect(materials.length, 2);
  // The last Material from `RawChip` should have the clip behavior.
  expect(materials.last.clipBehavior, clipBehavior);
}

void main() {
  testWidgets('FilterChip can be tapped', (final WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: FilterChip(
            onSelected: (final bool valueChanged) { },
            label: const Text('filter chip'),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(FilterChip));
    expect(tester.takeException(), null);
  });

  testWidgets('Filter chip check mark color is determined by platform brightness when light', (final WidgetTester tester) async {
    await pumpCheckmarkChip(
      tester,
      chip: selectedFilterChip(),
    );

    expectCheckmarkColor(
      find.byType(FilterChip),
      Colors.black.withAlpha(0xde),
    );
  });

  testWidgets('Filter chip check mark color is determined by platform brightness when dark', (final WidgetTester tester) async {
    await pumpCheckmarkChip(
      tester,
      chip: selectedFilterChip(),
      brightness: Brightness.dark,
    );

    expectCheckmarkColor(
      find.byType(FilterChip),
      Colors.white.withAlpha(0xde),
    );
  });

  testWidgets('Filter chip check mark color can be set by the chip theme', (final WidgetTester tester) async {
    await pumpCheckmarkChip(
      tester,
      chip: selectedFilterChip(),
      themeColor: const Color(0xff00ff00),
    );

    expectCheckmarkColor(
      find.byType(FilterChip),
      const Color(0xff00ff00),
    );
  });

  testWidgets('Filter chip check mark color can be set by the chip constructor', (final WidgetTester tester) async {
    await pumpCheckmarkChip(
      tester,
      chip: selectedFilterChip(checkmarkColor: const Color(0xff00ff00)),
    );

    expectCheckmarkColor(
      find.byType(FilterChip),
      const Color(0xff00ff00),
    );
  });

  testWidgets('Filter chip check mark color is set by chip constructor even when a theme color is specified', (final WidgetTester tester) async {
    await pumpCheckmarkChip(
      tester,
      chip: selectedFilterChip(checkmarkColor: const Color(0xffff0000)),
      themeColor: const Color(0xff00ff00),
    );

    expectCheckmarkColor(
      find.byType(FilterChip),
      const Color(0xffff0000),
    );
  });

  testWidgets('FilterChip clipBehavior properly passes through to the Material', (final WidgetTester tester) async {
    const Text label = Text('label');
    await tester.pumpWidget(wrapForChip(child: FilterChip(label: label, onSelected: (final bool b) { })));
    checkChipMaterialClipBehavior(tester, Clip.none);

    await tester.pumpWidget(wrapForChip(child: FilterChip(label: label, onSelected: (final bool b) { }, clipBehavior: Clip.antiAlias)));
    checkChipMaterialClipBehavior(tester, Clip.antiAlias);
  });

  testWidgets('M3 width should not change with selection', (final WidgetTester tester) async {
    // Regression tests for: https://github.com/flutter/flutter/issues/110645

    // For the text "FilterChip" the chip should default to 175 regardless of selection.
    const int expectedWidth = 175;

    // Unselected
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: Material(
        child: Center(
          child: FilterChip(
            label: const Text('FilterChip'),
            showCheckmark: false,
            onSelected: (final bool _) {},
         )
        ),
      ),
    ));
    expect(tester.getSize(find.byType(FilterChip)).width, expectedWidth);

    // Selected
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: Material(
        child: Center(
            child: FilterChip(
              label: const Text('FilterChip'),
              showCheckmark: false,
              selected: true,
              onSelected: (final bool _) {},
            )
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(FilterChip)).width, expectedWidth);
  });
}
