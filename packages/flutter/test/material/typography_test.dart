// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TextTheme control test', () {
    final Typography typography = new Typography(platform: TargetPlatform.android);
    expect(typography.black, equals(typography.black.copyWith()));
    expect(typography.black, equals(typography.black.apply()));
    expect(typography.black.hashCode, equals(typography.black.copyWith().hashCode));
    expect(typography.black, isNot(equals(typography.white)));
  });

  test('Typography is defined for all target platforms', () {
    for (TargetPlatform platform in TargetPlatform.values) {
      final Typography typography = new Typography(platform: platform);
      expect(typography, isNotNull, reason: 'null typography for $platform');
      expect(typography.black, isNotNull, reason: 'null black typography for $platform');
      expect(typography.white, isNotNull, reason: 'null white typography for $platform');
    }
  });

  test('TextTheme merges properly in the presence of null fields.', () {
    const TextTheme partialTheme = TextTheme(title: TextStyle(color: Color(0xcafefeed)));
    final TextTheme fullTheme = ThemeData.fallback().textTheme.merge(partialTheme);
    expect(fullTheme.title.color, equals(partialTheme.title.color));

    const TextTheme onlyHeadlineAndTitle = TextTheme(
      headline: TextStyle(color: Color(0xcafefeed)),
      title: TextStyle(color: Color(0xbeefcafe)),
    );
    const TextTheme onlyBody1AndTitle = TextTheme(
      body1: TextStyle(color: Color(0xfeedfeed)),
      title: TextStyle(color: Color(0xdeadcafe)),
    );
    TextTheme merged = onlyHeadlineAndTitle.merge(onlyBody1AndTitle);
    expect(merged.body2, isNull);
    expect(merged.body1.color, equals(onlyBody1AndTitle.body1.color));
    expect(merged.headline.color, equals(onlyHeadlineAndTitle.headline.color));
    expect(merged.title.color, equals(onlyBody1AndTitle.title.color));

    merged = onlyHeadlineAndTitle.merge(null);
    expect(merged, equals(onlyHeadlineAndTitle));
  });

  test('Typography on Android, Fuchsia defaults to Roboto', () {
    expect(new Typography(platform: TargetPlatform.android).black.title.fontFamily, 'Roboto');
    expect(new Typography(platform: TargetPlatform.fuchsia).black.title.fontFamily, 'Roboto');
  });

  test('Typography on iOS defaults to the correct SF font family based on size', () {
    // Ref: https://developer.apple.com/ios/human-interface-guidelines/visual-design/typography/
    final Matcher isDisplayFont = predicate((TextStyle s) {
      return s.fontFamily == '.SF UI Display';
    }, 'Uses SF Display font');

    final Matcher isTextFont = predicate((TextStyle s) {
      return s.fontFamily == '.SF UI Text';
    }, 'Uses SF Text font');

    final Typography typography = new Typography(platform: TargetPlatform.iOS);
    for (TextTheme textTheme in <TextTheme>[typography.black, typography.white]) {
      expect(textTheme.display4, isDisplayFont);
      expect(textTheme.display3, isDisplayFont);
      expect(textTheme.display2, isDisplayFont);
      expect(textTheme.display1, isDisplayFont);
      expect(textTheme.headline, isDisplayFont);
      expect(textTheme.title, isDisplayFont);
      expect(textTheme.subhead, isTextFont);
      expect(textTheme.body2, isTextFont);
      expect(textTheme.body1, isTextFont);
      expect(textTheme.caption, isTextFont);
      expect(textTheme.button, isTextFont);
    }
  });
}
