// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show Brightness;
import 'package:flutter/widgets.dart';

import 'colors.dart';

// Please update _DefaultCupertinoTextThemeData and _DefaultCupertinoTextThemeData
// accordingly after changing the default color here, as their implementation
// depends on the default value of the color field.
//
// Values derived from https://developer.apple.com/design/resources/.
const TextStyle _kDefaultTextStyle = TextStyle(
  inherit: false,
  fontFamily: '.SF Pro Text',
  fontSize: 17.0,
  letterSpacing: -0.41,
  color: CupertinoColors.label,
  decoration: TextDecoration.none,
);

// Please update _DefaultCupertinoTextThemeData and _DefaultCupertinoTextThemeData
// accordingly after changing the default color here, as their implementation
// depends on the default value of the color field.
//
// Values derived from https://developer.apple.com/design/resources/.
const TextStyle _kDefaultActionTextStyle = TextStyle(
  inherit: false,
  fontFamily: '.SF Pro Text',
  fontSize: 17.0,
  letterSpacing: -0.41,
  color: CupertinoColors.activeBlue,
  decoration: TextDecoration.none,
);

// Please update _DefaultCupertinoTextThemeData and _DefaultCupertinoTextThemeData
// accordingly after changing the default color here, as their implementation
// depends on the default value of the color field.
//
// Values derived from https://developer.apple.com/design/resources/.
const TextStyle _kDefaultTabLabelTextStyle = TextStyle(
  inherit: false,
  fontFamily: '.SF Pro Text',
  fontSize: 10.0,
  letterSpacing: -0.24,
  color: CupertinoColors.inactiveGray,
);

// Please update _DefaultCupertinoTextThemeData and _DefaultCupertinoTextThemeData
// accordingly after changing the default color here, as their implementation
// depends on the default value of the color field.
const TextStyle _kDefaultMiddleTitleTextStyle = TextStyle(
  inherit: false,
  fontFamily: '.SF Pro Text',
  fontSize: 17.0,
  fontWeight: FontWeight.w600,
  letterSpacing: -0.41,
  color: CupertinoColors.label,
);

// Please update _DefaultCupertinoTextThemeData and _DefaultCupertinoTextThemeData
// accordingly after changing the default color here, as their implementation
// depends on the default value of the color field.
const TextStyle _kDefaultLargeTitleTextStyle = TextStyle(
  inherit: false,
  fontFamily: '.SF Pro Display',
  fontSize: 34.0,
  fontWeight: FontWeight.w700,
  letterSpacing: 0.41,
  color: CupertinoColors.label,
);

// Please update _DefaultCupertinoTextThemeData and _DefaultCupertinoTextThemeData
// accordingly after changing the default color here, as their implementation
// depends on the default value of the color field.
//
// Inspected on iOS 13 simulator with "Debug View Hierarchy".
// Value extracted from off-center labels. Centered labels have a font size of 25pt.
const TextStyle _kDefaultPickerTextStyle = TextStyle(
  inherit: false,
  fontFamily: '.SF Pro Display',
  fontSize: 21.0,
  fontWeight: FontWeight.w400,
  letterSpacing: -0.41,
  color: CupertinoColors.label,
);

// Please update _DefaultCupertinoTextThemeData and _DefaultCupertinoTextThemeData
// accordingly after changing the default color here, as their implementation
// depends on the default value of the color field.
//
// Inspected on iOS 13 simulator with "Debug View Hierarchy".
// Value extracted from off-center labels. Centered labels have a font size of 25pt.
const TextStyle _kDefaultDateTimePickerTextStyle = TextStyle(
  inherit: false,
  fontFamily: '.SF Pro Display',
  fontSize: 21,
  fontWeight: FontWeight.normal,
  color: CupertinoColors.label,
);

TextStyle _resolveTextStyle(TextStyle style, BuildContext context, bool nullOk) {
  // This does not change the shadow color, etc.
  Paint foreground, background;
  if (style?.foreground != null)
    foreground..color = CupertinoDynamicColor.resolve(style?.foreground?.color, context, nullOk: nullOk);
  if (style?.background != null)
    background..color = CupertinoDynamicColor.resolve(style?.background?.color, context, nullOk: nullOk);

  return style?.copyWith(
    color: CupertinoDynamicColor.resolve(style?.color, context, nullOk: nullOk),
    backgroundColor: CupertinoDynamicColor.resolve(style?.backgroundColor, context, nullOk: nullOk),
    decorationColor: CupertinoDynamicColor.resolve(style?.decorationColor, context, nullOk: nullOk),
    foreground: foreground,
    background: background,
  );
}

/// Cupertino typography theme in a [CupertinoThemeData].
@immutable
class CupertinoTextThemeData extends Diagnosticable {
  /// Create a [CupertinoTextThemeData].
  ///
  /// The [primaryColor] is used to derive TextStyle defaults of other attributes
  /// such as [textStyle] and [actionTextStyle] etc. The default value of [primaryColor]
  /// is [CupertinoColors.activeBlue].
  ///
  /// Other [TextStyle] parameters default to default iOS text styles when
  /// unspecified.
  const CupertinoTextThemeData({
    Color primaryColor = CupertinoColors.systemBlue,
    @deprecated Brightness brightness, //ignore: avoid_unused_constructor_parameters
    TextStyle textStyle,
    TextStyle actionTextStyle,
    TextStyle tabLabelTextStyle,
    TextStyle navTitleTextStyle,
    TextStyle navLargeTitleTextStyle,
    TextStyle navActionTextStyle,
    TextStyle pickerTextStyle,
    TextStyle dateTimePickerTextStyle,
  }) : this._raw(
         const _DefaultCupertinoTextThemeData(),
         primaryColor,
         textStyle,
         actionTextStyle,
         tabLabelTextStyle,
         navTitleTextStyle,
         navLargeTitleTextStyle,
         navActionTextStyle,
         pickerTextStyle,
         dateTimePickerTextStyle,
       );

  const CupertinoTextThemeData._raw(
    this._defaults,
    this._primaryColor,
    this._textStyle,
    this._actionTextStyle,
    this._tabLabelTextStyle,
    this._navTitleTextStyle,
    this._navLargeTitleTextStyle,
    this._navActionTextStyle,
    this._pickerTextStyle,
    this._dateTimePickerTextStyle,
  ) : assert((_navActionTextStyle != null && _actionTextStyle != null) || _primaryColor != null);

  final _DefaultCupertinoTextThemeData _defaults;
  final Color _primaryColor;

  final TextStyle _textStyle;
  /// Typography of general text content for Cupertino widgets.
  TextStyle get textStyle => _textStyle ?? _defaults.textStyle;

  final TextStyle _actionTextStyle;
  /// Typography of interactive text content such as text in a button without background.
  TextStyle get actionTextStyle {
    return _actionTextStyle ?? _defaults.actionTextStyle(primaryColor: _primaryColor);
  }

  final TextStyle _tabLabelTextStyle;
  /// Typography of unselected tabs.
  TextStyle get tabLabelTextStyle => _tabLabelTextStyle ?? _defaults.tabLabelTextStyle;

  final TextStyle _navTitleTextStyle;
  /// Typography of titles in standard navigation bars.
  TextStyle get navTitleTextStyle => _navTitleTextStyle ?? _defaults.navTitleTextStyle;

  final TextStyle _navLargeTitleTextStyle;
  /// Typography of large titles in sliver navigation bars.
  TextStyle get navLargeTitleTextStyle => _navLargeTitleTextStyle ?? _defaults.navLargeTitleTextStyle;

  final TextStyle _navActionTextStyle;
  /// Typography of interactive text content in navigation bars.
  TextStyle get navActionTextStyle {
    return _navActionTextStyle ?? _defaults.navActionTextStyle(primaryColor: _primaryColor);
  }

  final TextStyle _pickerTextStyle;
  /// Typography of pickers.
  TextStyle get pickerTextStyle => _pickerTextStyle ?? _defaults.pickerTextStyle;

  final TextStyle _dateTimePickerTextStyle;
  /// Typography of date time pickers.
  TextStyle get dateTimePickerTextStyle => _dateTimePickerTextStyle ?? _defaults.dateTimePickerTextStyle;

  /// Returns a copy of the current [CupertinoTextThemeData] with all the colors
  /// resolved against the given [BuildContext].
  CupertinoTextThemeData resolveFrom(BuildContext context, { bool nullOk = false }) {
    return CupertinoTextThemeData._raw(
      _defaults?.resolveFrom(context, nullOk),
      CupertinoDynamicColor.resolve(_primaryColor, context, nullOk: nullOk),
      _resolveTextStyle(_textStyle, context, nullOk),
      _resolveTextStyle(_actionTextStyle, context, nullOk),
      _resolveTextStyle(_tabLabelTextStyle, context, nullOk),
      _resolveTextStyle(_navTitleTextStyle, context, nullOk),
      _resolveTextStyle(_navLargeTitleTextStyle, context, nullOk),
      _resolveTextStyle(_navActionTextStyle, context, nullOk),
      _resolveTextStyle(_pickerTextStyle, context, nullOk),
      _resolveTextStyle(_dateTimePickerTextStyle, context, nullOk),
    );
  }

  /// Returns a copy of the current [CupertinoTextThemeData] instance with
  /// specified overrides.
  CupertinoTextThemeData copyWith({
    Color primaryColor,
    @deprecated
    Brightness brightness,
    TextStyle textStyle,
    TextStyle actionTextStyle,
    TextStyle tabLabelTextStyle,
    TextStyle navTitleTextStyle,
    TextStyle navLargeTitleTextStyle,
    TextStyle navActionTextStyle,
    TextStyle pickerTextStyle,
    TextStyle dateTimePickerTextStyle,
  }) {
    return CupertinoTextThemeData._raw(
      _defaults,
      primaryColor ?? _primaryColor,
      textStyle ?? _textStyle,
      actionTextStyle ?? _actionTextStyle,
      tabLabelTextStyle ?? _tabLabelTextStyle,
      navTitleTextStyle ?? _navTitleTextStyle,
      navLargeTitleTextStyle ?? _navLargeTitleTextStyle,
      navActionTextStyle ?? _navActionTextStyle,
      pickerTextStyle ?? _pickerTextStyle,
      dateTimePickerTextStyle ?? _dateTimePickerTextStyle,
    );
  }
}

@immutable
class _DefaultCupertinoTextThemeData extends Diagnosticable {
  const _DefaultCupertinoTextThemeData({
    this.labelColor = CupertinoColors.label,
    this.inactiveGrayColor = CupertinoColors.inactiveGray,
  }) : assert(labelColor != null),
       assert(inactiveGrayColor != null);

  final Color labelColor;
  final Color inactiveGrayColor;

  static TextStyle applyLabelColor(TextStyle original, Color color) {
    return original?.color == color
      ?  original
      :  original?.copyWith(color: color);
  }

  TextStyle get textStyle => applyLabelColor(_kDefaultTextStyle, labelColor);
  TextStyle get tabLabelTextStyle => applyLabelColor(_kDefaultTabLabelTextStyle, inactiveGrayColor);
  TextStyle get navTitleTextStyle => applyLabelColor(_kDefaultMiddleTitleTextStyle, labelColor);
  TextStyle get navLargeTitleTextStyle => applyLabelColor(_kDefaultLargeTitleTextStyle, labelColor);
  TextStyle get pickerTextStyle => applyLabelColor(_kDefaultPickerTextStyle, labelColor);
  TextStyle get dateTimePickerTextStyle => applyLabelColor(_kDefaultDateTimePickerTextStyle, labelColor);

  TextStyle actionTextStyle({ Color primaryColor }) => _kDefaultActionTextStyle.copyWith(color: primaryColor);
  TextStyle navActionTextStyle({ Color primaryColor }) => actionTextStyle(primaryColor: primaryColor);

  _DefaultCupertinoTextThemeData resolveFrom(BuildContext context, bool nullOk) {
    final Color resolvedLabelColor = CupertinoDynamicColor.resolve(labelColor, context, nullOk: nullOk);
    final Color resolvedInactiveGray = CupertinoDynamicColor.resolve(inactiveGrayColor, context, nullOk: nullOk);
    return resolvedLabelColor == labelColor && resolvedInactiveGray == CupertinoColors.inactiveGray
      ? this
      : _DefaultCupertinoTextThemeData(labelColor: resolvedLabelColor, inactiveGrayColor: resolvedInactiveGray);
  }
}
