// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:ui/ui.dart' as ui;

import '../backend/vertices.dart';
import 'canvaskit_api.dart';

class CkVertices implements BackendVertices {
  factory CkVertices(
    ui.VertexMode mode,
    Float32List positions, {
    Float32List? textureCoordinates,
    Int32List? colors,
    Uint16List? indices,
  }) {
    Uint32List? unsignedColors;
    if (colors != null) {
      unsignedColors = colors.buffer.asUint32List(colors.offsetInBytes, colors.length);
    }

    return CkVertices._(
      toSkVertexMode(mode),
      positions,
      textureCoordinates,
      unsignedColors,
      indices,
    );
  }

  /// Creates a new `CkVertices` by calling the CanvasKit API.
  ///
  /// This constructor assumes that [positions] is not empty. `EngineVertices`
  /// ensures this by checking `positions.isNotEmpty` before delegating to the backend.
  /// If `positions` were empty, `canvasKit.MakeVertices` would return `null`,
  /// causing JS interop errors.
  CkVertices._(
    SkVertexMode mode,
    Float32List positions,
    Float32List? textureCoordinates,
    Uint32List? colors,
    Uint16List? indices,
  ) : skiaObject = canvasKit.MakeVertices(mode, positions, textureCoordinates, colors, indices);

  final SkVertices skiaObject;

  @override
  void dispose() {
    skiaObject.delete();
  }
}
