// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'app_bar.dart';
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
///  * <https://material.google.com/patterns/scrolling-techniques.html>
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
  bool _getEffectiveCenterTitle(ThemeData theme) {
    if (config.centerTitle != null)
      return config.centerTitle;
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

  Widget _buildContent(BuildContext context, BoxConstraints constraints) {
    final Size size = constraints.biggest;
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    final double currentHeight = size.height;
    final double maxHeight = statusBarHeight + AppBar.getExpandedHeightFor(context);
    final double minHeight = statusBarHeight + kToolbarHeight;
    final double deltaHeight = maxHeight - minHeight;

    // 0.0 -> Expanded
    // 1.0 -> Collapsed to toolbar
    final double t = (1.0 - (currentHeight - minHeight) / deltaHeight).clamp(0.0, 1.0);

    final List<Widget> children = <Widget>[];

    // background image
    if (config.background != null) {
      final double fadeStart = math.max(0.0, 1.0 - kToolbarHeight / deltaHeight);
      final double fadeEnd = 1.0;
      assert(fadeStart <= fadeEnd);
      final double opacity = 1.0 - new Interval(fadeStart, fadeEnd).transform(t);
      final double parallax = new Tween<double>(begin: 0.0, end: deltaHeight / 4.0).lerp(t);
      if (opacity > 0.0) {
        children.add(new Positioned(
          top: -parallax,
          left: 0.0,
          right: 0.0,
          height: maxHeight,
          child: new Opacity(
            opacity: opacity,
            child: config.background
          )
        ));
      }
    }

    if (config.title != null) {
      final ThemeData theme = Theme.of(context);
      final double opacity = (1.0 - (minHeight - currentHeight) / (kToolbarHeight - statusBarHeight)).clamp(0.0, 1.0);
      if (opacity > 0.0) {
        TextStyle titleStyle = theme.primaryTextTheme.title;
        titleStyle = titleStyle.copyWith(
          color: titleStyle.color.withOpacity(opacity)
        );
        final bool effectiveCenterTitle = _getEffectiveCenterTitle(theme);
        final double scaleValue = new Tween<double>(begin: 1.5, end: 1.0).lerp(t);
        final Matrix4 scaleTransform = new Matrix4.identity()
          ..scale(scaleValue, scaleValue, 1.0);
        final FractionalOffset titleAlignment = effectiveCenterTitle ? FractionalOffset.bottomCenter : FractionalOffset.bottomLeft;
        children.add(new Container(
          padding: new EdgeInsets.only(
            left: effectiveCenterTitle ? 0.0 : 72.0,
            bottom: 16.0
          ),
          child: new Transform(
            alignment: titleAlignment,
            transform: scaleTransform,
            child: new Align(
              alignment: titleAlignment,
              child: new DefaultTextStyle(style: titleStyle, child: config.title)
            )
          )
        ));
      }
    }

    return new ClipRect(child: new Stack(children: children));
  }

  @override
  Widget build(BuildContext context) {
    return new LayoutBuilder(builder: _buildContent);
  }
}
