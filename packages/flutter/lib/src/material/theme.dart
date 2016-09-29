// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'theme_data.dart';

export 'theme_data.dart' show Brightness, ThemeData;

/// The duration over which theme changes animate.
const Duration kThemeAnimationDuration = const Duration(milliseconds: 200);

/// Applies a theme to descendant widgets.
///
/// See also:
///
///  * [AnimatedTheme]
///  * [ThemeData]
///  * [MaterialApp]
class Theme extends InheritedWidget {
  /// Applies the given theme [data] to [child].
  ///
  /// The [data] and [child] arguments must not be null.
  Theme({
    Key key,
    @required this.data,
    this.isMaterialAppTheme: false,
    Widget child
  }) : super(key: key, child: child) {
    assert(child != null);
    assert(data != null);
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

  static final ThemeData _kFallbackTheme = new ThemeData.fallback();

  /// The data from the closest instance of this class that encloses the given context.
  ///
  /// Defaults to the fallback theme data if none exists.
  ///
  /// If [shadowThemeOnly] is true and the closest Theme ancestor was installed by
  /// the [MaterialApp] - in other words if the closest Theme ancestor does not
  /// shadow the app's theme - then return null. This property is specified in
  /// situations where its useful to wrap a route's widgets with a Theme, but only
  /// when the app's theme is being shadowed by a theme widget that is farather
  /// down in the tree. See [isMaterialAppTheme].
  static ThemeData of(BuildContext context, { bool shadowThemeOnly: false }) {
    final Theme theme = context.inheritFromWidgetOfExactType(Theme);
    final ThemeData themeData = theme?.data ?? _kFallbackTheme;
    return shadowThemeOnly ? (theme.isMaterialAppTheme ? null : themeData) : themeData;
  }

  @override
  bool updateShouldNotify(Theme old) => data != old.data;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('$data');
  }
}

/// An animated value that interpolates [ThemeData]s.
class ThemeDataTween extends Tween<ThemeData> {
  /// Creates an interpolation between [begin] and [end].
  ThemeDataTween({ ThemeData begin, ThemeData end }) : super(begin: begin, end: end);

  @override
  ThemeData lerp(double t) => ThemeData.lerp(begin, end, t);
}

/// Animated version of [Theme] which automatically transitions the colours,
/// etc, over a given duration whenever the given theme changes.
///
/// See also:
///
///  * [ThemeData]
class AnimatedTheme extends ImplicitlyAnimatedWidget {
  /// Creates an animated theme.
  ///
  /// By default, the theme transition uses a linear curve. The [data] and
  /// [child] arguments must not be null.
  AnimatedTheme({
    Key key,
    @required this.data,
    this.isMaterialAppTheme: false,
    Curve curve: Curves.linear,
    Duration duration: kThemeAnimationDuration,
    this.child
  }) : super(key: key, curve: curve, duration: duration) {
    assert(child != null);
    assert(data != null);
  }

  /// Specifies the color and typography values for descendant widgets.
  final ThemeData data;

  /// True if this theme was created by the [MaterialApp]. See [Theme.isMaterialAppTheme].
  final bool isMaterialAppTheme;

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  _AnimatedThemeState createState() => new _AnimatedThemeState();
}

class _AnimatedThemeState extends AnimatedWidgetBaseState<AnimatedTheme> {
  ThemeDataTween _data;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    // TODO(ianh): Use constructor tear-offs when it becomes possible
    _data = visitor(_data, config.data, (dynamic value) => new ThemeDataTween(begin: value));
    assert(_data != null);
  }

  @override
  Widget build(BuildContext context) {
    return new Theme(
      isMaterialAppTheme: config.isMaterialAppTheme,
      child: config.child,
      data: _data.evaluate(animation)
    );
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (_data != null)
      description.add('$_data');
  }
}
