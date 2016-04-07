// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'theme.dart';

const double _kMinScrollbarThumbLength = 18.0;
const double _kScrollbarThumbGirth = 6.0;
const Duration _kScrollbarThumbFadeDuration = const Duration(milliseconds: 300);

class _ScrollbarPainter extends CustomPainter {
  _ScrollbarPainter({
    this.scrollOffset,
    this.scrollDirection,
    this.contentExtent,
    this.containerExtent,
    this.thumbColor
  });

  final double scrollOffset;
  final Axis scrollDirection;
  final double contentExtent;
  final double containerExtent;
  final Color thumbColor;

  void paintScrollbar(Canvas canvas, Size size) {
    Point thumbOrigin;
    Size thumbSize;

    switch (scrollDirection) {
      case Axis.vertical:
        double thumbHeight = size.height * containerExtent / contentExtent;
        thumbHeight = thumbHeight.clamp(_kMinScrollbarThumbLength, size.height);
        final double maxThumbTop = size.height - thumbHeight;
        double thumbTop = (scrollOffset / (contentExtent - containerExtent)) * maxThumbTop;
        thumbTop = thumbTop.clamp(0.0, maxThumbTop);
        thumbOrigin = new Point(size.width - _kScrollbarThumbGirth, thumbTop);
        thumbSize = new Size(_kScrollbarThumbGirth, thumbHeight);
        break;
      case Axis.horizontal:
        double thumbWidth = size.width * containerExtent / contentExtent;
        thumbWidth = thumbWidth.clamp(_kMinScrollbarThumbLength, size.width);
        final double maxThumbLeft = size.width - thumbWidth;
        double thumbLeft = (scrollOffset / (contentExtent - containerExtent)) * maxThumbLeft;
        thumbLeft = thumbLeft.clamp(0.0, maxThumbLeft);
        thumbOrigin = new Point(thumbLeft, size.height - _kScrollbarThumbGirth);
        thumbSize = new Size(thumbWidth, _kScrollbarThumbGirth);
        break;
    }

    final Paint paint = new Paint()..color = thumbColor;
    canvas.drawRect(thumbOrigin & thumbSize, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (scrollOffset == null || thumbColor.alpha == 0)
      return;
    paintScrollbar(canvas, size);
  }

  @override
  bool shouldRepaint(_ScrollbarPainter oldPainter) {
    return oldPainter.scrollOffset != scrollOffset
      || oldPainter.scrollDirection != scrollDirection
      || oldPainter.contentExtent != contentExtent
      || oldPainter.containerExtent != containerExtent
      || oldPainter.thumbColor != thumbColor;
  }
}

/// Displays a scrollbar that tracks the scrollOffset of its child's [Scrollable]
/// descendant. If the Scrollbar's child has more than one Scrollable descendant
/// the scrollableKey parameter can be used to identify the one the Scrollbar
/// should track.
class Scrollbar extends StatefulWidget {
  Scrollbar({ Key key, this.scrollableKey, this.child }) : super(key: key) {
    assert(child != null);
  }

  final Key scrollableKey;
  final Widget child;

  @override
  _ScrollbarState createState() => new _ScrollbarState();
}

class _ScrollbarState extends State<Scrollbar> {
  final AnimationController _fade = new AnimationController(duration: _kScrollbarThumbFadeDuration);
  CurvedAnimation _opacity;
  double _scrollOffset;
  Axis _scrollDirection;
  double _containerExtent;
  double _contentExtent;

  @override
  void initState() {
    super.initState();
    _opacity = new CurvedAnimation(parent: _fade, curve: Curves.ease);
  }

  void _updateState(ScrollableState scrollable) {
    final ExtentScrollBehavior scrollBehavior = scrollable.scrollBehavior;
    _scrollOffset = scrollable.scrollOffset;
    _scrollDirection = scrollable.config.scrollDirection;
    _contentExtent = scrollBehavior.contentExtent;
    _containerExtent = scrollBehavior.containerExtent;
  }

  void _onScrollStarted(ScrollableState scrollable) {
    _updateState(scrollable);
   _fade.forward();
  }

  void _onScrollUpdated(ScrollableState scrollable) {
    setState(() {
      _updateState(scrollable);
    });
  }

  void _onScrollEnded(ScrollableState scrollable) {
    _updateState(scrollable);
    _fade.reverse();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (config.scrollableKey == null || config.scrollableKey == notification.scrollable.config.key) {
      final ScrollableState scrollable = notification.scrollable;
      switch(notification.kind) {
        case ScrollNotificationKind.started:
          _onScrollStarted(scrollable);
          break;
        case ScrollNotificationKind.updated:
          _onScrollUpdated(scrollable);
          break;
        case ScrollNotificationKind.ended:
          _onScrollEnded(scrollable);
          break;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return new NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: new AnimatedBuilder(
        animation: _opacity,
        builder: (BuildContext context, Widget child) {
          return new CustomPaint(
            foregroundPainter: new _ScrollbarPainter(
              scrollOffset: _scrollOffset,
              scrollDirection: _scrollDirection,
              containerExtent: _containerExtent,
              contentExtent: _contentExtent,
              thumbColor: Theme.of(context).highlightColor.withOpacity(_opacity.value)
            ),
            child: child
          );
        },
        child: config.child
      )
    );
  }
}