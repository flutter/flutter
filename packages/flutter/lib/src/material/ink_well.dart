// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

// This file has the following classes:
//  InkWell - the widget for material-design-style inkly-reacting material, showing splashes and a highlight
//  _InkWellState - InkWell's State class
//  _InkSplash - tracks a single splash
//  _RenderInkSplashes - a RenderBox that renders multiple _InkSplash objects and handles gesture recognition
//  _InkSplashes - the RenderObjectWidget for _RenderInkSplashes used by InkWell to handle the splashes

const int _kSplashInitialOpacity = 0x30; // 0..255
const double _kSplashCanceledVelocity = 0.7; // logical pixels per millisecond
const double _kSplashConfirmedVelocity = 0.7; // logical pixels per millisecond
const double _kSplashInitialSize = 0.0; // logical pixels
const double _kSplashUnconfirmedVelocity = 0.2; // logical pixels per millisecond
const Duration _kInkWellHighlightFadeDuration = const Duration(milliseconds: 100);

class InkWell extends StatefulComponent {
  InkWell({
    Key key,
    this.child,
    this.onTap,
    this.onLongPress,
    this.onHighlightChanged,
    this.defaultColor,
    this.highlightColor
  }) : super(key: key);

  final Widget child;
  final GestureTapCallback onTap;
  final GestureLongPressCallback onLongPress;
  final _HighlightChangedCallback onHighlightChanged;
  final Color defaultColor;
  final Color highlightColor;

  _InkWellState createState() => new _InkWellState();
}

class _InkWellState extends State<InkWell> {
  bool _highlight = false;
  Widget build(BuildContext context) {
    return new AnimatedContainer(
      decoration: new BoxDecoration(
        backgroundColor: _highlight ? config.highlightColor : config.defaultColor
      ),
      duration: _kInkWellHighlightFadeDuration,
      child: new _InkSplashes(
        onTap: config.onTap,
        onLongPress: config.onLongPress,
        onHighlightChanged: (bool value) {
          setState(() {
            _highlight = value;
          });
          if (config.onHighlightChanged != null)
            config.onHighlightChanged(value);
        },
        child: config.child
      )
    );
  }
}


double _getSplashTargetSize(Size bounds, Point position) {
  double d1 = (position - bounds.topLeft(Point.origin)).distance;
  double d2 = (position - bounds.topRight(Point.origin)).distance;
  double d3 = (position - bounds.bottomLeft(Point.origin)).distance;
  double d4 = (position - bounds.bottomRight(Point.origin)).distance;
  return math.max(math.max(d1, d2), math.max(d3, d4)).ceil().toDouble();
}

class _InkSplash {
  _InkSplash(this.position, this.renderer) {
    _targetRadius = _getSplashTargetSize(renderer.size, position);
    _radius = new ValuePerformance<double>(
      variable: new AnimatedValue<double>(
        _kSplashInitialSize,
        end: _targetRadius,
        curve: Curves.easeOut
      ),
      duration: new Duration(milliseconds: (_targetRadius / _kSplashUnconfirmedVelocity).floor())
    )..addListener(_handleRadiusChange)
     ..play();
  }

  final Point position;
  final _RenderInkSplashes renderer;

  double _targetRadius;
  double _pinnedRadius;
  ValuePerformance<double> _radius;

  void _updateVelocity(double velocity) {
    int duration = (_targetRadius / velocity).floor();
    _radius.duration = new Duration(milliseconds: duration);
    _radius.play();
  }

  void confirm() {
    _updateVelocity(_kSplashConfirmedVelocity);
    _pinnedRadius = null;
  }

  void cancel() {
    _updateVelocity(_kSplashCanceledVelocity);
    _pinnedRadius = _radius.value;
  }

  void _handleRadiusChange() {
    if (_radius.value == _targetRadius)
      renderer._removeSplash(this);
    renderer.markNeedsPaint();
  }

  void paint(PaintingCanvas canvas) {
    int opacity = (_kSplashInitialOpacity * (1.1 - (_radius.value / _targetRadius))).floor();
    Paint paint = new Paint()..color = new Color(opacity << 24);
    double radius = _pinnedRadius == null ? _radius.value : _pinnedRadius;
    canvas.drawCircle(position, radius, paint);
  }
}

typedef _HighlightChangedCallback(bool value);

class _RenderInkSplashes extends RenderProxyBox {
  _RenderInkSplashes({
    RenderBox child,
    GestureTapCallback onTap,
    GestureLongPressCallback onLongPress,
    this.onHighlightChanged
  }) : super(child) {
    this.onTap = onTap;
    this.onLongPress = onLongPress;
  }

  GestureTapCallback get onTap => _onTap;
  GestureTapCallback _onTap;
  void set onTap (GestureTapCallback value) {
    _onTap = value;
    _syncTapRecognizer();
  }

  GestureTapCallback get onLongPress => _onLongPress;
  GestureTapCallback _onLongPress;
  void set onLongPress (GestureTapCallback value) {
    _onLongPress = value;
    _syncLongPressRecognizer();
  }

  _HighlightChangedCallback onHighlightChanged;

  final List<_InkSplash> _splashes = new List<_InkSplash>();
  _InkSplash _lastSplash;

  TapGestureRecognizer _tap;
  LongPressGestureRecognizer _longPress;

  void _removeSplash(_InkSplash splash) {
    _splashes.remove(splash);
    if (_lastSplash == splash)
      _lastSplash = null;
  }

  void handleEvent(InputEvent event, BoxHitTestEntry entry) {
    if (event.type == 'pointerdown' && (onTap != null || onLongPress != null)) {
      _tap?.addPointer(event);
      _longPress?.addPointer(event);
    }
  }

  void attach() {
    super.attach();
    _syncTapRecognizer();
    _syncLongPressRecognizer();
  }

  void detach() {
    _disposeTapRecognizer();
    _disposeLongPressRecognizer();
    super.detach();
  }

  void _syncTapRecognizer() {
    if (onTap == null && onLongPress == null) {
      _disposeTapRecognizer();
    } else {
      _tap ??= new TapGestureRecognizer(router: FlutterBinding.instance.pointerRouter)
        ..onTapDown = _handleTapDown
        ..onTap = _handleTap
        ..onTapCancel = _handleTapCancel;
    }
  }

  void _disposeTapRecognizer() {
    _tap?.dispose();
    _tap = null;
  }

  void _syncLongPressRecognizer() {
    if (onLongPress == null) {
      _disposeLongPressRecognizer();
    } else {
      _longPress ??= new LongPressGestureRecognizer(router: FlutterBinding.instance.pointerRouter)
        ..onLongPress = _handleLongPress;
    }
  }

  void _disposeLongPressRecognizer() {
    _longPress?.dispose();
    _longPress = null;
  }

  void _handleTapDown(Point position) {
    _lastSplash = new _InkSplash(globalToLocal(position), this);
    _splashes.add(_lastSplash);
    if (onHighlightChanged != null)
      onHighlightChanged(true);
  }

  void _handleTap() {
    _lastSplash?.confirm();
    _lastSplash = null;
    if (onHighlightChanged != null)
      onHighlightChanged(false);
    if (onTap != null)
      onTap();
  }

  void _handleTapCancel() {
    _lastSplash?.cancel();
    _lastSplash = null;
    if (onHighlightChanged != null)
      onHighlightChanged(false);
  }

  void _handleLongPress() {
    _lastSplash?.confirm();
    _lastSplash = null;
    if (onLongPress != null)
      onLongPress();
  }

  bool hitTestSelf(Point position) => true;

  void paint(PaintingContext context, Offset offset) {
    if (!_splashes.isEmpty) {
      final PaintingCanvas canvas = context.canvas;
      canvas.save();
      canvas.translate(offset.dx, offset.dy);
      canvas.clipRect(Point.origin & size);
      for (_InkSplash splash in _splashes)
        splash.paint(canvas);
      canvas.restore();
    }
    super.paint(context, offset);
  }
}

class _InkSplashes extends OneChildRenderObjectWidget {
  _InkSplashes({
    Key key,
    Widget child,
    this.onTap,
    this.onLongPress,
    this.onHighlightChanged
  }) : super(key: key, child: child);

  final GestureTapCallback onTap;
  final GestureLongPressCallback onLongPress;
  final _HighlightChangedCallback onHighlightChanged;

  _RenderInkSplashes createRenderObject() => new _RenderInkSplashes(onTap: onTap, onLongPress: onLongPress, onHighlightChanged: onHighlightChanged);

  void updateRenderObject(_RenderInkSplashes renderObject, _InkSplashes oldWidget) {
    renderObject.onTap = onTap;
    renderObject.onLongPress = onLongPress;
    renderObject.onHighlightChanged = onHighlightChanged;
  }
}
