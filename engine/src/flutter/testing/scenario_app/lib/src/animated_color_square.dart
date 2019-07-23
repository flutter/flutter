// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui';

import 'scenario.dart';

/// A square that animates it color and bounces off the sides of the
/// device.
///
/// This scenario drives animation as quickly as possible, requesting new frames
/// that are constantly changing.
class AnimatedColorSquareScenario extends Scenario {
  /// Creates the AnimatedColorSquare scenario.
  ///
  /// The [window] parameter must not be null.
  AnimatedColorSquareScenario(Window window)
      : assert(window != null),
        super(window);

  static const double _squareSize = 200;
  /// Used to animate the red value in the color of the square.
  final _NumberSwinger<int> _r = _NumberSwinger<int>(0, 255);
  _NumberSwinger<double> _top = _NumberSwinger<double>(
    0,
    window.physicalSize.height - _squareSize,
  );
  _NumberSwinger<double> _left = _NumberSwinger<double>(
    0,
    window.physicalSize.width - _squareSize,
  );

  @override
  void onBeginFrame(Duration duration) {
    final SceneBuilder builder = SceneBuilder();
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    canvas.drawRect(
      const Rect.fromLTWH(0, 0, _squareSize, _squareSize),
      Paint()..color = Color.fromARGB(255, _r.swing(), 50, 50),
    );
    final Picture picture = recorder.endRecording();

    builder.pushOffset(_left.swing(), _top.swing());
    builder.addPicture(
      Offset.zero,
      picture,
      willChangeHint: true,
    );
    final Scene scene = builder.build();
    window.render(scene);
    scene.dispose();
  }

  @override
  void onDrawFrame() {
    window.scheduleFrame();
  }

  @override
  void onMetricsChanged() {
    _top = _NumberSwinger<double>(
      0,
      window.physicalSize.height - _squareSize,
      math.min(_top.current, window.physicalSize.height - _squareSize),
    );
    _left = _NumberSwinger<double>(
      0,
      window.physicalSize.width - _squareSize,
      math.min(_left.current, window.physicalSize.width - _squareSize),
    );
  }
}

class _NumberSwinger<T extends num> {
  _NumberSwinger(this._begin, this._end, [this._current])
      : assert(_begin != null),
        assert(_end != null),
        _up = _begin < _end {
    _current ??= _begin;
  }

  final T _begin;
  final T _end;

  /// The current value of the swinger.
  T get current => _current;
  T _current;

  bool _up;

  T swing() {
    if (_current >= _end) {
      _up = false;
    } else if (_current <= _begin) {
      _up = true;
    }
    _current = _up ? _current + 1 : _current - 1;
    return _current;
  }
}
