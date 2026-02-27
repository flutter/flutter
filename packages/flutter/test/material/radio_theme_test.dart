// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('RadioThemeData copyWith, ==, hashCode basics', () {
    expect(const RadioThemeData(), const RadioThemeData().copyWith());
    expect(const RadioThemeData().hashCode, const RadioThemeData().copyWith().hashCode);
  });

  test('RadioThemeData lerp special cases', () {
    expect(RadioThemeData.lerp(null, null, 0), const RadioThemeData());
    const data = RadioThemeData();
    expect(identical(RadioThemeData.lerp(data, data, 0.5), data), true);
  });

  test('RadioThemeData defaults', () {
    const themeData = RadioThemeData();
    expect(themeData.mouseCursor, null);
    expect(themeData.fillColor, null);
    expect(themeData.overlayColor, null);
    expect(themeData.splashRadius, null);
    expect(themeData.materialTapTargetSize, null);
    expect(themeData.visualDensity, null);
    expect(themeData.backgroundColor, null);
    expect(themeData.side, null);
    expect(themeData.innerRadius, null);

    const theme = RadioTheme(data: RadioThemeData(), child: SizedBox());
    expect(theme.data.mouseCursor, null);
    expect(theme.data.fillColor, null);
    expect(theme.data.overlayColor, null);
    expect(theme.data.splashRadius, null);
    expect(theme.data.materialTapTargetSize, null);
    expect(theme.data.visualDensity, null);
    expect(theme.data.backgroundColor, null);
    expect(theme.data.side, null);
    expect(theme.data.innerRadius, null);
  });

  testWidgets('Default RadioThemeData debugFillProperties', (WidgetTester tester) async {
    final builder = DiagnosticPropertiesBuilder();
    const RadioThemeData().debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(description, const <String>[]);
  });

  testWidgets('RadioThemeData implements debugFillProperties', (WidgetTester tester) async {
    final builder = DiagnosticPropertiesBuilder();
    const RadioThemeData(
      mouseCursor: WidgetStatePropertyAll<MouseCursor>(SystemMouseCursors.click),
      fillColor: WidgetStatePropertyAll<Color>(Color(0xfffffff0)),
      overlayColor: WidgetStatePropertyAll<Color>(Color(0xfffffff1)),
      splashRadius: 1.0,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.standard,
      backgroundColor: WidgetStatePropertyAll<Color>(Color(0xfffffff2)),
      side: BorderSide(color: Color(0xfffffff3), width: 2),
      innerRadius: WidgetStatePropertyAll<double>(5.0),
    ).debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(
      description,
      equalsIgnoringHashCodes(<String>[
        'mouseCursor: WidgetStatePropertyAll(SystemMouseCursor(click))',
        'fillColor: WidgetStatePropertyAll(${const Color(0xfffffff0)})',
        'overlayColor: WidgetStatePropertyAll(${const Color(0xfffffff1)})',
        'splashRadius: 1.0',
        'materialTapTargetSize: MaterialTapTargetSize.shrinkWrap',
        'visualDensity: VisualDensity#00000(h: 0.0, v: 0.0)',
        'backgroundColor: WidgetStatePropertyAll(${const Color(0xfffffff2)})',
        'side: BorderSide(color: ${const Color(0xfffffff3)}, width: 2.0)',
        'innerRadius: WidgetStatePropertyAll(5.0)',
      ]),
    );
  });

  testWidgets('Radio is themeable', (WidgetTester tester) async {
    tester.binding.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;

    const MouseCursor mouseCursor = SystemMouseCursors.text;
    const defaultFillColor = Color(0xfffffff0);
    const selectedFillColor = Color(0xfffffff1);
    const focusOverlayColor = Color(0xfffffff2);
    const hoverOverlayColor = Color(0xfffffff3);
    const defaultBackgroundColor = Color(0xfffffff4);
    const selectedBackgroundColor = Color(0xfffffff5);
    const splashRadius = 1.0;
    const MaterialTapTargetSize materialTapTargetSize = MaterialTapTargetSize.shrinkWrap;
    const visualDensity = VisualDensity(horizontal: 1, vertical: 1);
    const innerRadius = 5.0;

    Widget buildRadio({bool selected = false, bool autofocus = false}) {
      return MaterialApp(
        theme: ThemeData(
          radioTheme: RadioThemeData(
            mouseCursor: const WidgetStatePropertyAll<MouseCursor>(mouseCursor),
            fillColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return selectedFillColor;
              }
              return defaultFillColor;
            }),
            overlayColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
              if (states.contains(WidgetState.focused)) {
                return focusOverlayColor;
              }
              if (states.contains(WidgetState.hovered)) {
                return hoverOverlayColor;
              }
              return null;
            }),
            splashRadius: splashRadius,
            materialTapTargetSize: materialTapTargetSize,
            visualDensity: visualDensity,
            backgroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return selectedBackgroundColor;
              }
              return defaultBackgroundColor;
            }),
            innerRadius: const WidgetStatePropertyAll<double>(innerRadius),
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
    expect(
      _getRadioMaterial(tester),
      paints
        ..circle(color: defaultBackgroundColor)
        ..circle(color: defaultFillColor),
    );
    // Size from MaterialTapTargetSize.shrinkWrap with added VisualDensity.
    expect(tester.getSize(_findRadio()), const Size(40.0, 40.0) + visualDensity.baseSizeAdjustment);

    // Selected radio.
    await tester.pumpWidget(buildRadio(selected: true));
    await tester.pumpAndSettle();
    expect(
      _getRadioMaterial(tester),
      paints
        ..circle(color: selectedBackgroundColor)
        ..circle(color: selectedFillColor)
        ..circle(color: selectedFillColor, radius: innerRadius),
    );

    // Radio with hover.
    await tester.pumpWidget(buildRadio());
    await _pointGestureToRadio(tester);
    await tester.pumpAndSettle();
    expect(_getRadioMaterial(tester), paints..circle(color: hoverOverlayColor));
    expect(
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
      SystemMouseCursors.text,
    );

    // Radio with focus.
    await tester.pumpWidget(buildRadio(autofocus: true));
    await tester.pumpAndSettle();
    expect(
      _getRadioMaterial(tester),
      paints..circle(color: focusOverlayColor, radius: splashRadius),
    );
  });

  testWidgets('Radio side is themeable', (WidgetTester tester) async {
    const defaultSide = BorderSide(color: Color(0xfffffff0), width: 2.0);
    const selectedSide = BorderSide(color: Color(0xfffffff1), width: 3.0);

    Widget buildRadio({bool selected = false, bool autofocus = false}) {
      return MaterialApp(
        theme: ThemeData(
          radioTheme: RadioThemeData(
            side: WidgetStateBorderSide.resolveWith((Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return selectedSide;
              }
              return defaultSide;
            }),
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
    expect(
      _getRadioMaterial(tester),
      paints
        ..circle(color: Colors.transparent)
        ..circle(color: defaultSide.color, strokeWidth: defaultSide.width),
    );

    // Selected radio.
    await tester.pumpWidget(buildRadio(selected: true));
    await tester.pumpAndSettle();
    expect(
      _getRadioMaterial(tester),
      paints
        ..circle(color: Colors.transparent)
        ..circle(color: selectedSide.color, strokeWidth: selectedSide.width),
    );
  });

  testWidgets('Radio properties are taken over the theme values', (WidgetTester tester) async {
    tester.binding.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;

    const MouseCursor themeMouseCursor = SystemMouseCursors.click;
    const themeDefaultFillColor = Color(0xfffffff0);
    const themeSelectedFillColor = Color(0xfffffff1);
    const themeFocusOverlayColor = Color(0xfffffff2);
    const themeHoverOverlayColor = Color(0xfffffff3);
    const themeDefaultBackgroundColor = Color(0xfffffff4);
    const themeSelectedBackgroundColor = Color(0xfffffff5);
    const themeSplashRadius = 1.0;
    const MaterialTapTargetSize themeMaterialTapTargetSize = MaterialTapTargetSize.padded;
    const VisualDensity themeVisualDensity = VisualDensity.standard;
    const themeInnerRadius = 5.0;

    const MouseCursor mouseCursor = SystemMouseCursors.text;
    const defaultFillColor = Color(0xeffffff0);
    const selectedFillColor = Color(0xeffffff1);
    const focusColor = Color(0xeffffff2);
    const hoverColor = Color(0xeffffff3);
    const defaultBackgroundColor = Color(0xeffffff4);
    const selectedBackgroundColor = Color(0xeffffff5);
    const splashRadius = 2.0;
    const MaterialTapTargetSize materialTapTargetSize = MaterialTapTargetSize.shrinkWrap;
    const visualDensity = VisualDensity(horizontal: 1, vertical: 1);
    const innerRadius = 6.0;

    Widget buildRadio({bool selected = false, bool autofocus = false}) {
      return MaterialApp(
        theme: ThemeData(
          radioTheme: RadioThemeData(
            mouseCursor: const WidgetStatePropertyAll<MouseCursor>(themeMouseCursor),
            fillColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return themeSelectedFillColor;
              }
              return themeDefaultFillColor;
            }),
            overlayColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
              if (states.contains(WidgetState.focused)) {
                return themeFocusOverlayColor;
              }
              if (states.contains(WidgetState.hovered)) {
                return themeHoverOverlayColor;
              }
              return null;
            }),
            splashRadius: themeSplashRadius,
            materialTapTargetSize: themeMaterialTapTargetSize,
            visualDensity: themeVisualDensity,
            backgroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return themeSelectedBackgroundColor;
              }
              return themeDefaultBackgroundColor;
            }),
            innerRadius: const WidgetStatePropertyAll<double>(themeInnerRadius),
          ),
        ),
        home: Scaffold(
          body: Radio<int>(
            onChanged: (int? int) {},
            value: selected ? 0 : 1,
            groupValue: 0,
            autofocus: autofocus,
            mouseCursor: mouseCursor,
            fillColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return selectedFillColor;
              }
              return defaultFillColor;
            }),
            focusColor: focusColor,
            hoverColor: hoverColor,
            splashRadius: splashRadius,
            materialTapTargetSize: materialTapTargetSize,
            visualDensity: visualDensity,
            backgroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return selectedBackgroundColor;
              }
              return defaultBackgroundColor;
            }),
            innerRadius: const WidgetStatePropertyAll<double>(innerRadius),
          ),
        ),
      );
    }

    // Radio.
    await tester.pumpWidget(buildRadio());
    await tester.pumpAndSettle();
    expect(
      _getRadioMaterial(tester),
      paints
        ..circle(color: defaultBackgroundColor)
        ..circle(color: defaultFillColor),
    );
    // Size from MaterialTapTargetSize.shrinkWrap with added VisualDensity.
    expect(tester.getSize(_findRadio()), const Size(40.0, 40.0) + visualDensity.baseSizeAdjustment);

    // Selected radio.
    await tester.pumpWidget(buildRadio(selected: true));
    await tester.pumpAndSettle();
    expect(
      _getRadioMaterial(tester),
      paints
        ..circle(color: selectedBackgroundColor)
        ..circle(color: selectedFillColor)
        ..circle(color: selectedFillColor, radius: innerRadius),
    );

    // Radio with hover.
    await tester.pumpWidget(buildRadio());
    await _pointGestureToRadio(tester);
    await tester.pumpAndSettle();
    expect(_getRadioMaterial(tester), paints..circle(color: hoverColor));
    expect(
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
      SystemMouseCursors.text,
    );

    // Radio with focus.
    await tester.pumpWidget(buildRadio(autofocus: true));
    await tester.pumpAndSettle();
    expect(_getRadioMaterial(tester), paints..circle(color: focusColor, radius: splashRadius));
  });

  testWidgets('Radio side property is taken over the theme values', (WidgetTester tester) async {
    tester.binding.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;

    const themeDefaultSide = BorderSide(color: Color(0xfffffff0), width: 2.0);
    const themeSelectedSide = BorderSide(color: Color(0xfffffff1), width: 3.0);

    const defaultSide = BorderSide(color: Color(0xeffffff2), width: 4.0);
    const selectedSide = BorderSide(color: Color(0xeffffff3), width: 5.0);

    Widget buildRadio({bool selected = false, bool autofocus = false}) {
      return MaterialApp(
        theme: ThemeData(
          radioTheme: RadioThemeData(
            side: WidgetStateBorderSide.resolveWith((Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return themeSelectedSide;
              }
              return themeDefaultSide;
            }),
          ),
        ),
        home: Scaffold(
          body: Radio<int>(
            onChanged: (int? int) {},
            value: selected ? 0 : 1,
            groupValue: 0,
            autofocus: autofocus,
            side: WidgetStateBorderSide.resolveWith((Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return selectedSide;
              }
              return defaultSide;
            }),
          ),
        ),
      );
    }

    // Radio.
    await tester.pumpWidget(buildRadio());
    await tester.pumpAndSettle();
    expect(
      _getRadioMaterial(tester),
      paints
        ..circle(color: Colors.transparent)
        ..circle(color: defaultSide.color, strokeWidth: defaultSide.width),
    );

    // Selected radio.
    await tester.pumpWidget(buildRadio(selected: true));
    await tester.pumpAndSettle();
    expect(
      _getRadioMaterial(tester),
      paints
        ..circle(color: Colors.transparent)
        ..circle(color: selectedSide.color, strokeWidth: selectedSide.width),
    );
  });

  testWidgets('Radio activeColor property is taken over the theme', (WidgetTester tester) async {
    const themeDefaultFillColor = Color(0xfffffff0);
    const themeSelectedFillColor = Color(0xfffffff1);

    const selectedFillColor = Color(0xfffffff1);

    Widget buildRadio({bool selected = false, bool autofocus = false}) {
      return MaterialApp(
        theme: ThemeData(
          radioTheme: RadioThemeData(
            fillColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return themeSelectedFillColor;
              }
              return themeDefaultFillColor;
            }),
          ),
        ),
        home: Scaffold(
          body: Radio<int>(
            onChanged: (int? int) {},
            value: selected ? 0 : 1,
            groupValue: 0,
            autofocus: autofocus,
            activeColor: selectedFillColor,
          ),
        ),
      );
    }

    // Radio.
    await tester.pumpWidget(buildRadio());
    await tester.pumpAndSettle();
    expect(
      _getRadioMaterial(tester),
      paints
        ..circle(color: Colors.transparent)
        ..circle(color: themeDefaultFillColor),
    );

    // Selected radio.
    await tester.pumpWidget(buildRadio(selected: true));
    await tester.pumpAndSettle();
    expect(
      _getRadioMaterial(tester),
      paints
        ..circle(color: Colors.transparent)
        ..circle(color: selectedFillColor),
    );
  });

  testWidgets('Radio theme overlay color resolves in active/pressed states', (
    WidgetTester tester,
  ) async {
    const activePressedOverlayColor = Color(0xFF000001);
    const inactivePressedOverlayColor = Color(0xFF000002);

    Color? getOverlayColor(Set<WidgetState> states) {
      if (states.contains(WidgetState.pressed)) {
        if (states.contains(WidgetState.selected)) {
          return activePressedOverlayColor;
        }
        return inactivePressedOverlayColor;
      }
      return null;
    }

    const splashRadius = 24.0;

    Widget buildRadio({required bool active}) {
      return MaterialApp(
        theme: ThemeData(
          radioTheme: RadioThemeData(
            overlayColor: WidgetStateProperty.resolveWith(getOverlayColor),
            splashRadius: splashRadius,
          ),
        ),
        home: Scaffold(
          body: Radio<int>(value: active ? 1 : 0, groupValue: 1, onChanged: (_) {}),
        ),
      );
    }

    await tester.pumpWidget(buildRadio(active: false));
    await tester.press(_findRadio());
    await tester.pumpAndSettle();

    expect(
      _getRadioMaterial(tester),
      paints..circle(color: inactivePressedOverlayColor, radius: splashRadius),
      reason: 'Inactive pressed Radio should have overlay color: $inactivePressedOverlayColor',
    );

    await tester.pumpWidget(buildRadio(active: true));
    await tester.press(_findRadio());
    await tester.pumpAndSettle();

    expect(
      _getRadioMaterial(tester),
      paints..circle(color: activePressedOverlayColor, radius: splashRadius),
      reason: 'Active pressed Radio should have overlay color: $activePressedOverlayColor',
    );
  });

  testWidgets('Local RadioTheme can override global RadioTheme', (WidgetTester tester) async {
    const globalThemeFillColor = Color(0xfffffff1);
    const localThemeFillColor = Color(0xffff0000);

    Widget buildRadio({required bool active}) {
      return MaterialApp(
        theme: ThemeData(
          radioTheme: const RadioThemeData(
            fillColor: MaterialStatePropertyAll<Color>(globalThemeFillColor),
          ),
        ),
        home: Scaffold(
          body: RadioTheme(
            data: const RadioThemeData(
              fillColor: MaterialStatePropertyAll<Color>(localThemeFillColor),
            ),
            child: Radio<int>(value: active ? 1 : 0, groupValue: 1, onChanged: (_) {}),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildRadio(active: true));
    await tester.pumpAndSettle();
    expect(
      _getRadioMaterial(tester),
      paints
        ..circle(color: Colors.transparent)
        ..circle(color: localThemeFillColor),
    );
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
