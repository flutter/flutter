// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:ui' show window;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/painting.dart';

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

IconThemeData getIconData(WidgetTester tester) {
  final IconTheme iconTheme = tester.firstWidget(
    find.descendant(
      of: find.byType(RawChip),
      matching: find.byType(IconTheme),
    ),
  );
  return iconTheme.data;
}

DefaultTextStyle getLabelStyle(WidgetTester tester) {
  return tester.widget(
    find
        .descendant(
          of: find.byType(RawChip),
          matching: find.byType(DefaultTextStyle),
        )
        .last,
  );
}

void main() {
  testWidgets('Chip theme is built by ThemeData', (WidgetTester tester) async {
    final ThemeData theme = ThemeData(
      platform: TargetPlatform.android,
      primarySwatch: Colors.red,
    );
    final ChipThemeData chipTheme = theme.chipTheme;

    expect(chipTheme.backgroundColor, equals(Colors.black.withAlpha(0x1f)));
    expect(chipTheme.selectedColor, equals(Colors.black.withAlpha(0x3d)));
    expect(chipTheme.deleteIconColor, equals(Colors.black.withAlpha(0xde)));
  });

  testWidgets('Chip uses ThemeData chip theme if present', (WidgetTester tester) async {
    final ThemeData theme = ThemeData(
      platform: TargetPlatform.android,
      primarySwatch: Colors.red,
      backgroundColor: Colors.blue,
    );
    final ChipThemeData chipTheme = theme.chipTheme;

    Widget buildChip(ChipThemeData data) {
      return MaterialApp(
        locale: const Locale('en', 'us'),
        home: Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: MediaQueryData.fromWindow(window),
          child: Material(
            child: Center(
              child: Theme(
                data: theme,
                child: RawChip(
                  showCheckmark: true,
                  onDeleted: () { },
                  tapEnabled: true,
                  avatar: const Placeholder(),
                  deleteIcon: const Placeholder(),
                  isEnabled: true,
                  selected: false,
                  label: const Text('Chip'),
                  onSelected: (bool newValue) { },
                  onPressed: null,
                ),
              ),
            ),
          ),
        ),
      ));
    }

    await tester.pumpWidget(buildChip(chipTheme));
    await tester.pumpAndSettle();

    final RenderBox materialBox = getMaterialBox(tester);

    expect(materialBox, paints..path(color: chipTheme.backgroundColor));
  });

  testWidgets('Chip overrides ThemeData theme if ChipTheme present', (WidgetTester tester) async {
    final ThemeData theme = ThemeData(
      platform: TargetPlatform.android,
      primarySwatch: Colors.red,
    );
    final ChipThemeData chipTheme = theme.chipTheme;
    final ChipThemeData customTheme = chipTheme.copyWith(
      backgroundColor: Colors.purple,
      deleteIconColor: Colors.purple.withAlpha(0x3d),
      elevation: 3.0,
      shadowColor: Colors.pink,
    );
    const bool value = false;
    Widget buildChip(ChipThemeData data) {
      return MaterialApp(
        home: Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: MediaQueryData.fromWindow(window),
          child: Material(
            child: Center(
              child: Theme(
                data: theme,
                child: ChipTheme(
                  data: customTheme,
                  child: RawChip(
                    showCheckmark: true,
                    onDeleted: () { },
                    tapEnabled: true,
                    avatar: const Placeholder(),
                    deleteIcon: const Placeholder(),
                    isEnabled: true,
                    selected: value,
                    label: const Text('$value'),
                    onSelected: (bool newValue) { },
                    onPressed: null,
                  ),
                ),
              ),
            ),
          ),
        ),
      ));
    }

    await tester.pumpWidget(buildChip(chipTheme));
    await tester.pumpAndSettle();

    final RenderBox materialBox = getMaterialBox(tester);
    final Material material = getMaterial(tester);

    expect(materialBox, paints..path(color: Color(customTheme.backgroundColor.value)));
    expect(material.elevation, customTheme.elevation);
    expect(material.shadowColor, customTheme.shadowColor);
  });

  testWidgets('ChipThemeData generates correct opacities for defaults', (WidgetTester tester) async {
    const Color customColor1 = Color(0xcafefeed);
    const Color customColor2 = Color(0xdeadbeef);
    final TextStyle customStyle = ThemeData.fallback().textTheme.bodyText1.copyWith(color: customColor2);

    final ChipThemeData lightTheme = ChipThemeData.fromDefaults(
      secondaryColor: customColor1,
      brightness: Brightness.light,
      labelStyle: customStyle,
    );

    expect(lightTheme.backgroundColor, equals(Colors.black.withAlpha(0x1f)));
    expect(lightTheme.deleteIconColor, equals(Colors.black.withAlpha(0xde)));
    expect(lightTheme.disabledColor, equals(Colors.black.withAlpha(0x0c)));
    expect(lightTheme.selectedColor, equals(Colors.black.withAlpha(0x3d)));
    expect(lightTheme.secondarySelectedColor, equals(customColor1.withAlpha(0x3d)));
    expect(lightTheme.labelPadding, isNull);
    expect(lightTheme.padding, equals(const EdgeInsets.all(4.0)));
    expect(lightTheme.shape, isA<StadiumBorder>());
    expect(lightTheme.labelStyle.color, equals(Colors.black.withAlpha(0xde)));
    expect(lightTheme.secondaryLabelStyle.color, equals(customColor1.withAlpha(0xde)));
    expect(lightTheme.brightness, equals(Brightness.light));

    final ChipThemeData darkTheme = ChipThemeData.fromDefaults(
      secondaryColor: customColor1,
      brightness: Brightness.dark,
      labelStyle: customStyle,
    );

    expect(darkTheme.backgroundColor, equals(Colors.white.withAlpha(0x1f)));
    expect(darkTheme.deleteIconColor, equals(Colors.white.withAlpha(0xde)));
    expect(darkTheme.disabledColor, equals(Colors.white.withAlpha(0x0c)));
    expect(darkTheme.selectedColor, equals(Colors.white.withAlpha(0x3d)));
    expect(darkTheme.secondarySelectedColor, equals(customColor1.withAlpha(0x3d)));
    expect(darkTheme.labelPadding, isNull);
    expect(darkTheme.padding, equals(const EdgeInsets.all(4.0)));
    expect(darkTheme.shape, isA<StadiumBorder>());
    expect(darkTheme.labelStyle.color, equals(Colors.white.withAlpha(0xde)));
    expect(darkTheme.secondaryLabelStyle.color, equals(customColor1.withAlpha(0xde)));
    expect(darkTheme.brightness, equals(Brightness.dark));

    final ChipThemeData customTheme = ChipThemeData.fromDefaults(
      primaryColor: customColor1,
      secondaryColor: customColor2,
      labelStyle: customStyle,
    );

    expect(customTheme.backgroundColor, equals(customColor1.withAlpha(0x1f)));
    expect(customTheme.deleteIconColor, equals(customColor1.withAlpha(0xde)));
    expect(customTheme.disabledColor, equals(customColor1.withAlpha(0x0c)));
    expect(customTheme.selectedColor, equals(customColor1.withAlpha(0x3d)));
    expect(customTheme.secondarySelectedColor, equals(customColor2.withAlpha(0x3d)));
    expect(customTheme.labelPadding, isNull);
    expect(customTheme.padding, equals(const EdgeInsets.all(4.0)));
    expect(customTheme.shape, isA<StadiumBorder>());
    expect(customTheme.labelStyle.color, equals(customColor1.withAlpha(0xde)));
    expect(customTheme.secondaryLabelStyle.color, equals(customColor2.withAlpha(0xde)));
    expect(customTheme.brightness, equals(Brightness.light));
  });

  testWidgets('ChipThemeData lerps correctly', (WidgetTester tester) async {
    final ChipThemeData chipThemeBlack = ChipThemeData.fromDefaults(
      secondaryColor: Colors.black,
      brightness: Brightness.dark,
      labelStyle: ThemeData.fallback().textTheme.bodyText1.copyWith(color: Colors.black),
    ).copyWith(
      elevation: 1.0,
      labelPadding: const EdgeInsets.symmetric(horizontal: 8.0),
      pressElevation: 4.0,
      shadowColor: Colors.black,
      selectedShadowColor: Colors.black,
      checkmarkColor: Colors.black,
    );
    final ChipThemeData chipThemeWhite = ChipThemeData.fromDefaults(
      secondaryColor: Colors.white,
      brightness: Brightness.light,
      labelStyle: ThemeData.fallback().textTheme.bodyText1.copyWith(color: Colors.white),
    ).copyWith(
      padding: const EdgeInsets.all(2.0),
      labelPadding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      elevation: 5.0,
      pressElevation: 10.0,
      shadowColor: Colors.white,
      selectedShadowColor: Colors.white,
      checkmarkColor: Colors.white,
    );

    final ChipThemeData lerp = ChipThemeData.lerp(chipThemeBlack, chipThemeWhite, 0.5);
    const Color middleGrey = Color(0xff7f7f7f);
    expect(lerp.backgroundColor, equals(middleGrey.withAlpha(0x1f)));
    expect(lerp.deleteIconColor, equals(middleGrey.withAlpha(0xde)));
    expect(lerp.disabledColor, equals(middleGrey.withAlpha(0x0c)));
    expect(lerp.selectedColor, equals(middleGrey.withAlpha(0x3d)));
    expect(lerp.secondarySelectedColor, equals(middleGrey.withAlpha(0x3d)));
    expect(lerp.shadowColor, equals(middleGrey));
    expect(lerp.selectedShadowColor, equals(middleGrey));
    expect(lerp.labelPadding, equals(const EdgeInsets.all(4.0)));
    expect(lerp.padding, equals(const EdgeInsets.all(3.0)));
    expect(lerp.shape, isA<StadiumBorder>());
    expect(lerp.labelStyle.color, equals(middleGrey.withAlpha(0xde)));
    expect(lerp.secondaryLabelStyle.color, equals(middleGrey.withAlpha(0xde)));
    expect(lerp.brightness, equals(Brightness.light));
    expect(lerp.elevation, 3.0);
    expect(lerp.pressElevation, 7.0);
    expect(lerp.checkmarkColor, equals(middleGrey));

    expect(ChipThemeData.lerp(null, null, 0.25), isNull);

    final ChipThemeData lerpANull25 = ChipThemeData.lerp(null, chipThemeWhite, 0.25);
    expect(lerpANull25.backgroundColor, equals(Colors.black.withAlpha(0x08)));
    expect(lerpANull25.deleteIconColor, equals(Colors.black.withAlpha(0x38)));
    expect(lerpANull25.disabledColor, equals(Colors.black.withAlpha(0x03)));
    expect(lerpANull25.selectedColor, equals(Colors.black.withAlpha(0x0f)));
    expect(lerpANull25.secondarySelectedColor, equals(Colors.white.withAlpha(0x0f)));
    expect(lerpANull25.shadowColor, equals(Colors.white.withAlpha(0x40)));
    expect(lerpANull25.selectedShadowColor, equals(Colors.white.withAlpha(0x40)));
    expect(lerpANull25.labelPadding, equals(const EdgeInsets.only(left: 0.0, top: 2.0, right: 0.0, bottom: 2.0)));
    expect(lerpANull25.padding, equals(const EdgeInsets.all(0.5)));
    expect(lerpANull25.shape, isA<StadiumBorder>());
    expect(lerpANull25.labelStyle.color, equals(Colors.black.withAlpha(0x38)));
    expect(lerpANull25.secondaryLabelStyle.color, equals(Colors.white.withAlpha(0x38)));
    expect(lerpANull25.brightness, equals(Brightness.light));
    expect(lerpANull25.elevation, 1.25);
    expect(lerpANull25.pressElevation, 2.5);
    expect(lerpANull25.checkmarkColor, equals(Colors.white.withAlpha(0x40)));

    final ChipThemeData lerpANull75 = ChipThemeData.lerp(null, chipThemeWhite, 0.75);
    expect(lerpANull75.backgroundColor, equals(Colors.black.withAlpha(0x17)));
    expect(lerpANull75.deleteIconColor, equals(Colors.black.withAlpha(0xa7)));
    expect(lerpANull75.disabledColor, equals(Colors.black.withAlpha(0x09)));
    expect(lerpANull75.selectedColor, equals(Colors.black.withAlpha(0x2e)));
    expect(lerpANull75.secondarySelectedColor, equals(Colors.white.withAlpha(0x2e)));
    expect(lerpANull75.shadowColor, equals(Colors.white.withAlpha(0xbf)));
    expect(lerpANull75.selectedShadowColor, equals(Colors.white.withAlpha(0xbf)));
    expect(lerpANull75.labelPadding, equals(const EdgeInsets.only(left: 0.0, top: 6.0, right: 0.0, bottom: 6.0)));
    expect(lerpANull75.padding, equals(const EdgeInsets.all(1.5)));
    expect(lerpANull75.shape, isA<StadiumBorder>());
    expect(lerpANull75.labelStyle.color, equals(Colors.black.withAlpha(0xa7)));
    expect(lerpANull75.secondaryLabelStyle.color, equals(Colors.white.withAlpha(0xa7)));
    expect(lerpANull75.brightness, equals(Brightness.light));
    expect(lerpANull75.elevation, 3.75);
    expect(lerpANull75.pressElevation, 7.5);
    expect(lerpANull75.checkmarkColor, equals(Colors.white.withAlpha(0xbf)));

    final ChipThemeData lerpBNull25 = ChipThemeData.lerp(chipThemeBlack, null, 0.25);
    expect(lerpBNull25.backgroundColor, equals(Colors.white.withAlpha(0x17)));
    expect(lerpBNull25.deleteIconColor, equals(Colors.white.withAlpha(0xa7)));
    expect(lerpBNull25.disabledColor, equals(Colors.white.withAlpha(0x09)));
    expect(lerpBNull25.selectedColor, equals(Colors.white.withAlpha(0x2e)));
    expect(lerpBNull25.secondarySelectedColor, equals(Colors.black.withAlpha(0x2e)));
    expect(lerpBNull25.shadowColor, equals(Colors.black.withAlpha(0xbf)));
    expect(lerpBNull25.selectedShadowColor, equals(Colors.black.withAlpha(0xbf)));
    expect(lerpBNull25.labelPadding, equals(const EdgeInsets.only(left: 6.0, top: 0.0, right: 6.0, bottom: 0.0)));
    expect(lerpBNull25.padding, equals(const EdgeInsets.all(3.0)));
    expect(lerpBNull25.shape, isA<StadiumBorder>());
    expect(lerpBNull25.labelStyle.color, equals(Colors.white.withAlpha(0xa7)));
    expect(lerpBNull25.secondaryLabelStyle.color, equals(Colors.black.withAlpha(0xa7)));
    expect(lerpBNull25.brightness, equals(Brightness.dark));
    expect(lerpBNull25.elevation, 0.75);
    expect(lerpBNull25.pressElevation, 3.0);
    expect(lerpBNull25.checkmarkColor, equals(Colors.black.withAlpha(0xbf)));

    final ChipThemeData lerpBNull75 = ChipThemeData.lerp(chipThemeBlack, null, 0.75);
    expect(lerpBNull75.backgroundColor, equals(Colors.white.withAlpha(0x08)));
    expect(lerpBNull75.deleteIconColor, equals(Colors.white.withAlpha(0x38)));
    expect(lerpBNull75.disabledColor, equals(Colors.white.withAlpha(0x03)));
    expect(lerpBNull75.selectedColor, equals(Colors.white.withAlpha(0x0f)));
    expect(lerpBNull75.secondarySelectedColor, equals(Colors.black.withAlpha(0x0f)));
    expect(lerpBNull75.shadowColor, equals(Colors.black.withAlpha(0x40)));
    expect(lerpBNull75.selectedShadowColor, equals(Colors.black.withAlpha(0x40)));
    expect(lerpBNull75.labelPadding, equals(const EdgeInsets.only(left: 2.0, top: 0.0, right: 2.0, bottom: 0.0)));
    expect(lerpBNull75.padding, equals(const EdgeInsets.all(1.0)));
    expect(lerpBNull75.shape, isA<StadiumBorder>());
    expect(lerpBNull75.labelStyle.color, equals(Colors.white.withAlpha(0x38)));
    expect(lerpBNull75.secondaryLabelStyle.color, equals(Colors.black.withAlpha(0x38)));
    expect(lerpBNull75.brightness, equals(Brightness.light));
    expect(lerpBNull75.elevation, 0.25);
    expect(lerpBNull75.pressElevation, 1.0);
    expect(lerpBNull75.checkmarkColor, equals(Colors.black.withAlpha(0x40)));
  });

  testWidgets('Chip uses stateful color from chip theme', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode();

    const Color pressedColor = Color(0x00000001);
    const Color hoverColor = Color(0x00000002);
    const Color focusedColor = Color(0x00000003);
    const Color defaultColor = Color(0x00000004);
    const Color selectedColor = Color(0x00000005);
    const Color disabledColor = Color(0x00000006);

    Color getTextColor(Set<MaterialState> states) {
      if (states.contains(MaterialState.disabled))
        return disabledColor;

      if (states.contains(MaterialState.pressed))
        return pressedColor;

      if (states.contains(MaterialState.hovered))
        return hoverColor;

      if (states.contains(MaterialState.focused))
        return focusedColor;

      if (states.contains(MaterialState.selected))
        return selectedColor;

      return defaultColor;
    }

    final TextStyle labelStyle =  TextStyle(
      color: MaterialStateColor.resolveWith(getTextColor),
    );
    Widget chipWidget({ bool enabled = true, bool selected = false }) {
      return MaterialApp(
        theme: ThemeData(
          chipTheme: ThemeData.light().chipTheme.copyWith(
            labelStyle: labelStyle,
            secondaryLabelStyle: labelStyle,
          ),
        ),
        home: Scaffold(
          body: Focus(
            focusNode: focusNode,
            child: ChoiceChip(
              label: const Text('Chip'),
              selected: selected,
              onSelected: enabled ? (_) {} : null,
            ),
          ),
        ),
      );
    }
    Color textColor() {
      return tester.renderObject<RenderParagraph>(find.text('Chip')).text.style.color;
    }

    // Default, not disabled.
    await tester.pumpWidget(chipWidget());
    expect(textColor(), equals(defaultColor));

    // Selected.
    await tester.pumpWidget(chipWidget(selected: true));
    expect(textColor(), selectedColor);

    // Focused.
    final FocusNode chipFocusNode = focusNode.children.first;
    chipFocusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(textColor(), focusedColor);

    // Hovered.
    final Offset center = tester.getCenter(find.byType(ChoiceChip));
    final TestGesture gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await gesture.addPointer();
    await gesture.moveTo(center);
    await tester.pumpAndSettle();
    expect(textColor(), hoverColor);

    // Pressed.
    await gesture.down(center);
    await tester.pumpAndSettle();
    expect(textColor(), pressedColor);

    // Disabled.
    await tester.pumpWidget(chipWidget(enabled: false));
    await tester.pumpAndSettle();
    expect(textColor(), disabledColor);

    // Teardown.
    await gesture.removePointer();
  });
}
