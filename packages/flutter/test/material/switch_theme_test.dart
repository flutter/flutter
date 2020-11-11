// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

void main() {
  test('SwitchThemeData copyWith, ==, hashCode basics', () {
    expect(const SwitchThemeData(), const SwitchThemeData().copyWith());
    expect(const SwitchThemeData().hashCode, const SwitchThemeData().copyWith().hashCode);
  });

  test('SwitchThemeData defaults', () {
    const SwitchThemeData themeData = SwitchThemeData();
    expect(themeData.thumbColor, null);
    expect(themeData.trackColor, null);
    expect(themeData.mouseCursor, null);
    expect(themeData.materialTapTargetSize, null);
    expect(themeData.focusColor, null);
    expect(themeData.hoverColor, null);
    expect(themeData.splashRadius, null);

    const SwitchTheme theme = SwitchTheme(data: SwitchThemeData(), child: SizedBox());
    expect(theme.data.thumbColor, null);
    expect(theme.data.trackColor, null);
    expect(theme.data.mouseCursor, null);
    expect(theme.data.materialTapTargetSize, null);
    expect(theme.data.focusColor, null);
    expect(theme.data.hoverColor, null);
    expect(theme.data.splashRadius, null);
  });

  testWidgets('Default SwitchThemeData debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const SwitchThemeData().debugFillProperties(builder);

    final List<String> description = builder.properties
      .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
      .map((DiagnosticsNode node) => node.toString())
      .toList();

    expect(description, <String>[]);
  });

  testWidgets('SwitchThemeData implements debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    SwitchThemeData(
      thumbColor: MaterialStateProperty.all(const Color(0xfffffff0)),
      trackColor: MaterialStateProperty.all(const Color(0xfffffff1)),
      mouseCursor: MouseCursor.defer,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      focusColor: const Color(0xfffffff2),
      hoverColor: const Color(0xfffffff2),
      splashRadius: 1.0,
    ).debugFillProperties(builder);

    final List<String> description = builder.properties
      .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
      .map((DiagnosticsNode node) => node.toString())
      .toList();

    expect(description[0], 'thumbColor: MaterialStateProperty.all(Color(0xfffffff0))');
    expect(description[1], 'trackColor: MaterialStateProperty.all(Color(0xfffffff1))');
    expect(description[2], 'materialTapTargetSize: MaterialTapTargetSize.shrinkWrap');
    expect(description[3], 'mouseCursor: defer');
    expect(description[4], 'focusColor: Color(0xfffffff2)');
    expect(description[5], 'hoverColor: Color(0xfffffff2)');
    expect(description[6], 'splashRadius: 1.0');
  });

  testWidgets('Switch is themeable', (WidgetTester tester) async {
    tester.binding.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;

    const Color defaultThumbColor = Color(0xfffffff0);
    const Color selectedThumbColor = Color(0xfffffff1);
    const Color defaultTrackColor = Color(0xfffffff2);
    const Color selectedTrackColor = Color(0xfffffff3);
    const MouseCursor mouseCursor = SystemMouseCursors.text;
    const MaterialTapTargetSize materialTapTargetSize = MaterialTapTargetSize.shrinkWrap;
    const Color focusColor = Color(0xfffffff4);
    const Color hoverColor = Color(0xfffffff5);
    const double splashRadius = 1.0;

    Widget buildSwitch({bool selected = false, bool autofocus = false}) {
      return MaterialApp(
        theme: ThemeData(
          switchTheme: SwitchThemeData(
            thumbColor: MaterialStateProperty.resolveWith((Set<MaterialState> states) {
              if (states.contains(MaterialState.selected)) {
                return selectedThumbColor;
              }
              return defaultThumbColor;
            }),
            trackColor: MaterialStateProperty.resolveWith((Set<MaterialState> states) {
              if (states.contains(MaterialState.selected)) {
                return selectedTrackColor;
              }
              return defaultTrackColor;
            }),
            mouseCursor: mouseCursor,
            materialTapTargetSize: materialTapTargetSize,
            focusColor: focusColor,
            hoverColor: hoverColor,
            splashRadius: splashRadius,
          ),
        ),
        home: Scaffold(
          body: Switch(
            dragStartBehavior: DragStartBehavior.down,
            value: selected,
            onChanged: (bool value) {},
            autofocus: autofocus,
          ),
        ),
      );
    }

    // Switch.
    await tester.pumpWidget(buildSwitch());
    await tester.pumpAndSettle();
    expect(
      _getSwitchMaterial(tester),
      paints
        ..rrect(color: defaultTrackColor)
        ..circle()
        ..circle()
        ..circle()
        ..circle(color: defaultThumbColor),
    );
    // Size from MaterialTapTargetSize.shrinkWrap.
    expect(tester.getSize(find.byType(Switch)), const Size(59.0, 40.0));

    // Selected switch.
    await tester.pumpWidget(buildSwitch(selected: true));
    await tester.pumpAndSettle();
    expect(
      _getSwitchMaterial(tester),
      paints
        ..rrect(color: selectedTrackColor)
        ..circle()
        ..circle()
        ..circle()
        ..circle(color: selectedThumbColor),
    );

    // Switch with hover.
    await tester.pumpWidget(buildSwitch());
    await _pointGestureToSwitch(tester);
    await tester.pumpAndSettle();
    expect(RendererBinding.instance!.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.text);
    expect(_getSwitchMaterial(tester), paints..circle(color: hoverColor));

    // Switch with focus.
    await tester.pumpWidget(buildSwitch(autofocus: true));
    await tester.pumpAndSettle();
    expect(_getSwitchMaterial(tester), paints..circle(color: focusColor, radius: splashRadius));
  });

  testWidgets('Switch properties are taken over the theme values', (WidgetTester tester) async {
    tester.binding.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;

    const Color themeDefaultThumbColor = Color(0xfffffff0);
    const Color themeSelectedThumbColor = Color(0xfffffff1);
    const Color themeDefaultTrackColor = Color(0xfffffff2);
    const Color themeSelectedTrackColor = Color(0xfffffff3);
    const MouseCursor themeMouseCursor = SystemMouseCursors.click;
    const MaterialTapTargetSize themeMaterialTapTargetSize = MaterialTapTargetSize.padded;
    const Color themeFocusColor = Color(0xfffffff4);
    const Color themeHoverColor = Color(0xfffffff5);
    const double themeSplashRadius = 1.0;

    const Color defaultThumbColor = Color(0xffffff0f);
    const Color selectedThumbColor = Color(0xffffff1f);
    const Color defaultTrackColor = Color(0xffffff2f);
    const Color selectedTrackColor = Color(0xffffff3f);
    const MouseCursor mouseCursor = SystemMouseCursors.text;
    const MaterialTapTargetSize materialTapTargetSize = MaterialTapTargetSize.shrinkWrap;
    const Color focusColor = Color(0xffffff4f);
    const Color hoverColor = Color(0xffffff5f);
    const double splashRadius = 2.0;

    Widget buildSwitch({bool selected = false, bool autofocus = false}) {
      return MaterialApp(
        theme: ThemeData(
          switchTheme: SwitchThemeData(
            thumbColor: MaterialStateProperty.resolveWith((Set<MaterialState> states) {
              if (states.contains(MaterialState.selected)) {
                return themeSelectedThumbColor;
              }
              return themeDefaultThumbColor;
            }),
            trackColor: MaterialStateProperty.resolveWith((Set<MaterialState> states) {
              if (states.contains(MaterialState.selected)) {
                return themeSelectedTrackColor;
              }
              return themeDefaultTrackColor;
            }),
            mouseCursor: themeMouseCursor,
            materialTapTargetSize: themeMaterialTapTargetSize,
            focusColor: themeFocusColor,
            hoverColor: themeHoverColor,
            splashRadius: themeSplashRadius,
          ),
        ),
        home: Scaffold(
          body: Switch(
            value: selected,
            onChanged: (bool value) {},
            autofocus: autofocus,
            thumbColor: MaterialStateProperty.resolveWith((Set<MaterialState> states) {
              if (states.contains(MaterialState.selected)) {
                return selectedThumbColor;
              }
              return defaultThumbColor;
            }),
            trackColor: MaterialStateProperty.resolveWith((Set<MaterialState> states) {
              if (states.contains(MaterialState.selected)) {
                return selectedTrackColor;
              }
              return defaultTrackColor;
            }),
            mouseCursor: mouseCursor,
            materialTapTargetSize: materialTapTargetSize,
            focusColor: focusColor,
            hoverColor: hoverColor,
            splashRadius: splashRadius,
          ),
        ),
      );
    }

    // Switch.
    await tester.pumpWidget(buildSwitch());
    await tester.pumpAndSettle();
    expect(
      _getSwitchMaterial(tester),
      paints
        ..rrect(color: defaultTrackColor)
        ..circle()
        ..circle()
        ..circle()
        ..circle(color: defaultThumbColor),
    );
    // Size from MaterialTapTargetSize.shrinkWrap.
    expect(tester.getSize(find.byType(Switch)), const Size(59.0, 40.0));

    // Selected switch.
    await tester.pumpWidget(buildSwitch(selected: true));
    await tester.pumpAndSettle();
    expect(
      _getSwitchMaterial(tester),
      paints
        ..rrect(color: selectedTrackColor)
        ..circle()
        ..circle()
        ..circle()
        ..circle(color: selectedThumbColor),
    );

    // Switch with hover.
    await tester.pumpWidget(buildSwitch());
    await _pointGestureToSwitch(tester);
    await tester.pumpAndSettle();
    expect(RendererBinding.instance!.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.text);
    expect(_getSwitchMaterial(tester), paints..circle(color: hoverColor));

    // Switch with focus.
    await tester.pumpWidget(buildSwitch(autofocus: true));
    await tester.pumpAndSettle();
    expect(_getSwitchMaterial(tester), paints..circle(color: focusColor, radius: splashRadius));
  });
}

Future<void> _pointGestureToSwitch(WidgetTester tester) async {
  final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer();
  addTearDown(gesture.removePointer);
  await gesture.moveTo(tester.getCenter(find.byType(Switch)));
}

MaterialInkController? _getSwitchMaterial(WidgetTester tester) {
  return Material.of(tester.element(find.byType(Switch)));
}
