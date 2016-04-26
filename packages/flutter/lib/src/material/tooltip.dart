// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'theme.dart';

const double _kDefaultTooltipBorderRadius = 2.0;
const double _kDefaultTooltipHeight = 32.0;
const EdgeInsets _kDefaultTooltipPadding = const EdgeInsets.symmetric(horizontal: 16.0);
const double _kDefaultVerticalTooltipOffset = 24.0;
const EdgeInsets _kDefaultTooltipScreenEdgeMargin = const EdgeInsets.all(10.0);
const Duration _kDefaultTooltipFadeDuration = const Duration(milliseconds: 200);
const Duration _kDefaultTooltipShowDuration = const Duration(seconds: 2);

class Tooltip extends StatefulWidget {
  Tooltip({
    Key key,
    this.message,
    this.backgroundColor,
    this.textColor,
    this.style,
    this.opacity: 0.9,
    this.borderRadius: _kDefaultTooltipBorderRadius,
    this.height: _kDefaultTooltipHeight,
    this.padding: _kDefaultTooltipPadding,
    this.verticalOffset: _kDefaultVerticalTooltipOffset,
    this.screenEdgeMargin: _kDefaultTooltipScreenEdgeMargin,
    this.preferBelow: true,
    this.fadeDuration: _kDefaultTooltipFadeDuration,
    this.showDuration: _kDefaultTooltipShowDuration,
    this.child
  }) : super(key: key) {
    assert(message != null);
    assert(opacity != null);
    assert(borderRadius != null);
    assert(height != null);
    assert(padding != null);
    assert(verticalOffset != null);
    assert(screenEdgeMargin != null);
    assert(preferBelow != null);
    assert(fadeDuration != null);
    assert(showDuration != null);
    assert(child != null);
  }

  final String message;

  final Color backgroundColor;

  final Color textColor;

  final TextStyle style;

  final double opacity;

  final double borderRadius;

  final double height;

  /// The amount of space by which to inset the child.
  ///
  /// Defaults to 16.0 logical pixels in each direction.
  final EdgeInsets padding;

  final double verticalOffset;

  final EdgeInsets screenEdgeMargin;

  final bool preferBelow;

  final Duration fadeDuration;

  final Duration showDuration;

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  _TooltipState createState() => new _TooltipState();

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('"$message"');
    description.add('vertical offset: $verticalOffset');
    description.add('position: ${preferBelow ? "below" : "above"}');
  }
}

class _TooltipState extends State<Tooltip> {

  AnimationController _controller;
  OverlayEntry _entry;
  Timer _timer;

  @override
  void initState() {
    super.initState();
    _controller = new AnimationController(duration: config.fadeDuration)
      ..addStatusListener((AnimationStatus status) {
        switch (status) {
          case AnimationStatus.completed:
            assert(_entry != null);
            assert(_timer == null);
            resetShowTimer();
            break;
          case AnimationStatus.dismissed:
            assert(_entry != null);
            assert(_timer == null);
            _entry.remove();
            _entry = null;
            break;
          default:
            break;
        }
      });
  }

  @override
  void didUpdateConfig(Tooltip oldConfig) {
    super.didUpdateConfig(oldConfig);
    if (config.fadeDuration != oldConfig.fadeDuration)
      _controller.duration = config.fadeDuration;
    if (_entry != null &&
        (config.message != oldConfig.message ||
         config.backgroundColor != oldConfig.backgroundColor ||
         config.style != oldConfig.style ||
         config.textColor != oldConfig.textColor ||
         config.borderRadius != oldConfig.borderRadius ||
         config.height != oldConfig.height ||
         config.padding != oldConfig.padding ||
         config.opacity != oldConfig.opacity ||
         config.verticalOffset != oldConfig.verticalOffset ||
         config.screenEdgeMargin != oldConfig.screenEdgeMargin ||
         config.preferBelow != oldConfig.preferBelow))
      _entry.markNeedsBuild();
  }

  void resetShowTimer() {
    assert(_controller.status == AnimationStatus.completed);
    assert(_entry != null);
    _timer = new Timer(config.showDuration, hideTooltip);
  }

  void showTooltip() {
    if (_entry == null) {
      RenderBox box = context.findRenderObject();
      Point target = box.localToGlobal(box.size.center(Point.origin));
      _entry = new OverlayEntry(builder: (BuildContext context) {
        TextStyle textStyle = (config.style ?? Theme.of(context).textTheme.body1).copyWith(color: config.textColor ?? Colors.white);
        return new _TooltipOverlay(
          message: config.message,
          backgroundColor: config.backgroundColor ?? Colors.grey[700],
          style: textStyle,
          borderRadius: config.borderRadius,
          height: config.height,
          padding: config.padding,
          opacity: config.opacity,
          animation: new CurvedAnimation(
            parent: _controller,
            curve: Curves.ease
          ),
          target: target,
          verticalOffset: config.verticalOffset,
          screenEdgeMargin: config.screenEdgeMargin,
          preferBelow: config.preferBelow
        );
      });
      Overlay.of(context, debugRequiredFor: config).insert(_entry);
    }
    _timer?.cancel();
    if (_controller.status != AnimationStatus.completed) {
      _timer = null;
      _controller.forward();
    } else {
      resetShowTimer();
    }
  }

  void hideTooltip() {
    assert(_entry != null);
    _timer?.cancel();
    _timer = null;
    _controller.reverse();
  }

  @override
  void deactivate() {
    if (_entry != null)
      hideTooltip();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    assert(Overlay.of(context, debugRequiredFor: config) != null);
    return new GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: showTooltip,
      excludeFromSemantics: true,
      child: new Semantics(
        label: config.message,
        child: config.child
      )
    );
  }
}

class _TooltipPositionDelegate extends SingleChildLayoutDelegate {
  _TooltipPositionDelegate({
    this.target,
    this.verticalOffset,
    this.screenEdgeMargin,
    this.preferBelow
  });
  final Point target;
  final double verticalOffset;
  final EdgeInsets screenEdgeMargin;
  final bool preferBelow;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) => constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    // VERTICAL DIRECTION
    final bool fitsBelow = target.y + verticalOffset + childSize.height <= size.height - screenEdgeMargin.bottom;
    final bool fitsAbove = target.y - verticalOffset - childSize.height >= screenEdgeMargin.top;
    final bool tooltipBelow = preferBelow ? fitsBelow || !fitsAbove : !(fitsAbove || !fitsBelow);
    double y;
    if (tooltipBelow)
      y = math.min(target.y + verticalOffset, size.height - screenEdgeMargin.bottom);
    else
      y = math.max(target.y - verticalOffset - childSize.height, screenEdgeMargin.top);
    // HORIZONTAL DIRECTION
    double normalizedTargetX = target.x.clamp(screenEdgeMargin.left, size.width - screenEdgeMargin.right);
    double x;
    if (normalizedTargetX < screenEdgeMargin.left + childSize.width / 2.0) {
      x = screenEdgeMargin.left;
    } else if (normalizedTargetX > size.width - screenEdgeMargin.right - childSize.width / 2.0) {
      x = size.width - screenEdgeMargin.right - childSize.width;
    } else {
      x = normalizedTargetX - childSize.width / 2.0;
    }
    return new Offset(x, y);
  }

  @override
  bool shouldRelayout(_TooltipPositionDelegate oldDelegate) {
    return target != oldDelegate.target
        || verticalOffset != oldDelegate.verticalOffset
        || screenEdgeMargin != oldDelegate.screenEdgeMargin
        || preferBelow != oldDelegate.preferBelow;
  }
}

class _TooltipOverlay extends StatelessWidget {
  _TooltipOverlay({
    Key key,
    this.message,
    this.backgroundColor,
    this.style,
    this.borderRadius,
    this.height,
    this.padding,
    this.opacity,
    this.animation,
    this.target,
    this.verticalOffset,
    this.screenEdgeMargin,
    this.preferBelow
  }) : super(key: key);

  final String message;
  final Color backgroundColor;
  final TextStyle style;
  final double opacity;
  final double borderRadius;
  final double height;
  final EdgeInsets padding;
  final Animation<double> animation;
  final Point target;
  final double verticalOffset;
  final EdgeInsets screenEdgeMargin;
  final bool preferBelow;

  @override
  Widget build(BuildContext context) {
    return new Positioned(
      top: 0.0,
      left: 0.0,
      right: 0.0,
      bottom: 0.0,
      child: new IgnorePointer(
        child: new CustomSingleChildLayout(
          delegate: new _TooltipPositionDelegate(
            target: target,
            verticalOffset: verticalOffset,
            screenEdgeMargin: screenEdgeMargin,
            preferBelow: preferBelow
          ),
          child: new FadeTransition(
            opacity: animation,
            child: new Opacity(
              opacity: opacity,
              child: new Container(
                decoration: new BoxDecoration(
                  backgroundColor: backgroundColor,
                  borderRadius: borderRadius
                ),
                height: height,
                padding: padding,
                child: new Center(
                  widthFactor: 1.0,
                  child: new Text(message, style: style)
                )
              )
            )
          )
        )
      )
    );
  }
}
