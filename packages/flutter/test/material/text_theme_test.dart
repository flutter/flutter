// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TextTheme copyWith apply, merge basics with const TextTheme()', () {
    expect(const TextTheme(), equals(const TextTheme().copyWith()));
    expect(const TextTheme(), equals(const TextTheme().apply()));
    expect(const TextTheme(), equals(const TextTheme().merge(null)));
    expect(const TextTheme().hashCode, equals(const TextTheme().copyWith().hashCode));
    expect(const TextTheme(), equals(const TextTheme().copyWith()));
  });

  test('TextTheme copyWith apply, merge basics with Typography.black', () {
    final Typography typography = Typography(platform: TargetPlatform.android);
    expect(typography.black, equals(typography.black.copyWith()));
    expect(typography.black, equals(typography.black.apply()));
    expect(typography.black, equals(typography.black.merge(null)));
    expect(typography.black, equals(const TextTheme().merge(typography.black)));
    expect(typography.black, equals(typography.black.merge(typography.black)));
    expect(typography.white, equals(typography.black.merge(typography.white)));
    expect(typography.black.hashCode, equals(typography.black.copyWith().hashCode));
    expect(typography.black, isNot(equals(typography.white)));
  });

  test('TextTheme copyWith', () {
    final Typography typography = Typography(platform: TargetPlatform.android);
    final TextTheme whiteCopy = typography.black.copyWith(
      display4: typography.white.display4,
      display3: typography.white.display3,
      display2: typography.white.display2,
      display1: typography.white.display1,
      headline: typography.white.headline,
      title: typography.white.title,
      subhead: typography.white.subhead,
      body2: typography.white.body2,
      body1: typography.white.body1,
      caption: typography.white.caption,
      button: typography.white.button,
      subtitle: typography.white.subtitle,
      overline: typography.white.overline,
    );
    expect(typography.white, equals(whiteCopy));
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

  test('TextTheme apply', () {
    // The `displayColor` is applied to [display4], [display3], [display2],
    // [display1], and [caption]. The `bodyColor` is applied to the remaining
    // text styles.
    const Color displayColor = Color(1);
    const Color bodyColor = Color(2);
    const String fontFamily = 'fontFamily';
    const Color decorationColor = Color(3);
    const TextDecorationStyle decorationStyle = TextDecorationStyle.dashed;
    final TextDecoration decoration = TextDecoration.combine(<TextDecoration>[
      TextDecoration.underline,
      TextDecoration.lineThrough
    ]);

    final Typography typography = Typography(platform: TargetPlatform.android);
    final TextTheme theme = typography.black.apply(
      fontFamily: fontFamily,
      displayColor: displayColor,
      bodyColor: bodyColor,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
    );

    expect(theme.display4.color, displayColor);
    expect(theme.display3.color, displayColor);
    expect(theme.display2.color, displayColor);
    expect(theme.display1.color, displayColor);
    expect(theme.caption.color, displayColor);
    expect(theme.headline.color, bodyColor);
    expect(theme.title.color, bodyColor);
    expect(theme.subhead.color, bodyColor);
    expect(theme.body2.color, bodyColor);
    expect(theme.body1.color, bodyColor);
    expect(theme.button.color, bodyColor);
    expect(theme.subtitle.color, bodyColor);
    expect(theme.overline.color, bodyColor);

    final List<TextStyle> themeStyles = <TextStyle>[
      theme.display4,
      theme.display3,
      theme.display2,
      theme.display1,
      theme.caption,
      theme.headline,
      theme.title,
      theme.subhead,
      theme.body2,
      theme.body1,
      theme.button,
      theme.subtitle,
      theme.overline,
    ];
    expect(themeStyles.every((TextStyle style) => style.fontFamily == fontFamily), true);
    expect(themeStyles.every((TextStyle style) => style.decorationColor == decorationColor), true);
    expect(themeStyles.every((TextStyle style) => style.decorationStyle == decorationStyle), true);
    expect(themeStyles.every((TextStyle style) => style.decoration == decoration), true);
  });

  test('TextTheme apply fontSizeFactor fontSizeDelta', () {
    final Typography typography = Typography(platform: TargetPlatform.android);
    final TextTheme baseTheme = Typography.englishLike2014.merge(typography.black);
    final TextTheme sizeTheme = baseTheme.apply(
      fontSizeFactor: 2.0,
      fontSizeDelta: 5.0,
    );

    expect(sizeTheme.display4.fontSize, baseTheme.display4.fontSize * 2.0 + 5.0);
    expect(sizeTheme.display3.fontSize, baseTheme.display3.fontSize * 2.0 + 5.0);
    expect(sizeTheme.display2.fontSize, baseTheme.display2.fontSize * 2.0 + 5.0);
    expect(sizeTheme.display1.fontSize, baseTheme.display1.fontSize * 2.0 + 5.0);
    expect(sizeTheme.caption.fontSize, baseTheme.caption.fontSize * 2.0 + 5.0);
    expect(sizeTheme.headline.fontSize, baseTheme.headline.fontSize * 2.0 + 5.0);
    expect(sizeTheme.title.fontSize, baseTheme.title.fontSize * 2.0 + 5.0);
    expect(sizeTheme.subhead.fontSize, baseTheme.subhead.fontSize * 2.0 + 5.0);
    expect(sizeTheme.body2.fontSize, baseTheme.body2.fontSize * 2.0 + 5.0);
    expect(sizeTheme.body1.fontSize, baseTheme.body1.fontSize * 2.0 + 5.0);
    expect(sizeTheme.button.fontSize, baseTheme.button.fontSize * 2.0 + 5.0);
    expect(sizeTheme.subtitle.fontSize, baseTheme.subtitle.fontSize * 2.0 + 5.0);
    expect(sizeTheme.overline.fontSize, baseTheme.overline.fontSize * 2.0 + 5.0);
  });

}
