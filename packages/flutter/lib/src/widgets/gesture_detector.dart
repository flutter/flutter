// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:sky/gestures.dart';
import 'package:sky/src/widgets/basic.dart';
import 'package:sky/src/widgets/framework.dart';
import 'package:sky/src/rendering/binding.dart';

class GestureDetector extends StatefulComponent {
  const GestureDetector({
    Key key,
    this.child,
    this.onTap,
    this.onDoubleTap,
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

  final Widget child;
  final GestureTapListener onTap;
  final GestureTapListener onDoubleTap;
  final GestureShowPressListener onShowPress;
  final GestureLongPressListener onLongPress;

  final GestureDragStartCallback onVerticalDragStart;
  final GestureDragUpdateCallback onVerticalDragUpdate;
  final GestureDragEndCallback onVerticalDragEnd;

  final GestureDragStartCallback onHorizontalDragStart;
  final GestureDragUpdateCallback onHorizontalDragUpdate;
  final GestureDragEndCallback onHorizontalDragEnd;

  final GesturePanStartCallback onPanStart;
  final GesturePanUpdateCallback onPanUpdate;
  final GesturePanEndCallback onPanEnd;

  final GestureScaleStartCallback onScaleStart;
  final GestureScaleUpdateCallback onScaleUpdate;
  final GestureScaleEndCallback onScaleEnd;

  GestureDetectorState createState() => new GestureDetectorState();
}

class GestureDetectorState extends State<GestureDetector> {
  void initState() {
    super.initState();
    didUpdateConfig(null);
  }

  final PointerRouter _router = FlutterBinding.instance.pointerRouter;

  TapGestureRecognizer _tap;
  TapGestureRecognizer _ensureTap() {
    if (_tap == null)
      _tap = new TapGestureRecognizer(router: _router);
    return _tap;
  }

  DoubleTapGestureRecognizer _doubleTap;
  DoubleTapGestureRecognizer _ensureDoubleTap() {
    if (_doubleTap == null)
      _doubleTap = new DoubleTapGestureRecognizer(router: _router);
    return _doubleTap;
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

  void dispose() {
    _tap = _ensureDisposed(_tap);
    _doubleTap = _ensureDisposed(_doubleTap);
    _showPress = _ensureDisposed(_showPress);
    _longPress = _ensureDisposed(_longPress);
    _verticalDrag = _ensureDisposed(_verticalDrag);
    _horizontalDrag = _ensureDisposed(_horizontalDrag);
    _pan = _ensureDisposed(_pan);
    _scale = _ensureDisposed(_scale);
    super.dispose();
  }

  void didUpdateConfig(GestureDetector oldConfig) {
    _syncTap();
    _syncDoubleTap();
    _syncShowPress();
    _syncLongPress();
    _syncVerticalDrag();
    _syncHorizontalDrag();
    _syncPan();
    _syncScale();
  }

  void _syncTap() {
    if (config.onTap == null)
      _tap = _ensureDisposed(_tap);
    else
      _ensureTap().onTap = config.onTap;
  }

  void _syncDoubleTap() {
    if (config.onDoubleTap == null)
      _doubleTap = _ensureDisposed(_doubleTap);
    else
      _ensureDoubleTap().onDoubleTap = config.onDoubleTap;
  }

  void _syncShowPress() {
    if (config.onShowPress == null)
      _showPress = _ensureDisposed(_showPress);
    else
      _ensureShowPress().onShowPress = config.onShowPress;
  }

  void _syncLongPress() {
    if (config.onLongPress == null)
      _longPress = _ensureDisposed(_longPress);
    else
      _ensureLongPress().onLongPress = config.onLongPress;
  }

  void _syncVerticalDrag() {
    if (config.onVerticalDragStart == null && config.onVerticalDragUpdate == null && config.onVerticalDragEnd == null) {
      _verticalDrag = _ensureDisposed(_verticalDrag);
    } else {
      _ensureVerticalDrag()
        ..onStart = config.onVerticalDragStart
        ..onUpdate = config.onVerticalDragUpdate
        ..onEnd = config.onVerticalDragEnd;
    }
  }

  void _syncHorizontalDrag() {
    if (config.onHorizontalDragStart == null && config.onHorizontalDragUpdate == null && config.onHorizontalDragEnd == null) {
      _horizontalDrag = _ensureDisposed(_horizontalDrag);
    } else {
      _ensureHorizontalDrag()
        ..onStart = config.onHorizontalDragStart
        ..onUpdate = config.onHorizontalDragUpdate
        ..onEnd = config.onHorizontalDragEnd;
    }
  }

  void _syncPan() {
    if (config.onPanStart == null && config.onPanUpdate == null && config.onPanEnd == null) {
      _pan = _ensureDisposed(_pan);
    } else {
      _ensurePan()
        ..onStart = config.onPanStart
        ..onUpdate = config.onPanUpdate
        ..onEnd = config.onPanEnd;
    }
  }

  void _syncScale() {
    if (config.onScaleStart == null && config.onScaleUpdate == null && config.onScaleEnd == null) {
      _scale = _ensureDisposed(_pan);
    } else {
      _ensureScale()
        ..onStart = config.onScaleStart
        ..onUpdate = config.onScaleUpdate
        ..onEnd = config.onScaleEnd;
    }
  }

  GestureRecognizer _ensureDisposed(GestureRecognizer recognizer) {
    recognizer?.dispose();
    return null;
  }

  void _handlePointerDown(sky.PointerEvent event) {
    if (_tap != null)
      _tap.addPointer(event);
    if (_doubleTap != null)
      _doubleTap.addPointer(event);
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
  }

  Widget build(BuildContext context) {
    return new Listener(
      onPointerDown: _handlePointerDown,
      child: config.child
    );
  }
}
