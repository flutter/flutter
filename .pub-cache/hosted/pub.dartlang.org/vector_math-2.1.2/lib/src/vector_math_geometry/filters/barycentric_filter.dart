// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of vector_math_geometry;

class BarycentricFilter extends GeometryFilter {
  @override
  List<VertexAttrib> get generates =>
      <VertexAttrib>[VertexAttrib('BARYCENTRIC', 3, 'float')];

  @override
  MeshGeometry filter(MeshGeometry mesh) {
    final newAttribs = List<VertexAttrib>.from(mesh.attribs);

    if (mesh.getAttrib('BARYCENTRIC') == null) {
      newAttribs.add(VertexAttrib('BARYCENTRIC', 3, 'float'));
    }

    final output = MeshGeometry(mesh.triangleVertexCount, newAttribs);

    Vector3List barycentricCoords;
    final view = output.getViewForAttrib('BARYCENTRIC');
    if (view is Vector3List) {
      barycentricCoords = view;
    } else {
      throw UnimplementedError();
    }

    final srcAttribs = <VectorList<Vector>>[];
    final destAttribs = <VectorList<Vector>>[];
    for (var attrib in mesh.attribs) {
      if (attrib.name == 'BARYCENTRIC') {
        continue;
      }

      srcAttribs.add(mesh.getViewForAttrib(attrib.name)!);
      destAttribs.add(output.getViewForAttrib(attrib.name)!);
    }

    final b0 = Vector3(1.0, 0.0, 0.0);
    final b1 = Vector3(0.0, 1.0, 0.0);
    final b2 = Vector3(0.0, 0.0, 1.0);

    int i0, i1, i2;

    for (var i = 0; i < output.length; i += 3) {
      if (mesh.indices != null) {
        i0 = mesh.indices![i];
        i1 = mesh.indices![i + 1];
        i2 = mesh.indices![i + 2];
      } else {
        i0 = i;
        i1 = i + 1;
        i2 = i + 2;
      }

      barycentricCoords[i] = b0;
      barycentricCoords[i + 1] = b1;
      barycentricCoords[i + 2] = b2;

      // Copy the remaining attributes over
      for (var j = 0; j < srcAttribs.length; ++j) {
        destAttribs[j][i] = srcAttribs[j][i0];
        destAttribs[j][i + 1] = srcAttribs[j][i1];
        destAttribs[j][i + 2] = srcAttribs[j][i2];
      }
    }

    return output;
  }
}
