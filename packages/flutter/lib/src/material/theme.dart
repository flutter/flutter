// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'theme_data.dart';

export 'theme_data.dart' show ThemeData, ThemeBrightness;

/// The duration over which theme changes animate.
const Duration kThemeAnimationDuration = const Duration(milliseconds: 200);

/// Applies a theme to descendant widgets.
///
/// See also:
///
///  * [AnimatedTheme]
///  * [ThemeData]
class Theme extends InheritedWidget {
  /// Applies the given theme [data] to [child].
  ///
  /// Both [child] and [data] must be non-null.
  Theme({
    Key key,
    this.data,
    Widget child
  }) : super(key: key, child: child) {
    assert(child != null);
    assert(data != null);
  }

  /// Specifies the color and typography values for descendant widgets.
  final ThemeData data;

  static final ThemeData _kFallbackTheme = new ThemeData.fallback();

  /// The data from the closest instance of this class that encloses the given context.
  ///
  /// Defaults to the fallback theme data if none exists.
  static ThemeData of(BuildContext context) {
    Theme theme = context.inheritFromWidgetOfExactType(Theme);
    return theme?.data ?? _kFallbackTheme;
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
  /// By default, the theme transition uses a linear curve. Both [data] and
  /// [child] are required.
  AnimatedTheme({
    Key key,
    this.data,
    Curve curve: Curves.linear,
    Duration duration: kThemeAnimationDuration,
    this.child
  }) : super(key: key, curve: curve, duration: duration) {
    assert(child != null);
    assert(data != null);
  }

  /// Specifies the color and typography values for descendant widgets.
  final ThemeData data;

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
