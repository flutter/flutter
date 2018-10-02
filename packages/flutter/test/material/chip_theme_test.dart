// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show window;

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
    bool value;

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
                  onDeleted: () {},
                  tapEnabled: true,
                  avatar: const Placeholder(),
                  deleteIcon: const Placeholder(),
                  isEnabled: true,
                  selected: value,
                  label: Text('$value'),
                  onSelected: (bool newValue) {},
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
                    onDeleted: () {},
                    tapEnabled: true,
                    avatar: const Placeholder(),
                    deleteIcon: const Placeholder(),
                    isEnabled: true,
                    selected: value,
                    label: const Text('$value'),
                    onSelected: (bool newValue) {},
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

    expect(materialBox, paints..path(color: Color(customTheme.backgroundColor.value)));
  });

  testWidgets('ChipThemeData generates correct opacities for defaults', (WidgetTester tester) async {
    const Color customColor1 = Color(0xcafefeed);
    const Color customColor2 = Color(0xdeadbeef);
    final TextStyle customStyle = ThemeData.fallback().accentTextTheme.body2.copyWith(color: customColor2);

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
    expect(lightTheme.labelPadding, equals(const EdgeInsets.symmetric(horizontal: 8.0)));
    expect(lightTheme.padding, equals(const EdgeInsets.all(4.0)));
    expect(lightTheme.shape, equals(isInstanceOf<StadiumBorder>()));
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
    expect(darkTheme.labelPadding, equals(const EdgeInsets.symmetric(horizontal: 8.0)));
    expect(darkTheme.padding, equals(const EdgeInsets.all(4.0)));
    expect(darkTheme.shape, equals(isInstanceOf<StadiumBorder>()));
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
    expect(customTheme.labelPadding, equals(const EdgeInsets.symmetric(horizontal: 8.0)));
    expect(customTheme.padding, equals(const EdgeInsets.all(4.0)));
    expect(customTheme.shape, equals(isInstanceOf<StadiumBorder>()));
    expect(customTheme.labelStyle.color, equals(customColor1.withAlpha(0xde)));
    expect(customTheme.secondaryLabelStyle.color, equals(customColor2.withAlpha(0xde)));
    expect(customTheme.brightness, equals(Brightness.light));
  });

  testWidgets('ChipThemeData lerps correctly', (WidgetTester tester) async {
    final ChipThemeData chipThemeBlack = ChipThemeData.fromDefaults(
      secondaryColor: Colors.black,
      brightness: Brightness.dark,
      labelStyle: ThemeData.fallback().accentTextTheme.body2.copyWith(color: Colors.black),
    );
    final ChipThemeData chipThemeWhite = ChipThemeData.fromDefaults(
      secondaryColor: Colors.white,
      brightness: Brightness.light,
      labelStyle: ThemeData.fallback().accentTextTheme.body2.copyWith(color: Colors.white),
    ).copyWith(padding: const EdgeInsets.all(2.0), labelPadding: const EdgeInsets.only(top: 8.0, bottom: 8.0));
    final ChipThemeData lerp = ChipThemeData.lerp(chipThemeBlack, chipThemeWhite, 0.5);
    const Color middleGrey = Color(0xff7f7f7f);
    expect(lerp.backgroundColor, equals(middleGrey.withAlpha(0x1f)));
    expect(lerp.deleteIconColor, equals(middleGrey.withAlpha(0xde)));
    expect(lerp.disabledColor, equals(middleGrey.withAlpha(0x0c)));
    expect(lerp.selectedColor, equals(middleGrey.withAlpha(0x3d)));
    expect(lerp.secondarySelectedColor, equals(middleGrey.withAlpha(0x3d)));
    expect(lerp.labelPadding, equals(const EdgeInsets.all(4.0)));
    expect(lerp.padding, equals(const EdgeInsets.all(3.0)));
    expect(lerp.shape, equals(isInstanceOf<StadiumBorder>()));
    expect(lerp.labelStyle.color, equals(middleGrey.withAlpha(0xde)));
    expect(lerp.secondaryLabelStyle.color, equals(middleGrey.withAlpha(0xde)));
    expect(lerp.brightness, equals(Brightness.light));

    expect(ChipThemeData.lerp(null, null, 0.25), isNull);

    final ChipThemeData lerpANull25 = ChipThemeData.lerp(null, chipThemeWhite, 0.25);
    expect(lerpANull25.backgroundColor, equals(Colors.black.withAlpha(0x08)));
    expect(lerpANull25.deleteIconColor, equals(Colors.black.withAlpha(0x38)));
    expect(lerpANull25.disabledColor, equals(Colors.black.withAlpha(0x03)));
    expect(lerpANull25.selectedColor, equals(Colors.black.withAlpha(0x0f)));
    expect(lerpANull25.secondarySelectedColor, equals(Colors.white.withAlpha(0x0f)));
    expect(lerpANull25.labelPadding, equals(const EdgeInsets.only(left: 0.0, top: 2.0, right: 0.0, bottom: 2.0)));
    expect(lerpANull25.padding, equals(const EdgeInsets.all(0.5)));
    expect(lerpANull25.shape, equals(isInstanceOf<StadiumBorder>()));
    expect(lerpANull25.labelStyle.color, equals(Colors.black.withAlpha(0x38)));
    expect(lerpANull25.secondaryLabelStyle.color, equals(Colors.white.withAlpha(0x38)));
    expect(lerpANull25.brightness, equals(Brightness.light));

    final ChipThemeData lerpANull75 = ChipThemeData.lerp(null, chipThemeWhite, 0.75);
    expect(lerpANull75.backgroundColor, equals(Colors.black.withAlpha(0x17)));
    expect(lerpANull75.deleteIconColor, equals(Colors.black.withAlpha(0xa7)));
    expect(lerpANull75.disabledColor, equals(Colors.black.withAlpha(0x09)));
    expect(lerpANull75.selectedColor, equals(Colors.black.withAlpha(0x2e)));
    expect(lerpANull75.secondarySelectedColor, equals(Colors.white.withAlpha(0x2e)));
    expect(lerpANull75.labelPadding, equals(const EdgeInsets.only(left: 0.0, top: 6.0, right: 0.0, bottom: 6.0)));
    expect(lerpANull75.padding, equals(const EdgeInsets.all(1.5)));
    expect(lerpANull75.shape, equals(isInstanceOf<StadiumBorder>()));
    expect(lerpANull75.labelStyle.color, equals(Colors.black.withAlpha(0xa7)));
    expect(lerpANull75.secondaryLabelStyle.color, equals(Colors.white.withAlpha(0xa7)));
    expect(lerpANull75.brightness, equals(Brightness.light));

    final ChipThemeData lerpBNull25 = ChipThemeData.lerp(chipThemeBlack, null, 0.25);
    expect(lerpBNull25.backgroundColor, equals(Colors.white.withAlpha(0x17)));
    expect(lerpBNull25.deleteIconColor, equals(Colors.white.withAlpha(0xa7)));
    expect(lerpBNull25.disabledColor, equals(Colors.white.withAlpha(0x09)));
    expect(lerpBNull25.selectedColor, equals(Colors.white.withAlpha(0x2e)));
    expect(lerpBNull25.secondarySelectedColor, equals(Colors.black.withAlpha(0x2e)));
    expect(lerpBNull25.labelPadding, equals(const EdgeInsets.only(left: 6.0, top: 0.0, right: 6.0, bottom: 0.0)));
    expect(lerpBNull25.padding, equals(const EdgeInsets.all(3.0)));
    expect(lerpBNull25.shape, equals(isInstanceOf<StadiumBorder>()));
    expect(lerpBNull25.labelStyle.color, equals(Colors.white.withAlpha(0xa7)));
    expect(lerpBNull25.secondaryLabelStyle.color, equals(Colors.black.withAlpha(0xa7)));
    expect(lerpBNull25.brightness, equals(Brightness.dark));

    final ChipThemeData lerpBNull75 = ChipThemeData.lerp(chipThemeBlack, null, 0.75);
    expect(lerpBNull75.backgroundColor, equals(Colors.white.withAlpha(0x08)));
    expect(lerpBNull75.deleteIconColor, equals(Colors.white.withAlpha(0x38)));
    expect(lerpBNull75.disabledColor, equals(Colors.white.withAlpha(0x03)));
    expect(lerpBNull75.selectedColor, equals(Colors.white.withAlpha(0x0f)));
    expect(lerpBNull75.secondarySelectedColor, equals(Colors.black.withAlpha(0x0f)));
    expect(lerpBNull75.labelPadding, equals(const EdgeInsets.only(left: 2.0, top: 0.0, right: 2.0, bottom: 0.0)));
    expect(lerpBNull75.padding, equals(const EdgeInsets.all(1.0)));
    expect(lerpBNull75.shape, equals(isInstanceOf<StadiumBorder>()));
    expect(lerpBNull75.labelStyle.color, equals(Colors.white.withAlpha(0x38)));
    expect(lerpBNull75.secondaryLabelStyle.color, equals(Colors.black.withAlpha(0x38)));
    expect(lerpBNull75.brightness, equals(Brightness.light));
  });
}
