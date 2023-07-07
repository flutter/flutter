// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of vector_math_geometry;

class CylinderGenerator extends GeometryGenerator {
  late double _topRadius;
  late double _bottomRadius;
  late double _height;
  late int _segments;

  @override
  int get vertexCount => ((_segments + 1) * 2) + (_segments * 2);

  @override
  int get indexCount => (_segments * 6) + ((_segments - 2) * 6);

  MeshGeometry createCylinder(num topRadius, num bottomRadius, num height,
      {int segments = 16,
      GeometryGeneratorFlags? flags,
      List<GeometryFilter>? filters}) {
    _topRadius = topRadius.toDouble();
    _bottomRadius = bottomRadius.toDouble();
    _height = height.toDouble();
    _segments = segments;

    return createGeometry(flags: flags, filters: filters);
  }

  @override
  void generateIndices(Uint16List indices) {
    var i = 0;

    // Sides
    var base1 = 0;
    final base2 = _segments + 1;
    for (var x = 0; x < _segments; ++x) {
      indices[i++] = base1 + x;
      indices[i++] = base1 + x + 1;
      indices[i++] = base2 + x;

      indices[i++] = base1 + x + 1;
      indices[i++] = base2 + x + 1;
      indices[i++] = base2 + x;
    }

    // Top cap
    base1 = (_segments + 1) * 2;
    for (var x = 1; x < _segments - 1; ++x) {
      indices[i++] = base1;
      indices[i++] = base1 + x + 1;
      indices[i++] = base1 + x;
    }

    // Bottom cap
    base1 = (_segments + 1) * 2 + _segments;
    for (var x = 1; x < _segments - 1; ++x) {
      indices[i++] = base1;
      indices[i++] = base1 + x;
      indices[i++] = base1 + x + 1;
    }
  }

  @override
  void generateVertexPositions(Vector3List positions, Uint16List indices) {
    var i = 0;

    // Top
    for (var x = 0; x <= _segments; ++x) {
      final u = x / _segments;

      positions[i++] = Vector3(_topRadius * math.cos(u * math.pi * 2.0),
          _height * 0.5, _topRadius * math.sin(u * math.pi * 2.0));
    }

    // Bottom
    for (var x = 0; x <= _segments; ++x) {
      final u = x / _segments;

      positions[i++] = Vector3(_bottomRadius * math.cos(u * math.pi * 2.0),
          _height * -0.5, _bottomRadius * math.sin(u * math.pi * 2.0));
    }

    // Top cap
    for (var x = 0; x < _segments; ++x) {
      final u = x / _segments;

      positions[i++] = Vector3(_topRadius * math.cos(u * math.pi * 2.0),
          _height * 0.5, _topRadius * math.sin(u * math.pi * 2.0));
    }

    // Bottom cap
    for (var x = 0; x < _segments; ++x) {
      final u = x / _segments;

      positions[i++] = Vector3(_bottomRadius * math.cos(u * math.pi * 2.0),
          _height * -0.5, _bottomRadius * math.sin(u * math.pi * 2.0));
    }
  }

  @override
  void generateVertexTexCoords(
      Vector2List texCoords, Vector3List positions, Uint16List indices) {
    var i = 0;

    // Cylinder top
    for (var x = 0; x <= _segments; ++x) {
      final u = 1.0 - (x / _segments);
      texCoords[i++] = Vector2(u, 0.0);
    }

    // Cylinder bottom
    for (var x = 0; x <= _segments; ++x) {
      final u = 1.0 - (x / _segments);
      texCoords[i++] = Vector2(u, 1.0);
    }

    // Top cap
    for (var x = 0; x < _segments; ++x) {
      final r = (x / _segments) * math.pi * 2.0;
      texCoords[i++] =
          Vector2(math.cos(r) * 0.5 + 0.5, math.sin(r) * 0.5 + 0.5);
    }

    // Bottom cap
    for (var x = 0; x < _segments; ++x) {
      final r = (x / _segments) * math.pi * 2.0;
      texCoords[i++] =
          Vector2(math.cos(r) * 0.5 + 0.5, math.sin(r) * 0.5 + 0.5);
    }
  }
}
