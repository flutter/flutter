// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:sky/gestures/drag.dart';
import 'package:sky/gestures/long_press.dart';
import 'package:sky/gestures/scale.dart';
import 'package:sky/gestures/recognizer.dart';
import 'package:sky/gestures/show_press.dart';
import 'package:sky/gestures/tap.dart';
import 'package:sky/src/rendering/sky_binding.dart';
import 'package:sky/src/widgets/framework.dart';

class GestureDetector extends StatefulComponent {
  GestureDetector({
    Key key,
    this.child,
    this.onTap,
    this.onShowPress,
    this.onLongPress,
    this.onVerticalDragStart,
    this.onVerticalDragUpdate,
    this.onVerticalDragEnd,
    this.onHorizontalDragStart,
    this.onHorizontalDragUpdate,
    this.onHorizontalDragEnd,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.onScaleStart,
    this.onScaleUpdate,
    this.onScaleEnd
  }) : super(key: key);

  Widget child;
  GestureTapListener onTap;
  GestureShowPressListener onShowPress;
  GestureLongPressListener onLongPress;

  GestureDragStartCallback onVerticalDragStart;
  GestureDragUpdateCallback onVerticalDragUpdate;
  GestureDragEndCallback onVerticalDragEnd;

  GestureDragStartCallback onHorizontalDragStart;
  GestureDragUpdateCallback onHorizontalDragUpdate;
  GestureDragEndCallback onHorizontalDragEnd;

  GesturePanStartCallback onPanStart;
  GesturePanUpdateCallback onPanUpdate;
  GesturePanEndCallback onPanEnd;

  GestureScaleStartCallback onScaleStart;
  GestureScaleUpdateCallback onScaleUpdate;
  GestureScaleEndCallback onScaleEnd;

  void syncConstructorArguments(GestureDetector source) {
    child = source.child;
    onTap = source.onTap;
    onShowPress = source.onShowPress;
    onLongPress = source.onLongPress;
    onVerticalDragStart = source.onVerticalDragStart;
    onVerticalDragUpdate = source.onVerticalDragUpdate;
    onVerticalDragEnd = source.onVerticalDragEnd;
    onHorizontalDragStart = source.onHorizontalDragStart;
    onHorizontalDragUpdate = source.onHorizontalDragUpdate;
    onHorizontalDragEnd = source.onHorizontalDragEnd;
    onPanStart = source.onPanStart;
    onPanUpdate = source.onPanUpdate;
    onPanEnd = source.onPanEnd;
    onScaleStart = source.onScaleStart;
    onScaleUpdate = source.onScaleUpdate;
    onScaleEnd = source.onScaleEnd;
    _syncGestureListeners();
  }

  final PointerRouter _router = SkyBinding.instance.pointerRouter;

  TapGestureRecognizer _tap;
  TapGestureRecognizer _ensureTap() {
    if (_tap == null)
      _tap = new TapGestureRecognizer(router: _router);
    return _tap;
  }

  ShowPressGestureRecognizer _showPress;
  ShowPressGestureRecognizer _ensureShowPress() {
    if (_showPress == null)
      _showPress = new ShowPressGestureRecognizer(router: _router);
    return _showPress;
  }

  LongPressGestureRecognizer _longPress;
  LongPressGestureRecognizer _ensureLongPress() {
    if (_longPress == null)
      _longPress = new LongPressGestureRecognizer(router: _router);
    return _longPress;
  }

  VerticalDragGestureRecognizer _verticalDrag;
  VerticalDragGestureRecognizer _ensureVerticalDrag() {
    if (_verticalDrag == null)
      _verticalDrag = new VerticalDragGestureRecognizer(router: _router);
    return _verticalDrag;
  }

  HorizontalDragGestureRecognizer _horizontalDrag;
  HorizontalDragGestureRecognizer _ensureHorizontalDrag() {
    if (_horizontalDrag == null)
      _horizontalDrag = new HorizontalDragGestureRecognizer(router: _router);
    return _horizontalDrag;
  }

  PanGestureRecognizer _pan;
  PanGestureRecognizer _ensurePan() {
    assert(_scale == null);  // Scale is a superset of pan; just use scale
    if (_pan == null)
      _pan = new PanGestureRecognizer(router: _router);
    return _pan;
  }

  ScaleGestureRecognizer _scale;
  ScaleGestureRecognizer _ensureScale() {
    assert(_pan == null);  // Scale is a superset of pan; just use scale
    if (_scale == null)
      _scale = new ScaleGestureRecognizer(router: _router);
    return _scale;
  }

  void didMount() {
    super.didMount();
    _syncGestureListeners();
  }

  void didUnmount() {
    super.didUnmount();
    _tap = _ensureDisposed(_tap);
    _showPress = _ensureDisposed(_showPress);
    _longPress = _ensureDisposed(_longPress);
    _verticalDrag = _ensureDisposed(_verticalDrag);
    _horizontalDrag = _ensureDisposed(_horizontalDrag);
    _pan = _ensureDisposed(_pan);
    _scale = _ensureDisposed(_scale);
  }

  void _syncGestureListeners() {
    _syncTap();
    _syncShowPress();
    _syncLongPress();
    _syncVerticalDrag();
    _syncHorizontalDrag();
    _syncPan();
    _syncScale();
  }

  void _syncTap() {
    if (onTap == null)
      _tap = _ensureDisposed(_tap);
    else
      _ensureTap().onTap = onTap;
  }

  void _syncShowPress() {
    if (onShowPress == null)
      _showPress = _ensureDisposed(_showPress);
    else
      _ensureShowPress().onShowPress = onShowPress;
  }

  void _syncLongPress() {
    if (onLongPress == null)
      _longPress = _ensureDisposed(_longPress);
    else
      _ensureLongPress().onLongPress = onLongPress;
  }

  void _syncVerticalDrag() {
    if (onVerticalDragStart == null && onVerticalDragUpdate == null && onVerticalDragEnd == null) {
      _verticalDrag = _ensureDisposed(_verticalDrag);
    } else {
      _ensureVerticalDrag()
        ..onStart = onVerticalDragStart
        ..onUpdate = onVerticalDragUpdate
        ..onEnd = onVerticalDragEnd;
    }
  }

  void _syncHorizontalDrag() {
    if (onHorizontalDragStart == null && onHorizontalDragUpdate == null && onHorizontalDragEnd == null) {
      _horizontalDrag = _ensureDisposed(_horizontalDrag);
    } else {
      _ensureHorizontalDrag()
        ..onStart = onHorizontalDragStart
        ..onUpdate = onHorizontalDragUpdate
        ..onEnd = onHorizontalDragEnd;
    }
  }

  void _syncPan() {
    if (onPanStart == null && onPanUpdate == null && onPanEnd == null) {
      _pan = _ensureDisposed(_pan);
    } else {
      _ensurePan()
        ..onStart = onPanStart
        ..onUpdate = onPanUpdate
        ..onEnd = onPanEnd;
    }
  }

  void _syncScale() {
    if (onScaleStart == null && onScaleUpdate == null && onScaleEnd == null) {
      _scale = _ensureDisposed(_pan);
    } else {
      _ensureScale()
        ..onStart = onScaleStart
        ..onUpdate = onScaleUpdate
        ..onEnd = onScaleEnd;
    }
  }

  GestureRecognizer _ensureDisposed(GestureRecognizer recognizer) {
    recognizer?.dispose();
    return null;
  }

  EventDisposition _handlePointerDown(sky.PointerEvent event) {
    if (_tap != null)
      _tap.addPointer(event);
    if (_showPress != null)
      _showPress.addPointer(event);
    if (_longPress != null)
      _longPress.addPointer(event);
    if (_verticalDrag != null)
      _verticalDrag.addPointer(event);
    if (_horizontalDrag != null)
      _horizontalDrag.addPointer(event);
    if (_pan != null)
      _pan.addPointer(event);
    if (_scale != null)
      _scale.addPointer(event);
    return EventDisposition.processed;
  }

  Widget build() {
    return new Listener(
      onPointerDown: _handlePointerDown,
      child: child
    );
  }
}
