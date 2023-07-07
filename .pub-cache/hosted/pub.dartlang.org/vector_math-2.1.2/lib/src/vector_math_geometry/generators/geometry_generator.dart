// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of vector_math_geometry;

class GeometryGeneratorFlags {
  final bool texCoords;
  final bool normals;
  final bool tangents;

  GeometryGeneratorFlags(
      {this.texCoords = true, this.normals = true, this.tangents = true});
}

abstract class GeometryGenerator {
  int get vertexCount;
  int get indexCount;

  MeshGeometry createGeometry(
      {GeometryGeneratorFlags? flags, List<GeometryFilter>? filters}) {
    flags ??= GeometryGeneratorFlags();

    VertexAttrib positionAttrib;
    VertexAttrib texCoordAttrib;
    VertexAttrib normalAttrib;
    VertexAttrib tangentAttrib;

    Vector2List? texCoordView;
    Vector3List? positionView;
    Vector3List? normalView;
    Vector4List tangentView;

    final attribs = <VertexAttrib>[];

    positionAttrib = VertexAttrib('POSITION', 3, 'float');
    attribs.add(positionAttrib);

    if (flags.texCoords || flags.tangents) {
      texCoordAttrib = VertexAttrib('TEXCOORD0', 2, 'float');
      attribs.add(texCoordAttrib);
    }

    if (flags.normals || flags.tangents) {
      normalAttrib = VertexAttrib('NORMAL', 3, 'float');
      attribs.add(normalAttrib);
    }

    if (flags.tangents) {
      tangentAttrib = VertexAttrib('TANGENT', 4, 'float');
      attribs.add(tangentAttrib);
    }

    var mesh = MeshGeometry(vertexCount, attribs)
      ..indices = Uint16List(indexCount);
    generateIndices(mesh.indices!);

    var view = mesh.getViewForAttrib('POSITION');
    if (view is Vector3List) {
      positionView = view;
      generateVertexPositions(positionView, mesh.indices!);
    }

    if (flags.texCoords || flags.tangents) {
      view = mesh.getViewForAttrib('TEXCOORD0');
      if (view is Vector2List) {
        texCoordView = view;
        generateVertexTexCoords(texCoordView, positionView!, mesh.indices!);
      }
    }

    if (flags.normals || flags.tangents) {
      view = mesh.getViewForAttrib('NORMAL');
      if (view is Vector3List) {
        normalView = view;
        generateVertexNormals(normalView, positionView!, mesh.indices!);
      }
    }

    if (flags.tangents) {
      view = mesh.getViewForAttrib('TANGENT');
      if (view is Vector4List) {
        tangentView = view;
        generateVertexTangents(tangentView, positionView!, normalView!,
            texCoordView!, mesh.indices!);
      }
    }

    if (filters != null) {
      for (var filter in filters) {
        if (filter.inplace && filter is InplaceGeometryFilter) {
          filter.filterInplace(mesh);
        } else {
          mesh = filter.filter(mesh);
        }
      }
    }

    return mesh;
  }

  void generateIndices(Uint16List indices);

  void generateVertexPositions(Vector3List positions, Uint16List indices);

  void generateVertexTexCoords(
      Vector2List texCoords, Vector3List positions, Uint16List indices) {
    for (var i = 0; i < positions.length; ++i) {
      final p = positions[i];

      // These are TERRIBLE texture coords, but it's better than nothing.
      // Override this function and put better ones in place!
      texCoords[i] = Vector2(p.x + p.z, p.y + p.z);
    }
  }

  void generateVertexNormals(
      Vector3List normals, Vector3List positions, Uint16List indices) {
    generateNormals(normals, positions, indices);
  }

  void generateVertexTangents(Vector4List tangents, Vector3List positions,
      Vector3List normals, Vector2List texCoords, Uint16List indices) {
    generateTangents(tangents, positions, normals, texCoords, indices);
  }
}
