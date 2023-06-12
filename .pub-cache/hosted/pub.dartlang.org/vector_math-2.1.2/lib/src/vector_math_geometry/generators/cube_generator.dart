// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of vector_math_geometry;

class CubeGenerator extends GeometryGenerator {
  late double _width;
  late double _height;
  late double _depth;

  @override
  int get vertexCount => 24;

  @override
  int get indexCount => 36;

  MeshGeometry createCube(num width, num height, num depth,
      {GeometryGeneratorFlags? flags, List<GeometryFilter>? filters}) {
    _width = width.toDouble();
    _height = height.toDouble();
    _depth = depth.toDouble();

    return createGeometry(flags: flags, filters: filters);
  }

  @override
  void generateIndices(Uint16List indices) {
    indices.setAll(0, <int>[
      0,
      1,
      2,
      0,
      2,
      3,
      4,
      5,
      6,
      4,
      6,
      7,
      8,
      9,
      10,
      8,
      10,
      11,
      12,
      13,
      14,
      12,
      14,
      15,
      16,
      17,
      18,
      16,
      18,
      19,
      20,
      21,
      22,
      20,
      22,
      23
    ]);
  }

  @override
  void generateVertexPositions(Vector3List positions, Uint16List indices) {
    // Front
    positions[0] = Vector3(_width, _height, _depth);
    positions[1] = Vector3(-_width, _height, _depth);
    positions[2] = Vector3(-_width, -_height, _depth);
    positions[3] = Vector3(_width, -_height, _depth);

    // Back
    positions[4] = Vector3(_width, -_height, -_depth);
    positions[5] = Vector3(-_width, -_height, -_depth);
    positions[6] = Vector3(-_width, _height, -_depth);
    positions[7] = Vector3(_width, _height, -_depth);

    // Right
    positions[8] = Vector3(_width, -_height, _depth);
    positions[9] = Vector3(_width, -_height, -_depth);
    positions[10] = Vector3(_width, _height, -_depth);
    positions[11] = Vector3(_width, _height, _depth);

    // Left
    positions[12] = Vector3(-_width, _height, _depth);
    positions[13] = Vector3(-_width, _height, -_depth);
    positions[14] = Vector3(-_width, -_height, -_depth);
    positions[15] = Vector3(-_width, -_height, _depth);

    // Top
    positions[16] = Vector3(_width, _height, _depth);
    positions[17] = Vector3(_width, _height, -_depth);
    positions[18] = Vector3(-_width, _height, -_depth);
    positions[19] = Vector3(-_width, _height, _depth);

    // Bottom
    positions[20] = Vector3(-_width, -_height, _depth);
    positions[21] = Vector3(-_width, -_height, -_depth);
    positions[22] = Vector3(_width, -_height, -_depth);
    positions[23] = Vector3(_width, -_height, _depth);
  }

  @override
  void generateVertexTexCoords(
      Vector2List texCoords, Vector3List positions, Uint16List indices) {
    // Front
    texCoords[0] = Vector2(1.0, 0.0);
    texCoords[1] = Vector2(0.0, 0.0);
    texCoords[2] = Vector2(0.0, 1.0);
    texCoords[3] = Vector2(1.0, 1.0);

    // Back
    texCoords[4] = Vector2(0.0, 1.0);
    texCoords[5] = Vector2(1.0, 1.0);
    texCoords[6] = Vector2(1.0, 0.0);
    texCoords[7] = Vector2(0.0, 0.0);

    // Right
    texCoords[8] = Vector2(0.0, 1.0);
    texCoords[9] = Vector2(1.0, 1.0);
    texCoords[10] = Vector2(1.0, 0.0);
    texCoords[11] = Vector2(0.0, 0.0);

    // Left
    texCoords[12] = Vector2(1.0, 0.0);
    texCoords[13] = Vector2(0.0, 0.0);
    texCoords[14] = Vector2(0.0, 1.0);
    texCoords[15] = Vector2(1.0, 1.0);

    // Top
    texCoords[16] = Vector2(1.0, 1.0);
    texCoords[17] = Vector2(1.0, 0.0);
    texCoords[18] = Vector2(0.0, 0.0);
    texCoords[19] = Vector2(0.0, 1.0);

    // Bottom
    texCoords[20] = Vector2(0.0, 0.0);
    texCoords[21] = Vector2(0.0, 1.0);
    texCoords[22] = Vector2(1.0, 1.0);
    texCoords[23] = Vector2(1.0, 0.0);
  }
}
