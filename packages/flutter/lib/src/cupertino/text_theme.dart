// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';

// Values derived from https://developer.apple.com/design/resources/.
const TextStyle _kDefaultLightTextStyle = TextStyle(
  inherit: false,
  fontFamily: '.SF Pro Text',
  fontSize: 17.0,
  letterSpacing: -0.41,
  color: CupertinoColors.black,
  decoration: TextDecoration.none,
);

// Values derived from https://developer.apple.com/design/resources/.
const TextStyle _kDefaultDarkTextStyle = TextStyle(
  inherit: false,
  fontFamily: '.SF Pro Text',
  fontSize: 17.0,
  letterSpacing: -0.41,
  color: CupertinoColors.white,
  decoration: TextDecoration.none,
);

// Values derived from https://developer.apple.com/design/resources/.
const TextStyle _kDefaultActionTextStyle = TextStyle(
  inherit: false,
  fontFamily: '.SF Pro Text',
  fontSize: 17.0,
  letterSpacing: -0.41,
  color: CupertinoColors.activeBlue,
  decoration: TextDecoration.none,
);

// Values derived from https://developer.apple.com/design/resources/.
const TextStyle _kDefaultTabLabelTextStyle = TextStyle(
  inherit: false,
  fontFamily: '.SF Pro Text',
  fontSize: 10.0,
  letterSpacing: -0.24,
  color: CupertinoColors.inactiveGray,
);

const TextStyle _kDefaultMiddleTitleLightTextStyle = TextStyle(
  inherit: false,
  fontFamily: '.SF Pro Text',
  fontSize: 17.0,
  fontWeight: FontWeight.w600,
  letterSpacing: -0.41,
  color: CupertinoColors.black,
);

const TextStyle _kDefaultMiddleTitleDarkTextStyle = TextStyle(
  inherit: false,
  fontFamily: '.SF Pro Text',
  fontSize: 17.0,
  fontWeight: FontWeight.w600,
  letterSpacing: -0.41,
  color: CupertinoColors.white,
);

const TextStyle _kDefaultLargeTitleLightTextStyle = TextStyle(
  inherit: false,
  fontFamily: '.SF Pro Display',
  fontSize: 34.0,
  fontWeight: FontWeight.w700,
  letterSpacing: 0.41,
  color: CupertinoColors.black,
);

const TextStyle _kDefaultLargeTitleDarkTextStyle = TextStyle(
  inherit: false,
  fontFamily: '.SF Pro Display',
  fontSize: 34.0,
  fontWeight: FontWeight.w700,
  letterSpacing: 0.41,
  color: CupertinoColors.white,
);

/// Cupertino typography theme in a [CupertinoThemeData].
@immutable
class CupertinoTextTheme extends Diagnosticable {
  /// Create a [CupertinoTextTheme].
  ///
  /// The [primaryColor] and [isLight] parameters are only used to derive
  /// text style defaults when unspecified and themselves default to
  /// [CupertinoColors.activeBlue] and [true] when unspecified.
  ///
  /// Other [TextStyle] parameters default to default iOS text styles based on
  /// the present [primaryColor] and [isLight] when unspecified.
  const CupertinoTextTheme({
    Color primaryColor,
    bool isLight,
    TextStyle textStyle,
    TextStyle actionTextStyle,
    TextStyle tabLabelTextStyle,
    TextStyle navTitleTextStyle,
    TextStyle navLargeTitleTextStyle,
    TextStyle navActionTextStyle,
  }) : _primaryColor = primaryColor ?? CupertinoColors.activeBlue,
       _isLight = isLight ?? true,
       _textStyle = textStyle,
       _actionTextStyle = actionTextStyle,
       _tabLabelTextStyle = tabLabelTextStyle,
       _navTitleTextStyle = navTitleTextStyle,
       _navLargeTitleTextStyle = navLargeTitleTextStyle,
       _navActionTextStyle = navActionTextStyle;

  final Color _primaryColor;
  final bool _isLight;

  final TextStyle _textStyle;
  /// Typography of general text content for Cupertino widgets.
  TextStyle get textStyle => _textStyle ?? (_isLight ? _kDefaultLightTextStyle : _kDefaultDarkTextStyle);

  final TextStyle _actionTextStyle;
  /// Typography of interactive text content such as text in a button without background.
  TextStyle get actionTextStyle {
    return _actionTextStyle ?? _kDefaultActionTextStyle.copyWith(
      color: _primaryColor,
    );
  }

  final TextStyle _tabLabelTextStyle;
  /// Typography of unselected tabs.
  TextStyle get tabLabelTextStyle => _tabLabelTextStyle ?? _kDefaultTabLabelTextStyle;

  final TextStyle _navTitleTextStyle;
  /// Typography of titles in standard navigation bars.
  TextStyle get navTitleTextStyle {
    return _navTitleTextStyle ??
        (_isLight ? _kDefaultMiddleTitleLightTextStyle : _kDefaultMiddleTitleDarkTextStyle);
  }

  final TextStyle _navLargeTitleTextStyle;
  /// Typography of large titles in sliver navigation bars.
  TextStyle get navLargeTitleTextStyle {
    return _navLargeTitleTextStyle ??
        (_isLight ? _kDefaultLargeTitleLightTextStyle : _kDefaultLargeTitleDarkTextStyle);
  }

  final TextStyle _navActionTextStyle;
  /// Typography of interative text content in navigation bars.
  TextStyle get navActionTextStyle {
    return _navActionTextStyle ?? _kDefaultActionTextStyle.copyWith(
      color: _primaryColor,
    );
  }

  /// Returns a copy of the current [CupertinoTextTheme] instance with
  /// specified overrides.
  CupertinoTextTheme copyWith({
    Color primaryColor,
    bool isLight,
    TextStyle textStyle,
    TextStyle actionTextStyle,
    TextStyle tabLabelTextStyle,
    TextStyle navTitleTextStyle,
    TextStyle navLargeTitleTextStyle,
    TextStyle navActionTextStyle,
  }) {
    return CupertinoTextTheme(
      primaryColor: primaryColor ?? _primaryColor,
      isLight: isLight ?? _isLight,
      textStyle: textStyle ?? _textStyle,
      actionTextStyle: actionTextStyle ?? _actionTextStyle,
      tabLabelTextStyle: tabLabelTextStyle ?? _tabLabelTextStyle,
      navTitleTextStyle: navTitleTextStyle ?? _navTitleTextStyle,
      navLargeTitleTextStyle: navLargeTitleTextStyle ?? _navLargeTitleTextStyle,
      navActionTextStyle: navActionTextStyle ?? _navActionTextStyle,
    );
  }
}
