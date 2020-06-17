// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Typography is defined for all target platforms', () {
    for (final TargetPlatform platform in TargetPlatform.values) {
      final Typography typography = Typography.material2018(platform: platform);
      expect(typography, isNotNull, reason: 'null typography for $platform');
      expect(typography.black, isNotNull, reason: 'null black typography for $platform');
      expect(typography.white, isNotNull, reason: 'null white typography for $platform');
    }
  });

  test('Typography on non-Apple platforms defaults to the correct font', () {
    expect(Typography.material2018(platform: TargetPlatform.android).black.headline6.fontFamily, 'Roboto');
    expect(Typography.material2018(platform: TargetPlatform.fuchsia).black.headline6.fontFamily, 'Roboto');
    expect(Typography.material2018(platform: TargetPlatform.linux).black.headline6.fontFamily, 'Roboto');
    expect(Typography.material2018(platform: TargetPlatform.linux).black.headline6.fontFamilyFallback, <String>['Ubuntu', 'Cantarell', 'DejaVu Sans', 'Liberation Sans', 'Arial']);
    expect(Typography.material2018(platform: TargetPlatform.windows).black.headline6.fontFamily, 'Segoe UI');
    expect(Typography.material2018(platform: TargetPlatform.android).white.headline6.fontFamily, 'Roboto');
    expect(Typography.material2018(platform: TargetPlatform.fuchsia).white.headline6.fontFamily, 'Roboto');
    expect(Typography.material2018(platform: TargetPlatform.linux).white.headline6.fontFamily, 'Roboto');
    expect(Typography.material2018(platform: TargetPlatform.linux).white.headline6.fontFamilyFallback, <String>['Ubuntu', 'Cantarell', 'DejaVu Sans', 'Liberation Sans', 'Arial']);
    expect(Typography.material2018(platform: TargetPlatform.windows).white.headline6.fontFamily, 'Segoe UI');
  });

  // Ref: https://developer.apple.com/ios/human-interface-guidelines/visual-design/typography/
  final Matcher isSanFranciscoDisplayFont = predicate((TextStyle s) {
    return s.fontFamily == '.SF UI Display';
  }, 'Uses SF Display font');

  final Matcher isSanFranciscoTextFont = predicate((TextStyle s) {
    return s.fontFamily == '.SF UI Text';
  }, 'Uses SF Text font');

  test('Typography on iOS defaults to the correct SF font family based on size', () {
    final Typography typography = Typography.material2018(platform: TargetPlatform.iOS);
    for (final TextTheme textTheme in <TextTheme>[typography.black, typography.white]) {
      expect(textTheme.headline1, isSanFranciscoDisplayFont);
      expect(textTheme.headline2, isSanFranciscoDisplayFont);
      expect(textTheme.headline3, isSanFranciscoDisplayFont);
      expect(textTheme.headline4, isSanFranciscoDisplayFont);
      expect(textTheme.headline5, isSanFranciscoDisplayFont);
      expect(textTheme.headline6, isSanFranciscoDisplayFont);
      expect(textTheme.subtitle1, isSanFranciscoTextFont);
      expect(textTheme.bodyText1, isSanFranciscoTextFont);
      expect(textTheme.bodyText2, isSanFranciscoTextFont);
      expect(textTheme.caption, isSanFranciscoTextFont);
      expect(textTheme.button, isSanFranciscoTextFont);
      expect(textTheme.subtitle2, isSanFranciscoTextFont);
      expect(textTheme.overline, isSanFranciscoTextFont);
    }
  });

  test('Typography on macOS defaults to the correct SF font family based on size', () {
    final Typography typography = Typography.material2018(platform: TargetPlatform.macOS);
    for (final TextTheme textTheme in <TextTheme>[typography.black, typography.white]) {
      expect(textTheme.headline1, isSanFranciscoDisplayFont);
      expect(textTheme.headline2, isSanFranciscoDisplayFont);
      expect(textTheme.headline3, isSanFranciscoDisplayFont);
      expect(textTheme.headline4, isSanFranciscoDisplayFont);
      expect(textTheme.headline5, isSanFranciscoDisplayFont);
      expect(textTheme.headline6, isSanFranciscoDisplayFont);
      expect(textTheme.subtitle1, isSanFranciscoTextFont);
      expect(textTheme.bodyText1, isSanFranciscoTextFont);
      expect(textTheme.bodyText2, isSanFranciscoTextFont);
      expect(textTheme.caption, isSanFranciscoTextFont);
      expect(textTheme.button, isSanFranciscoTextFont);
      expect(textTheme.subtitle2, isSanFranciscoTextFont);
      expect(textTheme.overline, isSanFranciscoTextFont);
    }
  });

  testWidgets('Typography implements debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    Typography.material2014(
      platform: TargetPlatform.android,
      black: Typography.blackCupertino,
      white: Typography.whiteCupertino,
      englishLike: Typography.englishLike2018,
      dense: Typography.dense2018,
      tall: Typography.tall2018,
    ).debugFillProperties(builder);

    final List<String> nonDefaultPropertyNames = builder.properties
      .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
      .map((DiagnosticsNode node) => node.name).toList();

    expect(nonDefaultPropertyNames, <String>['black', 'white', 'englishLike', 'dense', 'tall']);
  });

  test('englishLike2018 TextTheme matches Material Design spec', () {
    // Check the default material text theme against the style values
    // shown https://material.io/design/typography/#type-scale.

    final TextTheme theme = Typography.englishLike2018.merge(Typography.blackMountainView);
    const FontWeight light = FontWeight.w300;
    const FontWeight regular = FontWeight.w400;
    const FontWeight medium = FontWeight.w500;

    // H1 Roboto light 96 -1.5
    expect(theme.headline1.fontFamily, 'Roboto');
    expect(theme.headline1.fontWeight, light);
    expect(theme.headline1.fontSize, 96);
    expect(theme.headline1.letterSpacing, -1.5);

    // H2 Roboto light 60 -0.5
    expect(theme.headline2.fontFamily, 'Roboto');
    expect(theme.headline2.fontWeight, light);
    expect(theme.headline2.fontSize, 60);
    expect(theme.headline2.letterSpacing, -0.5);

    // H3 Roboto regular 48 0
    expect(theme.headline3.fontFamily, 'Roboto');
    expect(theme.headline3.fontWeight, regular);
    expect(theme.headline3.fontSize, 48);
    expect(theme.headline3.letterSpacing, 0);

    // H4 Roboto regular 34 0.25
    expect(theme.headline4.fontFamily, 'Roboto');
    expect(theme.headline4.fontWeight, regular);
    expect(theme.headline4.fontSize, 34);
    expect(theme.headline4.letterSpacing, 0.25);

    // H5 Roboto regular 24 0
    expect(theme.headline5.fontFamily, 'Roboto');
    expect(theme.headline5.fontWeight, regular);
    expect(theme.headline5.fontSize, 24);
    expect(theme.headline5.letterSpacing, 0);

    // H6 Roboto medium 20 0.15
    expect(theme.headline6.fontFamily, 'Roboto');
    expect(theme.headline6.fontWeight, medium);
    expect(theme.headline6.fontSize, 20);
    expect(theme.headline6.letterSpacing, 0.15);

    // Subtitle1 Roboto regular 16 0.15
    expect(theme.subtitle1.fontFamily, 'Roboto');
    expect(theme.subtitle1.fontWeight, regular);
    expect(theme.subtitle1.fontSize, 16);
    expect(theme.subtitle1.letterSpacing, 0.15);

    // Subtitle2 Roboto medium 14 0.1
    expect(theme.subtitle2.fontFamily, 'Roboto');
    expect(theme.subtitle2.fontWeight, medium);
    expect(theme.subtitle2.fontSize, 14);
    expect(theme.subtitle2.letterSpacing, 0.1);

    // Body1 Roboto regular 16 0.5
    expect(theme.bodyText1.fontFamily, 'Roboto');
    expect(theme.bodyText1.fontWeight, regular);
    expect(theme.bodyText1.fontSize, 16);
    expect(theme.bodyText1.letterSpacing, 0.5);

    // Body2 Roboto regular 14 0.25
    expect(theme.bodyText2.fontFamily, 'Roboto');
    expect(theme.bodyText2.fontWeight, regular);
    expect(theme.bodyText2.fontSize, 14);
    expect(theme.bodyText2.letterSpacing, 0.25);

    // BUTTON Roboto medium 14 1.25
    expect(theme.button.fontFamily, 'Roboto');
    expect(theme.button.fontWeight, medium);
    expect(theme.button.fontSize, 14);
    expect(theme.button.letterSpacing, 1.25);

    // Caption Roboto regular 12 0.4
    expect(theme.caption.fontFamily, 'Roboto');
    expect(theme.caption.fontWeight, regular);
    expect(theme.caption.fontSize, 12);
    expect(theme.caption.letterSpacing, 0.4);

    // OVERLINE Roboto regular 10 1.5
    expect(theme.overline.fontFamily, 'Roboto');
    expect(theme.overline.fontWeight, regular);
    expect(theme.overline.fontSize, 10);
    expect(theme.overline.letterSpacing, 1.5);
  });
}
