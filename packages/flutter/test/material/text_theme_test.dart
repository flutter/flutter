// Copyright 2014 The Flutter Authors. All rights reserved.
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
    final Typography typography = Typography.material2018(platform: TargetPlatform.android);
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
    final Typography typography = Typography.material2018(platform: TargetPlatform.android);
    final TextTheme whiteCopy = typography.black.copyWith(
      headline1: typography.white.headline1,
      headline2: typography.white.headline2,
      headline3: typography.white.headline3,
      headline4: typography.white.headline4,
      headline5: typography.white.headline5,
      headline6: typography.white.headline6,
      subtitle1: typography.white.subtitle1,
      bodyText1: typography.white.bodyText1,
      bodyText2: typography.white.bodyText2,
      caption: typography.white.caption,
      button: typography.white.button,
      subtitle2: typography.white.subtitle2,
      overline: typography.white.overline,
    );
    expect(typography.white, equals(whiteCopy));
  });


  test('TextTheme merges properly in the presence of null fields.', () {
    const TextTheme partialTheme = TextTheme(headline6: TextStyle(color: Color(0xcafefeed)));
    final TextTheme fullTheme = ThemeData.fallback().textTheme.merge(partialTheme);
    expect(fullTheme.headline6!.color, equals(partialTheme.headline6!.color));

    const TextTheme onlyHeadlineAndTitle = TextTheme(
      headline5: TextStyle(color: Color(0xcafefeed)),
      headline6: TextStyle(color: Color(0xbeefcafe)),
    );
    const TextTheme onlyBody1AndTitle = TextTheme(
      bodyText2: TextStyle(color: Color(0xfeedfeed)),
      headline6: TextStyle(color: Color(0xdeadcafe)),
    );
    TextTheme merged = onlyHeadlineAndTitle.merge(onlyBody1AndTitle);
    expect(merged.bodyText1, isNull);
    expect(merged.bodyText2!.color, equals(onlyBody1AndTitle.bodyText2!.color));
    expect(merged.headline5!.color, equals(onlyHeadlineAndTitle.headline5!.color));
    expect(merged.headline6!.color, equals(onlyBody1AndTitle.headline6!.color));

    merged = onlyHeadlineAndTitle.merge(null);
    expect(merged, equals(onlyHeadlineAndTitle));
  });

  test('TextTheme apply', () {
    // The `displayColor` is applied to [headline1], [headline2], [headline3],
    // [headline4], and [caption]. The `bodyColor` is applied to the remaining
    // text styles.
    const Color displayColor = Color(0x00000001);
    const Color bodyColor = Color(0x00000002);
    const String fontFamily = 'fontFamily';
    const Color decorationColor = Color(0x00000003);
    const TextDecorationStyle decorationStyle = TextDecorationStyle.dashed;
    final TextDecoration decoration = TextDecoration.combine(<TextDecoration>[
      TextDecoration.underline,
      TextDecoration.lineThrough,
    ]);

    final Typography typography = Typography.material2018(platform: TargetPlatform.android);
    final TextTheme theme = typography.black.apply(
      fontFamily: fontFamily,
      displayColor: displayColor,
      bodyColor: bodyColor,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
    );

    expect(theme.headline1!.color, displayColor);
    expect(theme.headline2!.color, displayColor);
    expect(theme.headline3!.color, displayColor);
    expect(theme.headline4!.color, displayColor);
    expect(theme.caption!.color, displayColor);
    expect(theme.headline5!.color, bodyColor);
    expect(theme.headline6!.color, bodyColor);
    expect(theme.subtitle1!.color, bodyColor);
    expect(theme.bodyText1!.color, bodyColor);
    expect(theme.bodyText2!.color, bodyColor);
    expect(theme.button!.color, bodyColor);
    expect(theme.subtitle2!.color, bodyColor);
    expect(theme.overline!.color, bodyColor);

    final List<TextStyle> themeStyles = <TextStyle>[
      theme.headline1!,
      theme.headline2!,
      theme.headline3!,
      theme.headline4!,
      theme.caption!,
      theme.headline5!,
      theme.headline6!,
      theme.subtitle1!,
      theme.bodyText1!,
      theme.bodyText2!,
      theme.button!,
      theme.subtitle2!,
      theme.overline!,
    ];
    expect(themeStyles.every((TextStyle style) => style.fontFamily == fontFamily), true);
    expect(themeStyles.every((TextStyle style) => style.decorationColor == decorationColor), true);
    expect(themeStyles.every((TextStyle style) => style.decorationStyle == decorationStyle), true);
    expect(themeStyles.every((TextStyle style) => style.decoration == decoration), true);
  });

  test('TextTheme apply fontSizeFactor fontSizeDelta', () {
    final Typography typography = Typography.material2018(platform: TargetPlatform.android);
    final TextTheme baseTheme = Typography.englishLike2018.merge(typography.black);
    final TextTheme sizeTheme = baseTheme.apply(
      fontSizeFactor: 2.0,
      fontSizeDelta: 5.0,
    );

    expect(sizeTheme.headline1!.fontSize, baseTheme.headline1!.fontSize! * 2.0 + 5.0);
    expect(sizeTheme.headline2!.fontSize, baseTheme.headline2!.fontSize! * 2.0 + 5.0);
    expect(sizeTheme.headline3!.fontSize, baseTheme.headline3!.fontSize! * 2.0 + 5.0);
    expect(sizeTheme.headline4!.fontSize, baseTheme.headline4!.fontSize! * 2.0 + 5.0);
    expect(sizeTheme.caption!.fontSize, baseTheme.caption!.fontSize! * 2.0 + 5.0);
    expect(sizeTheme.headline5!.fontSize, baseTheme.headline5!.fontSize! * 2.0 + 5.0);
    expect(sizeTheme.headline6!.fontSize, baseTheme.headline6!.fontSize! * 2.0 + 5.0);
    expect(sizeTheme.subtitle1!.fontSize, baseTheme.subtitle1!.fontSize! * 2.0 + 5.0);
    expect(sizeTheme.bodyText1!.fontSize, baseTheme.bodyText1!.fontSize! * 2.0 + 5.0);
    expect(sizeTheme.bodyText2!.fontSize, baseTheme.bodyText2!.fontSize! * 2.0 + 5.0);
    expect(sizeTheme.button!.fontSize, baseTheme.button!.fontSize! * 2.0 + 5.0);
    expect(sizeTheme.subtitle2!.fontSize, baseTheme.subtitle2!.fontSize! * 2.0 + 5.0);
    expect(sizeTheme.overline!.fontSize, baseTheme.overline!.fontSize! * 2.0 + 5.0);
  });

  test('TextTheme lerp with second parameter null', () {
    final TextTheme theme = Typography.material2018().black;
    final TextTheme lerped = TextTheme.lerp(theme, null, 0.25);

    expect(lerped.headline1, TextStyle.lerp(theme.headline1, null, 0.25));
    expect(lerped.headline2, TextStyle.lerp(theme.headline2, null, 0.25));
    expect(lerped.headline3, TextStyle.lerp(theme.headline3, null, 0.25));
    expect(lerped.headline4, TextStyle.lerp(theme.headline4, null, 0.25));
    expect(lerped.caption, TextStyle.lerp(theme.caption, null, 0.25));
    expect(lerped.headline5, TextStyle.lerp(theme.headline5, null, 0.25));
    expect(lerped.headline6, TextStyle.lerp(theme.headline6, null, 0.25));
    expect(lerped.subtitle1, TextStyle.lerp(theme.subtitle1, null, 0.25));
    expect(lerped.bodyText1, TextStyle.lerp(theme.bodyText1, null, 0.25));
    expect(lerped.bodyText2, TextStyle.lerp(theme.bodyText2, null, 0.25));
    expect(lerped.button, TextStyle.lerp(theme.button, null, 0.25));
    expect(lerped.subtitle2, TextStyle.lerp(theme.subtitle2, null, 0.25));
    expect(lerped.overline, TextStyle.lerp(theme.overline, null, 0.25));
  });

  test('TextTheme lerp with first parameter null', () {
    final TextTheme theme = Typography.material2018().black;
    final TextTheme lerped = TextTheme.lerp(null, theme, 0.25);

    expect(lerped.headline1, TextStyle.lerp(null, theme.headline1, 0.25));
    expect(lerped.headline2, TextStyle.lerp(null, theme.headline2, 0.25));
    expect(lerped.headline3, TextStyle.lerp(null, theme.headline3, 0.25));
    expect(lerped.headline4, TextStyle.lerp(null, theme.headline4, 0.25));
    expect(lerped.caption, TextStyle.lerp(null, theme.caption, 0.25));
    expect(lerped.headline5, TextStyle.lerp(null, theme.headline5, 0.25));
    expect(lerped.headline6, TextStyle.lerp(null, theme.headline6, 0.25));
    expect(lerped.subtitle1, TextStyle.lerp(null, theme.subtitle1, 0.25));
    expect(lerped.bodyText1, TextStyle.lerp(null, theme.bodyText1, 0.25));
    expect(lerped.bodyText2, TextStyle.lerp(null, theme.bodyText2, 0.25));
    expect(lerped.button, TextStyle.lerp(null, theme.button, 0.25));
    expect(lerped.subtitle2, TextStyle.lerp(null, theme.subtitle2, 0.25));
    expect(lerped.overline, TextStyle.lerp(null, theme.overline, 0.25));
  });

  test('TextTheme lerp with null parameters', () {
    final TextTheme lerped = TextTheme.lerp(null, null, 0.25);
    expect(lerped.headline1, null);
    expect(lerped.headline2, null);
    expect(lerped.headline3, null);
    expect(lerped.headline4, null);
    expect(lerped.caption, null);
    expect(lerped.headline5, null);
    expect(lerped.headline6, null);
    expect(lerped.subtitle1, null);
    expect(lerped.bodyText1, null);
    expect(lerped.bodyText2, null);
    expect(lerped.button, null);
    expect(lerped.subtitle2, null);
    expect(lerped.overline, null);
  });
}
