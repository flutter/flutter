// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:sky/gestures/long_press.dart';
import 'package:sky/gestures/recognizer.dart';
import 'package:sky/gestures/scroll.dart';
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
    this.onVerticalScrollStart,
    this.onVerticalScrollUpdate,
    this.onVerticalScrollEnd,
    this.onHorizontalScrollStart,
    this.onHorizontalScrollUpdate,
    this.onHorizontalScrollEnd,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd
  }) : super(key: key);

  Widget child;
  GestureTapListener onTap;
  GestureShowPressListener onShowPress;
  GestureLongPressListener onLongPress;

  GestureScrollStartCallback onVerticalScrollStart;
  GestureScrollUpdateCallback onVerticalScrollUpdate;
  GestureScrollEndCallback onVerticalScrollEnd;

  GestureScrollStartCallback onHorizontalScrollStart;
  GestureScrollUpdateCallback onHorizontalScrollUpdate;
  GestureScrollEndCallback onHorizontalScrollEnd;

  GesturePanStartCallback onPanStart;
  GesturePanUpdateCallback onPanUpdate;
  GesturePanEndCallback onPanEnd;

  void syncConstructorArguments(GestureDetector source) {
    child = source.child;
    onTap = source.onTap;
    onShowPress = source.onShowPress;
    onLongPress = source.onLongPress;
    onVerticalScrollStart = source.onVerticalScrollStart;
    onVerticalScrollUpdate = source.onVerticalScrollUpdate;
    onVerticalScrollEnd = source.onVerticalScrollEnd;
    onHorizontalScrollStart = source.onHorizontalScrollStart;
    onHorizontalScrollUpdate = source.onHorizontalScrollUpdate;
    onHorizontalScrollEnd = source.onHorizontalScrollEnd;
    onPanStart = source.onPanStart;
    onPanUpdate = source.onPanUpdate;
    onPanEnd = source.onPanEnd;
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

  VerticalScrollGestureRecognizer _verticalScroll;
  VerticalScrollGestureRecognizer _ensureVerticalScroll() {
    if (_verticalScroll == null)
      _verticalScroll = new VerticalScrollGestureRecognizer(router: _router);
    return _verticalScroll;
  }

  HorizontalScrollGestureRecognizer _horizontalScroll;
  HorizontalScrollGestureRecognizer _ensureHorizontalScroll() {
    if (_horizontalScroll == null)
      _horizontalScroll = new HorizontalScrollGestureRecognizer(router: _router);
    return _horizontalScroll;
  }

  PanGestureRecognizer _pan;
  PanGestureRecognizer _ensurePan() {
    if (_pan == null)
      _pan = new PanGestureRecognizer(router: _router);
    return _pan;
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
    _verticalScroll = _ensureDisposed(_verticalScroll);
    _horizontalScroll = _ensureDisposed(_horizontalScroll);
    _pan = _ensureDisposed(_pan);
  }

  void _syncGestureListeners() {
    _syncTap();
    _syncShowPress();
    _syncLongPress();
    _syncVerticalScroll();
    _syncHorizontalScroll();
    _syncPan();
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

  void _syncVerticalScroll() {
    if (onVerticalScrollStart == null && onVerticalScrollUpdate == null && onVerticalScrollEnd == null) {
      _verticalScroll = _ensureDisposed(_verticalScroll);
    } else {
      _ensureVerticalScroll()
        ..onStart = onVerticalScrollStart
        ..onUpdate = onVerticalScrollUpdate
        ..onEnd = onVerticalScrollEnd;
    }
  }

  void _syncHorizontalScroll() {
    if (onHorizontalScrollStart == null && onHorizontalScrollUpdate == null && onHorizontalScrollEnd == null) {
      _horizontalScroll = _ensureDisposed(_horizontalScroll);
    } else {
      _ensureHorizontalScroll()
        ..onStart = onHorizontalScrollStart
        ..onUpdate = onHorizontalScrollUpdate
        ..onEnd = onHorizontalScrollEnd;
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
    if (_verticalScroll != null)
      _verticalScroll.addPointer(event);
    if (_horizontalScroll != null)
      _horizontalScroll.addPointer(event);
    if (_pan != null)
      _pan.addPointer(event);
    return EventDisposition.processed;
  }

  Widget build() {
    return new Listener(
      onPointerDown: _handlePointerDown,
      child: child
    );
  }
}
