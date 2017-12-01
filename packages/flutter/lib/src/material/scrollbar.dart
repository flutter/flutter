// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

const double _kScrollbarThickness = 6.0;

/// A material design scrollbar.
///
/// A scrollbar indicates which portion of a [Scrollable] widget is actually
/// visible.
///
/// Dynamically changes to a iOS style scrollbar that looks like
/// [CupertinoScrollbar] on iOS platform.
///
/// To add a scrollbar to a [ScrollView], simply wrap the scroll view widget in
/// a [Scrollbar] widget.
///
/// See also:
///
///  * [ListView], which display a linear, scrollable list of children.
///  * [GridView], which display a 2 dimensional, scrollable array of children.
class Scrollbar extends StatefulWidget {
  /// Creates a material design scrollbar that wraps the given [child].
  ///
  /// The [child] should be a source of [ScrollNotification] notifications,
  /// typically a [Scrollable] widget.
  const Scrollbar({
    Key key,
    @required this.child,
  }) : super(key: key);

  /// The subtree to place inside the [Scrollbar].
  ///
  /// This should include a source of [ScrollNotification] notifications,
  /// typically a [Scrollable] widget.
  final Widget child;

  @override
  _ScrollbarState createState() => new _ScrollbarState();

  static ScrollbarPainter buildMaterialScrollbarPainter(TickerProvider vsync) {
    return new ScrollbarPainter(
        vsync: vsync,
        thickness: _kScrollbarThickness,
        crossAxisMargin: 0.0,
      );
  }
}


class _ScrollbarState extends State<Scrollbar> with TickerProviderStateMixin {
  ScrollbarPainter _painter;
  TargetPlatform _lastPlatform;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final ThemeData theme = Theme.of(context);
    if (_lastPlatform != null && _lastPlatform != theme.platform) {
      _painter.dispose();
      _painter = null;
    }

    if (theme.platform == TargetPlatform.iOS) {
      _painter ??= CupertinoScrollbar.buildCupertinoScrollbarPainter(this);
    } else {
      _painter ??= Scrollbar.buildMaterialScrollbarPainter(this);
      _painter.color = theme.highlightColor;
    }

    _painter.textDirection = Directionality.of(context);
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification ||
        notification is OverscrollNotification)
      _painter.update(notification.metrics, notification.metrics.axisDirection);
    return false;
  }

  @override
  void dispose() {
    _painter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      // TODO(ianh): Maybe we should try to collapse out these repaint
      // boundaries when the scroll bars are invisible.
      child: new RepaintBoundary(
        child: new CustomPaint(
          foregroundPainter: _painter,
          child: new RepaintBoundary(
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
