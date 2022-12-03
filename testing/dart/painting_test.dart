// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'dart:ui';

import 'package:litetest/litetest.dart';

void main() {
  test('Vertices checks', () {
    try {
      Vertices(
        VertexMode.triangles,
        const <Offset>[Offset.zero, Offset.zero, Offset.zero],
        indices: Uint16List.fromList(const <int>[0, 2, 5]),
      );
      throw 'Vertices did not throw the expected error.';
    } on ArgumentError catch (e) {
      expect('$e', 'Invalid argument(s): "indices" values must be valid indices in the positions list (i.e. numbers in the range 0..2), but indices[2] is 5, which is too big.');
    }
    Vertices( // This one does not throw.
      VertexMode.triangles,
      const <Offset>[Offset.zero],
    ).dispose();
    Vertices( // This one should not throw.
      VertexMode.triangles,
      const <Offset>[Offset.zero, Offset.zero, Offset.zero],
      indices: Uint16List.fromList(const <int>[0, 2, 1, 2, 0, 1, 2, 0]), // Uint16List implements List<int> so this is ok.
    ).dispose();
  });

  test('Vertices.raw checks', () {
    try {
      Vertices.raw(
        VertexMode.triangles,
        Float32List.fromList(const <double>[0.0]),
      );
      throw 'Vertices.raw did not throw the expected error.';
    } on ArgumentError catch (e) {
      expect('$e', 'Invalid argument(s): "positions" must have an even number of entries (each coordinate is an x,y pair).');
    }
    try {
      Vertices.raw(
        VertexMode.triangles,
        Float32List.fromList(const <double>[0.0, 0.0, 0.0, 0.0, 0.0, 0.0]),
        indices: Uint16List.fromList(const <int>[0, 2, 5]),
      );
      throw 'Vertices.raw did not throw the expected error.';
    } on ArgumentError catch (e) {
      expect('$e', 'Invalid argument(s): "indices" values must be valid indices in the positions list (i.e. numbers in the range 0..2), but indices[2] is 5, which is too big.');
    }
    Vertices.raw( // This one does not throw.
      VertexMode.triangles,
      Float32List.fromList(const <double>[0.0, 0.0]),
    ).dispose();
    Vertices.raw( // This one should not throw.
      VertexMode.triangles,
      Float32List.fromList(const <double>[0.0, 0.0, 0.0, 0.0, 0.0, 0.0]),
      indices: Uint16List.fromList(const <int>[0, 2, 1, 2, 0, 1, 2, 0]),
    ).dispose();
  });
}
