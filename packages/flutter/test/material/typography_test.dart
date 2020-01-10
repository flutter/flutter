// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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

  test('Typography on Android, Fuchsia defaults to Roboto', () {
    expect(Typography.material2018(platform: TargetPlatform.android).black.headline6.fontFamily, 'Roboto');
    expect(Typography.material2018(platform: TargetPlatform.fuchsia).black.headline6.fontFamily, 'Roboto');
  });

  test('Typography on iOS defaults to the correct SF font family based on size', () {
    // Ref: https://developer.apple.com/ios/human-interface-guidelines/visual-design/typography/
    final Matcher isDisplayFont = predicate((TextStyle s) {
      return s.fontFamily == '.SF UI Display';
    }, 'Uses SF Display font');

    final Matcher isTextFont = predicate((TextStyle s) {
      return s.fontFamily == '.SF UI Text';
    }, 'Uses SF Text font');

    final Typography typography = Typography.material2018(platform: TargetPlatform.iOS);
    for (final TextTheme textTheme in <TextTheme>[typography.black, typography.white]) {
      expect(textTheme.headline1, isDisplayFont);
      expect(textTheme.headline2, isDisplayFont);
      expect(textTheme.headline3, isDisplayFont);
      expect(textTheme.headline4, isDisplayFont);
      expect(textTheme.headline5, isDisplayFont);
      expect(textTheme.headline6, isDisplayFont);
      expect(textTheme.subtitle1, isTextFont);
      expect(textTheme.bodyText1, isTextFont);
      expect(textTheme.bodyText2, isTextFont);
      expect(textTheme.caption, isTextFont);
      expect(textTheme.button, isTextFont);
      expect(textTheme.subtitle2, isTextFont);
      expect(textTheme.overline, isTextFont);
    }
  });

  testWidgets('Typography implements debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    Typography.material2018(
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

    expect(nonDefaultPropertyNames, <String>['black', 'white']);
  });
}
