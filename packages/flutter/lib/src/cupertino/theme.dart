// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'icon_theme_data.dart';
import 'text_theme.dart';

export 'package:flutter/foundation.dart' show Brightness;

/// An interface that defines custom additions to a [CupertinoThemeData] object.
///
/// Typically used for custom colors. To use, subclass [CupertinoThemeExtension],
/// define a number of fields (e.g. [Color]s), and implement the [copyWith] and
/// [resolveFrom] methods. The latter will ensure smooth transitions of properties when
/// switching themes.
///
/// {@tool dartpad}
/// This sample shows how to create and use a subclass of [CupertinoThemeExtension] that
/// defines two colors.
///
/// ** See code in examples/api/lib/cupertino/theme/cupertino_theme_extension.1.dart **
/// {@end-tool}
abstract class CupertinoThemeExtension<T extends CupertinoThemeExtension<T>> {
  /// Enable const constructor for subclasses.
  const CupertinoThemeExtension();

  /// The extension's type.
  Object get type => T;

  /// Creates a copy of this theme extension with the given fields
  /// replaced by the non-null parameter values.
  CupertinoThemeExtension<T> copyWith();

  /// Resolves this [CupertinoThemeExtension] using the provided [BuildContext].
  CupertinoThemeExtension<T> resolveFrom(BuildContext context);
}

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
  false,
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
    super.key,
    required this.data,
    required this.child,
  });

  /// The [CupertinoThemeData] styling for this theme.
  final CupertinoThemeData data;

  /// Retrieves the [CupertinoThemeData] from the closest ancestor [CupertinoTheme]
  /// widget, or a default [CupertinoThemeData] if no [CupertinoTheme] ancestor
  /// exists.
  ///
  /// Resolves all the colors defined in that [CupertinoThemeData] against the
  /// given [BuildContext] on a best-effort basis.
  static CupertinoThemeData of(BuildContext context) {
    final _InheritedCupertinoTheme? inheritedTheme = context.dependOnInheritedWidgetOfExactType<_InheritedCupertinoTheme>();
    return (inheritedTheme?.theme.data ?? CupertinoThemeData()).resolveFrom(context);
  }

  /// Retrieves the [Brightness] to use for descendant Cupertino widgets, based
  /// on the value of [CupertinoThemeData.brightness] in the given [context].
  ///
  /// If no [CupertinoTheme] can be found in the given [context], or its `brightness`
  /// is null, it will fall back to [MediaQueryData.platformBrightness].
  ///
  /// Throws an exception if no valid [CupertinoTheme] or [MediaQuery] widgets
  /// exist in the ancestry tree.
  ///
  /// See also:
  ///
  /// * [maybeBrightnessOf], which returns null if no valid [CupertinoTheme] or
  ///   [MediaQuery] exists, instead of throwing.
  /// * [CupertinoThemeData.brightness], the property takes precedence over
  ///   [MediaQueryData.platformBrightness] for descendant Cupertino widgets.
  static Brightness brightnessOf(BuildContext context) {
    final _InheritedCupertinoTheme? inheritedTheme = context.dependOnInheritedWidgetOfExactType<_InheritedCupertinoTheme>();
    return inheritedTheme?.theme.data.brightness ?? MediaQuery.platformBrightnessOf(context);
  }

  /// Retrieves the [Brightness] to use for descendant Cupertino widgets, based
  /// on the value of [CupertinoThemeData.brightness] in the given [context].
  ///
  /// If no [CupertinoTheme] can be found in the given [context], it will fall
  /// back to [MediaQueryData.platformBrightness].
  ///
  /// Returns null if no valid [CupertinoTheme] or [MediaQuery] widgets exist in
  /// the ancestry tree.
  ///
  /// See also:
  ///
  /// * [CupertinoThemeData.brightness], the property takes precedence over
  ///   [MediaQueryData.platformBrightness] for descendant Cupertino widgets.
  /// * [brightnessOf], which throws if no valid [CupertinoTheme] or
  ///   [MediaQuery] exists, instead of returning null.
  static Brightness? maybeBrightnessOf(BuildContext context) {
    final _InheritedCupertinoTheme? inheritedTheme = context.dependOnInheritedWidgetOfExactType<_InheritedCupertinoTheme>();
    return inheritedTheme?.theme.data.brightness ?? MediaQuery.maybePlatformBrightnessOf(context);
  }

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
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
    required this.theme,
    required super.child,
  });

  final CupertinoTheme theme;

  @override
  bool updateShouldNotify(_InheritedCupertinoTheme old) => theme.data != old.theme.data;
}

/// Convert the [extensionsIterable] passed to [CupertinoThemeData.new] or [copyWith]
/// to the stored [extensions] map, where each entry's key consists of the extension's type.
Map<Object, CupertinoThemeExtension<dynamic>> _themeExtensionIterableToMap(Iterable<CupertinoThemeExtension<dynamic>> extensionsIterable) {
  return Map<Object, CupertinoThemeExtension<dynamic>>.unmodifiable(<Object, CupertinoThemeExtension<dynamic>>{
    // Strangely, the cast is necessary for tests to run.
    for (final CupertinoThemeExtension<dynamic> extension in extensionsIterable) extension.type: extension as CupertinoThemeExtension<CupertinoThemeExtension<dynamic>>,
  });
}

/// Returns a copy of the current [extensions] with all the fields resolved 
/// against the given [BuildContext].
Map<Object, CupertinoThemeExtension<dynamic>>? _resolveThemeExtensions(Map<Object, CupertinoThemeExtension<dynamic>>? extensions, BuildContext context) {
  final Map<Object, CupertinoThemeExtension<dynamic>>? newExtensions = extensions?.map((Object id, CupertinoThemeExtension<dynamic> extension) {
    return MapEntry<Object, CupertinoThemeExtension<dynamic>>(id, extension.resolveFrom(context));
  });
  return newExtensions;
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
class CupertinoThemeData extends NoDefaultCupertinoThemeData with Diagnosticable {
  /// Creates a [CupertinoTheme] styling specification.
  ///
  /// Unspecified parameters default to a reasonable iOS default style.
  factory CupertinoThemeData({
    Brightness? brightness,
    Iterable<CupertinoThemeExtension<dynamic>>? extensions,
    Color? primaryColor,
    Color? primaryContrastingColor,
    CupertinoTextThemeData? textTheme,
    Color? barBackgroundColor,
    Color? scaffoldBackgroundColor,
    bool? applyThemeToAll,
  }) => CupertinoThemeData.raw(
      brightness,
      (extensions != null) ? _themeExtensionIterableToMap(extensions) : null,
      primaryColor,
      primaryContrastingColor,
      textTheme,
      barBackgroundColor,
      scaffoldBackgroundColor,
      applyThemeToAll,
    );

  /// Same as the default constructor but with positional arguments to avoid
  /// forgetting any and to specify all arguments.
  ///
  /// Used by subclasses to get the superclass's defaulting behaviors.
  @protected
  const CupertinoThemeData.raw(
    Brightness? brightness,
    Map<Object, CupertinoThemeExtension<dynamic>>? extensions,
    Color? primaryColor,
    Color? primaryContrastingColor,
    CupertinoTextThemeData? textTheme,
    Color? barBackgroundColor,
    Color? scaffoldBackgroundColor,
    bool? applyThemeToAll,
  ) : _defaults = _kDefaultTheme,
      super.raw(
        brightness: brightness,
        extensions: extensions,
        primaryColor: primaryColor,
        primaryContrastingColor: primaryContrastingColor,
        textTheme: textTheme,
        barBackgroundColor: barBackgroundColor,
        scaffoldBackgroundColor: scaffoldBackgroundColor,
        applyThemeToAll: applyThemeToAll,
      );

  const CupertinoThemeData._rawWithDefaults(
    Brightness? brightness,
    Map<Object, CupertinoThemeExtension<dynamic>>? extensions,
    Color? primaryColor,
    Color? primaryContrastingColor,
    CupertinoTextThemeData? textTheme,
    Color? barBackgroundColor,
    Color? scaffoldBackgroundColor,
    bool? applyThemeToAll,
    this._defaults,
  ) : super.raw(
    brightness: brightness,
    extensions: extensions,
    primaryColor: primaryColor,
    primaryContrastingColor: primaryContrastingColor,
    textTheme: textTheme,
    barBackgroundColor: barBackgroundColor,
    scaffoldBackgroundColor: scaffoldBackgroundColor,
    applyThemeToAll: applyThemeToAll,
  );

  final _CupertinoThemeDefaults _defaults;

  @override
  Color get primaryColor => super.primaryColor ?? _defaults.primaryColor;

  @override
  Color get primaryContrastingColor => super.primaryContrastingColor ?? _defaults.primaryContrastingColor;

  @override
  CupertinoTextThemeData get textTheme {
    return super.textTheme ?? _defaults.textThemeDefaults.createDefaults(primaryColor: primaryColor);
  }

  @override
  Color get barBackgroundColor => super.barBackgroundColor ?? _defaults.barBackgroundColor;

  @override
  Color get scaffoldBackgroundColor => super.scaffoldBackgroundColor ?? _defaults.scaffoldBackgroundColor;

  @override
  bool get applyThemeToAll => super.applyThemeToAll ?? _defaults.applyThemeToAll;

  @override
  NoDefaultCupertinoThemeData noDefault() {
    return NoDefaultCupertinoThemeData.raw(
      brightness: super.brightness,
      extensions: super.extensions,
      primaryColor: super.primaryColor,
      primaryContrastingColor: super.primaryContrastingColor,
      textTheme: super.textTheme,
      barBackgroundColor: super.barBackgroundColor,
      scaffoldBackgroundColor: super.scaffoldBackgroundColor,
      applyThemeToAll: super.applyThemeToAll,
    );
  }

  @override
  CupertinoThemeData resolveFrom(BuildContext context) {
    Color? convertColor(Color? color) => CupertinoDynamicColor.maybeResolve(color, context);

    return CupertinoThemeData._rawWithDefaults(
      brightness,
      _resolveThemeExtensions(extensions, context),
      convertColor(super.primaryColor),
      convertColor(super.primaryContrastingColor),
      super.textTheme?.resolveFrom(context),
      convertColor(super.barBackgroundColor),
      convertColor(super.scaffoldBackgroundColor),
      applyThemeToAll,
      _defaults.resolveFrom(context, super.textTheme == null),
    );
  }

  @override
  CupertinoThemeData copyWith({
    Brightness? brightness,
    Iterable<CupertinoThemeExtension<dynamic>>? extensions,
    Color? primaryColor,
    Color? primaryContrastingColor,
    CupertinoTextThemeData? textTheme,
    Color? barBackgroundColor,
    Color? scaffoldBackgroundColor,
    bool? applyThemeToAll,
  }) {
    return CupertinoThemeData._rawWithDefaults(
      brightness ?? super.brightness,
      (extensions != null) ? _themeExtensionIterableToMap(extensions) : super.extensions,
      primaryColor ?? super.primaryColor,
      primaryContrastingColor ?? super.primaryContrastingColor,
      textTheme ?? super.textTheme,
      barBackgroundColor ?? super.barBackgroundColor,
      scaffoldBackgroundColor ?? super.scaffoldBackgroundColor,
      applyThemeToAll ?? super.applyThemeToAll,
      _defaults,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    final CupertinoThemeData defaultData = CupertinoThemeData();
    properties.add(EnumProperty<Brightness>('brightness', brightness, defaultValue: null));
    properties.add(IterableProperty<CupertinoThemeExtension<dynamic>>('extensions', extensions?.values, defaultValue: null, level: DiagnosticLevel.debug));
    properties.add(createCupertinoColorProperty('primaryColor', primaryColor, defaultValue: defaultData.primaryColor));
    properties.add(createCupertinoColorProperty('primaryContrastingColor', primaryContrastingColor, defaultValue: defaultData.primaryContrastingColor));
    properties.add(createCupertinoColorProperty('barBackgroundColor', barBackgroundColor, defaultValue: defaultData.barBackgroundColor));
    properties.add(createCupertinoColorProperty('scaffoldBackgroundColor', scaffoldBackgroundColor, defaultValue: defaultData.scaffoldBackgroundColor));
    properties.add(DiagnosticsProperty<bool>('applyThemeToAll', applyThemeToAll, defaultValue: defaultData.applyThemeToAll));
    textTheme.debugFillProperties(properties);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is CupertinoThemeData
      && other.brightness == brightness
      && mapEquals(other.extensions, extensions)
      && other.primaryColor == primaryColor
      && other.primaryContrastingColor == primaryContrastingColor
      && other.textTheme == textTheme
      && other.barBackgroundColor == barBackgroundColor
      && other.scaffoldBackgroundColor == scaffoldBackgroundColor
      && other.applyThemeToAll == applyThemeToAll;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    brightness,
    ...?extensions?.keys,
    ...?extensions?.values,
    primaryColor,
    primaryContrastingColor,
    textTheme,
    barBackgroundColor,
    scaffoldBackgroundColor,
    applyThemeToAll,
  ]);
}

/// Styling specifications for a cupertino theme without default values for
/// unspecified properties.
///
/// Unlike [CupertinoThemeData] instances of this class do not return default
/// values for properties that have been left unspecified in the constructor.
/// Instead, unspecified properties will return null. This is used by
/// Material's [ThemeData.cupertinoOverrideTheme].
///
/// See also:
///
///  * [CupertinoThemeData], which uses reasonable default values for
///    unspecified theme properties.
class NoDefaultCupertinoThemeData {
  /// Creates a [NoDefaultCupertinoThemeData] styling specification.
  ///
  /// Unspecified properties default to null.
  factory NoDefaultCupertinoThemeData({
    Brightness? brightness,
    Iterable<CupertinoThemeExtension<dynamic>>? extensions,
    Color? primaryColor,
    Color? primaryContrastingColor,
    CupertinoTextThemeData? textTheme,
    Color? barBackgroundColor,
    Color? scaffoldBackgroundColor,
    bool? applyThemeToAll,
  }) => CupertinoThemeData.raw(
      brightness,
      (extensions != null) ? _themeExtensionIterableToMap(extensions) : null,
      primaryColor,
      primaryContrastingColor,
      textTheme,
      barBackgroundColor,
      scaffoldBackgroundColor,
      applyThemeToAll,
    );

  /// Same as the default constructor but with positional arguments to avoid
  /// forgetting any and to specify all arguments.
  ///
  /// Used by subclasses to get the superclass's defaulting behaviors.
  const NoDefaultCupertinoThemeData.raw({
    this.brightness,
    this.extensions,
    this.primaryColor,
    this.primaryContrastingColor,
    this.textTheme,
    this.barBackgroundColor,
    this.scaffoldBackgroundColor,
    this.applyThemeToAll,
  });

  /// The brightness override for Cupertino descendants.
  ///
  /// Defaults to null. If a non-null [Brightness] is specified, the value will
  /// take precedence over the ambient [MediaQueryData.platformBrightness], when
  /// determining the brightness of descendant Cupertino widgets.
  ///
  /// If coming from a Material [Theme] and unspecified, [brightness] will be
  /// derived from the Material [ThemeData]'s [brightness].
  ///
  /// See also:
  ///
  ///  * [MaterialBasedCupertinoThemeData], a [CupertinoThemeData] that defers
  ///    [brightness] to its Material [Theme] parent if it's unspecified.
  ///
  ///  * [CupertinoTheme.brightnessOf], a method used to retrieve the overall
  ///    [Brightness] from a [BuildContext], for Cupertino widgets.
  final Brightness? brightness;

  /// Arbitrary additions to this theme.
  ///
  /// To define extensions, pass an [Iterable] containing one or more [CupertinoThemeExtension]
  /// subclasses to [CupertinoThemeData.new] or [copyWith].
  ///
  /// To obtain an extension, use [extension].
  ///
  /// {@tool dartpad}
  /// This sample shows how to create and use a subclass of [CupertinoThemeExtension] that
  /// defines two colors.
  ///
  /// ** See code in examples/api/lib/cupertino/theme/cupertino_theme_extension.1.dart **
  /// {@end-tool}
  ///
  /// See also:
  ///
  /// * [extension], a convenience function for obtaining a specific extension.
  final Map<Object, CupertinoThemeExtension<dynamic>>? extensions;

  /// Used to obtain a particular [CupertinoThemeExtension] from [extensions].
  ///
  /// Obtain with `CupertinoTheme.of(context).extension<MyThemeExtension>()`.
  ///
  /// See [extensions] for an interactive example.
  T? extension<T>() => extensions?[T] as T?;

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
  final Color? primaryColor;

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
  final Color? primaryContrastingColor;

  /// Text styles used by Cupertino widgets.
  ///
  /// Derived from [primaryColor] if unspecified.
  final CupertinoTextThemeData? textTheme;

  /// Background color of the top nav bar and bottom tab bar.
  ///
  /// Defaults to a light gray in light mode, or a dark translucent gray color in
  /// dark mode.
  final Color? barBackgroundColor;

  /// Background color of the scaffold.
  ///
  /// Defaults to [CupertinoColors.systemBackground].
  final Color? scaffoldBackgroundColor;

  /// Flag to apply this theme to all descendant Cupertino widgets.
  ///
  /// Certain Cupertino widgets previously didn't use theming, matching past
  /// versions of iOS. For example, [CupertinoSwitch]s always used
  /// [CupertinoColors.systemGreen] when active.
  ///
  /// Today, however, these widgets can indeed be themed on iOS. Moreover on
  /// macOS, the accent color is reflected in these widgets. Turning this flag
  /// on ensures that descendant Cupertino widgets will be themed accordingly.
  ///
  /// This flag currently applies to the following widgets:
  /// - [CupertinoSwitch] & [Switch.adaptive]
  ///
  /// Defaults to false.
  final bool? applyThemeToAll;

  /// Returns an instance of the theme data whose property getters only return
  /// the construction time specifications with no derived values.
  ///
  /// Used in Material themes to let unspecified properties fallback to Material
  /// theme properties instead of iOS defaults.
  NoDefaultCupertinoThemeData noDefault() => this;

  /// Returns a new theme data with all its colors resolved against the
  /// given [BuildContext].
  ///
  /// Called by [CupertinoTheme.of] to resolve colors defined in the retrieved
  /// [CupertinoThemeData].
  @protected
  NoDefaultCupertinoThemeData resolveFrom(BuildContext context) {
    Color? convertColor(Color? color) => CupertinoDynamicColor.maybeResolve(color, context);

    return NoDefaultCupertinoThemeData.raw(
      brightness: brightness,
      extensions: _resolveThemeExtensions(extensions, context),
      primaryColor: convertColor(primaryColor),
      primaryContrastingColor: convertColor(primaryContrastingColor),
      textTheme: textTheme?.resolveFrom(context),
      barBackgroundColor: convertColor(barBackgroundColor),
      scaffoldBackgroundColor: convertColor(scaffoldBackgroundColor),
      applyThemeToAll: applyThemeToAll,
    );
  }

  /// Creates a copy of the theme data with specified attributes overridden.
  ///
  /// Only the current instance's specified attributes are copied instead of
  /// derived values. For instance, if the current [textTheme] is implied from
  /// the current [primaryColor] because it was not specified, copying with a
  /// different [primaryColor] will also change the copy's implied [textTheme].
  NoDefaultCupertinoThemeData copyWith({
    Brightness? brightness,
    Iterable<CupertinoThemeExtension<dynamic>>? extensions,
    Color? primaryColor,
    Color? primaryContrastingColor,
    CupertinoTextThemeData? textTheme,
    Color? barBackgroundColor,
    Color? scaffoldBackgroundColor,
    bool? applyThemeToAll,
  }) {
    return NoDefaultCupertinoThemeData.raw(
      brightness: brightness ?? this.brightness,
      extensions: (extensions != null) ? _themeExtensionIterableToMap(extensions) : this.extensions,
      primaryColor: primaryColor ?? this.primaryColor,
      primaryContrastingColor: primaryContrastingColor ?? this.primaryContrastingColor,
      textTheme: textTheme ?? this.textTheme,
      barBackgroundColor: barBackgroundColor ?? this.barBackgroundColor,
      scaffoldBackgroundColor: scaffoldBackgroundColor ?? this.scaffoldBackgroundColor,
      applyThemeToAll: applyThemeToAll ?? this.applyThemeToAll,
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
    this.applyThemeToAll,
    this.textThemeDefaults,
  );

  final Brightness? brightness;
  final Color primaryColor;
  final Color primaryContrastingColor;
  final Color barBackgroundColor;
  final Color scaffoldBackgroundColor;
  final bool applyThemeToAll;
  final _CupertinoTextThemeDefaults textThemeDefaults;

  _CupertinoThemeDefaults resolveFrom(BuildContext context, bool resolveTextTheme) {
    Color convertColor(Color color) => CupertinoDynamicColor.resolve(color, context);

    return _CupertinoThemeDefaults(
      brightness,
      convertColor(primaryColor),
      convertColor(primaryContrastingColor),
      convertColor(barBackgroundColor),
      convertColor(scaffoldBackgroundColor),
      applyThemeToAll,
      resolveTextTheme ? textThemeDefaults.resolveFrom(context) : textThemeDefaults,
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

  _CupertinoTextThemeDefaults resolveFrom(BuildContext context) {
    return _CupertinoTextThemeDefaults(
      CupertinoDynamicColor.resolve(labelColor, context),
      CupertinoDynamicColor.resolve(inactiveGray, context),
    );
  }

  CupertinoTextThemeData createDefaults({ required Color primaryColor }) {
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
    required this.labelColor,
    required this.inactiveGray,
    required super.primaryColor,
  });

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
