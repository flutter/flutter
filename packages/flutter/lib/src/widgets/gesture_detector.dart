// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'framework.dart';

export 'package:flutter/gestures.dart' show
  GestureTapDownCallback,
  GestureTapUpCallback,
  GestureTapCallback,
  GestureTapCancelCallback,
  GestureLongPressCallback,
  GestureDragStartCallback,
  GestureDragUpdateCallback,
  GestureDragEndCallback,
  GestureDragStartCallback,
  GestureDragUpdateCallback,
  GestureDragEndCallback,
  GesturePanStartCallback,
  GesturePanUpdateCallback,
  GesturePanEndCallback,
  GestureScaleStartCallback,
  GestureScaleUpdateCallback,
  GestureScaleEndCallback;

class GestureDetector extends StatefulComponent {
  const GestureDetector({
    Key key,
    this.child,
    this.onTapDown,
    this.onTapUp,
    this.onTap,
    this.onTapCancel,
    this.onDoubleTap,
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
    this.onScaleEnd,
    this.behavior
  }) : super(key: key);

  final Widget child;

  final GestureTapDownCallback onTapDown;
  final GestureTapDownCallback onTapUp;
  final GestureTapCallback onTap;
  final GestureTapCancelCallback onTapCancel;
  final GestureTapCallback onDoubleTap;

  final GestureLongPressCallback onLongPress;

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

  final HitTestBehavior behavior;

  _GestureDetectorState createState() => new _GestureDetectorState();
}

class _GestureDetectorState extends State<GestureDetector> {
  PointerRouter get _router => FlutterBinding.instance.pointerRouter;

  TapGestureRecognizer _tap;
  DoubleTapGestureRecognizer _doubleTap;
  LongPressGestureRecognizer _longPress;
  VerticalDragGestureRecognizer _verticalDrag;
  HorizontalDragGestureRecognizer _horizontalDrag;
  PanGestureRecognizer _pan;
  ScaleGestureRecognizer _scale;

  void initState() {
    super.initState();
    _syncAll();
  }

  void didUpdateConfig(GestureDetector oldConfig) {
    _syncAll();
  }

  void dispose() {
    _tap = _ensureDisposed(_tap);
    _doubleTap = _ensureDisposed(_doubleTap);
    _longPress = _ensureDisposed(_longPress);
    _verticalDrag = _ensureDisposed(_verticalDrag);
    _horizontalDrag = _ensureDisposed(_horizontalDrag);
    _pan = _ensureDisposed(_pan);
    _scale = _ensureDisposed(_scale);
    super.dispose();
  }

  void _syncAll() {
    _syncTap();
    _syncDoubleTap();
    _syncLongPress();
    _syncVerticalDrag();
    _syncHorizontalDrag();
    _syncPan();
    _syncScale();
  }

  void _syncTap() {
    if (config.onTapDown == null && config.onTapUp == null && config.onTap == null && config.onTapCancel == null) {
      _tap = _ensureDisposed(_tap);
    } else {
      _tap ??= new TapGestureRecognizer(router: _router);
      _tap
        ..onTapDown = config.onTapDown
        ..onTapUp = config.onTapUp
        ..onTap = config.onTap
        ..onTapCancel = config.onTapCancel;
    }
  }

  void _syncDoubleTap() {
    if (config.onDoubleTap == null) {
      _doubleTap = _ensureDisposed(_doubleTap);
    } else {
      _doubleTap ??= new DoubleTapGestureRecognizer(router: _router);
      _doubleTap.onDoubleTap = config.onDoubleTap;
    }
  }

  void _syncLongPress() {
    if (config.onLongPress == null) {
      _longPress = _ensureDisposed(_longPress);
    } else {
      _longPress ??= new LongPressGestureRecognizer(router: _router);
      _longPress.onLongPress = config.onLongPress;
    }
  }

  void _syncVerticalDrag() {
    if (config.onVerticalDragStart == null && config.onVerticalDragUpdate == null && config.onVerticalDragEnd == null) {
      _verticalDrag = _ensureDisposed(_verticalDrag);
    } else {
      _verticalDrag ??= new VerticalDragGestureRecognizer(router: _router);
      _verticalDrag
        ..onStart = config.onVerticalDragStart
        ..onUpdate = config.onVerticalDragUpdate
        ..onEnd = config.onVerticalDragEnd;
    }
  }

  void _syncHorizontalDrag() {
    if (config.onHorizontalDragStart == null && config.onHorizontalDragUpdate == null && config.onHorizontalDragEnd == null) {
      _horizontalDrag = _ensureDisposed(_horizontalDrag);
    } else {
      _horizontalDrag ??= new HorizontalDragGestureRecognizer(router: _router);
      _horizontalDrag
        ..onStart = config.onHorizontalDragStart
        ..onUpdate = config.onHorizontalDragUpdate
        ..onEnd = config.onHorizontalDragEnd;
    }
  }

  void _syncPan() {
    if (config.onPanStart == null && config.onPanUpdate == null && config.onPanEnd == null) {
      _pan = _ensureDisposed(_pan);
    } else {
      assert(_scale == null);  // Scale is a superset of pan; just use scale
      _pan ??= new PanGestureRecognizer(router: _router);
      _pan
        ..onStart = config.onPanStart
        ..onUpdate = config.onPanUpdate
        ..onEnd = config.onPanEnd;
    }
  }

  void _syncScale() {
    if (config.onScaleStart == null && config.onScaleUpdate == null && config.onScaleEnd == null) {
      _scale = _ensureDisposed(_scale);
    } else {
      assert(_pan == null);  // Scale is a superset of pan; just use scale
      _scale ??= new ScaleGestureRecognizer(router: _router);
      _scale
        ..onStart = config.onScaleStart
        ..onUpdate = config.onScaleUpdate
        ..onEnd = config.onScaleEnd;
    }
  }

  GestureRecognizer _ensureDisposed(GestureRecognizer recognizer) {
    recognizer?.dispose();
    return null;
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (_tap != null)
      _tap.addPointer(event);
    if (_doubleTap != null)
      _doubleTap.addPointer(event);
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

  HitTestBehavior get _defaultBehavior {
    return config.child == null ? HitTestBehavior.translucent : HitTestBehavior.deferToChild;
  }

  Widget build(BuildContext context) {
    return new Listener(
      onPointerDown: _handlePointerDown,
      behavior: config.behavior ?? _defaultBehavior,
      child: config.child
    );
  }

  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    List<String> gestures = <String>[];
    if (_tap != null)
      gestures.add('tap');
    if (_doubleTap != null)
      gestures.add('double tap');
    if (_longPress != null)
      gestures.add('long press');
    if (_verticalDrag != null)
      gestures.add('vertical drag');
    if (_horizontalDrag != null)
      gestures.add('horizontal drag');
    if (_pan != null)
      gestures.add('pan');
    if (_scale != null)
      gestures.add('scale');
    if (gestures.isEmpty)
      gestures.add('<none>');
    description.add('gestures: ${gestures.join(", ")}');
    switch (config.behavior) {
      case HitTestBehavior.translucent:
        description.add('behavior: translucent');
        break;
      case HitTestBehavior.opaque:
        description.add('behavior: opaque');
        break;
      case HitTestBehavior.deferToChild:
        description.add('behavior: defer-to-child');
        break;
    }
  }
}
