// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';

// Values derived from https://developer.apple.com/design/resources/.
const TextStyle _kDefaultLightTextStyle = TextStyle(
  fontFamily: '.SF Pro Text',
  fontSize: 17.0,
  letterSpacing: -0.41,
  color: CupertinoColors.black,
  decoration: TextDecoration.none,
);

// Values derived from https://developer.apple.com/design/resources/.
const TextStyle _kDefaultDarkTextStyle = TextStyle(
  fontFamily: '.SF Pro Text',
  fontSize: 17.0,
  letterSpacing: -0.41,
  color: CupertinoColors.white,
  decoration: TextDecoration.none,
);

// Values derived from https://developer.apple.com/design/resources/.
// Color comes from the primary color.
const TextStyle _kDefaultActionSheetTextActionStyle = TextStyle(
  fontFamily: '.SF Pro Display',
  inherit: false,
  fontSize: 20.0,
  letterSpacing: 0.38,
);

// Values derived from https://developer.apple.com/design/resources/.
const TextStyle _kDefaultActionSheetTextContentStyle = TextStyle(
  fontFamily: '.SF Pro Text',
  inherit: false,
  fontSize: 13.0,
  letterSpacing: -0.08,
  color: Color(0xFF8F8F8F),
);

// Values derived from https://developer.apple.com/design/resources/.
const TextStyle _kDefaultTabLabelTextStyle = TextStyle(
  fontFamily: '.SF Pro Text',
  inherit: false,
  fontSize: 10.0,
  letterSpacing: -0.24,
  color: CupertinoColors.inactiveGray,
);

const TextStyle _kDefaultMiddleTitleLightTextStyle = TextStyle(
  fontFamily: '.SF Pro Text',
  fontSize: 17.0,
  fontWeight: FontWeight.w600,
  letterSpacing: -0.41,
  color: CupertinoColors.black,
);

const TextStyle _kDefaultMiddleTitleDarkTextStyle = TextStyle(
  fontFamily: '.SF Pro Text',
  fontSize: 17.0,
  fontWeight: FontWeight.w600,
  letterSpacing: -0.41,
  color: CupertinoColors.white,
);

const TextStyle _kDefaultLargeTitleLightTextStyle = TextStyle(
  fontFamily: '.SF Pro Display',
  fontSize: 34.0,
  fontWeight: FontWeight.w700,
  letterSpacing: 0.41,
  color: CupertinoColors.black,
);

const TextStyle _kDefaultLargeTitleDarkTextStyle = TextStyle(
  fontFamily: '.SF Pro Display',
  fontSize: 34.0,
  fontWeight: FontWeight.w700,
  letterSpacing: 0.41,
  color: CupertinoColors.white,
);

@immutable
class CupertinoTextTheme extends Diagnosticable {
  factory CupertinoTextTheme({
    Color primaryColor,
    bool isDark,
    TextStyle textStyle,
    TextStyle actionTextStyle,
    TextStyle actionSheetActionTextStyle,
    TextStyle actionSheetContentTextStyle,
    TextStyle tabLabelTextStyle,
    TextStyle navTitleTextStyle,
    TextStyle navLargeTitleTextStyle,
    TextStyle navActionTextStyle,
  }) {
    textStyle ??= isDark ? _kDefaultDarkTextStyle : _kDefaultLightTextStyle;
    actionTextStyle ??= _kDefaultLightTextStyle.copyWith(
      color: primaryColor,
    );
    actionSheetActionTextStyle ??= _kDefaultActionSheetTextActionStyle.copyWith(
      color: primaryColor,
    );
    actionSheetContentTextStyle ??= _kDefaultActionSheetTextContentStyle;
    tabLabelTextStyle ??= _kDefaultTabLabelTextStyle;
    navTitleTextStyle ??= isDark ? _kDefaultMiddleTitleDarkTextStyle : _kDefaultMiddleTitleLightTextStyle;
    navLargeTitleTextStyle ??= isDark ? _kDefaultLargeTitleDarkTextStyle : _kDefaultLargeTitleLightTextStyle;
    navActionTextStyle ??= _kDefaultLightTextStyle.copyWith(
      color: primaryColor,
    );
    return CupertinoTextTheme._(
      textStyle,
      actionTextStyle,
      actionSheetContentTextStyle,
      actionSheetActionTextStyle,
      tabLabelTextStyle,
      navTitleTextStyle,
      navLargeTitleTextStyle,
      navActionTextStyle,
    );
  }

  CupertinoTextTheme._(
    this.textStyle,
    this.actionTextStyle,
    this.actionSheetContentTextStyle,
    this.actionSheetActionTextStyle,
    this.tabLabelTextStyle,
    this.navTitleTextStyle,
    this.navLargeTitleTextStyle,
    this.navActionTextStyle,
  );

  final TextStyle textStyle;
  final TextStyle actionTextStyle;
  final TextStyle actionSheetContentTextStyle;
  final TextStyle actionSheetActionTextStyle;
  final TextStyle tabLabelTextStyle;
  final TextStyle navTitleTextStyle;
  final TextStyle navLargeTitleTextStyle;
  final TextStyle navActionTextStyle;

  CupertinoTextTheme copyWith({
    TextStyle textStyle,
    TextStyle actionTextStyle,
    TextStyle actionSheetActionTextStyle,
    TextStyle actionSheetContentTextStyle,
    TextStyle tabLabelTextStyle,
    TextStyle navTitleTextStyle,
    TextStyle navLargeTitleTextStyle,
    TextStyle navActionTextStyle,
  }) {
    return CupertinoTextTheme._(
      textStyle ?? this.textStyle,
      actionTextStyle ?? this.actionTextStyle,
      actionSheetContentTextStyle ?? this.actionSheetContentTextStyle,
      actionSheetActionTextStyle ?? this.actionSheetContentTextStyle,
      tabLabelTextStyle ?? this.tabLabelTextStyle,
      navTitleTextStyle ?? this.navTitleTextStyle,
      navLargeTitleTextStyle ?? this.navLargeTitleTextStyle,
      navActionTextStyle ?? this.navActionTextStyle,
    );
  }

  CupertinoTextTheme merge(CupertinoTextTheme other) {
    if (other == null)
      return this;
    return copyWith(
      textStyle: textStyle?.merge(other.textStyle) ?? other.textStyle,
      actionTextStyle: actionTextStyle?.merge(other.actionTextStyle) ?? other.actionTextStyle,
      actionSheetContentTextStyle: actionSheetContentTextStyle?.merge(other.actionSheetContentTextStyle) ?? other.actionSheetContentTextStyle,
      actionSheetActionTextStyle: actionSheetActionTextStyle?.merge(other.actionSheetActionTextStyle) ?? other.actionSheetContentTextStyle,
      tabLabelTextStyle: tabLabelTextStyle?.merge(other.tabLabelTextStyle) ?? other.tabLabelTextStyle,
      navTitleTextStyle: navTitleTextStyle?.merge(other.navTitleTextStyle) ?? other.navTitleTextStyle,
      navLargeTitleTextStyle: navLargeTitleTextStyle?.merge(other.navLargeTitleTextStyle) ?? other.navLargeTitleTextStyle,
      navActionTextStyle: navActionTextStyle?.merge(other.navActionTextStyle) ?? other.navActionTextStyle,
    );
  }
}
