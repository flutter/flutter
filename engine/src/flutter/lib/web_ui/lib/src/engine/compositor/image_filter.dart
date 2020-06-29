// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

/// The CanvasKit implementation of [ui.ImageFilter].
///
/// Currently only supports `blur`.
class SkImageFilter extends ResurrectableSkiaObject implements ui.ImageFilter {
  SkImageFilter.blur({double sigmaX = 0.0, double sigmaY = 0.0})
      : _sigmaX = sigmaX,
        _sigmaY = sigmaY;

  final double _sigmaX;
  final double _sigmaY;

  @override
  js.JsObject createDefault() => _initSkiaObject();

  @override
  js.JsObject resurrect() => _initSkiaObject();

  js.JsObject _initSkiaObject() => canvasKit['SkImageFilter'].callMethod(
        'MakeBlur',
        <dynamic>[
          _sigmaX,
          _sigmaY,
          canvasKit['TileMode']['Clamp'],
          null,
        ],
      );

  @override
  bool operator ==(dynamic other) {
    if (other is! SkImageFilter) {
      return false;
    }
    final SkImageFilter typedOther = other;
    return _sigmaX == typedOther._sigmaX && _sigmaY == typedOther._sigmaY;
  }

  @override
  int get hashCode => ui.hashValues(_sigmaX, _sigmaY);

  @override
  String toString() {
    return 'ImageFilter.blur($_sigmaX, $_sigmaY)';
  }
}
