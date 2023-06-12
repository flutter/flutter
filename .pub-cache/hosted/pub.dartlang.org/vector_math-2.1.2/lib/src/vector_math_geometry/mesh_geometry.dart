// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of vector_math_geometry;

class VertexAttrib {
  final String name;
  final String type;
  final int size;
  final int stride;
  final int offset;

  VertexAttrib(this.name, this.size, this.type)
      : stride = 0,
        offset = 0;

  VertexAttrib.copy(VertexAttrib attrib)
      : name = attrib.name,
        size = attrib.size,
        type = attrib.type,
        stride = attrib.stride,
        offset = attrib.offset;

  VertexAttrib._internal(
      this.name, this.size, this.type, this.stride, this.offset);

  VertexAttrib._resetStrideOffset(VertexAttrib attrib, this.stride, this.offset)
      : name = attrib.name,
        size = attrib.size,
        type = attrib.type;

  VectorList<Vector> getView(Float32List buffer) {
    final viewOffset = offset ~/ buffer.elementSizeInBytes;
    final viewStride = stride ~/ buffer.elementSizeInBytes;
    switch (size) {
      case 2:
        return Vector2List.view(buffer, viewOffset, viewStride);
      case 3:
        return Vector3List.view(buffer, viewOffset, viewStride);
      case 4:
        return Vector4List.view(buffer, viewOffset, viewStride);
      default:
        throw StateError('size of $size is not supported');
    }
  }

  String get format => '$type$size';

  int get elementSize {
    switch (type) {
      case 'float':
      case 'int':
        return 4;
      case 'short':
        return 2;
      case 'byte':
        return 1;
      default:
        return 0;
    }
  }

  Map<String, Object> toJson() => <String, Object>{
        'format': format,
        'name': name,
        'offset': offset,
        'stride': stride,
        'size': size,
        'type': type
      };
}

class MeshGeometry {
  late final Float32List buffer;
  Uint16List? indices;
  final List<VertexAttrib> attribs;
  final int length;
  final int stride;

  factory MeshGeometry(int length, List<VertexAttrib> attributes) {
    var stride = 0;
    for (var a in attributes) {
      stride += a.elementSize * a.size;
    }
    var offset = 0;
    final attribs = <VertexAttrib>[];
    for (var a in attributes) {
      attribs.add(VertexAttrib._resetStrideOffset(a, stride, offset));
      offset += a.elementSize * a.size;
    }

    return MeshGeometry._internal(length, stride, attribs);
  }

  MeshGeometry._internal(this.length, this.stride, this.attribs,
      [Float32List? externBuffer]) {
    buffer = externBuffer ??
        Float32List((length * stride) ~/ Float32List.bytesPerElement);
  }

  MeshGeometry.copy(MeshGeometry mesh)
      : stride = mesh.stride,
        length = mesh.length,
        attribs = mesh.attribs {
    // Copy the buffer
    buffer = Float32List(mesh.buffer.length);
    buffer.setAll(0, mesh.buffer);

    // Copy the indices
    if (mesh.indices != null) {
      indices = Uint16List(mesh.indices!.length)..setAll(0, mesh.indices!);
    }
  }

  factory MeshGeometry.fromJson(Map<String, Object> json) {
    Float32List buffer;
    final jsonBuffer = json['buffer'];
    if (jsonBuffer is List<double>) {
      buffer = Float32List.fromList(jsonBuffer);
    } else {
      throw ArgumentError.value(
          jsonBuffer, 'json["buffer"]', 'Value type must be List<double>');
    }

    final jsonAttribs = json['attribs'];
    Map<String, Object> jsonAttribsMap;
    if (jsonAttribs is Map<String, Object>) {
      jsonAttribsMap = jsonAttribs;
    } else {
      throw ArgumentError.value(jsonBuffer, 'json["attribs"]',
          'Value type must be Map<String, Object>');
    }
    final attribs = <VertexAttrib>[];
    var stride = 0;
    for (var key in jsonAttribsMap.keys) {
      VertexAttrib attrib;
      final jsonAttrib = jsonAttribsMap[key];
      if (jsonAttrib is Map<String, Object>) {
        attrib = attribFromJson(key, jsonAttrib);
        attribs.add(attrib);
        if (stride == 0) {
          stride = attrib.stride;
        }
      }
    }

    final mesh = MeshGeometry._internal(
        buffer.lengthInBytes ~/ stride, stride, attribs, buffer);

    final jsonIndices = json['indices'];
    if (jsonIndices is List<int>) {
      mesh.indices = Uint16List.fromList(jsonIndices);
    }

    return mesh;
  }

  factory MeshGeometry.resetAttribs(
      MeshGeometry inputMesh, List<VertexAttrib> attributes) {
    final mesh = MeshGeometry(inputMesh.length, attributes)
      ..indices = inputMesh.indices;

    // Copy over the attributes that were specified
    for (var attrib in mesh.attribs) {
      final inputAttrib = inputMesh.getAttrib(attrib.name);
      if (inputAttrib != null) {
        if (inputAttrib.size != attrib.size ||
            inputAttrib.type != attrib.type) {
          throw Exception(
              'Attributes size or type is mismatched: ${attrib.name}');
        }

        final inputView = inputAttrib.getView(inputMesh.buffer);

        // Copy [inputView] to a view from attrib
        attrib.getView(mesh.buffer).copy(inputView);
      }
    }

    return mesh;
  }

  factory MeshGeometry.combine(List<MeshGeometry> meshes) {
    if (meshes.length < 2) {
      throw Exception(
          'Must provide at least two MeshGeometry instances to combine.');
    }

    // When combining meshes they must all have a matching set of VertexAttribs
    final firstMesh = meshes[0];
    var totalVerts = firstMesh.length;
    var totalIndices =
        firstMesh.indices != null ? firstMesh.indices!.length : 0;
    for (var i = 1; i < meshes.length; ++i) {
      final srcMesh = meshes[i];
      if (!firstMesh.attribsAreCompatible(srcMesh)) {
        throw Exception(
            'All meshes must have identical attributes to combine.');
      }
      totalVerts += srcMesh.length;
      totalIndices += srcMesh.indices != null ? srcMesh.indices!.length : 0;
    }

    final mesh =
        MeshGeometry._internal(totalVerts, firstMesh.stride, firstMesh.attribs);

    if (totalIndices > 0) {
      mesh.indices = Uint16List(totalIndices);
    }

    // Copy over the buffer data:
    var bufferOffset = 0;
    var indexOffset = 0;
    var vertexOffset = 0;
    for (var i = 0; i < meshes.length; ++i) {
      final srcMesh = meshes[i];
      mesh.buffer.setAll(bufferOffset, srcMesh.buffer);

      if (totalIndices > 0) {
        for (var j = 0; j < srcMesh.indices!.length; ++j) {
          mesh.indices![j + indexOffset] = srcMesh.indices![j] + vertexOffset;
        }
        vertexOffset += srcMesh.length;
        indexOffset += srcMesh.indices!.length;
      }

      bufferOffset += srcMesh.buffer.length;
    }

    return mesh;
  }

  int get triangleVertexCount => indices != null ? indices!.length : length;

  Map<String, dynamic> toJson() {
    final r = <String, dynamic>{};
    r['attributes'] = attribs;
    r['indices'] = indices;
    r['vertices'] = buffer;
    return r;
  }

  static VertexAttrib attribFromJson(String name, Map<String, Object> json) {
    final jsonSize = json['size'];
    final jsonType = json['type'];
    final jsonStride = json['stride'];
    final jsonOffset = json['offset'];
    if (jsonSize is int &&
        jsonType is String &&
        jsonStride is int &&
        jsonOffset is int) {
      return VertexAttrib._internal(
          name, jsonSize, jsonType, jsonStride, jsonOffset);
    } else {
      throw UnimplementedError();
    }
  }

  VertexAttrib? getAttrib(String name) {
    for (var attrib in attribs) {
      if (attrib.name == name) {
        return attrib;
      }
    }
    return null;
  }

  VectorList<Vector>? getViewForAttrib(String name) {
    for (var attrib in attribs) {
      if (attrib.name == name) {
        return attrib.getView(buffer);
      }
    }
    return null;
  }

  bool attribsAreCompatible(MeshGeometry mesh) {
    if (mesh.attribs.length != attribs.length) {
      return false;
    }

    for (var attrib in attribs) {
      final otherAttrib = mesh.getAttrib(attrib.name);
      if (otherAttrib == null) {
        return false;
      }
      if (attrib.type != otherAttrib.type ||
          attrib.size != otherAttrib.size ||
          attrib.stride != otherAttrib.stride ||
          attrib.offset != otherAttrib.offset) {
        return false;
      }
    }

    if ((indices == null && mesh.indices != null) ||
        (indices != null && mesh.indices == null)) {
      return false;
    }

    return true;
  }
}
