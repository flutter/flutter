// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

void main() {
  test('RadioThemeData copyWith, ==, hashCode basics', () {
    expect(const RadioThemeData(), const RadioThemeData().copyWith());
    expect(const RadioThemeData().hashCode, const RadioThemeData().copyWith().hashCode);
  });

  test('RadioThemeData defaults', () {
    const RadioThemeData themeData = RadioThemeData();
    expect(themeData.fillColor, null);
    expect(themeData.mouseCursor, null);
    expect(themeData.materialTapTargetSize, null);
    expect(themeData.visualDensity, null);
    expect(themeData.focusColor, null);
    expect(themeData.hoverColor, null);
    expect(themeData.splashRadius, null);

    const RadioTheme theme = RadioTheme(data: RadioThemeData(), child: SizedBox());
    expect(theme.data.fillColor, null);
    expect(theme.data.mouseCursor, null);
    expect(theme.data.materialTapTargetSize, null);
    expect(theme.data.visualDensity, null);
    expect(theme.data.focusColor, null);
    expect(theme.data.hoverColor, null);
    expect(theme.data.splashRadius, null);
  });

  testWidgets('Default RadioThemeData debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const RadioThemeData().debugFillProperties(builder);

    final List<String> description = builder.properties
      .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
      .map((DiagnosticsNode node) => node.toString())
      .toList();

    expect(description, <String>[]);
  });

  testWidgets('RadioThemeData implements debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    RadioThemeData(
      fillColor: MaterialStateProperty.all(const Color(0xfffffff0)),
      mouseCursor: MouseCursor.defer,
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
    expect(description[2], 'materialTapTargetSize: MaterialTapTargetSize.shrinkWrap');
    expect(description[3], 'visualDensity: VisualDensity#00000(h: 0.0, v: 0.0)');
    expect(description[4], 'focusColor: Color(0xfffffff2)');
    expect(description[5], 'hoverColor: Color(0xfffffff2)');
    expect(description[6], 'splashRadius: 1.0');
  });

  testWidgets('Radio is themeable', (WidgetTester tester) async {
    tester.binding.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;

    const Color defaultFillColor = Color(0xfffffff0);
    const Color selectedFillColor = Color(0xfffffff1);
    const MouseCursor mouseCursor = SystemMouseCursors.text;
    const MaterialTapTargetSize materialTapTargetSize = MaterialTapTargetSize.shrinkWrap;
    const VisualDensity visualDensity = VisualDensity(horizontal: 1, vertical: 1);
    const Color focusColor = Color(0xfffffff2);
    const Color hoverColor = Color(0xfffffff3);
    const double splashRadius = 1.0;

    Widget buildRadio({bool selected = false, bool autofocus = false}) {
      return MaterialApp(
        theme: ThemeData(
          radioTheme: RadioThemeData(
            fillColor: MaterialStateProperty.resolveWith((Set<MaterialState> states) {
              if (states.contains(MaterialState.selected)) {
                return selectedFillColor;
              }
              return defaultFillColor;
            }),
            mouseCursor: mouseCursor,
            materialTapTargetSize: materialTapTargetSize,
            visualDensity: visualDensity,
            focusColor: focusColor,
            hoverColor: hoverColor,
            splashRadius: splashRadius,
          ),
        ),
        home: Scaffold(
          body: Radio<int>(
            onChanged: (int? int) {},
            value: selected ? 1 : 0,
            groupValue: 1,
            autofocus: autofocus,
          ),
        ),
      );
    }

    // Radio.
    await tester.pumpWidget(buildRadio());
    await tester.pumpAndSettle();
    expect(_getRadioMaterial(tester), paints..circle(color: defaultFillColor));
    // Size from MaterialTapTargetSize.shrinkWrap with added VisualDensity.
    expect(tester.getSize(_findRadio()), const Size(40.0, 40.0) + visualDensity.baseSizeAdjustment);

    // Selected radio.
    await tester.pumpWidget(buildRadio(selected: true));
    await tester.pumpAndSettle();
    expect(_getRadioMaterial(tester), paints..circle(color: selectedFillColor));

    // Radio with hover.
    await tester.pumpWidget(buildRadio());
    await _pointGestureToRadio(tester);
    await tester.pumpAndSettle();
    expect(_getRadioMaterial(tester), paints..circle(color: hoverColor));
    expect(RendererBinding.instance!.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.text);

    // Radio with focus.
    await tester.pumpWidget(buildRadio(autofocus: true));
    await tester.pumpAndSettle();
    expect(_getRadioMaterial(tester), paints..circle(color: focusColor, radius: splashRadius));
  });

  testWidgets('Radio properties are taken over the theme values', (WidgetTester tester) async {
    tester.binding.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;

    const Color themeDefaultFillColor = Color(0xfffffff0);
    const Color themeSelectedFillColor = Color(0xfffffff1);
    const MouseCursor themeMouseCursor = SystemMouseCursors.click;
    const MaterialTapTargetSize themeMaterialTapTargetSize = MaterialTapTargetSize.padded;
    const VisualDensity themeVisualDensity = VisualDensity.standard;
    const Color themeFocusColor = Color(0xfffffff2);
    const Color themeHoverColor = Color(0xfffffff3);
    const double themeSplashRadius = 1.0;

    const Color defaultFillColor = Color(0xfffffff0);
    const Color selectedFillColor = Color(0xfffffff1);
    const MouseCursor mouseCursor = SystemMouseCursors.text;
    const MaterialTapTargetSize materialTapTargetSize = MaterialTapTargetSize.shrinkWrap;
    const VisualDensity visualDensity = VisualDensity(horizontal: 1, vertical: 1);
    const Color focusColor = Color(0xfffffff2);
    const Color hoverColor = Color(0xfffffff3);
    const double splashRadius = 2.0;

    Widget buildRadio({bool selected = false, bool autofocus = false}) {
      return MaterialApp(
        theme: ThemeData(
          radioTheme: RadioThemeData(
            fillColor: MaterialStateProperty.resolveWith((Set<MaterialState> states) {
              if (states.contains(MaterialState.selected)) {
                return themeSelectedFillColor;
              }
              return themeDefaultFillColor;
            }),
            mouseCursor: themeMouseCursor,
            materialTapTargetSize: themeMaterialTapTargetSize,
            visualDensity: themeVisualDensity,
            focusColor: themeFocusColor,
            hoverColor: themeHoverColor,
            splashRadius: themeSplashRadius,
          ),
        ),
        home: Scaffold(
          body: Radio<int>(
            onChanged: (int? int) {},
            value: selected ? 0 : 1,
            groupValue: 0,
            autofocus: autofocus,
            fillColor: MaterialStateProperty.resolveWith((Set<MaterialState> states) {
              if (states.contains(MaterialState.selected)) {
                return selectedFillColor;
              }
              return defaultFillColor;
            }),
            mouseCursor: mouseCursor,
            materialTapTargetSize: materialTapTargetSize,
            visualDensity: visualDensity,
            focusColor: focusColor,
            hoverColor: hoverColor,
            splashRadius: splashRadius,
          ),
        ),
      );
    }

    // Radio.
    await tester.pumpWidget(buildRadio());
    await tester.pumpAndSettle();
    expect(_getRadioMaterial(tester), paints..circle(color: defaultFillColor));
    // Size from MaterialTapTargetSize.shrinkWrap with added VisualDensity.
    expect(tester.getSize(_findRadio()), const Size(40.0, 40.0) + visualDensity.baseSizeAdjustment);

    // Selected radio.
    await tester.pumpWidget(buildRadio(selected: true));
    await tester.pumpAndSettle();
    expect(_getRadioMaterial(tester), paints..circle(color: selectedFillColor));

    // Radio with hover.
    await tester.pumpWidget(buildRadio());
    await _pointGestureToRadio(tester);
    await tester.pumpAndSettle();
    expect(_getRadioMaterial(tester), paints..circle(color: hoverColor));
    expect(RendererBinding.instance!.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.text);

    // Radio with focus.
    await tester.pumpWidget(buildRadio(autofocus: true));
    await tester.pumpAndSettle();
    expect(_getRadioMaterial(tester), paints..circle(color: focusColor, radius: splashRadius));
  });
}

Finder _findRadio() {
  return find.byWidgetPredicate((Widget widget) => widget is Radio<int>);
}

Future<void> _pointGestureToRadio(WidgetTester tester) async {
  final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer();
  addTearDown(gesture.removePointer);
  await gesture.moveTo(tester.getCenter(_findRadio()));
}

MaterialInkController? _getRadioMaterial(WidgetTester tester) {
  return Material.of(tester.element(_findRadio()));
}
