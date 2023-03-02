// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: avoid_unused_constructor_parameters

import 'dart:typed_data';

import 'package:ui/ui.dart' as ui;

class SkwasmVertices implements ui.Vertices {
  factory SkwasmVertices(
    ui.VertexMode mode,
    List<ui.Offset> positions, {
    List<ui.Offset>? textureCoordinates,
    List<ui.Color>? colors,
    List<int>? indices,
  }) {
    throw UnimplementedError();
  }

  factory SkwasmVertices.raw(
    ui.VertexMode mode,
    Float32List positions, {
    Float32List? textureCoordinates,
    Int32List? colors,
    Uint16List? indices,
  }) {
    throw UnimplementedError();
  }

  @override
  bool get debugDisposed => throw UnimplementedError();

  @override
  void dispose() {
  }
}
