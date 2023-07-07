// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of vector_math_geometry;

class FlatShadeFilter extends GeometryFilter {
  @override
  List<VertexAttrib> get requires =>
      <VertexAttrib>[VertexAttrib('POSITION', 3, 'float')];

  @override
  List<VertexAttrib> get generates =>
      <VertexAttrib>[VertexAttrib('NORMAL', 3, 'float')];

  @override
  MeshGeometry filter(MeshGeometry mesh) {
    final newAttribs = List<VertexAttrib>.from(mesh.attribs);

    if (mesh.getAttrib('NORMAL') == null) {
      newAttribs.add(VertexAttrib('NORMAL', 3, 'float'));
    }

    final output = MeshGeometry(mesh.triangleVertexCount, newAttribs);

    final p0 = Vector3.zero(), p1 = Vector3.zero(), p2 = Vector3.zero();

    final srcPosition = mesh.getViewForAttrib('POSITION');
    final destPosition = output.getViewForAttrib('POSITION');
    final normals = output.getViewForAttrib('NORMAL');

    if (srcPosition is! Vector3List ||
        destPosition is! Vector3List ||
        normals is! Vector3List) {
      throw UnimplementedError();
    }

    final srcAttribs = <VectorList<Vector>>[];
    final destAttribs = <VectorList<Vector>>[];
    for (var attrib in mesh.attribs) {
      if (attrib.name == 'POSITION' || attrib.name == 'NORMAL') {
        continue;
      }

      srcAttribs.add(mesh.getViewForAttrib(attrib.name)!);
      destAttribs.add(output.getViewForAttrib(attrib.name)!);
    }

    for (var i = 0; i < output.length; i += 3) {
      final i0 = mesh.indices![i];
      final i1 = mesh.indices![i + 1];
      final i2 = mesh.indices![i + 2];

      srcPosition
        ..load(i0, p0)
        ..load(i1, p1)
        ..load(i2, p2);

      destPosition[i] = p0;
      destPosition[i + 1] = p1;
      destPosition[i + 2] = p2;

      // Store the normalized cross product of p1 and p2 in p0.
      p1.sub(p0);
      p2.sub(p0);
      p1.crossInto(p2, p0).normalize();

      normals[i] = p0;
      normals[i + 1] = p0;
      normals[i + 2] = p0;

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
