// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

// All values eyeballed.
const Color _kScrollbarColor = const Color(0x99999999);
const double _kScrollbarThickness = 2.5;
const double _kScrollbarDistanceFromEdge = 2.5;
const Radius _kScrollbarRadius = const Radius.circular(1.25);
const Duration _kScrollbarTimeToFade = const Duration(milliseconds: 20);

/// A iOS style scrollbar.
///
/// A scrollbar indicates which portion of a [Scrollable] widget is actually
/// visible.
///
/// To add a scrollbar to a [ScrollView], simply wrap the scroll view widget in
/// a [CupertinoScrollbar] widget.
///
/// See also:
///
///  * [ListView], which display a linear, scrollable list of children.
///  * [GridView], which display a 2 dimensional, scrollable array of children.
class CupertinoScrollbar extends StatefulWidget {
  /// Creates an iOS style scrollbar that wraps the given [child].
  ///
  /// The [child] should be a source of [ScrollNotification] notifications,
  /// typically a [Scrollable] widget.
  const CupertinoScrollbar({
    Key key,
    @required this.child,
  }) : super(key: key);

  /// The subtree to place inside the [CupertinoScrollbar].
  ///
  /// This should include a source of [ScrollNotification] notifications,
  /// typically a [Scrollable] widget.
  final Widget child;

  @override
  _CupertinoScrollbarState createState() => new _CupertinoScrollbarState();
}

ScrollbarPainter buildScrollbarPainter(TickerProvider vsync) {
  return new ScrollbarPainter(
    vsync: vsync,
    thickness: _kScrollbarThickness,
    distanceFromEdge: _kScrollbarDistanceFromEdge,
    radius: _kScrollbarRadius,
    timeToFadeout: _kScrollbarTimeToFade,
  )
      ..color = _kScrollbarColor;
}

class _CupertinoScrollbarState extends State<CupertinoScrollbar> with TickerProviderStateMixin {
  ScrollbarPainter _painter;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _painter ??= buildScrollbarPainter(this);
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
