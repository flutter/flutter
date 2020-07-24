// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.10
part of engine;

/// An error related to the CanvasKit rendering backend.
class CanvasKitError extends Error {
  CanvasKitError(this.message);

  /// Describes this error.
  final String message;

  @override
  String toString() => 'CanvasKitError: $message';
}

/// Creates a new color array.
Float32List makeFreshSkColor(ui.Color color) {
  final Float32List result = Float32List(4);
  result[0] = color.red / 255.0;
  result[1] = color.green / 255.0;
  result[2] = color.blue / 255.0;
  result[3] = color.alpha / 255.0;
  return result;
}

ui.TextPosition fromPositionWithAffinity(SkTextPosition positionWithAffinity) {
  final ui.TextAffinity affinity = ui.TextAffinity.values[positionWithAffinity.affinity.value];
  return ui.TextPosition(
    offset: positionWithAffinity.pos,
    affinity: affinity,
  );
}

void drawSkShadow(
  SkCanvas skCanvas,
  CkPath path,
  ui.Color color,
  double elevation,
  bool transparentOccluder,
  double devicePixelRatio,
) {
  const double ambientAlpha = 0.039;
  const double spotAlpha = 0.25;

  final int flags = transparentOccluder ? 0x01 : 0x00;

  final ui.Rect bounds = path.getBounds();
  final double shadowX = (bounds.left + bounds.right) / 2.0;
  final double shadowY = bounds.top - 600.0;

  ui.Color inAmbient = color.withAlpha((color.alpha * ambientAlpha).round());
  ui.Color inSpot = color.withAlpha((color.alpha * spotAlpha).round());

  final SkTonalColors inTonalColors = SkTonalColors(
    ambient: makeFreshSkColor(inAmbient),
    spot: makeFreshSkColor(inSpot),
  );

  final SkTonalColors tonalColors =
      canvasKit.computeTonalColors(inTonalColors);

  skCanvas.drawShadow(
    path._skPath,
    Float32List(3)
      ..[2] = devicePixelRatio * elevation,
    Float32List(3)
      ..[0] = shadowX
      ..[1] = shadowY
      ..[2] = devicePixelRatio * kLightHeight,
    devicePixelRatio * kLightRadius,
    tonalColors.ambient,
    tonalColors.spot,
    flags,
  );
}
