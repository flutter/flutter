// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

void main() {
  test('CheckboxThemeData copyWith, ==, hashCode basics', () {
    expect(const CheckboxThemeData(), const CheckboxThemeData().copyWith());
    expect(const CheckboxThemeData().hashCode, const CheckboxThemeData().copyWith().hashCode);
  });

  test('CheckboxThemeData defaults', () {
    const CheckboxThemeData themeData = CheckboxThemeData();
    expect(themeData.mouseCursor, null);
    expect(themeData.fillColor, null);
    expect(themeData.checkColor, null);
    expect(themeData.focusColor, null);
    expect(themeData.hoverColor, null);
    expect(themeData.splashRadius, null);
    expect(themeData.materialTapTargetSize, null);
    expect(themeData.visualDensity, null);

    const CheckboxTheme theme = CheckboxTheme(data: CheckboxThemeData(), child: SizedBox());
    expect(theme.data.mouseCursor, null);
    expect(theme.data.fillColor, null);
    expect(theme.data.checkColor, null);
    expect(theme.data.focusColor, null);
    expect(theme.data.hoverColor, null);
    expect(theme.data.splashRadius, null);
    expect(theme.data.materialTapTargetSize, null);
    expect(theme.data.visualDensity, null);
  });

  testWidgets('Default CheckboxThemeData debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const CheckboxThemeData().debugFillProperties(builder);

    final List<String> description = builder.properties
      .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
      .map((DiagnosticsNode node) => node.toString())
      .toList();

    expect(description, <String>[]);
  });

  testWidgets('CheckboxThemeData implements debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    CheckboxThemeData(
      mouseCursor: MouseCursor.defer,
      fillColor: MaterialStateProperty.all(const Color(0xfffffff0)),
      checkColor: const Color(0xfffffff1),
      focusColor: const Color(0xfffffff2),
      hoverColor: const Color(0xfffffff2),
      splashRadius: 1.0,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.standard,
    ).debugFillProperties(builder);

    final List<String> description = builder.properties
      .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
      .map((DiagnosticsNode node) => node.toString())
      .toList();

    expect(description[0], 'mouseCursor: defer');
    expect(description[1], 'fillColor: MaterialStateProperty.all(Color(0xfffffff0))');
    expect(description[2], 'checkColor: Color(0xfffffff1)');
    expect(description[3], 'focusColor: Color(0xfffffff2)');
    expect(description[4], 'hoverColor: Color(0xfffffff2)');
    expect(description[5], 'splashRadius: 1.0');
    expect(description[6], 'materialTapTargetSize: MaterialTapTargetSize.shrinkWrap');
    expect(description[7], 'visualDensity: VisualDensity#00000(h: 0.0, v: 0.0)');
  });

  testWidgets('Checkbox is themeable', (WidgetTester tester) async {
    tester.binding.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;

    const MouseCursor mouseCursor = SystemMouseCursors.text;
    const Color defaultFillColor = Color(0xfffffff0);
    const Color selectedFillColor = Color(0xfffffff1);
    const Color checkColor = Color(0xfffffff2);
    const Color focusColor = Color(0xfffffff3);
    const Color hoverColor = Color(0xfffffff4);
    const double splashRadius = 1.0;
    const MaterialTapTargetSize materialTapTargetSize = MaterialTapTargetSize.shrinkWrap;
    const VisualDensity visualDensity = VisualDensity(vertical: 1.0, horizontal: 1.0);

    Widget buildCheckbox({bool selected = false, bool autofocus = false}) {
      return MaterialApp(
        theme: ThemeData(
          checkboxTheme: CheckboxThemeData(
            mouseCursor: mouseCursor,
            fillColor: MaterialStateProperty.resolveWith((Set<MaterialState> states) {
              if (states.contains(MaterialState.selected)) {
                return selectedFillColor;
              }
              return defaultFillColor;
            }),
            checkColor: checkColor,
            focusColor: focusColor,
            hoverColor: hoverColor,
            splashRadius: splashRadius,
            materialTapTargetSize: materialTapTargetSize,
            visualDensity: visualDensity,
          ),
        ),
        home: Scaffold(
          body: Checkbox(
            onChanged: (bool? value) {},
            value: selected,
            autofocus: autofocus,
          ),
        ),
      );
    }

    // Checkbox.
    await tester.pumpWidget(buildCheckbox());
    await tester.pumpAndSettle();
    expect(_getCheckboxMaterial(tester), paints..drrect(color: defaultFillColor));
    // Size from MaterialTapTargetSize.shrinkWrap with added VisualDensity.
    expect(tester.getSize(find.byType(Checkbox)), const Size(40.0, 40.0) + visualDensity.baseSizeAdjustment);

    // Selected checkbox.
    await tester.pumpWidget(buildCheckbox(selected: true));
    await tester.pumpAndSettle();
    expect(_getCheckboxMaterial(tester), paints..rrect(color: selectedFillColor));
    expect(_getCheckboxMaterial(tester), paints..path(color: checkColor));

    // Checkbox with hover.
    await tester.pumpWidget(buildCheckbox());
    await _pointGestureToCheckbox(tester);
    await tester.pumpAndSettle();
    expect(RendererBinding.instance!.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.text);
    expect(_getCheckboxMaterial(tester), paints..circle(color: hoverColor));

    // Checkbox with focus.
    await tester.pumpWidget(buildCheckbox(autofocus: true));
    await tester.pumpAndSettle();
    expect(_getCheckboxMaterial(tester), paints..circle(color: focusColor, radius: splashRadius));
  });

  testWidgets('Checkbox properties are taken over the theme values', (WidgetTester tester) async {
    tester.binding.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;

    const MouseCursor themeMouseCursor = SystemMouseCursors.click;
    const Color themeDefaultFillColor = Color(0xfffffff0);
    const Color themeSelectedFillColor = Color(0xfffffff1);
    const Color themeCheckColor = Color(0xfffffff2);
    const Color themeFocusColor = Color(0xfffffff3);
    const Color themeHoverColor = Color(0xfffffff4);
    const double themeSplashRadius = 1.0;
    const MaterialTapTargetSize themeMaterialTapTargetSize = MaterialTapTargetSize.padded;
    const VisualDensity themeVisualDensity = VisualDensity.standard;

    const MouseCursor mouseCursor = SystemMouseCursors.text;
    const Color defaultFillColor = Color(0xfffffff5);
    const Color selectedFillColor = Color(0xfffffff6);
    const Color checkColor = Color(0xfffffff7);
    const Color focusColor = Color(0xfffffff8);
    const Color hoverColor = Color(0xfffffff9);
    const double splashRadius = 2.0;
    const MaterialTapTargetSize materialTapTargetSize = MaterialTapTargetSize.shrinkWrap;
    const VisualDensity visualDensity = VisualDensity.standard;

    Widget buildCheckbox({bool selected = false, bool autofocus = false}) {
        return MaterialApp(
          theme: ThemeData(
            checkboxTheme: CheckboxThemeData(
              mouseCursor: themeMouseCursor,
              fillColor: MaterialStateProperty.resolveWith((Set<MaterialState> states) {
                if (states.contains(MaterialState.selected)) {
                  return themeSelectedFillColor;
                }
                return themeDefaultFillColor;
              }),
              checkColor: themeCheckColor,
              focusColor: themeFocusColor,
              hoverColor: themeHoverColor,
              splashRadius: themeSplashRadius,
              materialTapTargetSize: themeMaterialTapTargetSize,
              visualDensity: themeVisualDensity,
            ),
          ),
          home: Scaffold(
            body: Checkbox(
              onChanged: (bool? value) { },
              value: selected,
              autofocus: autofocus,
              mouseCursor: mouseCursor,
              fillColor: MaterialStateProperty.resolveWith((Set<MaterialState> states) {
                if (states.contains(MaterialState.selected)) {
                  return selectedFillColor;
                }
                return defaultFillColor;
              }),
              checkColor: checkColor,
              focusColor: focusColor,
              hoverColor: hoverColor,
              splashRadius: splashRadius,
              materialTapTargetSize: materialTapTargetSize,
              visualDensity: visualDensity,
            ),
          ),
        );
    }

    // Checkbox.
    await tester.pumpWidget(buildCheckbox());
    await tester.pumpAndSettle();
    expect(_getCheckboxMaterial(tester), paints..drrect(color: defaultFillColor));
    // Size from MaterialTapTargetSize.shrinkWrap with added VisualDensity.
    expect(tester.getSize(find.byType(Checkbox)), const Size(40.0, 40.0) + visualDensity.baseSizeAdjustment);

    // Selected checkbox.
    await tester.pumpWidget(buildCheckbox(selected: true));
    await tester.pumpAndSettle();
    expect(_getCheckboxMaterial(tester), paints..rrect(color: selectedFillColor));
    expect(_getCheckboxMaterial(tester), paints..path(color: checkColor));

    // Checkbox with hover.
    await tester.pumpWidget(buildCheckbox());
    await _pointGestureToCheckbox(tester);
    await tester.pumpAndSettle();
    expect(RendererBinding.instance!.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.text);
    expect(_getCheckboxMaterial(tester), paints..circle(color: hoverColor));

    // Checkbox with focus.
    await tester.pumpWidget(buildCheckbox(autofocus: true));
    await tester.pumpAndSettle();
    expect(_getCheckboxMaterial(tester), paints..circle(color: focusColor, radius: splashRadius));
  });

  testWidgets('Checkbox activeColor property is taken over the theme', (WidgetTester tester) async {
    const Color themeSelectedFillColor = Color(0xfffffff1);
    const Color themeDefaultFillColor = Color(0xfffffff0);
    const Color selectedFillColor = Color(0xfffffff6);

    Widget buildCheckbox({bool selected = false}) {
        return MaterialApp(
          theme: ThemeData(
            checkboxTheme: CheckboxThemeData(
              fillColor: MaterialStateProperty.resolveWith((Set<MaterialState> states) {
                if (states.contains(MaterialState.selected)) {
                  return themeSelectedFillColor;
                }
                return themeDefaultFillColor;
              }),
            ),
          ),
          home: Scaffold(
            body: Checkbox(
              onChanged: (bool? value) { },
              value: selected,
              activeColor: selectedFillColor,
            ),
          ),
        );
    }

    // Unselected checkbox.
    await tester.pumpWidget(buildCheckbox());
    await tester.pumpAndSettle();
    expect(_getCheckboxMaterial(tester), paints..drrect(color: themeDefaultFillColor));

    // Selected checkbox.
    await tester.pumpWidget(buildCheckbox(selected: true));
    await tester.pumpAndSettle();
    expect(_getCheckboxMaterial(tester), paints..rrect(color: selectedFillColor));
  });
}

Future<void> _pointGestureToCheckbox(WidgetTester tester) async {
  final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer();
  addTearDown(gesture.removePointer);
  await gesture.moveTo(tester.getCenter(find.byType(Checkbox)));
}

MaterialInkController? _getCheckboxMaterial(WidgetTester tester) {
  return Material.of(tester.element(find.byType(Checkbox)));
}
