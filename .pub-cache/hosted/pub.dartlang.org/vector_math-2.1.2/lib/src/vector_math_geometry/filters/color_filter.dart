// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of vector_math_geometry;

class ColorFilter extends GeometryFilter {
  Vector4 color;

  ColorFilter(this.color);

  @override
  List<VertexAttrib> get generates =>
      <VertexAttrib>[VertexAttrib('COLOR', 4, 'float')];

  @override
  MeshGeometry filter(MeshGeometry mesh) {
    MeshGeometry output;
    if (mesh.getAttrib('COLOR') == null) {
      final attributes = <VertexAttrib>[
        ...mesh.attribs,
        VertexAttrib('COLOR', 4, 'float'),
      ];
      output = MeshGeometry.resetAttribs(mesh, attributes);
    } else {
      output = MeshGeometry.copy(mesh);
    }

    final colors = output.getViewForAttrib('COLOR');
    if (colors is Vector4List) {
      for (var i = 0; i < colors.length; ++i) {
        colors[i] = color;
      }
      return output;
    } else {
      throw UnimplementedError();
    }
  }
}
