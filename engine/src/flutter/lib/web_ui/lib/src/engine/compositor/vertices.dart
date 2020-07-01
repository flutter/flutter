// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


part of engine;

js.JsArray<Float32List> _encodeRawColorList(Int32List rawColors) {
  final int colorCount = rawColors.length;
  final List<ui.Color> colors = <ui.Color>[];
  for (int i = 0; i < colorCount; ++i) {
    colors.add(ui.Color(rawColors[i]));
  }
  return makeColorList(colors);
}

class CkVertices implements ui.Vertices {
  js.JsObject? skVertices;

  CkVertices(
    ui.VertexMode mode,
    List<ui.Offset> positions, {
    List<ui.Offset>? textureCoordinates,
    List<ui.Color>? colors,
    List<int>? indices,
  })  : assert(mode != null), // ignore: unnecessary_null_comparison
        assert(positions != null) { // ignore: unnecessary_null_comparison
    if (textureCoordinates != null &&
        textureCoordinates.length != positions.length)
      throw ArgumentError(
          '"positions" and "textureCoordinates" lengths must match.');
    if (colors != null && colors.length != positions.length)
      throw ArgumentError('"positions" and "colors" lengths must match.');
    if (indices != null &&
        indices.any((int i) => i < 0 || i >= positions.length))
      throw ArgumentError(
          '"indices" values must be valid indices in the positions list.');

    final js.JsArray<js.JsArray<double>>? encodedPositions = encodePointList(positions);
    final js.JsArray<js.JsArray<double>>? encodedTextures =
        encodePointList(textureCoordinates);
    final js.JsArray<Float32List>? encodedColors =
        colors != null ? makeColorList(colors) : null;
    if (!_init(mode, encodedPositions, encodedTextures, encodedColors, indices))
      throw ArgumentError('Invalid configuration for vertices.');
  }

  CkVertices.raw(
    ui.VertexMode mode,
    Float32List positions, {
    Float32List? textureCoordinates,
    Int32List? colors,
    Uint16List? indices,
  })  : assert(mode != null), // ignore: unnecessary_null_comparison
        assert(positions != null) { // ignore: unnecessary_null_comparison
    if (textureCoordinates != null &&
        textureCoordinates.length != positions.length)
      throw ArgumentError(
          '"positions" and "textureCoordinates" lengths must match.');
    if (colors != null && colors.length * 2 != positions.length)
      throw ArgumentError('"positions" and "colors" lengths must match.');
    if (indices != null &&
        indices.any((int i) => i < 0 || i >= positions.length))
      throw ArgumentError(
          '"indices" values must be valid indices in the positions list.');

    if (!_init(
      mode,
      encodeRawPointList(positions) as js.JsArray<js.JsArray<double>>?,
      encodeRawPointList(textureCoordinates) as js.JsArray<js.JsArray<double>>?,
      colors != null ? _encodeRawColorList(colors) : null,
      indices,
    )) {
      throw ArgumentError('Invalid configuration for vertices.');
    }
  }

  bool _init(
      ui.VertexMode mode,
      js.JsArray<js.JsArray<double>>? positions,
      js.JsArray<js.JsArray<double>>? textureCoordinates,
      js.JsArray<Float32List>? colors,
      List<int>? indices) {
    js.JsObject? skVertexMode;
    switch (mode) {
      case ui.VertexMode.triangles:
        skVertexMode = canvasKit['VertexMode']['Triangles'];
        break;
      case ui.VertexMode.triangleStrip:
        skVertexMode = canvasKit['VertexMode']['TrianglesStrip'];
        break;
      case ui.VertexMode.triangleFan:
        skVertexMode = canvasKit['VertexMode']['TriangleFan'];
        break;
    }

    final js.JsObject? vertices =
        canvasKit.callMethod('MakeSkVertices', <dynamic>[
      skVertexMode,
      positions,
      textureCoordinates,
      colors,
      indices,
    ]);

    if (vertices != null) {
      skVertices = vertices;
      return true;
    } else {
      return false;
    }
  }
}
