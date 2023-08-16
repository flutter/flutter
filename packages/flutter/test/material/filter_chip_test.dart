// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

/// Adds the basic requirements for a Chip.
Widget wrapForChip({
  required Widget child,
  TextDirection textDirection = TextDirection.ltr,
  double textScaleFactor = 1.0,
  Brightness brightness = Brightness.light,
  bool? useMaterial3,
}) {
  return MaterialApp(
    theme: ThemeData(brightness: brightness, useMaterial3: useMaterial3),
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
  WidgetTester tester, {
  required Widget chip,
  Color? themeColor,
  Brightness brightness = Brightness.light,
  ThemeData? theme,
}) async {
  await tester.pumpWidget(
    wrapForChip(
      useMaterial3: false,
      brightness: brightness,
      child: Builder(
        builder: (BuildContext context) {
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

Widget selectedFilterChip({ Color? checkmarkColor }) {
  return FilterChip(
    label: const Text('InputChip'),
    selected: true,
    showCheckmark: true,
    checkmarkColor: checkmarkColor,
    onSelected: (bool _) { },
  );
}

void expectCheckmarkColor(Finder finder, Color color) {
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

RenderBox getMaterialBox(WidgetTester tester, Finder type) {
  return tester.firstRenderObject<RenderBox>(
    find.descendant(
      of: type,
      matching: find.byType(CustomPaint),
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

Material getMaterial(WidgetTester tester) {
  return tester.widget<Material>(
    find.descendant(
      of: find.byType(FilterChip),
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

void main() {
  testWidgetsWithLeakTracking('FilterChip defaults', (WidgetTester tester) async {
    final ThemeData theme = ThemeData(useMaterial3: true);
    const String label = 'filter chip';

    // Test enabled FilterChip defaults.
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Material(
          child: Center(
            child: FilterChip(
              onSelected: (bool valueChanged) { },
              label: const Text(label),
            ),
          ),
        ),
      ),
    );

    // Test default chip size.
    expect(
      tester.getSize(find.byType(FilterChip)),
      within(distance: 0.001, from: const Size(189.1, 48.0)),
    );
    // Test default label style.
    expect(
      getLabelStyle(tester, label).style.color!.value,
      theme.textTheme.labelLarge!.color!.value,
    );

    Material chipMaterial = getMaterial(tester);
    expect(chipMaterial.elevation, 0);
    expect(chipMaterial.shadowColor, Colors.transparent);
    expect(chipMaterial.surfaceTintColor, theme.colorScheme.surfaceTint);
    expect(
      chipMaterial.shape,
      RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(8.0)),
        side: BorderSide(color: theme.colorScheme.outline),
      ),
    );

    ShapeDecoration decoration = tester.widget<Ink>(find.byType(Ink)).decoration! as ShapeDecoration;
    expect(decoration.color, null);

    // Test disabled FilterChip defaults.
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Material(
          child: FilterChip(
            onSelected: null,
            label: Text(label),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    chipMaterial = getMaterial(tester);
    expect(chipMaterial.elevation, 0);
    expect(chipMaterial.shadowColor, Colors.transparent);
    expect(chipMaterial.surfaceTintColor, theme.colorScheme.surfaceTint);
    expect(
      chipMaterial.shape,
      RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(8.0)),
        side: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.12)),
      ),
    );

    decoration = tester.widget<Ink>(find.byType(Ink)).decoration! as ShapeDecoration;
    expect(decoration.color, null);

    // Test selected enabled FilterChip defaults.
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Material(
          child: FilterChip(
            selected: true,
            onSelected: (bool valueChanged) { },
            label: const Text(label),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    chipMaterial = getMaterial(tester);
    expect(chipMaterial.elevation, 0);
    expect(chipMaterial.shadowColor, null);
    expect(chipMaterial.surfaceTintColor, theme.colorScheme.surfaceTint);
    expect(
      chipMaterial.shape,
      const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
        side: BorderSide(color: Colors.transparent),
      ),
    );

    decoration = tester.widget<Ink>(find.byType(Ink)).decoration! as ShapeDecoration;
    expect(decoration.color, theme.colorScheme.secondaryContainer);

    // Test selected disabled FilterChip defaults.
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Material(
          child: FilterChip(
            selected: true,
            onSelected: null,
            label: Text(label),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    chipMaterial = getMaterial(tester);
    expect(chipMaterial.elevation, 0);
    expect(chipMaterial.shadowColor, null);
    expect(chipMaterial.surfaceTintColor, theme.colorScheme.surfaceTint);
    expect(
      chipMaterial.shape,
      const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
        side: BorderSide(color: Colors.transparent),
      ),
    );

    decoration = tester.widget<Ink>(find.byType(Ink)).decoration! as ShapeDecoration;
    expect(decoration.color, theme.colorScheme.onSurface.withOpacity(0.12));
  });

  testWidgetsWithLeakTracking('FilterChip.elevated defaults', (WidgetTester tester) async {
    final ThemeData theme = ThemeData(useMaterial3: true);
    const String label = 'filter chip';

    // Test enabled FilterChip.elevated defaults.
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Material(
          child: Center(
            child: FilterChip.elevated(
              onSelected: (bool valueChanged) { },
              label: const Text(label),
            ),
          ),
        ),
      ),
    );

    // Test default chip size.
    expect(
      tester.getSize(find.byType(FilterChip)),
      within(distance: 0.001, from: const Size(189.1, 48.0)),
    );
    // Test default label style.
    expect(
      getLabelStyle(tester, 'filter chip').style.color!.value,
      theme.textTheme.labelLarge!.color!.value,
    );

    Material chipMaterial = getMaterial(tester);
    expect(chipMaterial.elevation, 1);
    expect(chipMaterial.shadowColor, theme.colorScheme.shadow);
    expect(chipMaterial.surfaceTintColor, theme.colorScheme.surfaceTint);
    expect(
      chipMaterial.shape,
      const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
        side: BorderSide(color: Colors.transparent),
      ),
    );

    ShapeDecoration decoration = tester.widget<Ink>(find.byType(Ink)).decoration! as ShapeDecoration;
    expect(decoration.color, null);

    // Test disabled FilterChip.elevated defaults.
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Material(
          child: FilterChip.elevated(
            onSelected: null,
            label: Text(label),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    chipMaterial = getMaterial(tester);
    expect(chipMaterial.elevation, 0);
    expect(chipMaterial.shadowColor, theme.colorScheme.shadow);
    expect(chipMaterial.surfaceTintColor, theme.colorScheme.surfaceTint);
    expect(
      chipMaterial.shape,
      const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
        side: BorderSide(color: Colors.transparent),
      ),
    );

    decoration = tester.widget<Ink>(find.byType(Ink)).decoration! as ShapeDecoration;
    expect(decoration.color, theme.colorScheme.onSurface.withOpacity(0.12));

    // Test selected enabled FilterChip.elevated defaults.
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Material(
          child: FilterChip.elevated(
            selected: true,
            onSelected: (bool valueChanged) { },
            label: const Text(label),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    chipMaterial = getMaterial(tester);
    expect(chipMaterial.elevation, 1);
    expect(chipMaterial.shadowColor, null);
    expect(chipMaterial.surfaceTintColor, theme.colorScheme.surfaceTint);
    expect(
      chipMaterial.shape,
      const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
        side: BorderSide(color: Colors.transparent),
      ),
    );

    decoration = tester.widget<Ink>(find.byType(Ink)).decoration! as ShapeDecoration;
    expect(decoration.color, theme.colorScheme.secondaryContainer);

    // Test selected disabled FilterChip.elevated defaults.
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Material(
          child: FilterChip.elevated(
            selected: true,
            onSelected: null,
            label: Text(label),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    chipMaterial = getMaterial(tester);
    expect(chipMaterial.elevation, 0);
    expect(chipMaterial.shadowColor, null);
    expect(chipMaterial.surfaceTintColor, theme.colorScheme.surfaceTint);
    expect(
      chipMaterial.shape,
      const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
        side: BorderSide(color: Colors.transparent),
      ),
    );

    decoration = tester.widget<Ink>(find.byType(Ink)).decoration! as ShapeDecoration;
    expect(decoration.color, theme.colorScheme.onSurface.withOpacity(0.12));
  });

  testWidgetsWithLeakTracking('FilterChip.color resolves material states', (WidgetTester tester) async {
    const Color disabledSelectedColor = Color(0xffffff00);
    const Color disabledColor = Color(0xff00ff00);
    const Color backgroundColor = Color(0xff0000ff);
    const Color selectedColor = Color(0xffff0000);
    final MaterialStateProperty<Color?> color = MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.disabled) && states.contains(MaterialState.selected)) {
        return disabledSelectedColor;
      }
      if (states.contains(MaterialState.disabled)) {
        return disabledColor;
      }
      if (states.contains(MaterialState.selected)) {
        return selectedColor;
      }
      return backgroundColor;
    });
    Widget buildApp({ required bool enabled, required bool selected }) {
      return wrapForChip(
        useMaterial3: true,
        child: Column(
          children: <Widget>[
            FilterChip(
              onSelected: enabled ? (bool value) { } : null,
              selected: selected,
              color: color,
              label: const Text('FilterChip'),
            ),
            FilterChip.elevated(
              onSelected: enabled ? (bool value) { } : null,
              selected: selected,
              color: color,
              label: const Text('FilterChip.elevated'),
            ),
          ],
        ),
      );
    }

    // Test enabled state.
    await tester.pumpWidget(buildApp(enabled: true, selected: false));

    // Enabled FilterChip should have the provided backgroundColor.
    expect(
      getMaterialBox(tester, find.byType(RawChip).first),
      paints..rrect(color: backgroundColor),
    );
    // Enabled elevated FilterChip should have the provided backgroundColor.
    expect(
      getMaterialBox(tester, find.byType(RawChip).last),
      paints..rrect(color: backgroundColor),
    );

    // Test disabled state.
    await tester.pumpWidget(buildApp(enabled: false, selected: false));
    await tester.pumpAndSettle();

    // Disabled FilterChip should have the provided disabledColor.
    expect(
      getMaterialBox(tester, find.byType(RawChip).first),
      paints..rrect(color: disabledColor),
    );
    // Disabled elevated FilterChip should have the provided disabledColor.
    expect(
      getMaterialBox(tester, find.byType(RawChip).last),
      paints..rrect(color: disabledColor),
    );

    // Test enabled & selected state.
    await tester.pumpWidget(buildApp(enabled: true, selected: true));
    await tester.pumpAndSettle();

    // Enabled & selected FilterChip should have the provided selectedColor.
    expect(
      getMaterialBox(tester, find.byType(RawChip).first),
      paints..rrect(color: selectedColor),
    );
    // Enabled & selected elevated FilterChip should have the provided selectedColor.
    expect(
      getMaterialBox(tester, find.byType(RawChip).last),
      paints..rrect(color: selectedColor),
    );

    // Test disabled & selected state.
    await tester.pumpWidget(buildApp(enabled: false, selected: true));
    await tester.pumpAndSettle();

    // Disabled & selected FilterChip should have the provided disabledSelectedColor.
    expect(
      getMaterialBox(tester, find.byType(RawChip).first),
      paints..rrect(color: disabledSelectedColor),
    );
    // Disabled & selected elevated FilterChip should have the
    // provided disabledSelectedColor.
    expect(
      getMaterialBox(tester, find.byType(RawChip).last),
      paints..rrect(color: disabledSelectedColor),
    );
  });

  testWidgetsWithLeakTracking('FilterChip uses provided state color properties', (WidgetTester tester) async {
    const Color disabledColor = Color(0xff00ff00);
    const Color backgroundColor = Color(0xff0000ff);
    const Color selectedColor = Color(0xffff0000);
    Widget buildApp({ required bool enabled, required bool selected }) {
      return wrapForChip(
        useMaterial3: true,
        child: Column(
          children: <Widget>[
            FilterChip(
              onSelected: enabled ? (bool value) { } : null,
              selected: selected,
              disabledColor: disabledColor,
              backgroundColor: backgroundColor,
              selectedColor: selectedColor,
              label: const Text('FilterChip'),
            ),
            FilterChip.elevated(
              onSelected: enabled ? (bool value) { } : null,
              selected: selected,
              disabledColor: disabledColor,
              backgroundColor: backgroundColor,
              selectedColor: selectedColor,
              label: const Text('FilterChip.elevated'),
            ),
          ],
        ),
      );
    }

    // Test enabled state.
    await tester.pumpWidget(buildApp(enabled: true, selected: false));

    // Enabled FilterChip should have the provided backgroundColor.
    expect(
      getMaterialBox(tester, find.byType(RawChip).first),
      paints..rrect(color: backgroundColor),
    );
    // Enabled elevated FilterChip should have the provided backgroundColor.
    expect(
      getMaterialBox(tester, find.byType(RawChip).last),
      paints..rrect(color: backgroundColor),
    );

    // Test disabled state.
    await tester.pumpWidget(buildApp(enabled: false, selected: false));
    await tester.pumpAndSettle();

    // Disabled FilterChip should have the provided disabledColor.
    expect(
      getMaterialBox(tester, find.byType(RawChip).first),
      paints..rrect(color: disabledColor),
    );
    // Disabled elevated FilterChip should have the provided disabledColor.
    expect(
      getMaterialBox(tester, find.byType(RawChip).last),
      paints..rrect(color: disabledColor),
    );

    // Test enabled & selected state.
    await tester.pumpWidget(buildApp(enabled: true, selected: true));
    await tester.pumpAndSettle();

    // Enabled & selected FilterChip should have the provided selectedColor.
    expect(
      getMaterialBox(tester, find.byType(RawChip).first),
      paints..rrect(color: selectedColor),
    );
    // Enabled & selected elevated FilterChip should have the provided selectedColor.
    expect(
      getMaterialBox(tester, find.byType(RawChip).last),
      paints..rrect(color: selectedColor),
    );
  });

  testWidgetsWithLeakTracking('FilterChip can be tapped', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: FilterChip(
            onSelected: (bool valueChanged) { },
            label: const Text('filter chip'),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(FilterChip));
    expect(tester.takeException(), null);
  });

  testWidgetsWithLeakTracking('Filter chip check mark color is determined by platform brightness when light', (WidgetTester tester) async {
    await pumpCheckmarkChip(
      theme: ThemeData(useMaterial3: false),
      tester,
      chip: selectedFilterChip(),
    );

    expectCheckmarkColor(
      find.byType(FilterChip),
      Colors.black.withAlpha(0xde),
    );
  });

  testWidgetsWithLeakTracking('Filter chip check mark color is determined by platform brightness when dark', (WidgetTester tester) async {
    await pumpCheckmarkChip(
      tester,
      chip: selectedFilterChip(),
      brightness: Brightness.dark,
      theme: ThemeData(useMaterial3: false),
    );

    expectCheckmarkColor(
      find.byType(FilterChip),
      Colors.white.withAlpha(0xde),
    );
  });

  testWidgetsWithLeakTracking('Filter chip check mark color can be set by the chip theme', (WidgetTester tester) async {
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

  testWidgetsWithLeakTracking('Filter chip check mark color can be set by the chip constructor', (WidgetTester tester) async {
    await pumpCheckmarkChip(
      tester,
      chip: selectedFilterChip(checkmarkColor: const Color(0xff00ff00)),
    );

    expectCheckmarkColor(
      find.byType(FilterChip),
      const Color(0xff00ff00),
    );
  });

  testWidgetsWithLeakTracking('Filter chip check mark color is set by chip constructor even when a theme color is specified', (WidgetTester tester) async {
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

  testWidgetsWithLeakTracking('FilterChip clipBehavior properly passes through to the Material', (WidgetTester tester) async {
    const Text label = Text('label');
    await tester.pumpWidget(wrapForChip(child: FilterChip(label: label, onSelected: (bool b) { })));
    checkChipMaterialClipBehavior(tester, Clip.none);

    await tester.pumpWidget(wrapForChip(child: FilterChip(label: label, onSelected: (bool b) { }, clipBehavior: Clip.antiAlias)));
    checkChipMaterialClipBehavior(tester, Clip.antiAlias);
  });

  testWidgetsWithLeakTracking('M3 width should not change with selection', (WidgetTester tester) async {
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
            onSelected: (bool _) {},
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
              onSelected: (bool _) {},
            )
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(FilterChip)).width, expectedWidth);
  });
}
