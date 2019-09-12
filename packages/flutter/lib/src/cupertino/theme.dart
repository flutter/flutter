// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'text_theme.dart';

export 'package:flutter/services.dart' show Brightness;

// Values derived from https://developer.apple.com/design/resources/.
const Color _kDefaultBarLightBackgroundColor = Color(0xCCF8F8F8);
const Color _kDefaultBarDarkBackgroundColor = Color(0xB7212121);

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
///  * [CupertinoApp], which will automatically add a [CupertinoTheme].
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

  /// Retrieve the [CupertinoThemeData] from an ancestor [CupertinoTheme] widget.
  ///
  /// Returns a default [CupertinoThemeData] if no [CupertinoTheme] widgets
  /// exist in the ancestry tree.
  static CupertinoThemeData of(BuildContext context) {
    final _InheritedCupertinoTheme inheritedTheme = context.inheritFromWidgetOfExactType(_InheritedCupertinoTheme);
    return (inheritedTheme?.theme?.data ?? const CupertinoThemeData()).resolveFrom(context, nullOk: true);
  }

  /// Retrieve the [Brightness] value from the closest ancestor [CupertinoTheme]
  /// widget.
  ///
  /// If no ancestral [CupertinoTheme] widget with explicit brightness value could
  /// be found, the method will resort to the closest ancestor [MediaQuery] widget.
  ///
  /// Throws an exception if no such [CupertinoTheme] or [MediaQuery] widgets exist
  /// in the ancestry tree, unless [nullOk] is set to true.
  static Brightness brightnessOf(BuildContext context, { bool nullOk = false }) {
    final _InheritedCupertinoTheme inheritedTheme = context.inheritFromWidgetOfExactType(_InheritedCupertinoTheme);
    return inheritedTheme?.theme?.data?._brightness ?? MediaQuery.of(context, nullOk: nullOk)?.platformBrightness;
  }

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return  _InheritedCupertinoTheme(
      theme: this,
      child: IconTheme(
        data: IconThemeData(color: data.primaryColor),
        child: child,
      )
    );
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
class CupertinoThemeData extends Diagnosticable {
  /// Create a [CupertinoTheme] styling specification.
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
    this._brightness,
    this._primaryColor,
    this._primaryContrastingColor,
    this._textTheme,
    this._barBackgroundColor,
    this._scaffoldBackgroundColor,
  );

  bool get _isLight => brightness == Brightness.light;

  /// The general brightness theme of the [CupertinoThemeData].
  ///
  /// Affects all other theme properties when unspecified. Defaults to
  /// [Brightness.light].
  ///
  /// If coming from a Material [Theme] and unspecified, [brightness] will be
  /// derived from the Material [ThemeData]'s `brightness`.
  Brightness get brightness => _brightness ?? Brightness.light;
  final Brightness _brightness;

  /// A color used on interactive elements of the theme.
  ///
  /// This color is generally used on text and icons in buttons and tappable
  /// elements. Defaults to [CupertinoColors.activeBlue] or
  /// [CupertinoColors.activeOrange] when [brightness] is light or dark.
  ///
  /// If coming from a Material [Theme] and unspecified, [primaryColor] will be
  /// derived from the Material [ThemeData]'s `colorScheme.primary`. However, in
  /// iOS styling, the [primaryColor] is more sparsely used than in Material
  /// Design where the [primaryColor] can appear on non-interactive surfaces like
  /// the [AppBar] background, [TextField] borders etc.
  Color get primaryColor {
    return _primaryColor ??
        (_isLight ? CupertinoColors.activeBlue : CupertinoColors.activeOrange);
  }
  final Color _primaryColor;

  /// A color used for content that must contrast against a [primaryColor] background.
  ///
  /// For example, this color is used for a [CupertinoButton]'s text and icons
  /// when the button's background is [primaryColor].
  ///
  /// If coming from a Material [Theme] and unspecified, [primaryContrastingColor]
  /// will be derived from the Material [ThemeData]'s `colorScheme.onPrimary`.
  Color get primaryContrastingColor {
    return _primaryContrastingColor ??
        (_isLight ? CupertinoColors.white : CupertinoColors.black);
  }
  final Color _primaryContrastingColor;

  /// Text styles used by Cupertino widgets.
  ///
  /// Derived from [brightness] and [primaryColor] if unspecified, including
  /// [brightness] and [primaryColor] of a Material [ThemeData] if coming
  /// from a Material [Theme].
  CupertinoTextThemeData get textTheme {
    return _textTheme ?? CupertinoTextThemeData(
      brightness: brightness,
      primaryColor: primaryColor,
    );
  }
  final CupertinoTextThemeData _textTheme;

  /// Background color of the top nav bar and bottom tab bar.
  ///
  /// Defaults to a light gray or a dark gray translucent color depending
  /// on the [brightness].
  Color get barBackgroundColor {
    return _barBackgroundColor ??
        (_isLight ? _kDefaultBarLightBackgroundColor : _kDefaultBarDarkBackgroundColor);
  }
  final Color _barBackgroundColor;

  /// Background color of the scaffold.
  ///
  /// Defaults to white or black depending on the [brightness].
  Color get scaffoldBackgroundColor {
    return _scaffoldBackgroundColor ??
        (_isLight ? CupertinoColors.white : CupertinoColors.black);
  }
  final Color _scaffoldBackgroundColor;

  /// Return an instance of the [CupertinoThemeData] whose property getters
  /// only return the construction time specifications with no derived values.
  ///
  /// Used in Material themes to let unspecified properties fallback to Material
  /// theme properties instead of iOS defaults.
  CupertinoThemeData noDefault() {
    return _NoDefaultCupertinoThemeData(
      _brightness,
      _primaryColor,
      _primaryContrastingColor,
      _textTheme,
      _barBackgroundColor,
      _scaffoldBackgroundColor,
    );
  }

  /// Return a new `CupertinoThemeData` whose colors are from this `CupertinoThemeData`,
  /// but resolved aginst the given [BuildContext].
  ///
  /// It will be called in [CupertinoTheme.of].
  @protected
  CupertinoThemeData resolveFrom(BuildContext context, { bool nullOk = false }) {
    Color convertColor(Color color) => CupertinoDynamicColor.resolve(color, context, nullOk: nullOk);

    return copyWith(
      primaryColor: convertColor(primaryColor),
      primaryContrastingColor: convertColor(primaryContrastingColor),
      textTheme: textTheme?.resolveFrom(context, nullOk: nullOk),
      barBackgroundColor: convertColor(barBackgroundColor),
      scaffoldBackgroundColor: convertColor(scaffoldBackgroundColor),
    );
  }

  /// Create a copy of [CupertinoThemeData] with specified attributes overridden.
  ///
  /// Only the current instance's specified attributes are copied instead of
  /// derived values. For instance, if the current [primaryColor] is implied
  /// to be [CupertinoColors.activeOrange] due to the current [brightness],
  /// copying with a different [brightness] will also change the copy's
  /// implied [primaryColor].
  CupertinoThemeData copyWith({
    Brightness brightness,
    Color primaryColor,
    Color primaryContrastingColor,
    CupertinoTextThemeData textTheme,
    Color barBackgroundColor,
    Color scaffoldBackgroundColor,
  }) {
    return CupertinoThemeData(
      brightness: brightness ?? _brightness,
      primaryColor: primaryColor ?? _primaryColor,
      primaryContrastingColor: primaryContrastingColor ?? _primaryContrastingColor,
      textTheme: textTheme ?? _textTheme,
      barBackgroundColor: barBackgroundColor ?? _barBackgroundColor,
      scaffoldBackgroundColor: scaffoldBackgroundColor ?? _scaffoldBackgroundColor,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    const CupertinoThemeData defaultData = CupertinoThemeData();
    properties.add(EnumProperty<Brightness>('brightness', brightness, defaultValue: defaultData.brightness));
    properties.add(ColorProperty('primaryColor', primaryColor, defaultValue: defaultData.primaryColor));
    properties.add(ColorProperty('primaryContrastingColor', primaryContrastingColor, defaultValue: defaultData.primaryContrastingColor));
    properties.add(DiagnosticsProperty<CupertinoTextThemeData>('textTheme', textTheme, defaultValue: defaultData.textTheme));
    properties.add(ColorProperty('barBackgroundColor', barBackgroundColor, defaultValue: defaultData.barBackgroundColor));
    properties.add(ColorProperty('scaffoldBackgroundColor', scaffoldBackgroundColor, defaultValue: defaultData.scaffoldBackgroundColor));
  }
}

class _NoDefaultCupertinoThemeData extends CupertinoThemeData {
  const _NoDefaultCupertinoThemeData(
    this.brightness,
    this.primaryColor,
    this.primaryContrastingColor,
    this.textTheme,
    this.barBackgroundColor,
    this.scaffoldBackgroundColor,
  ) : super.raw(
        brightness,
        primaryColor,
        primaryContrastingColor,
        textTheme,
        barBackgroundColor,
        scaffoldBackgroundColor,
      );

  @override
  final Brightness brightness;
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
    Color scaffoldBackgroundColor
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
