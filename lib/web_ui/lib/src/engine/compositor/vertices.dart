// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.10
part of engine;

class CkVertices extends ManagedSkiaObject<SkVertices> implements ui.Vertices {
  factory CkVertices(
    ui.VertexMode mode,
    List<ui.Offset> positions, {
    List<ui.Offset>? textureCoordinates,
    List<ui.Color>? colors,
    List<int>? indices,
  }) {
    assert(mode != null); // ignore: unnecessary_null_comparison
    assert(positions != null); // ignore: unnecessary_null_comparison
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

    return CkVertices._(
      toSkVertexMode(mode),
      toSkPoints2d(positions),
      textureCoordinates != null ? toSkPoints2d(textureCoordinates) : null,
      colors != null ? toSkFloatColorList(colors) : null,
      indices != null ? toUint16List(indices) : null,
    );
  }

  factory CkVertices.raw(
    ui.VertexMode mode,
    Float32List positions, {
    Float32List? textureCoordinates,
    Int32List? colors,
    Uint16List? indices,
  }) {
    assert(mode != null); // ignore: unnecessary_null_comparison
    assert(positions != null); // ignore: unnecessary_null_comparison
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

    return CkVertices._(
      toSkVertexMode(mode),
      rawPointsToSkPoints2d(positions),
      textureCoordinates != null ? rawPointsToSkPoints2d(textureCoordinates) : null,
      colors != null ? encodeRawColorList(colors) : null,
      indices,
    );
  }

  CkVertices._(
    this._mode,
    this._positions,
    this._textureCoordinates,
    this._colors,
    this._indices,
  );

  final SkVertexMode _mode;
  final List<Float32List> _positions;
  final List<Float32List>? _textureCoordinates;
  final List<Float32List>? _colors;
  final Uint16List? _indices;

  @override
  SkVertices createDefault() {
    return canvasKit.MakeSkVertices(
      _mode,
      _positions,
      _textureCoordinates,
      _colors,
      _indices,
    );
  }

  @override
  SkVertices resurrect() {
    return createDefault();
  }

  @override
  void delete() {
    rawSkiaObject?.delete();
  }
}
