// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'app_bar_theme.dart';
import 'banner_theme.dart';
import 'bottom_app_bar_theme.dart';
import 'bottom_sheet_theme.dart';
import 'button_bar_theme.dart';
import 'button_theme.dart';
import 'card_theme.dart';
import 'chip_theme.dart';
import 'color_scheme.dart';
import 'colors.dart';
import 'dialog_theme.dart';
import 'divider_theme.dart';
import 'floating_action_button_theme.dart';
import 'ink_well.dart';
import 'input_decorator.dart';
import 'material_localizations.dart';
import 'navigation_rail_theme.dart';
import 'page_transitions_theme.dart';
import 'popup_menu_theme.dart';
import 'slider_theme.dart';
import 'snack_bar_theme.dart';
import 'tab_bar_theme.dart';
import 'text_theme.dart';
import 'theme_data.dart';
import 'toggle_buttons_theme.dart';
import 'tooltip_theme.dart';
import 'typography.dart';

export 'theme_data.dart' show Brightness, ThemeData;

/// The duration over which theme changes animate by default.
const Duration kThemeAnimationDuration = Duration(milliseconds: 200);

/// Applies a theme to descendant widgets.
///
/// A theme describes the colors and typographic choices of an application.
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
  ///
  /// The [data] and [child] arguments must not be null.
  const Theme({
    Key key,
    @required this.data,
    this.isMaterialAppTheme = false,
    @required this.child,
  })  : assert(child != null),
        assert(data != null),
        super(key: key);

  /// Creates a theme that controls the the colors and typographic choices of
  /// descendant widgets, and merges in the current theme, if any.
  ///
  /// The [child] argument must not be null.
  static Widget merge({
    Key key,
    Brightness brightness,
    VisualDensity visualDensity,
    MaterialColor primarySwatch,
    Color primaryColor,
    Brightness primaryColorBrightness,
    Color primaryColorLight,
    Color primaryColorDark,
    Color accentColor,
    Brightness accentColorBrightness,
    Color canvasColor,
    Color scaffoldBackgroundColor,
    Color bottomAppBarColor,
    Color cardColor,
    Color dividerColor,
    Color focusColor,
    Color hoverColor,
    Color highlightColor,
    Color splashColor,
    InteractiveInkFeatureFactory splashFactory,
    Color selectedRowColor,
    Color unselectedWidgetColor,
    Color disabledColor,
    Color buttonColor,
    ButtonThemeData buttonTheme,
    ToggleButtonsThemeData toggleButtonsTheme,
    Color secondaryHeaderColor,
    Color textSelectionColor,
    Color cursorColor,
    Color textSelectionHandleColor,
    Color backgroundColor,
    Color dialogBackgroundColor,
    Color indicatorColor,
    Color hintColor,
    Color errorColor,
    Color toggleableActiveColor,
    String fontFamily,
    TextTheme textTheme,
    TextTheme primaryTextTheme,
    TextTheme accentTextTheme,
    InputDecorationTheme inputDecorationTheme,
    IconThemeData iconTheme,
    IconThemeData primaryIconTheme,
    IconThemeData accentIconTheme,
    SliderThemeData sliderTheme,
    TabBarTheme tabBarTheme,
    TooltipThemeData tooltipTheme,
    CardTheme cardTheme,
    ChipThemeData chipTheme,
    TargetPlatform platform,
    MaterialTapTargetSize materialTapTargetSize,
    bool applyElevationOverlayColor,
    PageTransitionsTheme pageTransitionsTheme,
    AppBarTheme appBarTheme,
    BottomAppBarTheme bottomAppBarTheme,
    ColorScheme colorScheme,
    DialogTheme dialogTheme,
    FloatingActionButtonThemeData floatingActionButtonTheme,
    NavigationRailThemeData navigationRailTheme,
    Typography typography,
    CupertinoThemeData cupertinoOverrideTheme,
    SnackBarThemeData snackBarTheme,
    BottomSheetThemeData bottomSheetTheme,
    PopupMenuThemeData popupMenuTheme,
    MaterialBannerThemeData bannerTheme,
    DividerThemeData dividerTheme,
    ButtonBarThemeData buttonBarTheme,
    @required Widget child,
  }) {
    return Builder(
      builder: (BuildContext context) {
        return Theme(
          key: key,
          data: Theme.of(context).copyWith(
            brightness: brightness,
            visualDensity: visualDensity,
            primarySwatch: primarySwatch,
            primaryColor: primaryColor,
            primaryColorLight: primaryColorLight,
            primaryColorDark: primaryColorDark,
            accentColor: accentColor,
            accentColorBrightness: accentColorBrightness,
            canvasColor: canvasColor,
            scaffoldBackgroundColor: scaffoldBackgroundColor,
            bottomAppBarColor: bottomAppBarColor,
            cardColor: cardColor,
            dividerColor: dividerColor,
            focusColor: focusColor,
            hoverColor: hoverColor,
            highlightColor: highlightColor,
            splashColor: splashColor,
            splashFactory: splashFactory,
            selectedRowColor: selectedRowColor,
            unselectedWidgetColor: unselectedWidgetColor,
            disabledColor: disabledColor,
            buttonColor: buttonColor,
            buttonTheme: buttonTheme,
            toggleButtonsTheme: toggleButtonsTheme,
            secondaryHeaderColor: secondaryHeaderColor,
            textSelectionColor: textSelectionColor,
            cursorColor: cursorColor,
            textSelectionHandleColor: textSelectionHandleColor,
            backgroundColor: backgroundColor,
            dialogBackgroundColor: dialogBackgroundColor,
            indicatorColor: indicatorColor,
            hintColor: hintColor,
            errorColor: errorColor,
            toggleableActiveColor: toggleableActiveColor,
            fontFamily: fontFamily,
            textTheme: textTheme,
            primaryTextTheme: primaryTextTheme,
            accentTextTheme: accentTextTheme,
            inputDecorationTheme: inputDecorationTheme,
            iconTheme: iconTheme,
            chipTheme: chipTheme,
            platform: platform,
            materialTapTargetSize: materialTapTargetSize,
            applyElevationOverlayColor: applyElevationOverlayColor,
            pageTransitionsTheme: pageTransitionsTheme,
            appBarTheme: appBarTheme,
            bottomAppBarTheme: bottomAppBarTheme,
            colorScheme: colorScheme,
            dialogTheme: dialogTheme,
            floatingActionButtonTheme: floatingActionButtonTheme,
            navigationRailTheme: navigationRailTheme,
            typography: typography,
            cupertinoOverrideTheme: cupertinoOverrideTheme,
            snackBarTheme: snackBarTheme,
            bottomSheetTheme: bottomSheetTheme,
            popupMenuTheme: popupMenuTheme,
            bannerTheme: bannerTheme,
            dividerTheme: dividerTheme,
            buttonBarTheme: buttonBarTheme,
          ),
          child: child,
        );
      },
    );
  }

  /// Specifies the color and typography values for descendant widgets.
  final ThemeData data;

  /// True if this theme was installed by the [MaterialApp].
  ///
  /// When an app uses the [Navigator] to push a route, the route's widgets
  /// will only inherit from the app's theme, even though the widget that
  /// triggered the push may inherit from a theme that "shadows" the app's
  /// theme because it's deeper in the widget tree. Apps can find the shadowing
  /// theme with `Theme.of(context, shadowThemeOnly: true)` and pass it along
  /// to the class that creates a route's widgets. Material widgets that push
  /// routes, like [PopupMenuButton] and [DropdownButton], do this.
  final bool isMaterialAppTheme;

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  static final ThemeData _kFallbackTheme = ThemeData.fallback();

  /// The data from the closest [Theme] instance that encloses the given
  /// context.
  ///
  /// If the given context is enclosed in a [Localizations] widget providing
  /// [MaterialLocalizations], the returned data is localized according to the
  /// nearest available [MaterialLocalizations].
  ///
  /// Defaults to [new ThemeData.fallback] if there is no [Theme] in the given
  /// build context.
  ///
  /// If [shadowThemeOnly] is true and the closest [Theme] ancestor was
  /// installed by the [MaterialApp] — in other words if the closest [Theme]
  /// ancestor does not shadow the application's theme — then this returns null.
  /// This argument should be used in situations where its useful to wrap a
  /// route's widgets with a [Theme], but only when the application's overall
  /// theme is being shadowed by a [Theme] widget that is deeper in the tree.
  /// See [isMaterialAppTheme].
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// @override
  /// Widget build(BuildContext context) {
  ///   return Text(
  ///     'Example',
  ///     style: Theme.of(context).textTheme.headline6,
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
  ///     body: Builder(
  ///       // Create an inner BuildContext so that we can refer to
  ///       // the Theme with Theme.of().
  ///       builder: (BuildContext context) {
  ///         return Center(
  ///           child: Text(
  ///             'Example',
  ///             style: Theme.of(context).textTheme.headline6,
  ///           ),
  ///         );
  ///       },
  ///     ),
  ///   );
  /// }
  /// ```
  static ThemeData of(BuildContext context, { bool shadowThemeOnly = false }) {
    final _InheritedTheme inheritedTheme = context.dependOnInheritedWidgetOfExactType<_InheritedTheme>();
    if (shadowThemeOnly) {
      if (inheritedTheme == null || inheritedTheme.theme.isMaterialAppTheme)
        return null;
      return inheritedTheme.theme.data;
    }

    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    final ScriptCategory category = localizations?.scriptCategory ?? ScriptCategory.englishLike;
    final ThemeData theme = inheritedTheme?.theme?.data ?? _kFallbackTheme;
    return ThemeData.localize(theme, theme.typography.geometryThemeFor(category));
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedTheme(
      theme: this,
      child: CupertinoTheme(
        // We're using a MaterialBasedCupertinoThemeData here instead of a
        // CupertinoThemeData because it defers some properties to the Material
        // ThemeData.
        data: MaterialBasedCupertinoThemeData(
          materialTheme: data,
        ),
        child: IconTheme(
          data: data.iconTheme,
          child: child,
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

class _InheritedTheme extends InheritedTheme {
  const _InheritedTheme({
    Key key,
    @required this.theme,
    @required Widget child,
  }) : assert(theme != null),
       super(key: key, child: child);

  final Theme theme;

  @override
  Widget wrap(BuildContext context, Widget child) {
    final _InheritedTheme ancestorTheme = context.findAncestorWidgetOfExactType<_InheritedTheme>();
    return identical(this, ancestorTheme) ? child : Theme(data: theme.data, child: child);
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
  ThemeDataTween({ ThemeData begin, ThemeData end }) : super(begin: begin, end: end);

  @override
  ThemeData lerp(double t) => ThemeData.lerp(begin, end, t);
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
  /// By default, the theme transition uses a linear curve. The [data] and
  /// [child] arguments must not be null.
  const AnimatedTheme({
    Key key,
    @required this.data,
    this.isMaterialAppTheme = false,
    Curve curve = Curves.linear,
    Duration duration = kThemeAnimationDuration,
    VoidCallback onEnd,
    @required this.child,
  }) : assert(child != null),
       assert(data != null),
       super(key: key, curve: curve, duration: duration, onEnd: onEnd);

  /// Specifies the color and typography values for descendant widgets.
  final ThemeData data;

  /// True if this theme was created by the [MaterialApp]. See [Theme.isMaterialAppTheme].
  final bool isMaterialAppTheme;

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  @override
  _AnimatedThemeState createState() => _AnimatedThemeState();
}

class _AnimatedThemeState extends AnimatedWidgetBaseState<AnimatedTheme> {
  ThemeDataTween _data;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    // TODO(ianh): Use constructor tear-offs when it becomes possible
    _data = visitor(_data, widget.data, (dynamic value) => ThemeDataTween(begin: value as ThemeData)) as ThemeDataTween;
    assert(_data != null);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      isMaterialAppTheme: widget.isMaterialAppTheme,
      child: widget.child,
      data: _data.evaluate(animation),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(DiagnosticsProperty<ThemeDataTween>('data', _data, showName: false, defaultValue: null));
  }
}
