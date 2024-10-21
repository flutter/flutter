// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'dart:collection';
/// @docImport 'app.dart';
/// @docImport 'color_scheme.dart';
/// @docImport 'text_theme.dart';
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import 'material_localizations.dart';
import 'theme_data.dart';
import 'typography.dart';

export 'theme_data.dart' show Brightness, ThemeData;

/// The duration over which theme changes animate by default.
const Duration kThemeAnimationDuration = Duration(milliseconds: 200);

final ThemeData _kFallbackTheme = ThemeData.fallback();

/// Applies a theme to descendant widgets.
///
/// A theme describes the colors and typographic choices of an application.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=oTvQDJOBXmM}
///
/// Descendant widgets obtain the current theme's [ThemeData] object using
/// [Theme.of]. When a widget uses [Theme.of], it is automatically rebuilt if
/// the theme later changes, so that the changes can be applied.
///
/// The [Theme] widget implies an [IconTheme] widget, set to the value of the
/// [ThemeData.iconTheme] of the [data] for the [Theme].
///
/// See also:
///
///  * [ThemeData], which describes the actual configuration of a theme.
///  * [AnimatedTheme], which animates the [ThemeData] when it changes rather
///    than changing the theme all at once.
///  * [MaterialApp], which includes an [AnimatedTheme] widget configured via
///    the [MaterialApp.theme] argument.
class Theme extends StatelessWidget {
  /// Applies the given theme [data] to [child].
  const Theme({
    super.key,
    required this.data,
    required this.child,
  });

  /// Specifies the color and typography values for descendant widgets.
  final ThemeData data;

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  /// The data from the closest [Theme] instance that encloses the given
  /// context.
  ///
  /// If the given context is enclosed in a [Localizations] widget providing
  /// [MaterialLocalizations], the returned data is localized according to the
  /// nearest available [MaterialLocalizations].
  ///
  /// Defaults to [ThemeData.fallback] if there is no [Theme] in the given
  /// build context.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// @override
  /// Widget build(BuildContext context) {
  ///   return Text(
  ///     'Example',
  ///     style: Theme.of(context).textTheme.titleLarge,
  ///   );
  /// }
  /// ```
  ///
  /// When the [Theme] is actually created in the same `build` function
  /// (possibly indirectly, e.g. as part of a [MaterialApp]), the `context`
  /// argument to the `build` function can't be used to find the [Theme] (since
  /// it's "above" the widget being returned). In such cases, the following
  /// technique with a [Builder] can be used to provide a new scope with a
  /// [BuildContext] that is "under" the [Theme]:
  ///
  /// ```dart
  /// @override
  /// Widget build(BuildContext context) {
  ///   return MaterialApp(
  ///     theme: ThemeData.light(),
  ///     home: Builder(
  ///       // Create an inner BuildContext so that we can refer to
  ///       // the Theme with Theme.of().
  ///       builder: (BuildContext context) {
  ///         return Center(
  ///           child: Text(
  ///             'Example',
  ///             style: Theme.of(context).textTheme.titleLarge,
  ///           ),
  ///         );
  ///       },
  ///     ),
  ///   );
  /// }
  /// ```
  ///
  /// See also:
  ///
  /// * [ColorScheme.of], a convenience method that returns [ThemeData.colorScheme]
  ///   from the closest [Theme] ancestor. (equivalent to `Theme.of(context).colorScheme`).
  /// * [TextTheme.of], a convenience method that returns [ThemeData.textTheme]
  ///   from the closest [Theme] ancestor. (equivalent to `Theme.of(context).textTheme`).
  /// * [IconTheme.of], that returns [ThemeData.iconTheme] from the closest [Theme] or
  ///   [IconThemeData.fallback] if there is no [IconTheme] ancestor.
  static ThemeData of(BuildContext context) {
    final ThemeData? data = context.dependOnInheritedWidgetOfExactType<_InheritedThemeFilter>(
      aspect: const ThemeSelector<ThemeData>.from(_selectAll),
    )?.data;

    return data ?? _fallback(context);
  }
  static ThemeData _selectAll(ThemeData theme) => theme;

  static ThemeData _fallback(BuildContext context, [ThemeData? data]) {
    final MaterialLocalizations? localizations = Localizations.of<MaterialLocalizations>(context, MaterialLocalizations);
    final ScriptCategory category = localizations?.scriptCategory ?? ScriptCategory.englishLike;
    final InheritedCupertinoTheme? inheritedCupertinoTheme = context.dependOnInheritedWidgetOfExactType<InheritedCupertinoTheme>();
    final ThemeData theme = data ?? (
      inheritedCupertinoTheme != null ? CupertinoBasedMaterialThemeData(themeData: inheritedCupertinoTheme.theme.data).materialTheme : _kFallbackTheme
    );
    return ThemeData.localize(theme, theme.typography.geometryThemeFor(category));
  }

  /// {@template flutter.material.Theme.select}
  /// Evaluates [ThemeSelector.select] using [ThemeData] provided by the
  /// nearest ancestor [Theme] widget, and returns the result.
  ///
  /// When this value changes, a notification is sent to the [context]
  /// to trigger an update.
  /// {@endtemplate}
  @optionalTypeArgs
  static T select<T>(BuildContext context, T Function(ThemeData theme) select) {
    final ThemeData? data = context.dependOnInheritedWidgetOfExactType<_InheritedThemeFilter>(
      aspect: ThemeSelector<T>.from(select),
    )?.data;

    return select(data ?? _fallback(context));
  }

  /// Locates a [ThemeExtension] of the specified type using [data] provided
  /// by the nearest ancestor [Theme] widget, and returns the result.
  ///
  /// Returns null if the extension was not found.
  ///
  /// When this value changes, a notification is sent to the [context]
  /// to trigger an update.
  static T? extension<T extends ThemeExtension<T>>(BuildContext context) {
    return Theme.select(context, (ThemeData theme) => theme.extension<T>());
  }

  // The inherited themes in widgets library can not infer their values from
  // Theme in material library. Wraps the child with these inherited themes to
  // overrides their values directly.
  Widget _wrapsWidgetThemes(BuildContext context, Widget child) {
    final DefaultSelectionStyle selectionStyle = DefaultSelectionStyle.of(context);
    return IconTheme(
      data: data.iconTheme,
      child: DefaultSelectionStyle(
        selectionColor: data.textSelectionTheme.selectionColor ?? selectionStyle.selectionColor,
        cursorColor: data.textSelectionTheme.cursorColor ?? selectionStyle.cursorColor,
        child: child,
      ),
    );
  }

  CupertinoThemeData _inheritedCupertinoThemeData(BuildContext context) {
    final InheritedCupertinoTheme? inheritedTheme = context.dependOnInheritedWidgetOfExactType<InheritedCupertinoTheme>();
    return (inheritedTheme?.theme.data ?? MaterialBasedCupertinoThemeData(materialTheme: data)).resolveFrom(context);
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedTheme(
      theme: this,
      child: _ThemeFilter(
        child: CupertinoTheme(
          // If a CupertinoThemeData doesn't exist, we're using a
          // MaterialBasedCupertinoThemeData here instead of a CupertinoThemeData
          // because it defers some properties to the Material ThemeData.
          data: _inheritedCupertinoThemeData(context),
          child: _wrapsWidgetThemes(context, child),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ThemeData>('data', data, showName: false));
  }
}

/// Stores instructions for how to obtain relevant information from [ThemeData].
///
/// {@tool snippet}
/// A widget can be notified to rebuild only when the [Brightness] changes
/// as follows:
///
/// ```dart
/// class ThemeBrightness with ThemeSelector<Brightness> {
///   const ThemeBrightness();
///
///   @override
///   Brightness select(ThemeData theme) => theme.brightness;
/// }
///
/// class MyWidget extends StatelessWidget {
///   const MyWidget({super.key});
///
///   @override
///   Widget build(BuildContext context) {
///     final Brightness brightness = const ThemeBrightness().resolve(context);
///
///     final IconData icon = switch (brightness) {
///       Brightness.light => Icons.sunny,
///       Brightness.dark => Icons.nightlight,
///     };
///
///     return Icon(icon);
///   }
/// }
/// ```
/// {@end-tool}
abstract mixin class ThemeSelector<T> {
  /// Creates a [ThemeSelector] using the provided callback.
  ///
  /// Global functions can be used to make `const` theme selectors, and the
  /// `static` keyword can be used to do the same inside a class declaration.
  ///
  /// Since [ColorScheme.of] is used frequently, it defines a `const` selector
  /// so that each [InheritedFilter] aspect refers to the same instance.
  const factory ThemeSelector.from(T Function(ThemeData theme) select) = _SelectFrom<T>;

  /// Selects a value from the [ThemeData].
  ///
  /// Multiple values can be selected if [T] is a [Record] type.
  T select(ThemeData theme);

  /// {@macro flutter.material.Theme.select}
  T resolve(BuildContext context) {
    return select(
      context.dependOnInheritedWidgetOfExactType<_InheritedThemeFilter>(aspect: this)?.data
        ?? Theme._fallback(context),
    );
  }
}

class _SelectFrom<T> with ThemeSelector<T> {
  const _SelectFrom(this._select);

  final T Function(ThemeData theme) _select;

  @override
  T select(ThemeData theme) => _select(theme);
}

class _ThemeFilter extends StatelessWidget {
  const _ThemeFilter({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Theme theme = context.dependOnInheritedWidgetOfExactType<_InheritedTheme>()!.theme;
    return _InheritedThemeFilter(
      data: Theme._fallback(context, theme.data),
      child: child,
    );
  }
}

class _InheritedThemeFilter extends InheritedFilter<ThemeSelector<Object?>> {
  const _InheritedThemeFilter({required this.data, required super.child});

  final ThemeData data;

  @override
  Object? select(ThemeSelector<Object?> selector) => selector.select(data);
}

class _InheritedTheme extends InheritedTheme {
  const _InheritedTheme({
    required this.theme,
    required super.child,
  });

  final Theme theme;

  @override
  Widget wrap(BuildContext context, Widget child) {
    return Theme(data: theme.data, child: child);
  }

  @override
  bool updateShouldNotify(_InheritedTheme old) => theme.data != old.theme.data;
}

/// An interpolation between two [ThemeData]s.
///
/// This class specializes the interpolation of [Tween<ThemeData>] to call the
/// [ThemeData.lerp] method.
///
/// See [Tween] for a discussion on how to use interpolation objects.
class ThemeDataTween extends Tween<ThemeData> {
  /// Creates a [ThemeData] tween.
  ///
  /// The [begin] and [end] properties must be non-null before the tween is
  /// first used, but the arguments can be null if the values are going to be
  /// filled in later.
  ThemeDataTween({ super.begin, super.end });

  @override
  ThemeData lerp(double t) => ThemeData.lerp(begin!, end!, t);
}

/// Animated version of [Theme] which automatically transitions the colors,
/// etc, over a given duration whenever the given theme changes.
///
/// Here's an illustration of what using this widget looks like, using a [curve]
/// of [Curves.elasticInOut].
/// {@animation 250 266 https://flutter.github.io/assets-for-api-docs/assets/widgets/animated_theme.mp4}
///
/// See also:
///
///  * [Theme], which [AnimatedTheme] uses to actually apply the interpolated
///    theme.
///  * [ThemeData], which describes the actual configuration of a theme.
///  * [MaterialApp], which includes an [AnimatedTheme] widget configured via
///    the [MaterialApp.theme] argument.
class AnimatedTheme extends ImplicitlyAnimatedWidget {
  /// Creates an animated theme.
  ///
  /// By default, the theme transition uses a linear curve.
  const AnimatedTheme({
    super.key,
    required this.data,
    super.curve,
    super.duration = kThemeAnimationDuration,
    super.onEnd,
    required this.child,
  });

  /// Specifies the color and typography values for descendant widgets.
  final ThemeData data;

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  @override
  AnimatedWidgetBaseState<AnimatedTheme> createState() => _AnimatedThemeState();
}

class _AnimatedThemeState extends AnimatedWidgetBaseState<AnimatedTheme> {
  ThemeDataTween? _data;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _data = visitor(_data, widget.data, (dynamic value) => ThemeDataTween(begin: value as ThemeData))! as ThemeDataTween;
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _data!.evaluate(animation),
      child: widget.child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(DiagnosticsProperty<ThemeDataTween>('data', _data, showName: false, defaultValue: null));
  }
}
