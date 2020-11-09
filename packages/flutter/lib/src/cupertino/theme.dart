// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'icon_theme_data.dart';
import 'text_theme.dart';

export 'package:flutter/services.dart' show Brightness;

// Values derived from https://developer.apple.com/design/resources/.
const _CupertinoThemeDefaults _kDefaultTheme = _CupertinoThemeDefaults(
  null,
  CupertinoColors.systemBlue,
  CupertinoColors.systemBackground,
  CupertinoDynamicColor.withBrightness(
    color: Color(0xF0F9F9F9),
    darkColor: Color(0xF01D1D1D),
    // Values extracted from navigation bar. For toolbar or tabbar the dark color is 0xF0161616.
  ),
  CupertinoColors.systemBackground,
  _CupertinoTextThemeDefaults(CupertinoColors.label, CupertinoColors.inactiveGray),
);

/// Applies a visual styling theme to descendant Cupertino widgets.
///
/// Affects the color and text styles of Cupertino widgets whose styling
/// are not overridden when constructing the respective widgets instances.
///
/// Descendant widgets can retrieve the current [CupertinoThemeData] by calling
/// [CupertinoTheme.of]. An [InheritedWidget] dependency is created when
/// an ancestor [CupertinoThemeData] is retrieved via [CupertinoTheme.of].
///
/// The [CupertinoTheme] widget implies an [IconTheme] widget, whose
/// [IconTheme.data] has the same color as [CupertinoThemeData.primaryColor]
///
/// See also:
///
///  * [CupertinoThemeData], specifies the theme's visual styling.
///  * [CupertinoApp], which will automatically add a [CupertinoTheme] based on the
///    value of [CupertinoApp.theme].
///  * [Theme], a Material theme which will automatically add a [CupertinoTheme]
///    with a [CupertinoThemeData] derived from the Material [ThemeData].
class CupertinoTheme extends StatelessWidget {
  /// Creates a [CupertinoTheme] to change descendant Cupertino widgets' styling.
  ///
  /// The [data] and [child] parameters must not be null.
  const CupertinoTheme({
    Key key,
    @required this.data,
    @required this.child,
  }) : assert(child != null),
       assert(data != null),
       super(key: key);

  /// The [CupertinoThemeData] styling for this theme.
  final CupertinoThemeData data;

  /// Retrieves the [CupertinoThemeData] from the closest ancestor [CupertinoTheme]
  /// widget, or a default [CupertinoThemeData] if no [CupertinoTheme] ancestor
  /// exists.
  ///
  /// Resolves all the colors defined in that [CupertinoThemeData] against the
  /// given [BuildContext] on a best-effort basis.
  static CupertinoThemeData of(BuildContext context) {
    final _InheritedCupertinoTheme inheritedTheme = context.dependOnInheritedWidgetOfExactType<_InheritedCupertinoTheme>();
    return (inheritedTheme?.theme?.data ?? const CupertinoThemeData()).resolveFrom(context, nullOk: true);
  }

  /// Retrieves the [Brightness] to use for descendant Cupertino widgets, based
  /// on the value of [CupertinoThemeData.brightness] in the given [context].
  ///
  /// If no [CupertinoTheme] can be found in the given [context], or its `brightness`
  /// is null, it will fall back to [MediaQueryData.platformBrightness].
  ///
  /// Throws an exception if no valid [CupertinoTheme] or [MediaQuery] widgets
  /// exist in the ancestry tree, unless [nullOk] is set to true.
  ///
  /// See also:
  ///
  /// * [CupertinoThemeData.brightness], the property takes precedence over
  ///   [MediaQueryData.platformBrightness] for descendant Cupertino widgets.
  static Brightness brightnessOf(BuildContext context, { bool nullOk = false }) {
    final _InheritedCupertinoTheme inheritedTheme = context.dependOnInheritedWidgetOfExactType<_InheritedCupertinoTheme>();
    return inheritedTheme?.theme?.data?.brightness ?? MediaQuery.of(context, nullOk: nullOk)?.platformBrightness;
  }

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _InheritedCupertinoTheme(
      theme: this,
      child: IconTheme(
        data: CupertinoIconThemeData(color: data.primaryColor),
        child: child,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    data.debugFillProperties(properties);
  }
}

class _InheritedCupertinoTheme extends InheritedWidget {
  const _InheritedCupertinoTheme({
    Key key,
    @required this.theme,
    @required Widget child,
  }) : assert(theme != null),
       super(key: key, child: child);

  final CupertinoTheme theme;

  @override
  bool updateShouldNotify(_InheritedCupertinoTheme old) => theme.data != old.theme.data;
}

/// Styling specifications for a [CupertinoTheme].
///
/// All constructor parameters can be null, in which case a
/// [CupertinoColors.activeBlue] based default iOS theme styling is used.
///
/// Parameters can also be partially specified, in which case some parameters
/// will cascade down to other dependent parameters to create a cohesive
/// visual effect. For instance, if a [primaryColor] is specified, it would
/// cascade down to affect some fonts in [textTheme] if [textTheme] is not
/// specified.
///
/// See also:
///
///  * [CupertinoTheme], in which this [CupertinoThemeData] is inserted.
///  * [ThemeData], a Material equivalent that also configures Cupertino
///    styling via a [CupertinoThemeData] subclass [MaterialBasedCupertinoThemeData].
@immutable
class CupertinoThemeData with Diagnosticable {
  /// Creates a [CupertinoTheme] styling specification.
  ///
  /// Unspecified parameters default to a reasonable iOS default style.
  const CupertinoThemeData({
    Brightness brightness,
    Color primaryColor,
    Color primaryContrastingColor,
    CupertinoTextThemeData textTheme,
    Color barBackgroundColor,
    Color scaffoldBackgroundColor,
  }) : this.raw(
        brightness,
        primaryColor,
        primaryContrastingColor,
        textTheme,
        barBackgroundColor,
        scaffoldBackgroundColor,
      );

  /// Same as the default constructor but with positional arguments to avoid
  /// forgetting any and to specify all arguments.
  ///
  /// Used by subclasses to get the superclass's defaulting behaviors.
  @protected
  const CupertinoThemeData.raw(
    Brightness brightness,
    Color primaryColor,
    Color primaryContrastingColor,
    CupertinoTextThemeData textTheme,
    Color barBackgroundColor,
    Color scaffoldBackgroundColor,
  ) : this._rawWithDefaults(
    brightness,
    primaryColor,
    primaryContrastingColor,
    textTheme,
    barBackgroundColor,
    scaffoldBackgroundColor,
    _kDefaultTheme,
  );

  const CupertinoThemeData._rawWithDefaults(
    this.brightness,
    this._primaryColor,
    this._primaryContrastingColor,
    this._textTheme,
    this._barBackgroundColor,
    this._scaffoldBackgroundColor,
    this._defaults,
  );

  final _CupertinoThemeDefaults _defaults;

  /// The brightness override for Cupertino descendants.
  ///
  /// Defaults to null. If a non-null [Brightness] is specified, the value will
  /// take precedence over the ambient [MediaQueryData.platformBrightness], when
  /// determining the brightness of descendant Cupertino widgets.
  ///
  /// If coming from a Material [Theme] and unspecified, [brightness] will be
  /// derived from the Material [ThemeData]'s `brightness`.
  ///
  /// See also:
  ///
  ///  * [MaterialBasedCupertinoThemeData], a [CupertinoThemeData] that defers
  ///    [brightness] to its Material [Theme] parent if it's unspecified.
  ///
  ///  * [CupertinoTheme.brightnessOf], a method used to retrieve the overall
  ///    [Brightness] from a [BuildContext], for Cupertino widgets.
  final Brightness brightness;

  /// A color used on interactive elements of the theme.
  ///
  /// This color is generally used on text and icons in buttons and tappable
  /// elements. Defaults to [CupertinoColors.activeBlue].
  ///
  /// If coming from a Material [Theme] and unspecified, [primaryColor] will be
  /// derived from the Material [ThemeData]'s `colorScheme.primary`. However, in
  /// iOS styling, the [primaryColor] is more sparsely used than in Material
  /// Design where the [primaryColor] can appear on non-interactive surfaces like
  /// the [AppBar] background, [TextField] borders etc.
  ///
  /// See also:
  ///
  ///  * [MaterialBasedCupertinoThemeData], a [CupertinoThemeData] that defers
  ///    [primaryColor] to its Material [Theme] parent if it's unspecified.
  Color get primaryColor => _primaryColor ?? _defaults.primaryColor;
  final Color _primaryColor;

  /// A color that must be easy to see when rendered on a [primaryColor] background.
  ///
  /// For example, this color is used for a [CupertinoButton]'s text and icons
  /// when the button's background is [primaryColor].
  ///
  /// If coming from a Material [Theme] and unspecified, [primaryContrastingColor]
  /// will be derived from the Material [ThemeData]'s `colorScheme.onPrimary`.
  ///
  /// See also:
  ///
  ///  * [MaterialBasedCupertinoThemeData], a [CupertinoThemeData] that defers
  ///    [primaryContrastingColor] to its Material [Theme] parent if it's unspecified.
  Color get primaryContrastingColor => _primaryContrastingColor ?? _defaults.primaryContrastingColor;
  final Color _primaryContrastingColor;

  /// Text styles used by Cupertino widgets.
  ///
  /// Derived from [primaryColor] if unspecified.
  CupertinoTextThemeData get textTheme {
    return _textTheme ?? _defaults.textThemeDefaults.createDefaults(primaryColor: primaryColor);
  }
  final CupertinoTextThemeData _textTheme;

  /// Background color of the top nav bar and bottom tab bar.
  ///
  /// Defaults to a light gray in light mode, or a dark translucent gray color in
  /// dark mode.
  Color get barBackgroundColor => _barBackgroundColor ?? _defaults.barBackgroundColor;
  final Color _barBackgroundColor;

  /// Background color of the scaffold.
  ///
  /// Defaults to [CupertinoColors.systemBackground].
  Color get scaffoldBackgroundColor => _scaffoldBackgroundColor ?? _defaults.scaffoldBackgroundColor;
  final Color _scaffoldBackgroundColor;

  /// Returns an instance of the [CupertinoThemeData] whose property getters
  /// only return the construction time specifications with no derived values.
  ///
  /// Used in Material themes to let unspecified properties fallback to Material
  /// theme properties instead of iOS defaults.
  CupertinoThemeData noDefault() {
    return _NoDefaultCupertinoThemeData(
      brightness,
      _primaryColor,
      _primaryContrastingColor,
      _textTheme,
      _barBackgroundColor,
      _scaffoldBackgroundColor,
    );
  }

  /// Returns a new `CupertinoThemeData` with all its colors resolved against the
  /// given [BuildContext].
  ///
  /// Called by [CupertinoTheme.of] to resolve colors defined in the retrieved
  /// [CupertinoThemeData].
  @protected
  CupertinoThemeData resolveFrom(BuildContext context, { bool nullOk = false }) {
    Color convertColor(Color color) => CupertinoDynamicColor.resolve(color, context, nullOk: nullOk);

    return CupertinoThemeData._rawWithDefaults(
      brightness,
      convertColor(_primaryColor),
      convertColor(_primaryContrastingColor),
      _textTheme?.resolveFrom(context, nullOk: nullOk),
      convertColor(_barBackgroundColor),
      convertColor(_scaffoldBackgroundColor),
      _defaults.resolveFrom(context, _textTheme == null, nullOk: nullOk),
    );
  }

  /// Creates a copy of [CupertinoThemeData] with specified attributes overridden.
  ///
  /// Only the current instance's specified attributes are copied instead of
  /// derived values. For instance, if the current [CupertinoThemeData.textTheme]
  /// is implied from the current [primaryColor] because it was not specified,
  /// copying with a different [primaryColor] will also change the copy's implied
  /// [textTheme].
  CupertinoThemeData copyWith({
    Brightness brightness,
    Color primaryColor,
    Color primaryContrastingColor,
    CupertinoTextThemeData textTheme,
    Color barBackgroundColor,
    Color scaffoldBackgroundColor,
  }) {
    return CupertinoThemeData._rawWithDefaults(
      brightness ?? this.brightness,
      primaryColor ?? _primaryColor,
      primaryContrastingColor ?? _primaryContrastingColor,
      textTheme ?? _textTheme,
      barBackgroundColor ?? _barBackgroundColor,
      scaffoldBackgroundColor ?? _scaffoldBackgroundColor,
      _defaults,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    const CupertinoThemeData defaultData = CupertinoThemeData();
    properties.add(EnumProperty<Brightness>('brightness', brightness, defaultValue: null));
    properties.add(createCupertinoColorProperty('primaryColor', primaryColor, defaultValue: defaultData.primaryColor));
    properties.add(createCupertinoColorProperty('primaryContrastingColor', primaryContrastingColor, defaultValue: defaultData.primaryContrastingColor));
    properties.add(createCupertinoColorProperty('barBackgroundColor', barBackgroundColor, defaultValue: defaultData.barBackgroundColor));
    properties.add(createCupertinoColorProperty('scaffoldBackgroundColor', scaffoldBackgroundColor, defaultValue: defaultData.scaffoldBackgroundColor));
    textTheme.debugFillProperties(properties);
  }
}

class _NoDefaultCupertinoThemeData extends CupertinoThemeData {
  const _NoDefaultCupertinoThemeData(
    Brightness brightness,
    this.primaryColor,
    this.primaryContrastingColor,
    this.textTheme,
    this.barBackgroundColor,
    this.scaffoldBackgroundColor,
  ) : super._rawWithDefaults(
        brightness,
        primaryColor,
        primaryContrastingColor,
        textTheme,
        barBackgroundColor,
        scaffoldBackgroundColor,
        null,
      );

  @override
  final Color primaryColor;
  @override
  final Color primaryContrastingColor;
  @override
  final CupertinoTextThemeData textTheme;
  @override
  final Color barBackgroundColor;
  @override
  final Color scaffoldBackgroundColor;

  @override
  _NoDefaultCupertinoThemeData resolveFrom(BuildContext context, { bool nullOk = false }) {
    Color convertColor(Color color) => CupertinoDynamicColor.resolve(color, context, nullOk: nullOk);

    return _NoDefaultCupertinoThemeData(
      brightness,
      convertColor(primaryColor),
      convertColor(primaryContrastingColor),
      textTheme?.resolveFrom(context, nullOk: nullOk),
      convertColor(barBackgroundColor),
      convertColor(scaffoldBackgroundColor),
    );
  }

  @override
  CupertinoThemeData copyWith({
    Brightness brightness,
    Color primaryColor,
    Color primaryContrastingColor,
    CupertinoTextThemeData textTheme,
    Color barBackgroundColor ,
    Color scaffoldBackgroundColor,
  }) {
    return _NoDefaultCupertinoThemeData(
      brightness ?? this.brightness,
      primaryColor ?? this.primaryColor,
      primaryContrastingColor ?? this.primaryContrastingColor,
      textTheme ?? this.textTheme,
      barBackgroundColor ?? this.barBackgroundColor,
      scaffoldBackgroundColor ?? this.scaffoldBackgroundColor,
    );
  }
}

@immutable
class _CupertinoThemeDefaults {
  const _CupertinoThemeDefaults(
    this.brightness,
    this.primaryColor,
    this.primaryContrastingColor,
    this.barBackgroundColor,
    this.scaffoldBackgroundColor,
    this.textThemeDefaults,
  );

  final Brightness brightness;
  final Color primaryColor;
  final Color primaryContrastingColor;
  final Color barBackgroundColor;
  final Color scaffoldBackgroundColor;
  final _CupertinoTextThemeDefaults textThemeDefaults;

  _CupertinoThemeDefaults resolveFrom(BuildContext context, bool resolveTextTheme, { @required bool nullOk }) {
    assert(nullOk != null);
    Color convertColor(Color color) => CupertinoDynamicColor.resolve(color, context, nullOk: nullOk);

    return _CupertinoThemeDefaults(
      brightness,
      convertColor(primaryColor),
      convertColor(primaryContrastingColor),
      convertColor(barBackgroundColor),
      convertColor(scaffoldBackgroundColor),
      resolveTextTheme ? textThemeDefaults?.resolveFrom(context, nullOk: nullOk) : textThemeDefaults,
    );
  }
}

@immutable
class _CupertinoTextThemeDefaults {
  const _CupertinoTextThemeDefaults(
    this.labelColor,
    this.inactiveGray,
  );

  final Color labelColor;
  final Color inactiveGray;

  _CupertinoTextThemeDefaults resolveFrom(BuildContext context, { @required bool nullOk }) {
    return _CupertinoTextThemeDefaults(
      CupertinoDynamicColor.resolve(labelColor, context, nullOk: nullOk),
      CupertinoDynamicColor.resolve(inactiveGray, context, nullOk: nullOk),
    );
  }

  CupertinoTextThemeData createDefaults({ @required Color primaryColor }) {
    assert(primaryColor != null);
    return _DefaultCupertinoTextThemeData(
      primaryColor: primaryColor,
      labelColor: labelColor,
      inactiveGray: inactiveGray,
    );
  }
}

// CupertinoTextThemeData with no text styles explicitly specified.
// The implementation of this class may need to be updated when any of the default
// text styles changes.
class _DefaultCupertinoTextThemeData extends CupertinoTextThemeData {
  const _DefaultCupertinoTextThemeData({
    @required this.labelColor,
    @required this.inactiveGray,
    @required Color primaryColor,
  }) : assert(labelColor != null),
       assert(inactiveGray != null),
       assert(primaryColor != null),
       super(primaryColor: primaryColor);

  final Color labelColor;
  final Color inactiveGray;

  @override
  TextStyle get textStyle => super.textStyle.copyWith(color: labelColor);

  @override
  TextStyle get tabLabelTextStyle => super.tabLabelTextStyle.copyWith(color: inactiveGray);

  @override
  TextStyle get navTitleTextStyle => super.navTitleTextStyle.copyWith(color: labelColor);

  @override
  TextStyle get navLargeTitleTextStyle => super.navLargeTitleTextStyle.copyWith(color: labelColor);

  @override
  TextStyle get pickerTextStyle => super.pickerTextStyle.copyWith(color: labelColor);

  @override
  TextStyle get dateTimePickerTextStyle => super.dateTimePickerTextStyle.copyWith(color: labelColor);
}
