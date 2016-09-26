// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'theme.dart';

const double _kMinScrollbarThumbExtent = 18.0;
const double _kScrollbarThumbGirth = 6.0;
const Duration _kScrollbarThumbFadeDuration = const Duration(milliseconds: 300);

class _Painter extends CustomPainter {
  _Painter({
    this.scrollOffset,
    this.scrollDirection,
    this.contentExtent,
    this.containerExtent,
    this.color
  });

  final double scrollOffset;
  final Axis scrollDirection;
  final double contentExtent;
  final double containerExtent;
  final Color color;

  void paintScrollbar(Canvas canvas, Size size) {
    Point thumbOrigin;
    Size thumbSize;

    switch (scrollDirection) {
      case Axis.vertical:
        double thumbHeight = size.height * containerExtent / contentExtent;
        thumbHeight = thumbHeight.clamp(_kMinScrollbarThumbExtent, size.height);
        final double maxThumbTop = size.height - thumbHeight;
        double thumbTop = (scrollOffset / (contentExtent - containerExtent)) * maxThumbTop;
        thumbTop = thumbTop.clamp(0.0, maxThumbTop);
        thumbOrigin = new Point(size.width - _kScrollbarThumbGirth, thumbTop);
        thumbSize = new Size(_kScrollbarThumbGirth, thumbHeight);
        break;
      case Axis.horizontal:
        double thumbWidth = size.width * containerExtent / contentExtent;
        thumbWidth = thumbWidth.clamp(_kMinScrollbarThumbExtent, size.width);
        final double maxThumbLeft = size.width - thumbWidth;
        double thumbLeft = (scrollOffset / (contentExtent - containerExtent)) * maxThumbLeft;
        thumbLeft = thumbLeft.clamp(0.0, maxThumbLeft);
        thumbOrigin = new Point(thumbLeft, size.height - _kScrollbarThumbGirth);
        thumbSize = new Size(thumbWidth, _kScrollbarThumbGirth);
        break;
    }

    final Paint paint = new Paint()..color = color;
    canvas.drawRect(thumbOrigin & thumbSize, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (scrollOffset == null || color.alpha == 0)
      return;
    paintScrollbar(canvas, size);
  }

  @override
  bool shouldRepaint(_Painter oldPainter) {
    return oldPainter.scrollOffset != scrollOffset
        || oldPainter.scrollDirection != scrollDirection
        || oldPainter.contentExtent != contentExtent
        || oldPainter.containerExtent != containerExtent
        || oldPainter.color != color;
  }
}

/// Displays a scrollbar that tracks the scrollOffset of its child's [Scrollable]
/// descendant. If the Scrollbar's child has more than one Scrollable descendant
/// the scrollableKey parameter can be used to identify the one the Scrollbar
/// should track.
class Scrollbar extends StatefulWidget {
  /// Creates a scrollbar.
  ///
  /// The child argument must not be null.
  Scrollbar({ Key key, this.scrollableKey, this.child }) : super(key: key) {
    assert(child != null);
  }

  /// Identifies the [Scrollable] descendant of child that the scrollbar will
  /// track. Can be null if there's only one [Scrollable] descendant.
  final Key scrollableKey;

  /// The scrollbar will be stacked on top of this child. The scrollbar will
  /// display when child's [Scrollable] descendant is scrolled.
  final Widget child;

  @override
  _ScrollbarState createState() => new _ScrollbarState();
}

class _ScrollbarState extends State<Scrollbar> with SingleTickerProviderStateMixin {
  AnimationController _fade;
  CurvedAnimation _opacity;
  double _scrollOffset;
  Axis _scrollDirection;
  double _containerExtent;
  double _contentExtent;

  @override
  void initState() {
    super.initState();
    _fade = new AnimationController(duration: _kScrollbarThumbFadeDuration, vsync: this);
    _opacity = new CurvedAnimation(parent: _fade, curve: Curves.fastOutSlowIn);
  }

  @override
  void dispose() {
    _fade.stop();
    super.dispose();
  }

  void _updateState(ScrollableState scrollable) {
    if (scrollable.scrollBehavior is! ExtentScrollBehavior)
      return;
    if (_scrollOffset != scrollable.scrollOffset)
      setState(() { _scrollOffset = scrollable.scrollOffset; });
    if (_scrollDirection != scrollable.config.scrollDirection)
      setState(() { _scrollDirection = scrollable.config.scrollDirection; });
    final ExtentScrollBehavior scrollBehavior = scrollable.scrollBehavior;
    if (_contentExtent != scrollBehavior.contentExtent)
      setState(() { _contentExtent = scrollBehavior.contentExtent; });
    if (_containerExtent != scrollBehavior.containerExtent)
      setState(() { _containerExtent = scrollBehavior.containerExtent; });
  }

  void _onScrollStarted(ScrollableState scrollable) {
    _updateState(scrollable);
  }

  void _onScrollUpdated(ScrollableState scrollable) {
    _updateState(scrollable);
    if (_fade.status != AnimationStatus.completed)
      _fade.forward();
  }

  void _onScrollEnded(ScrollableState scrollable) {
    _updateState(scrollable);
    _fade.reverse();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (config.scrollableKey == null) {
      if (notification.depth != 0)
        return false;
    } else if (config.scrollableKey != notification.scrollable.config.key) {
      return false;
    }

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
            foregroundPainter: new _Painter(
              scrollOffset: _scrollOffset,
              scrollDirection: _scrollDirection,
              containerExtent: _containerExtent,
              contentExtent: _contentExtent,
              color: Theme.of(context).highlightColor.withOpacity(_opacity.value)
            ),
            child: child
          );
        },
        child: config.child
      )
    );
  }
}
