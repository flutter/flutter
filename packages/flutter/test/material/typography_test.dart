// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TextTheme control test', () {
    Typography typography = new Typography(platform: TargetPlatform.android);
    expect(typography.black, equals(typography.black.copyWith()));
    expect(typography.black, equals(typography.black.apply()));
    expect(typography.black.hashCode, equals(typography.black.copyWith().hashCode));
    expect(typography.black, isNot(equals(typography.white)));
  });

  test('Typography is defined for all target platforms', () {
    for (TargetPlatform platform in TargetPlatform.values) {
      Typography typography = new Typography(platform: platform);
      expect(typography, isNotNull, reason: 'null typography for $platform');
      expect(typography.black, isNotNull, reason: 'null black typography for $platform');
      expect(typography.white, isNotNull, reason: 'null white typography for $platform');
    }
  });

  test('Typography on Android, Fuchsia defaults to Roboto', () {
    expect(new Typography(platform: TargetPlatform.android).black.title.fontFamily, 'Roboto');
    expect(new Typography(platform: TargetPlatform.fuchsia).black.title.fontFamily, 'Roboto');
  });

  test('Typography on iOS defaults to the correct SF font family based on size', () {
    // Ref: https://developer.apple.com/ios/human-interface-guidelines/visual-design/typography/
    Matcher hasCorrectFont = predicate((TextStyle s) {
      return s.fontFamily == (s.fontSize <= 19.0 ? '.SF UI Text' : '.SF UI Display');
    }, 'Uses SF Display font for font sizes over 19.0, otherwise SF Text font');

    Typography typography = new Typography(platform: TargetPlatform.iOS);
    for (TextTheme textTheme in <TextTheme>[typography.black, typography.white]) {
      expect(textTheme.display4, hasCorrectFont);
      expect(textTheme.display3, hasCorrectFont);
      expect(textTheme.display2, hasCorrectFont);
      expect(textTheme.display1, hasCorrectFont);
      expect(textTheme.headline, hasCorrectFont);
      expect(textTheme.title, hasCorrectFont);
      expect(textTheme.subhead, hasCorrectFont);
      expect(textTheme.body2, hasCorrectFont);
      expect(textTheme.body1, hasCorrectFont);
      expect(textTheme.caption, hasCorrectFont);
      expect(textTheme.button, hasCorrectFont);
    }
  });
}
