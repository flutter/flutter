// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'constants.dart';
import 'theme.dart';

/// The collapsing effect while the space bar expands or collapses.
enum CollapseMode {
  /// The background widget will scroll in a parallax fashion.
  parallax,

  /// The background widget pin in place until it reaches the min extent.
  pin,

  /// The background widget will act as normal with no collapsing effect.
  none,
}

/// The part of a material design [AppBar] that expands and collapses.
///
/// Most commonly used in in the [SliverAppBar.flexibleSpace] field, a flexible
/// space bar expands and contracts as the app scrolls so that the [AppBar]
/// reaches from the top of the app to the top of the scrolling contents of the
/// app.
///
/// The widget that sizes the [AppBar] must wrap it in the widget returned by
/// [FlexibleSpaceBar.createSettings], to convey sizing information down to the
/// [FlexibleSpaceBar].
///
/// See also:
///
///  * [SliverAppBar], which implements the expanding and contracting.
///  * [AppBar], which is used by [SliverAppBar].
///  * <https://material.google.com/patterns/scrolling-techniques.html>
class FlexibleSpaceBar extends StatefulWidget {
  /// Creates a flexible space bar.
  ///
  /// Most commonly used in the [AppBar.flexibleSpace] field.
  const FlexibleSpaceBar({
    Key key,
    this.title,
    this.background,
    this.centerTitle,
    this.collapseMode = CollapseMode.parallax
  }) : assert(collapseMode != null),
       super(key: key);

  /// The primary contents of the flexible space bar when expanded.
  ///
  /// Typically a [Text] widget.
  final Widget title;

  /// Shown behind the [title] when expanded.
  ///
  /// Typically an [Image] widget with [Image.fit] set to [BoxFit.cover].
  final Widget background;

  /// Whether the title should be centered.
  ///
  /// Defaults to being adapted to the current [TargetPlatform].
  final bool centerTitle;

  /// Collapse effect while scrolling.
  ///
  /// Defaults to [CollapseMode.parallax].
  final CollapseMode collapseMode;

  /// Wraps a widget that contains an [AppBar] to convey sizing information down
  /// to the [FlexibleSpaceBar].
  ///
  /// Used by [Scaffold] and [SliverAppBar].
  ///
  /// `toolbarOpacity` affects how transparent the text within the toolbar
  /// appears. `minExtent` sets the minimum height of the resulting
  /// [FlexibleSpaceBar] when fully collapsed. `maxExtent` sets the maximum
  /// height of the resulting [FlexibleSpaceBar] when fully expanded.
  /// `currentExtent` sets the scale of the [FlexibleSpaceBar.background] and
  /// [FlexibleSpaceBar.title] widgets of [FlexibleSpaceBar] upon
  /// initialization.
  ///
  /// See also:
  ///
  ///   * [FlexibleSpaceBarSettings] which creates a settings object that can be
  ///     used to specify these settings to a [FlexibleSpaceBar].
  static Widget createSettings({
    double toolbarOpacity,
    double minExtent,
    double maxExtent,
    @required double currentExtent,
    @required Widget child,
  }) {
    assert(currentExtent != null);
    return FlexibleSpaceBarSettings(
      toolbarOpacity: toolbarOpacity ?? 1.0,
      minExtent: minExtent ?? currentExtent,
      maxExtent: maxExtent ?? currentExtent,
      currentExtent: currentExtent,
      child: child,
    );
  }

  @override
  _FlexibleSpaceBarState createState() => _FlexibleSpaceBarState();
}

class _FlexibleSpaceBarState extends State<FlexibleSpaceBar> {
  bool _getEffectiveCenterTitle(ThemeData theme) {
    if (widget.centerTitle != null)
      return widget.centerTitle;
    assert(theme.platform != null);
    switch (theme.platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        return false;
      case TargetPlatform.iOS:
        return true;
    }
    return null;
  }

  Alignment _getTitleAlignment(bool effectiveCenterTitle) {
    if (effectiveCenterTitle)
      return Alignment.bottomCenter;
    final TextDirection textDirection = Directionality.of(context);
    assert(textDirection != null);
    switch (textDirection) {
      case TextDirection.rtl:
        return Alignment.bottomRight;
      case TextDirection.ltr:
        return Alignment.bottomLeft;
    }
    return null;
  }

  double _getCollapsePadding(double t, FlexibleSpaceBarSettings settings) {
    switch (widget.collapseMode) {
      case CollapseMode.pin:
        return -(settings.maxExtent - settings.currentExtent);
      case CollapseMode.none:
        return 0.0;
      case CollapseMode.parallax:
        final double deltaExtent = settings.maxExtent - settings.minExtent;
        return -Tween<double>(begin: 0.0, end: deltaExtent / 4.0).transform(t);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final FlexibleSpaceBarSettings settings = context.inheritFromWidgetOfExactType(FlexibleSpaceBarSettings);
    assert(settings != null, 'A FlexibleSpaceBar must be wrapped in the widget returned by FlexibleSpaceBar.createSettings().');

    final List<Widget> children = <Widget>[];

    final double deltaExtent = settings.maxExtent - settings.minExtent;

    // 0.0 -> Expanded
    // 1.0 -> Collapsed to toolbar
    final double t = (1.0 - (settings.currentExtent - settings.minExtent) / deltaExtent).clamp(0.0, 1.0);

    // background image
    if (widget.background != null) {
      final double fadeStart = math.max(0.0, 1.0 - kToolbarHeight / deltaExtent);
      const double fadeEnd = 1.0;
      assert(fadeStart <= fadeEnd);
      final double opacity = 1.0 - Interval(fadeStart, fadeEnd).transform(t);
      if (opacity > 0.0) {
        children.add(Positioned(
          top: _getCollapsePadding(t, settings),
          left: 0.0,
          right: 0.0,
          height: settings.maxExtent,
          child: Opacity(
            opacity: opacity,
            child: widget.background
          )
        ));
      }
    }

    if (widget.title != null) {
      Widget title;
      switch (defaultTargetPlatform) {
        case TargetPlatform.iOS:
          title = widget.title;
          break;
        case TargetPlatform.fuchsia:
        case TargetPlatform.android:
          title = Semantics(
            namesRoute: true,
            child: widget.title,
          );
      }

      final ThemeData theme = Theme.of(context);
      final double opacity = settings.toolbarOpacity;
      if (opacity > 0.0) {
        TextStyle titleStyle = theme.primaryTextTheme.title;
        titleStyle = titleStyle.copyWith(
          color: titleStyle.color.withOpacity(opacity)
        );
        final bool effectiveCenterTitle = _getEffectiveCenterTitle(theme);
        final double scaleValue = Tween<double>(begin: 1.5, end: 1.0).transform(t);
        final Matrix4 scaleTransform = Matrix4.identity()
          ..scale(scaleValue, scaleValue, 1.0);
        final Alignment titleAlignment = _getTitleAlignment(effectiveCenterTitle);
        children.add(Container(
          padding: EdgeInsetsDirectional.only(
            start: effectiveCenterTitle ? 0.0 : 72.0,
            bottom: 16.0
          ),
          child: Transform(
            alignment: titleAlignment,
            transform: scaleTransform,
            child: Align(
              alignment: titleAlignment,
              child: DefaultTextStyle(
                style: titleStyle,
                child: title,
              )
            )
          )
        ));
      }
    }

    return ClipRect(child: Stack(children: children));
  }
}

/// Provides sizing and opacity information to a [FlexibleSpaceBar].
///
/// See also:
///
///   * [FlexibleSpaceBar] which creates a flexible space bar.
class FlexibleSpaceBarSettings extends InheritedWidget {
  /// Creates a Flexible Space Bar Settings widget.
  ///
  /// Used by [Scaffold] and [SliverAppBar]. [child] must have a
  /// [FlexibleSpaceBar] widget in its tree for the settings to take affect.
  const FlexibleSpaceBarSettings({
    Key key,
    this.toolbarOpacity,
    this.minExtent,
    this.maxExtent,
    @required this.currentExtent,
    @required Widget child,
  }) :  assert(currentExtent != null),
        super(key: key, child: child);

  /// Affects how transparent the text within the toolbar appears.
  final double toolbarOpacity;

  /// Minimum height of the resulting [FlexibleSpaceBar] when fully collapsed.
  final double minExtent;

  /// Maximum height of the resulting [FlexibleSpaceBar] when fully expanded.
  final double maxExtent;

  /// If the [FlexibleSpaceBar.title] or the [FlexibleSpaceBar.background] is
  /// not null, then this value is used to calculate the relative scale of
  /// these elements upon initialization.
  final double currentExtent;

  @override
  bool updateShouldNotify(FlexibleSpaceBarSettings oldWidget) {
    return toolbarOpacity != oldWidget.toolbarOpacity
        || minExtent != oldWidget.minExtent
        || maxExtent != oldWidget.maxExtent
        || currentExtent != oldWidget.currentExtent;
  }
}
