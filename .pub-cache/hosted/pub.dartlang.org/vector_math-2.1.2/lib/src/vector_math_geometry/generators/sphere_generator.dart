// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of vector_math_geometry;

class SphereGenerator extends GeometryGenerator {
  late double _radius;
  late int _latSegments;
  late int _lonSegments;

  @override
  int get vertexCount => (_lonSegments + 1) * (_latSegments + 1);

  @override
  int get indexCount => 6 * _lonSegments * _latSegments;

  MeshGeometry createSphere(num radius,
      {int latSegments = 16,
      int lonSegments = 16,
      GeometryGeneratorFlags? flags,
      List<GeometryFilter>? filters}) {
    _radius = radius.toDouble();
    _latSegments = latSegments;
    _lonSegments = lonSegments;

    return createGeometry(flags: flags, filters: filters);
  }

  @override
  void generateIndices(Uint16List indices) {
    var i = 0;
    for (var y = 0; y < _latSegments; ++y) {
      final base1 = (_lonSegments + 1) * y;
      final base2 = (_lonSegments + 1) * (y + 1);

      for (var x = 0; x < _lonSegments; ++x) {
        indices[i++] = base1 + x;
        indices[i++] = base1 + x + 1;
        indices[i++] = base2 + x;

        indices[i++] = base1 + x + 1;
        indices[i++] = base2 + x + 1;
        indices[i++] = base2 + x;
      }
    }
  }

  @override
  void generateVertexPositions(Vector3List positions, Uint16List indices) {
    var i = 0;
    for (var y = 0; y <= _latSegments; ++y) {
      final v = y / _latSegments;
      final sv = math.sin(v * math.pi);
      final cv = math.cos(v * math.pi);

      for (var x = 0; x <= _lonSegments; ++x) {
        final u = x / _lonSegments;

        positions[i++] = Vector3(_radius * math.cos(u * math.pi * 2.0) * sv,
            _radius * cv, _radius * math.sin(u * math.pi * 2.0) * sv);
      }
    }
  }

  @override
  void generateVertexTexCoords(
      Vector2List texCoords, Vector3List positions, Uint16List indices) {
    var i = 0;
    for (var y = 0; y <= _latSegments; ++y) {
      final v = y / _latSegments;

      for (var x = 0; x <= _lonSegments; ++x) {
        final u = x / _lonSegments;
        texCoords[i++] = Vector2(u, v);
      }
    }
  }

  @override
  void generateVertexNormals(
      Vector3List normals, Vector3List positions, Uint16List indices) {
    var i = 0;
    for (var y = 0; y <= _latSegments; ++y) {
      final v = y / _latSegments;
      final sv = math.sin(v * math.pi);
      final cv = math.cos(v * math.pi);

      for (var x = 0; x <= _lonSegments; ++x) {
        final u = x / _lonSegments;

        normals[i++] = Vector3(math.cos(u * math.pi * 2.0) * sv, cv,
            math.sin(u * math.pi * 2.0) * sv);
      }
    }
  }
}
