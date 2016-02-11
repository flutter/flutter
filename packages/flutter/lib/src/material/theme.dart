// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'theme_data.dart';

export 'theme_data.dart' show ThemeData, ThemeBrightness;

const kThemeAnimationDuration = const Duration(milliseconds: 200);

class Theme extends InheritedWidget {
  Theme({
    Key key,
    this.data,
    Widget child
  }) : super(key: key, child: child) {
    assert(child != null);
    assert(data != null);
  }

  final ThemeData data;

  static final ThemeData _kFallbackTheme = new ThemeData.fallback();

  /// The data from the closest instance of this class that encloses the given context.
  ///
  /// Defaults to the fallback theme data if none exists.
  static ThemeData of(BuildContext context) {
    Theme theme = context.inheritFromWidgetOfExactType(Theme);
    return theme?.data ?? _kFallbackTheme;
  }

  bool updateShouldNotify(Theme old) => data != old.data;

  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('$data');
  }
}

/// An animated value that interpolates [ThemeData]s.
class ThemeDataTween extends Tween<ThemeData> {
  ThemeDataTween({ ThemeData begin, ThemeData end }) : super(begin: begin, end: end);

  ThemeData lerp(double t) => ThemeData.lerp(begin, end, t);
}

/// Animated version of [Theme] which automatically transitions the colours,
/// etc, over a given duration whenever the given theme changes.
class AnimatedTheme extends AnimatedWidgetBase {
  AnimatedTheme({
    Key key,
    this.data,
    Curve curve: Curves.linear,
    Duration duration,
    this.child
  }) : super(key: key, curve: curve, duration: duration) {
    assert(child != null);
    assert(data != null);
  }

  final ThemeData data;

  final Widget child;

  _AnimatedThemeState createState() => new _AnimatedThemeState();
}

class _AnimatedThemeState extends AnimatedWidgetBaseState<AnimatedTheme> {
  ThemeDataTween _data;

  void forEachTween(TweenVisitor visitor) {
    // TODO(ianh): Use constructor tear-offs when it becomes possible
    _data = visitor(_data, config.data, (dynamic value) => new ThemeDataTween(begin: value));
    assert(_data != null);
  }

  Widget build(BuildContext context) {
    return new Theme(
      child: config.child,
      data: _data.evaluate(animation)
    );
  }

  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (_data != null)
      description.add('$_data');
  }
}
