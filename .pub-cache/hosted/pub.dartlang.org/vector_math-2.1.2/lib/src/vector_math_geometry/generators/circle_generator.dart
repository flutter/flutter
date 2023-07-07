// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of vector_math_geometry;

class CircleGenerator extends GeometryGenerator {
  late double _radius;
  late int _segments;
  late double _thetaStart;
  late double _thetaLength;

  @override
  int get vertexCount => _segments + 2;

  @override
  int get indexCount => _segments * 3;

  MeshGeometry createCircle(double radius,
      {GeometryGeneratorFlags? flags,
      List<GeometryFilter>? filters,
      int segments = 64,
      double thetaStart = 0.0,
      double thetaLength = math.pi * 2.0}) {
    _radius = radius;
    _segments = segments;
    _thetaStart = thetaStart;
    _thetaLength = thetaLength;
    return createGeometry(flags: flags, filters: filters);
  }

  @override
  void generateVertexPositions(Vector3List positions, Uint16List indices) {
    final v = Vector3.zero();
    positions[0] = v;
    var index = 1;
    for (var i = 0; i <= _segments; i++) {
      final percent = i / _segments;
      v
        ..x = _radius * math.cos(_thetaStart + percent * _thetaLength)
        ..z = _radius * math.sin(_thetaStart + percent * _thetaLength);
      positions[index] = v;
      index++;
    }
    assert(index == vertexCount);
  }

  @override
  void generateVertexTexCoords(
      Vector2List texCoords, Vector3List positions, Uint16List indices) {
    final v = Vector2(0.5, 0.5);
    texCoords[0] = v;
    var index = 1;
    for (var i = 0; i <= _segments; i++) {
      final position = positions[index];
      final x = (position.x / (_radius + 1.0)) * 0.5;
      final y = (position.z / (_radius + 1.0)) * 0.5;
      v
        ..x = x + 0.5
        ..y = y + 0.5;
      texCoords[index] = v;
      index++;
    }
    assert(index == vertexCount);
  }

  @override
  void generateIndices(Uint16List indices) {
    var index = 0;
    for (var i = 1; i <= _segments; i++) {
      indices[index] = i;
      indices[index + 1] = i + 1;
      indices[index + 2] = 0;
      index += 3;
    }
    assert(index == indexCount);
  }
}
