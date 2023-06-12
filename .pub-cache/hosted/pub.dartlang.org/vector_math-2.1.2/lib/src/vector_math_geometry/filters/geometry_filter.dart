// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of vector_math_geometry;

abstract class GeometryFilter {
  bool get inplace => false;
  List<VertexAttrib> get requires => <VertexAttrib>[];
  List<VertexAttrib> get generates => <VertexAttrib>[];

  /// Returns a copy of the mesh with any filter transforms applied.
  MeshGeometry filter(MeshGeometry mesh);
}

abstract class InplaceGeometryFilter extends GeometryFilter {
  @override
  bool get inplace => true;

  @override
  MeshGeometry filter(MeshGeometry mesh) {
    final output = MeshGeometry.copy(mesh);
    filterInplace(output);
    return output;
  }

  /// Applies the filter to the mesh.
  void filterInplace(MeshGeometry mesh);
}
