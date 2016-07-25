// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'debug.dart';
import 'constants.dart';
import 'scaffold.dart';
import 'theme.dart';

/// The part of a material design [AppBar] that expands and collapses.
///
/// Most commonly used in in the [AppBar.flexibleSpace] field, a flexible space
/// bar expands and contracts as the app scrolls so that the [AppBar] reaches
/// from the top of the app to the top of the scrolling contents of the app.
///
/// Requires one of its ancestors to be a [Scaffold] widget because the
/// [Scaffold] coordinates the scrolling effect between the flexible space and
/// its body.
///
/// See also:
///
///  * [AppBar]
///  * [Scaffold]
///  * <https://www.google.com/design/spec/patterns/scrolling-techniques.html>
class FlexibleSpaceBar extends StatefulWidget {
  /// Creates a flexible space bar.
  ///
  /// Most commonly used in the [AppBar.flexibleSpace] field. Requires one of
  /// its ancestors to be a [Scaffold] widget.
  FlexibleSpaceBar({
    Key key,
    this.title,
    this.background,
    this.centerTitle
  }) : super(key: key);

  /// The primary contents of the flexible space bar when expanded.
  ///
  /// Typically a [Text] widget.
  final Widget title;

  /// Shown behind the [title] when expanded.
  ///
  /// Typically an [AssetImage] widget with [AssetImage.fit] set to [ImageFit.cover].
  final Widget background;

  /// Whether the title should be centered.
  ///
  /// Defaults to being adapted to the current [TargetPlatform].
  final bool centerTitle;

  @override
  _FlexibleSpaceBarState createState() => new _FlexibleSpaceBarState();
}

class _FlexibleSpaceBarState extends State<FlexibleSpaceBar> {
  Animation<double> _scaffoldAnimation;

  void _handleTick() {
    setState(() {
      // The animation's state is our build state, and it changed already.
    });
  }

  @override
  void deactivate() {
    _scaffoldAnimation?.removeListener(_handleTick);
    _scaffoldAnimation = null;
    super.deactivate();
  }

  bool _getEffectiveCenterTitle(ThemeData theme) {
    if (config.centerTitle != null)
      return config.centerTitle;
    assert(theme.platform != null);
    switch (theme.platform) {
      case TargetPlatform.android:
        return false;
      case TargetPlatform.iOS:
        return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasScaffold(context));
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final ScaffoldState scaffold = Scaffold.of(context);
    _scaffoldAnimation ??= scaffold.appBarAnimation..addListener(_handleTick);
    final double appBarHeight = scaffold.appBarHeight + statusBarHeight;
    final double toolBarHeight = kToolBarHeight + statusBarHeight;
    final List<Widget> children = <Widget>[];

    // background image
    if (config.background != null) {
      final double fadeStart = (appBarHeight - toolBarHeight * 2.0) / appBarHeight;
      final double fadeEnd = (appBarHeight - toolBarHeight) / appBarHeight;
      final CurvedAnimation opacityCurve = new CurvedAnimation(
        parent: _scaffoldAnimation,
        curve: new Interval(math.max(0.0, fadeStart), math.min(fadeEnd, 1.0))
      );
      final double parallax = new Tween<double>(begin: 0.0, end: appBarHeight / 4.0).evaluate(_scaffoldAnimation);
      final double opacity = new Tween<double>(begin: 1.0, end: 0.0).evaluate(opacityCurve);
      if (opacity > 0.0) {
        children.add(new Positioned(
          top: -parallax,
          left: 0.0,
          right: 0.0,
          child: new Opacity(
            opacity: opacity,
            child: new SizedBox(
              height: appBarHeight + statusBarHeight,
              child: config.background
            )
          )
        ));
      }
    }

    // title
    if (config.title != null) {
      final ThemeData theme = Theme.of(context);
      final double fadeStart = (appBarHeight - toolBarHeight) / appBarHeight;
      final double fadeEnd = (appBarHeight - toolBarHeight / 2.0) / appBarHeight;
      final CurvedAnimation opacityCurve = new CurvedAnimation(
        parent: _scaffoldAnimation,
        curve: new Interval(fadeStart, fadeEnd)
      );
      final int alpha = new Tween<double>(begin: 255.0, end: 0.0).evaluate(opacityCurve).toInt();
      if (alpha > 0) {
        TextStyle titleStyle = theme.primaryTextTheme.title;
        titleStyle = titleStyle.copyWith(
          color: titleStyle.color.withAlpha(alpha)
        );
        final double yAlignStart = 1.0;
        final double yAlignEnd = (statusBarHeight + kToolBarHeight / 2.0) / toolBarHeight;
        final double scaleAndAlignEnd = (appBarHeight - toolBarHeight) / appBarHeight;
        final CurvedAnimation scaleAndAlignCurve = new CurvedAnimation(
          parent: _scaffoldAnimation,
          curve: new Interval(0.0, scaleAndAlignEnd)
        );
        final bool effectiveCenterTitle = _getEffectiveCenterTitle(theme);
        final FractionalOffset titleAlignment = effectiveCenterTitle ? FractionalOffset.bottomCenter : FractionalOffset.bottomLeft;
        children.add(new Padding(
          padding: new EdgeInsets.only(left: effectiveCenterTitle ? 0.0 : 72.0, bottom: 14.0),
          child: new Align(
            alignment: new Tween<FractionalOffset>(
              begin: new FractionalOffset(0.0, yAlignStart),
              end: new FractionalOffset(0.0, yAlignEnd)
            ).evaluate(scaleAndAlignCurve),
            child: new ScaleTransition(
              alignment: titleAlignment,
              scale: new Tween<double>(begin: 1.5, end: 1.0).animate(scaleAndAlignCurve),
              child: new Align(
                alignment: titleAlignment,
                child: new DefaultTextStyle(style: titleStyle, child: config.title)
              )
            )
          )
        ));
      }
    }

    return new ClipRect(child: new Stack(children: children));
  }
}
