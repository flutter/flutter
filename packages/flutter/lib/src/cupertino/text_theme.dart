// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show Brightness;
import 'package:flutter/widgets.dart';

import 'colors.dart';

// Please update _TextThemeDefaultsBuilder accordingly after changing the default
// color here, as their implementation depends on the default value of the color
// field.
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

// Please update _TextThemeDefaultsBuilder accordingly after changing the default
// color here, as their implementation depends on the default value of the color
// field.
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

// Please update _TextThemeDefaultsBuilder accordingly after changing the default
// color here, as their implementation depends on the default value of the color
// field.
//
// Values derived from https://developer.apple.com/design/resources/.
const TextStyle _kDefaultTabLabelTextStyle = TextStyle(
  inherit: false,
  fontFamily: '.SF Pro Text',
  fontSize: 10.0,
  letterSpacing: -0.24,
  color: CupertinoColors.inactiveGray,
);

const TextStyle _kDefaultMiddleTitleTextStyle = TextStyle(
  inherit: false,
  fontFamily: '.SF Pro Text',
  fontSize: 17.0,
  fontWeight: FontWeight.w600,
  letterSpacing: -0.41,
  color: CupertinoColors.label,
);

const TextStyle _kDefaultLargeTitleTextStyle = TextStyle(
  inherit: false,
  fontFamily: '.SF Pro Display',
  fontSize: 34.0,
  fontWeight: FontWeight.w700,
  letterSpacing: 0.41,
  color: CupertinoColors.label,
);

// Please update _TextThemeDefaultsBuilder accordingly after changing the default
// color here, as their implementation depends on the default value of the color
// field.
//
// Inspected on iOS 13 simulator with "Debug View Hierarchy".
// Value extracted from off-center labels. Centered labels have a font size of 25pt.
//
// The letterSpacing sourced from iOS 14 simulator screenshots for comparison.
// See also:
//
// * https://github.com/flutter/flutter/pull/65501#discussion_r486557093
const TextStyle _kDefaultPickerTextStyle = TextStyle(
  inherit: false,
  fontFamily: '.SF Pro Display',
  fontSize: 21.0,
  fontWeight: FontWeight.w400,
  letterSpacing: -0.6,
  color: CupertinoColors.label,
);

// Please update _TextThemeDefaultsBuilder accordingly after changing the default
// color here, as their implementation depends on the default value of the color
// field.
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

/// Cupertino typography theme in a [CupertinoThemeData].
@immutable
class CupertinoTextThemeData with Diagnosticable {
  /// Create a [CupertinoTextThemeData].
  ///
  /// The [primaryColor] is used to derive TextStyle defaults of other attributes
  /// such as [navActionTextStyle] and [actionTextStyle], it must not be null when
  /// either [navActionTextStyle] or [actionTextStyle] is null. Defaults to
  /// [CupertinoColors.systemBlue].
  ///
  /// Other [TextStyle] parameters default to default iOS text styles when
  /// unspecified.
  const CupertinoTextThemeData({
    Color primaryColor = CupertinoColors.systemBlue,
    // ignore: avoid_unused_constructor_parameters, the parameter is deprecated.
    @Deprecated(
      'This argument no longer does anything. You can remove it. '
      'This feature was deprecated after v1.10.14.'
    )
    Brightness? brightness,
    TextStyle? textStyle,
    TextStyle? actionTextStyle,
    TextStyle? tabLabelTextStyle,
    TextStyle? navTitleTextStyle,
    TextStyle? navLargeTitleTextStyle,
    TextStyle? navActionTextStyle,
    TextStyle? pickerTextStyle,
    TextStyle? dateTimePickerTextStyle,
  }) : this._raw(
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

  final Color? _primaryColor;

  final TextStyle? _textStyle;
  /// The [TextStyle] of general text content for Cupertino widgets.
  TextStyle get textStyle => _textStyle ?? _kDefaultTextStyle;

  final TextStyle? _actionTextStyle;
  /// The [TextStyle] of interactive text content such as text in a button without background.
  TextStyle get actionTextStyle {
    return _actionTextStyle ?? _kDefaultActionTextStyle.copyWith(color: _primaryColor);
  }

  final TextStyle? _tabLabelTextStyle;
  /// The [TextStyle] of unselected tabs.
  TextStyle get tabLabelTextStyle => _tabLabelTextStyle ?? _kDefaultTabLabelTextStyle;

  final TextStyle? _navTitleTextStyle;
  /// The [TextStyle] of titles in standard navigation bars.
  TextStyle get navTitleTextStyle => _navTitleTextStyle ?? _kDefaultMiddleTitleTextStyle;

  final TextStyle? _navLargeTitleTextStyle;
  /// The [TextStyle] of large titles in sliver navigation bars.
  TextStyle get navLargeTitleTextStyle => _navLargeTitleTextStyle ?? _kDefaultLargeTitleTextStyle;

  final TextStyle? _navActionTextStyle;
  /// The [TextStyle] of interactive text content in navigation bars.
  TextStyle get navActionTextStyle {
    return _navActionTextStyle ?? _kDefaultActionTextStyle.copyWith(color: _primaryColor);
  }

  final TextStyle? _pickerTextStyle;
  /// The [TextStyle] of pickers.
  TextStyle get pickerTextStyle => _pickerTextStyle ?? _kDefaultPickerTextStyle;

  final TextStyle? _dateTimePickerTextStyle;
  /// The [TextStyle] of date time pickers.
  TextStyle get dateTimePickerTextStyle => _dateTimePickerTextStyle ?? _kDefaultDateTimePickerTextStyle;

  /// Returns a copy of the current [CupertinoTextThemeData] with all the colors
  /// resolved against the given [BuildContext].
  ///
  /// If any of the [InheritedWidget]s required to resolve this
  /// [CupertinoTextThemeData] is not found in [context], any unresolved
  /// [CupertinoDynamicColor]s will use the default trait value
  /// ([Brightness.light] platform brightness, normal contrast,
  /// [CupertinoUserInterfaceLevelData.base] elevation level).
  CupertinoTextThemeData resolveFrom(BuildContext context) {
    return _CupertinoDynamicTextThemeData(
      baseTextThemeData: this,
      context: context,
    );
  }

  /// Returns a copy of the current [CupertinoTextThemeData] instance with
  /// specified overrides.
  CupertinoTextThemeData copyWith({
    Color? primaryColor,
    @Deprecated(
      'This argument no longer does anything. You can remove it. '
      'This feature was deprecated after v1.10.14.'
    )
    Brightness? brightness,
    TextStyle? textStyle,
    TextStyle? actionTextStyle,
    TextStyle? tabLabelTextStyle,
    TextStyle? navTitleTextStyle,
    TextStyle? navLargeTitleTextStyle,
    TextStyle? navActionTextStyle,
    TextStyle? pickerTextStyle,
    TextStyle? dateTimePickerTextStyle,
  }) {
    return CupertinoTextThemeData._raw(
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    const CupertinoTextThemeData defaultData = CupertinoTextThemeData();
    properties.add(DiagnosticsProperty<TextStyle>('textStyle', textStyle, defaultValue: defaultData.textStyle));
    properties.add(DiagnosticsProperty<TextStyle>('actionTextStyle', actionTextStyle, defaultValue: defaultData.actionTextStyle));
    properties.add(DiagnosticsProperty<TextStyle>('tabLabelTextStyle', tabLabelTextStyle, defaultValue: defaultData.tabLabelTextStyle));
    properties.add(DiagnosticsProperty<TextStyle>('navTitleTextStyle', navTitleTextStyle, defaultValue: defaultData.navTitleTextStyle));
    properties.add(DiagnosticsProperty<TextStyle>('navLargeTitleTextStyle', navLargeTitleTextStyle, defaultValue: defaultData.navLargeTitleTextStyle));
    properties.add(DiagnosticsProperty<TextStyle>('navActionTextStyle', navActionTextStyle, defaultValue: defaultData.navActionTextStyle));
    properties.add(DiagnosticsProperty<TextStyle>('pickerTextStyle', pickerTextStyle, defaultValue: defaultData.pickerTextStyle));
    properties.add(DiagnosticsProperty<TextStyle>('dateTimePickerTextStyle', dateTimePickerTextStyle, defaultValue: defaultData.dateTimePickerTextStyle));
  }
}

class _CupertinoDynamicTextThemeData with Diagnosticable implements CupertinoTextThemeData {
  _CupertinoDynamicTextThemeData({
    required CupertinoTextThemeData baseTextThemeData,
    required BuildContext context,
  }) : _textThemeData = baseTextThemeData,
       _context = context;

  final CupertinoTextThemeData _textThemeData;
  final BuildContext _context;

  @override
  Color? get _primaryColor => _textThemeData._primaryColor;

  @override
  TextStyle? get _textStyle => _textThemeData._textStyle;
  @override
  late final TextStyle textStyle = _resolveTextStyle(_textThemeData.textStyle);

  @override
  TextStyle? get _actionTextStyle => _textThemeData._actionTextStyle;
  @override
  late final TextStyle actionTextStyle = _resolveTextStyle(_textThemeData.actionTextStyle);

  @override
  TextStyle? get _tabLabelTextStyle => _textThemeData._tabLabelTextStyle;
  @override
  late final TextStyle tabLabelTextStyle = _resolveTextStyle(_textThemeData.tabLabelTextStyle);

  @override
  TextStyle? get _navTitleTextStyle => _textThemeData._navTitleTextStyle;
  @override
  late final TextStyle navTitleTextStyle = _resolveTextStyle(_textThemeData.navTitleTextStyle);

  @override
  TextStyle? get _navLargeTitleTextStyle => _textThemeData._navLargeTitleTextStyle;
  @override
  late final TextStyle navLargeTitleTextStyle = _resolveTextStyle(_textThemeData.navLargeTitleTextStyle);

  @override
  TextStyle? get _navActionTextStyle => _textThemeData._navActionTextStyle;
  @override
  late final TextStyle navActionTextStyle = _resolveTextStyle(_textThemeData.navActionTextStyle);

  @override
  TextStyle? get _pickerTextStyle => _textThemeData._pickerTextStyle;
  @override
  late final TextStyle pickerTextStyle = _resolveTextStyle(_textThemeData.pickerTextStyle);

  @override
  TextStyle? get _dateTimePickerTextStyle => _textThemeData._dateTimePickerTextStyle;
  @override
  late final TextStyle dateTimePickerTextStyle = _resolveTextStyle(_textThemeData.dateTimePickerTextStyle);

  @override
  CupertinoTextThemeData resolveFrom(BuildContext context) {
    return _CupertinoDynamicTextThemeData(
      baseTextThemeData: _textThemeData,
      context: context,
    );
  }

  TextStyle _resolveTextStyle(TextStyle style) {
    // This does not resolve the shadow color, foreground, background, etc.
    return style.copyWith(
      color: CupertinoDynamicColor.maybeResolve(style.color, _context),
      backgroundColor: CupertinoDynamicColor.maybeResolve(style.backgroundColor, _context),
      decorationColor: CupertinoDynamicColor.maybeResolve(style.decorationColor, _context),
    );
  }

  @override
  CupertinoTextThemeData copyWith({
    Color? primaryColor,
    @Deprecated(
      'This argument no longer does anything. You can remove it. '
      'This feature was deprecated after v1.10.14.'
    )
    Brightness? brightness,
    TextStyle? textStyle,
    TextStyle? actionTextStyle,
    TextStyle? tabLabelTextStyle,
    TextStyle? navTitleTextStyle,
    TextStyle? navLargeTitleTextStyle,
    TextStyle? navActionTextStyle,
    TextStyle? pickerTextStyle,
    TextStyle? dateTimePickerTextStyle,
  }) {
    return _CupertinoDynamicTextThemeData(
      baseTextThemeData: _textThemeData.copyWith(
        primaryColor: primaryColor,
        textStyle: textStyle,
        actionTextStyle: actionTextStyle,
        tabLabelTextStyle: tabLabelTextStyle,
        navTitleTextStyle: navTitleTextStyle,
        navLargeTitleTextStyle: navLargeTitleTextStyle,
        navActionTextStyle: navActionTextStyle,
        pickerTextStyle: pickerTextStyle,
        dateTimePickerTextStyle: dateTimePickerTextStyle,
      ),
      context: _context,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    const CupertinoTextThemeData defaultData = CupertinoTextThemeData();
    properties.add(DiagnosticsProperty<TextStyle>('textStyle', textStyle, defaultValue: defaultData.textStyle));
    properties.add(DiagnosticsProperty<TextStyle>('actionTextStyle', actionTextStyle, defaultValue: defaultData.actionTextStyle));
    properties.add(DiagnosticsProperty<TextStyle>('tabLabelTextStyle', tabLabelTextStyle, defaultValue: defaultData.tabLabelTextStyle));
    properties.add(DiagnosticsProperty<TextStyle>('navTitleTextStyle', navTitleTextStyle, defaultValue: defaultData.navTitleTextStyle));
    properties.add(DiagnosticsProperty<TextStyle>('navLargeTitleTextStyle', navLargeTitleTextStyle, defaultValue: defaultData.navLargeTitleTextStyle));
    properties.add(DiagnosticsProperty<TextStyle>('navActionTextStyle', navActionTextStyle, defaultValue: defaultData.navActionTextStyle));
    properties.add(DiagnosticsProperty<TextStyle>('pickerTextStyle', pickerTextStyle, defaultValue: defaultData.pickerTextStyle));
    properties.add(DiagnosticsProperty<TextStyle>('dateTimePickerTextStyle', dateTimePickerTextStyle, defaultValue: defaultData.dateTimePickerTextStyle));
  }
}
