// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
part of engine;

/// The CanvasKit implementation of [ui.ImageFilter].
///
/// Currently only supports `blur`.
class SkImageFilter implements ui.ImageFilter {
  js.JsObject skImageFilter;

  SkImageFilter.blur({double sigmaX = 0.0, double sigmaY = 0.0})
      : _sigmaX = sigmaX,
        _sigmaY = sigmaY {
    skImageFilter = canvasKit['SkImageFilter'].callMethod(
      'MakeBlur',
      <dynamic>[
        sigmaX,
        sigmaY,
        canvasKit['TileMode']['Clamp'],
        null,
      ],
    );
  }

  final double _sigmaX;
  final double _sigmaY;

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
