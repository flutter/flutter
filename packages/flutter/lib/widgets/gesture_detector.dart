// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:sky/gestures/long_press.dart';
import 'package:sky/gestures/recognizer.dart';
import 'package:sky/gestures/scroll.dart';
import 'package:sky/gestures/show_press.dart';
import 'package:sky/gestures/tap.dart';
import 'package:sky/rendering/sky_binding.dart';
import 'package:sky/widgets/framework.dart';

class GestureDetector extends StatefulComponent {
  GestureDetector({
    Key key,
    this.child,
    this.onTap,
    this.onShowPress,
    this.onLongPress,
    this.onScrollStart,
    this.onScrollUpdate,
    this.onScrollEnd
  }) : super(key: key);

  Widget child;
  GestureTapListener onTap;
  GestureShowPressListener onShowPress;
  GestureLongPressListener onLongPress;
  GestureScrollStartCallback onScrollStart;
  GestureScrollUpdateCallback onScrollUpdate;
  GestureScrollEndCallback onScrollEnd;

  void syncConstructorArguments(GestureDetector source) {
    child = source.child;
    onTap = source.onTap;
    onShowPress = source.onShowPress;
    onLongPress = source.onLongPress;
    onScrollStart = source.onScrollStart;
    onScrollUpdate = source.onScrollUpdate;
    onScrollEnd = source.onScrollEnd;
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

  ScrollGestureRecognizer _scroll;
  ScrollGestureRecognizer _ensureScroll() {
    if (_scroll == null)
      _scroll = new ScrollGestureRecognizer(router: _router);
    return _scroll;
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
    _scroll = _ensureDisposed(_scroll);
  }

  void _syncGestureListeners() {
    _syncTap();
    _syncShowPress();
    _syncLongPress();
    _syncScroll();
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

  void _syncScroll() {
    if (onScrollStart == null && onScrollUpdate == null && onScrollEnd == null) {
      _scroll = _ensureDisposed(_scroll);
    } else {
      _ensureScroll()
        ..onScrollStart = onScrollStart
        ..onScrollUpdate = onScrollUpdate
        ..onScrollEnd = onScrollEnd;
    }
  }

  GestureRecognizer _ensureDisposed(GestureRecognizer recognizer) {
    if (recognizer != null)
      recognizer.dispose();
    return null;
  }

  EventDisposition _handlePointerDown(sky.PointerEvent event) {
    if (_tap != null)
      _tap.addPointer(event);
    if (_showPress != null)
      _showPress.addPointer(event);
    if (_longPress != null)
      _longPress.addPointer(event);
    if (_scroll != null)
      _scroll.addPointer(event);
    return EventDisposition.processed;
  }

  Widget build() {
    return new Listener(
      onPointerDown: _handlePointerDown,
      child: child
    );
  }
}
