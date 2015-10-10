// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as sky;

import 'package:flutter/animation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

const int _kSplashInitialOpacity = 0x30;
const double _kSplashCanceledVelocity = 0.7;
const double _kSplashConfirmedVelocity = 0.7;
const double _kSplashInitialSize = 0.0;
const double _kSplashUnconfirmedVelocity = 0.2;

double _getSplashTargetSize(Size bounds, Point position) {
  double d1 = (position - bounds.topLeft(Point.origin)).distance;
  double d2 = (position - bounds.topRight(Point.origin)).distance;
  double d3 = (position - bounds.bottomLeft(Point.origin)).distance;
  double d4 = (position - bounds.bottomRight(Point.origin)).distance;
  return math.max(math.max(d1, d2), math.max(d3, d4)).ceil().toDouble();
}

class _InkSplash {
  _InkSplash(this.position, this.well) {
    _targetRadius = _getSplashTargetSize(well.size, position);
    _radius = new AnimatedValue<double>(
        _kSplashInitialSize, end: _targetRadius, curve: easeOut);

    _performance = new ValuePerformance<double>(
      variable: _radius,
      duration: new Duration(milliseconds: (_targetRadius / _kSplashUnconfirmedVelocity).floor())
    )..addListener(_handleRadiusChange);

    // Wait kTapTimeout to avoid creating tiny splashes during scrolls.
    _startTimer = new Timer(kTapTimeout, _play);
  }

  final Point position;
  final _RenderInkWell well;

  double _targetRadius;
  double _pinnedRadius;
  AnimatedValue<double> _radius;
  Performance _performance;
  Timer _startTimer;

  bool _cancelStartTimer() {
    if (_startTimer != null) {
      _startTimer.cancel();
      _startTimer = null;
      return true;
    }
    return false;
  }

  void _play() {
    _cancelStartTimer();
    _performance.play();
  }

  void _updateVelocity(double velocity) {
    int duration = (_targetRadius / velocity).floor();
    _performance.duration = new Duration(milliseconds: duration);
    _play();
  }

  void confirm() {
    if (_cancelStartTimer())
      return;
    _updateVelocity(_kSplashConfirmedVelocity);
    _pinnedRadius = null;
  }

  void cancel() {
    if (_cancelStartTimer())
      return;
    _updateVelocity(_kSplashCanceledVelocity);
    _pinnedRadius = _radius.value;
  }

  void _handleRadiusChange() {
    if (_radius.value == _targetRadius)
      well._splashes.remove(this);
    well.markNeedsPaint();
  }

  void paint(PaintingCanvas canvas) {
    int opacity = (_kSplashInitialOpacity * (1.1 - (_radius.value / _targetRadius))).floor();
    sky.Paint paint = new sky.Paint()..color = new sky.Color(opacity << 24);
    double radius = _pinnedRadius == null ? _radius.value : _pinnedRadius;
    canvas.drawCircle(position, radius, paint);
  }
}

typedef _HighlightChangedCallback(bool value);

class _RenderInkWell extends RenderProxyBox {
  _RenderInkWell({
    RenderBox child,
    GestureTapCallback onTap,
    GestureLongPressCallback onLongPress,
    _HighlightChangedCallback onHighlightChanged
  }) : super(child) {
    this.onTap = onTap;
    this.onHighlightChanged = onHighlightChanged;
    this.onLongPress = onLongPress;
  }

  GestureTapCallback get onTap => _onTap;
  GestureTapCallback _onTap;
  void set onTap (GestureTapCallback value) {
    _onTap = value;
    _syncTapRecognizer();
  }

  _HighlightChangedCallback get onHighlightChanged => _onHighlightChanged;
  _HighlightChangedCallback _onHighlightChanged;
  void set onHighlightChanged (_HighlightChangedCallback value) {
    _onHighlightChanged = value;
    _syncTapRecognizer();
  }

  GestureTapCallback get onLongPress => _onLongPress;
  GestureTapCallback _onLongPress;
  void set onLongPress (GestureTapCallback value) {
    _onLongPress = value;
    _syncLongPressRecognizer();
  }

  final List<_InkSplash> _splashes = new List<_InkSplash>();

  TapGestureRecognizer _tap;
  LongPressGestureRecognizer _longPress;

  void handleEvent(sky.Event event, BoxHitTestEntry entry) {
    if (event.type == 'pointerdown' && (_tap != null || _longPress != null)) {
      _tap?.addPointer(event);
      _longPress?.addPointer(event);
      _splashes.add(new _InkSplash(entry.localPosition, this));
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
    if (onTap == null && onHighlightChanged == null) {
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

  void _handleTapDown() {
    if (onHighlightChanged != null)
      onHighlightChanged(true);
  }

  void _handleTap() {
    if (_splashes.isNotEmpty)
      _splashes.last.confirm();

    if (onHighlightChanged != null)
      onHighlightChanged(false);

    if (onTap != null)
      onTap();
  }

  void _handleTapCancel() {
    _splashes.last?.cancel();
    if (onHighlightChanged != null)
      onHighlightChanged(false);
  }

  void _handleLongPress() {
    _splashes.last?.confirm();
    onLongPress();
  }

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

class InkWell extends OneChildRenderObjectWidget {
  InkWell({
    Key key,
    Widget child,
    this.onTap,
    this.onHighlightChanged,
    this.onLongPress
  }) : super(key: key, child: child);

  final GestureTapCallback onTap;
  final _HighlightChangedCallback onHighlightChanged;
  final GestureLongPressCallback onLongPress;

  _RenderInkWell createRenderObject() => new _RenderInkWell(onTap: onTap, onHighlightChanged: onHighlightChanged, onLongPress: onLongPress);

  void updateRenderObject(_RenderInkWell renderObject, InkWell oldWidget) {
    renderObject.onTap = onTap;
    renderObject.onHighlightChanged = onHighlightChanged;
    renderObject.onLongPress = onLongPress;
  }
}
