// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Typography is defined for all target platforms', () {
    for (TargetPlatform platform in TargetPlatform.values) {
      final Typography typography = Typography(platform: platform);
      expect(typography, isNotNull, reason: 'null typography for $platform');
      expect(typography.black, isNotNull, reason: 'null black typography for $platform');
      expect(typography.white, isNotNull, reason: 'null white typography for $platform');
    }
  });

  test('Typography on Android, Fuchsia defaults to Roboto', () {
    expect(Typography(platform: TargetPlatform.android).black.title.fontFamily, 'Roboto');
    expect(Typography(platform: TargetPlatform.fuchsia).black.title.fontFamily, 'Roboto');
  });

  test('Typography on iOS defaults to the correct SF font family based on size', () {
    // Ref: https://developer.apple.com/ios/human-interface-guidelines/visual-design/typography/
    final Matcher isDisplayFont = predicate((TextStyle s) {
      return s.fontFamily == '.SF UI Display';
    }, 'Uses SF Display font');

    final Matcher isTextFont = predicate((TextStyle s) {
      return s.fontFamily == '.SF UI Text';
    }, 'Uses SF Text font');

    final Typography typography = Typography(platform: TargetPlatform.iOS);
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
      expect(textTheme.subtitle, isTextFont);
      expect(textTheme.overline, isTextFont);
    }
  });
}
