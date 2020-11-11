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
    expect(themeData.fillColor, null);
    expect(themeData.mouseCursor, null);
    expect(themeData.checkColor, null);
    expect(themeData.materialTapTargetSize, null);
    expect(themeData.visualDensity, null);
    expect(themeData.focusColor, null);
    expect(themeData.hoverColor, null);
    expect(themeData.splashRadius, null);

    const CheckboxTheme theme = CheckboxTheme(data: CheckboxThemeData(), child: SizedBox());
    expect(theme.data.fillColor, null);
    expect(theme.data.mouseCursor, null);
    expect(theme.data.checkColor, null);
    expect(theme.data.materialTapTargetSize, null);
    expect(theme.data.visualDensity, null);
    expect(theme.data.focusColor, null);
    expect(theme.data.hoverColor, null);
    expect(theme.data.splashRadius, null);
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
      fillColor: MaterialStateProperty.all(const Color(0xfffffff0)),
      mouseCursor: MouseCursor.defer,
      checkColor: const Color(0xfffffff1),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.standard,
      focusColor: const Color(0xfffffff2),
      hoverColor: const Color(0xfffffff2),
      splashRadius: 1.0,
    ).debugFillProperties(builder);

    final List<String> description = builder.properties
      .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
      .map((DiagnosticsNode node) => node.toString())
      .toList();

    expect(description[0], 'fillColor: MaterialStateProperty.all(Color(0xfffffff0))');
    expect(description[1], 'mouseCursor: defer');
    expect(description[2], 'checkColor: Color(0xfffffff1)');
    expect(description[3], 'materialTapTargetSize: MaterialTapTargetSize.shrinkWrap');
    expect(description[4], 'visualDensity: VisualDensity#00000(h: 0.0, v: 0.0)');
    expect(description[5], 'focusColor: Color(0xfffffff2)');
    expect(description[6], 'hoverColor: Color(0xfffffff2)');
    expect(description[7], 'splashRadius: 1.0');
  });

  testWidgets('Checkbox is themeable', (WidgetTester tester) async {
    tester.binding.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;

    const Color defaultFillColor = Color(0xfffffff0);
    const Color selectedFillColor = Color(0xfffffff1);
    const MouseCursor mouseCursor = SystemMouseCursors.text;
    const Color checkColor = Color(0xfffffff2);
    const MaterialTapTargetSize materialTapTargetSize = MaterialTapTargetSize.shrinkWrap;
    const VisualDensity visualDensity = VisualDensity(vertical: 1.0, horizontal: 1.0);
    const Color focusColor = Color(0xfffffff3);
    const Color hoverColor = Color(0xfffffff4);
    const double splashRadius = 1.0;

    Widget buildCheckbox({bool selected = false, bool autofocus = false}) {
      return MaterialApp(
        theme: ThemeData(
          checkboxTheme: CheckboxThemeData(
            fillColor: MaterialStateProperty.resolveWith((Set<MaterialState> states) {
              if (states.contains(MaterialState.selected)) {
                return selectedFillColor;
              }
              return defaultFillColor;
            }),
            mouseCursor: mouseCursor,
            checkColor: checkColor,
            materialTapTargetSize: materialTapTargetSize,
            visualDensity: visualDensity,
            focusColor: focusColor,
            hoverColor: hoverColor,
            splashRadius: splashRadius,
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

    const Color themeDefaultFillColor = Color(0xfffffff0);
    const Color themeSelectedFillColor = Color(0xfffffff1);
    const MouseCursor themeMouseCursor = SystemMouseCursors.click;
    const Color themeCheckColor = Color(0xfffffff2);
    const MaterialTapTargetSize themeMaterialTapTargetSize = MaterialTapTargetSize.padded;
    const VisualDensity themeVisualDensity = VisualDensity.standard;
    const Color themeFocusColor = Color(0xfffffff3);
    const Color themeHoverColor = Color(0xfffffff4);
    const double themeSplashRadius = 1.0;

    const Color defaultFillColor = Color(0xfffffff5);
    const Color selectedFillColor = Color(0xfffffff6);
    const MouseCursor mouseCursor = SystemMouseCursors.text;
    const Color checkColor = Color(0xfffffff7);
    const MaterialTapTargetSize materialTapTargetSize = MaterialTapTargetSize.shrinkWrap;
    const VisualDensity visualDensity = VisualDensity.standard;
    const Color focusColor = Color(0xfffffff8);
    const Color hoverColor = Color(0xfffffff9);
    const double splashRadius = 2.0;

    Widget buildCheckbox({bool selected = false, bool autofocus = false}) {
        return MaterialApp(
          theme: ThemeData(
            checkboxTheme: CheckboxThemeData(
            fillColor: MaterialStateProperty.resolveWith((Set<MaterialState> states) {
              if (states.contains(MaterialState.selected)) {
                return themeSelectedFillColor;
              }
              return themeDefaultFillColor;
            }),
              mouseCursor: themeMouseCursor,
              checkColor: themeCheckColor,
              materialTapTargetSize: themeMaterialTapTargetSize,
              visualDensity: themeVisualDensity,
              focusColor: themeFocusColor,
              hoverColor: themeHoverColor,
              splashRadius: themeSplashRadius,
            ),
          ),
          home: Scaffold(
            body: Checkbox(
              onChanged: (bool? value) { },
              value: selected,
              autofocus: autofocus,
              fillColor: MaterialStateProperty.resolveWith((Set<MaterialState> states) {
                if (states.contains(MaterialState.selected)) {
                  return selectedFillColor;
                }
                return defaultFillColor;
              }),
              mouseCursor: mouseCursor,
              checkColor: checkColor,
              materialTapTargetSize: materialTapTargetSize,
              visualDensity: visualDensity,
              focusColor: focusColor,
              hoverColor: hoverColor,
              splashRadius: splashRadius,
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
