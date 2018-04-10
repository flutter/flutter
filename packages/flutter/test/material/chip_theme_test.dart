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
    final ThemeData theme = new ThemeData(
      platform: TargetPlatform.android,
      primarySwatch: Colors.red,
    );
    final ChipThemeData chipTheme = theme.chipTheme;

    expect(chipTheme.backgroundColor, equals(Colors.black.withAlpha(0x1f)));
    expect(chipTheme.selectedColor, equals(Colors.black.withAlpha(0x3d)));
    expect(chipTheme.deleteIconColor, equals(Colors.black.withAlpha(0xde)));
  });

  testWidgets('Chip uses ThemeData chip theme if present', (WidgetTester tester) async {
    final ThemeData theme = new ThemeData(
      platform: TargetPlatform.android,
      primarySwatch: Colors.red,
      backgroundColor: Colors.blue,
    );
    final ChipThemeData chipTheme = theme.chipTheme;
    bool value;

    Widget buildChip(ChipThemeData data) {
      return new Directionality(
        textDirection: TextDirection.ltr,
        child: new MediaQuery(
          data: new MediaQueryData.fromWindow(window),
          child: new Material(
            child: new Center(
              child: new Theme(
                data: theme,
                child: new RawChip(
                  showCheckmark: true,
                  onDeleted: () {},
                  tapEnabled: true,
                  avatar: const Placeholder(),
                  deleteIcon: const Placeholder(),
                  isEnabled: true,
                  selected: value,
                  label: new Text('$value'),
                  onSelected: (bool newValue) {},
                  onPressed: null,
                ),
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildChip(chipTheme));
    await tester.pumpAndSettle();

    final RenderBox materialBox = getMaterialBox(tester);

    expect(materialBox, paints..path(color: chipTheme.backgroundColor));
  });

  testWidgets('Chip overrides ThemeData theme if ChipTheme present', (WidgetTester tester) async {
    final ThemeData theme = new ThemeData(
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
      return new Directionality(
        textDirection: TextDirection.ltr,
        child: new MediaQuery(
          data: new MediaQueryData.fromWindow(window),
          child: new Material(
            child: new Center(
              child: new Theme(
                data: theme,
                child: new ChipTheme(
                  data: customTheme,
                  child: new RawChip(
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
      );
    }

    await tester.pumpWidget(buildChip(chipTheme));
    await tester.pumpAndSettle();

    final RenderBox materialBox = getMaterialBox(tester);

    expect(materialBox, paints..path(color: new Color(customTheme.backgroundColor.value)));
  });

  testWidgets('ChipThemeData generates correct opacities for defaults', (WidgetTester tester) async {
    const Color customColor1 = const Color(0xcafefeed);
    const Color customColor2 = const Color(0xdeadbeef);
    final TextStyle customStyle = new ThemeData.fallback().accentTextTheme.body2.copyWith(color: customColor2);

    final ChipThemeData lightTheme = new ChipThemeData.defaults(
      primaryColor: customColor1,
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
    expect(lightTheme.shape, equals(const isInstanceOf<StadiumBorder>()));
    expect(lightTheme.labelStyle.color, equals(Colors.black.withAlpha(0xde)));
    expect(lightTheme.secondaryLabelStyle.color, equals(customColor1.withAlpha(0xde)));
    expect(lightTheme.brightness, equals(Brightness.light));

    final ChipThemeData darkTheme = new ChipThemeData.defaults(
      primaryColor: customColor1,
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
    expect(darkTheme.shape, equals(const isInstanceOf<StadiumBorder>()));
    expect(darkTheme.labelStyle.color, equals(Colors.white.withAlpha(0xde)));
    expect(darkTheme.secondaryLabelStyle.color, equals(customColor1.withAlpha(0xde)));
    expect(darkTheme.brightness, equals(Brightness.dark));
  });

  testWidgets('ChipThemeData lerps correctly', (WidgetTester tester) async {
    final ChipThemeData chipThemeBlack = new ChipThemeData.defaults(
      primaryColor: Colors.black,
      brightness: Brightness.dark,
      labelStyle: new ThemeData.fallback().accentTextTheme.body2.copyWith(color: Colors.black),
    );
    final ChipThemeData chipThemeWhite = new ChipThemeData.defaults(
      primaryColor: Colors.white,
      brightness: Brightness.light,
      labelStyle: new ThemeData.fallback().accentTextTheme.body2.copyWith(color: Colors.white),
    ).copyWith(padding: const EdgeInsets.all(2.0), labelPadding: const EdgeInsets.only(top: 8.0, bottom: 8.0));
    final ChipThemeData lerp = ChipThemeData.lerp(chipThemeBlack, chipThemeWhite, 0.5);
    print ('$lerp');
    const Color middleGrey = const Color(0xff7f7f7f);
    expect(lerp.backgroundColor, equals(middleGrey.withAlpha(0x1f)));
    expect(lerp.deleteIconColor, equals(middleGrey.withAlpha(0xde)));
    expect(lerp.disabledColor, equals(middleGrey.withAlpha(0x0c)));
    expect(lerp.selectedColor, equals(middleGrey.withAlpha(0x3d)));
    expect(lerp.secondarySelectedColor, equals(middleGrey.withAlpha(0x3d)));
    expect(lerp.labelPadding, equals(const EdgeInsets.all(4.0)));
    expect(lerp.padding, equals(const EdgeInsets.all(3.0)));
    expect(lerp.shape, equals(const isInstanceOf<StadiumBorder>()));
    expect(lerp.labelStyle.color, equals(middleGrey.withAlpha(0xde)));
    expect(lerp.secondaryLabelStyle.color, equals(middleGrey.withAlpha(0xde)));
    expect(lerp.brightness, equals(Brightness.light));
  });
}
