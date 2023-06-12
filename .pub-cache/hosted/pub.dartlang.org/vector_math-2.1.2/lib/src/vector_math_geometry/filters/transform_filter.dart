// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of vector_math_geometry;

class TransformFilter extends InplaceGeometryFilter {
  Matrix4 transform;

  TransformFilter(this.transform);

  @override
  List<VertexAttrib> get requires =>
      <VertexAttrib>[VertexAttrib('POSITION', 3, 'float')];

  @override
  void filterInplace(MeshGeometry mesh) {
    final position = mesh.getViewForAttrib('POSITION');
    if (position is Vector3List) {
      for (var i = 0; i < position.length; ++i) {
        // multiplication always returns Vector3 here
        // ignore: invalid_assignment
        position[i] = transform * position[i];
      }
    }
  }
}
