// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../animation/animated_value.dart';
import '../animation/curves.dart';
import '../animation/generators.dart';
import '../fn.dart';
import '../theme/view-configuration.dart' as config;
import 'dart:async';
import 'dart:math' as math;
import 'dart:sky' as sky;

const double _kSplashConfirmedDuration = 350.0;
const double _kSplashUnconfirmedDuration = config.kDefaultLongPressTimeout;
const double _kSplashAbortDuration = 100.0;
const double _kSplashInitialDelay = 0.0; // we could delay initially in case the user scrolls

double _getSplashTargetSize(sky.ClientRect rect, double x, double y) {
  return 2.0 * math.max(math.max(x - rect.left, rect.right - x),
                        math.max(y - rect.top, rect.bottom - y));
}

class SplashController {
  final int pointer;
  Stream<String> get onStyleChanged => _styleStream;

  final AnimatedValue _size = new AnimatedValue(0.0);
  double _offsetX;
  double _offsetY;
  double _lastSize = 0.0;
  bool _growing = true;
  double _targetSize;
  Stream<String> _styleStream;

  void start() {
    _size.animateTo(_targetSize, _kSplashUnconfirmedDuration, curve: easeOut, initialDelay: _kSplashInitialDelay);
  }

  void confirm() {
    double fractionRemaining = (_targetSize - _size.value) / _targetSize;
    double duration = fractionRemaining * _kSplashConfirmedDuration;
    if (duration <= 0.0)
      return;
    _size.animateTo(_targetSize, duration, curve: easeOut);
  }

  void abort() {
    _growing = false;
    double durationRemaining = _size.remainingTime;
    if (durationRemaining <= _kSplashAbortDuration)
      return;
    _size.animateTo(_targetSize, _kSplashAbortDuration, curve: easeOut);
  }

  void cancel() {
    _size.stop();
  }

  SplashController(sky.ClientRect rect, double x, double y,
                   { this.pointer, Function onDone })
      : _offsetX = x - rect.left,
        _offsetY = y - rect.top,
        _targetSize = _getSplashTargetSize(rect, x, y) {

    _styleStream = _size.onValueChanged.map((p) {
      if (p == _targetSize) {
        onDone();
      }
      double size;
      if (_growing) {
        sise = p;
        _lastSize = p;
      } else {
        size = _lastSize;
      }
      return '''
        top: ${_offsetY - size/2}px;
        left: ${_offsetX - size/2}px;
        width: ${size}px;
        height: ${size}px;
        border-radius: ${size}px;
        opacity: ${1.0 - (p / _targetSize)};''';
    });

    start();
  }
}

class InkSplash extends Component {
  static final Style _clipperStyle = new Style('''
    position: absolute;
    pointer-events: none;
    overflow: hidden;
    top: 0;
    left: 0;
    bottom: 0;
    right: 0;''');

  static final Style _splashStyle = new Style('''
    position: absolute;
    background-color: rgba(0, 0, 0, 0.4);''');

  Stream<String> onStyleChanged;

  double _offsetX;
  double _offsetY;
  String _inlineStyle;

  InkSplash(Stream<String> onStyleChanged)
    : onStyleChanged = onStyleChanged,
      super(stateful: true, key: onStyleChanged.hashCode);

  bool _listening = false;

  void _ensureListening() {
    if (_listening)
      return;

    _listening = true;

    onStyleChanged.listen((style) {
      setState(() {
        _inlineStyle = style;
      });
    });
  }

  UINode build() {
    _ensureListening();

    return new Container(
      style: _clipperStyle,
      children: [
        new Container(
          inlineStyle: _inlineStyle,
          style: _splashStyle
        )
      ]
    );
  }
}
