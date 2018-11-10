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
/// [CupertinoThemeData.of]. A dependency for the [CupertinoThemeData]'s
/// attribute is created when an attribute is read. Changes to that specific
/// attribute in the [CupertinoThemeData] will trigger a rebuild in the
/// dependent widget.
///
/// See also:
///
///  * [CupertinoThemeData], specifies the theme's visual styling.
///  * [CupertinoApp], which will automatically add a [CupertinoTheme].
///  * [Theme], a Material theme which will automatically add a [CupertinoTheme]
///    with a [CupertinoThemeData] derived from the Material [ThemeData].
class CupertinoTheme extends InheritedWidget {
  /// Creates a [CupertinoTheme] to change downstream Cupertino widgets' styling.
  ///
  /// The [data] and [child] parameters must not be null.
  const CupertinoTheme({
    Key key,
    @required this.data,
    @required Widget child,
  }) : assert(child != null),
       assert(data != null),
       super(key: key, child: child);

  /// The [CupertinoThemeData] styling for this theme.
  final CupertinoThemeData data;

  @override
  bool updateShouldNotify(CupertinoTheme oldWidget) => data != oldWidget.data;

  /// Retrieve the [CupertinoThemeData] from an ancestor [CupertinoTheme] widget.
  ///
  /// May return a default [CupertinoThemeData] if no [CupertinoTheme] widgets
  /// exist in the ancestry tree.
  ///
  /// No [InheritedModel] dependency is created when the [CupertinoThemeData]
  /// object is provided but a dependency is created when properties on the
  /// [CupertinoThemeData] are read. When a dependency is created, a rebuild
  /// is invoked on the reader when the read properties are changed.
  static CupertinoThemeData of(BuildContext context) {
    final CupertinoTheme theme = context.inheritFromWidgetOfExactType(CupertinoTheme);
    return theme?.data ?? const CupertinoThemeData();
  }
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
/// When retrieved using [CupertinoTheme.of], reading each property will create
/// a dependency in the [BuildContext] given to [CupertinoTheme.of]. The
/// given [BuildContext] will rebuild when that property changes.
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
    CupertinoTextTheme textTheme,
    Color barBackgroundColor,
    Color scaffoldBackgroundColor,
    Color tableBackgroundColor,
  }) : this.raw(
        brightness,
        primaryColor,
        primaryContrastingColor,
        textTheme,
        barBackgroundColor,
        scaffoldBackgroundColor,
        tableBackgroundColor,
      );

  /// A raw constructor used by subclasses to populate the superclass's fields
  /// to get superclass behaviors not overriden by subclasses.
  ///
  /// Same as the default constructor but with positional arguments to avoid
  /// forgetting any.
  @protected
  const CupertinoThemeData.raw(
    this._brightness,
    this._primaryColor,
    this._primaryContrastingColor,
    this._textTheme,
    this._barBackgroundColor,
    this._scaffoldBackgroundColor,
    this._tableBackgroundColor,
  );

  bool get _isLight => brightness == Brightness.light;

  final Brightness _brightness;
  /// The general brightness theme of the [CupertinoThemeData].
  ///
  /// Affects all other theme properties when unspecified. Defaults to
  /// [Brightness.light].
  ///
  /// If coming from a Material [Theme] and unspecified, [brightness] will be
  /// derived from the Material [ThemeData]'s `brightness`.
  ///
  /// Reading this property from [CupertinoTheme.of] will create a dependency
  /// from the [BuildContext] to changes in this property.
  Brightness get brightness => _brightness ?? Brightness.light;

  final Color _primaryColor;
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
  ///
  /// Reading this property from [CupertinoTheme.of] will create a dependency
  /// from the [BuildContext] to changes in this property.
  Color get primaryColor {
    return _primaryColor ??
        (_isLight ? CupertinoColors.activeBlue : CupertinoColors.activeOrange);
  }

  final Color _primaryContrastingColor;
  /// A color used for content that must contrast against a [primaryColor] background.
  ///
  /// For example, this color is used for a [CupertinoButton]'s text and icons
  /// when the button's background is [primaryColor].
  ///
  /// If coming from a Material [Theme] and unspecified, [primaryContrastingColor]
  /// will be derived from the Material [ThemeData]'s `colorScheme.onPrimary`.
  ///
  /// Reading this property from [CupertinoTheme.of] will create a dependency
  /// from the [BuildContext] to changes in this property.
  Color get primaryContrastingColor {
    return _primaryContrastingColor ??
        (_isLight ? CupertinoColors.white : CupertinoColors.black);
  }

  final CupertinoTextTheme _textTheme;
  /// Text styles used by Cupertino widgets.
  ///
  /// Derived from [brightness] and [primaryColor] if unspecified, including
  /// [brightness] and [primaryColor] of a Material [ThemeData] if coming
  /// from a Material [Theme].
  ///
  /// Reading this property from [CupertinoTheme.of] will create a dependency
  /// from the [BuildContext] to changes in this property.
  CupertinoTextTheme get textTheme {
    return _textTheme ?? CupertinoTextTheme(
      brightness: brightness,
      primaryColor: primaryColor,
    );
  }

  final Color _barBackgroundColor;
  /// Background color of the top nav bar and bottom tab bar.
  ///
  /// Defaults to a light gray or a dark gray translucent color depending
  /// on the [brightness].
  ///
  /// Reading this property from [CupertinoTheme.of] will create a dependency
  /// from the [BuildContext] to changes in this property.
  Color get barBackgroundColor {
    return _barBackgroundColor ??
        (_isLight ? _kDefaultBarLightBackgroundColor : _kDefaultBarDarkBackgroundColor);
  }

  final Color _scaffoldBackgroundColor;
  /// Background color of the scaffold.
  ///
  /// Defaults to white or black depending on the [brightness].
  ///
  /// Reading this property from [CupertinoTheme.of] will create a dependency
  /// from the [BuildContext] to changes in this property.
  Color get scaffoldBackgroundColor {
    return _scaffoldBackgroundColor ??
        (_isLight ? CupertinoColors.white : CupertinoColors.black);
  }

  final Color _tableBackgroundColor;
  /// Background color of a table view behind cell groups.
  ///
  /// Defaults to a [CupertinoColors.extraLightBackgroundGray] or
  /// [CupertinoColors.darkBackgroundGray] depending on the [brightness].
  ///
  /// Reading this property from [CupertinoTheme.of] will create a dependency
  /// from the [BuildContext] to changes in this property.
  Color get tableBackgroundColor {
    return _tableBackgroundColor ??
        (_isLight ? CupertinoColors.extraLightBackgroundGray : CupertinoColors.darkBackgroundGray);
  }

  /// Return an instance of the [CupertinoThemeData] whose property getters
  /// only return the construction time specifications with no derived values.
  CupertinoThemeData raw() {
    return _RawCupertinoThemeData(
      _brightness,
      _primaryColor,
      _primaryContrastingColor,
      _textTheme,
      _barBackgroundColor,
      _scaffoldBackgroundColor,
      _tableBackgroundColor,
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
    CupertinoTextTheme textTheme,
    Color barBackgroundColor,
    Color scaffoldBackgroundColor,
    Color tableBackgroundColor,
  }) {
    return CupertinoThemeData(
      brightness: brightness ?? _brightness,
      primaryColor: primaryColor ?? _primaryColor,
      primaryContrastingColor: primaryContrastingColor ?? _primaryContrastingColor,
      textTheme: textTheme ?? _textTheme,
      barBackgroundColor: barBackgroundColor ?? _barBackgroundColor,
      scaffoldBackgroundColor: scaffoldBackgroundColor ?? _scaffoldBackgroundColor,
      tableBackgroundColor: tableBackgroundColor ?? _tableBackgroundColor,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    const CupertinoThemeData defaultData = CupertinoThemeData();
    properties.add(EnumProperty<Brightness>('brightness', brightness, defaultValue: defaultData.brightness));
    properties.add(DiagnosticsProperty<Color>('primaryColor', primaryColor, defaultValue: defaultData.primaryColor));
    properties.add(DiagnosticsProperty<Color>('primaryContrastingColor', primaryContrastingColor, defaultValue: defaultData.primaryContrastingColor));
    properties.add(DiagnosticsProperty<CupertinoTextTheme>('textTheme', textTheme, defaultValue: defaultData.textTheme));
    properties.add(DiagnosticsProperty<Color>('barBackgroundColor', barBackgroundColor, defaultValue: defaultData.barBackgroundColor));
    properties.add(DiagnosticsProperty<Color>('scaffoldBackgroundColor', scaffoldBackgroundColor, defaultValue: defaultData.scaffoldBackgroundColor));
    properties.add(DiagnosticsProperty<Color>('tableBackgroundColor', tableBackgroundColor, defaultValue: defaultData.tableBackgroundColor));
  }
}

@immutable
class _RawCupertinoThemeData extends CupertinoThemeData {
  const _RawCupertinoThemeData(
    this.brightness,
    this.primaryColor,
    this.primaryContrastingColor,
    this.textTheme,
    this.barBackgroundColor,
    this.scaffoldBackgroundColor,
    this.tableBackgroundColor,
  ) : super.raw(
        brightness,
        primaryColor,
        primaryContrastingColor,
        textTheme,
        barBackgroundColor,
        scaffoldBackgroundColor,
        tableBackgroundColor,
      );

  @override final Brightness brightness;
  @override final Color primaryColor;
  @override final Color primaryContrastingColor;
  @override final CupertinoTextTheme textTheme;
  @override final Color barBackgroundColor;
  @override final Color scaffoldBackgroundColor;
  @override final Color tableBackgroundColor;
}
