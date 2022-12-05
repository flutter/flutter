// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <cstddef>
#include <map>

#include "flutter/fml/macros.h"
#include "impeller/geometry/matrix.h"
#include "impeller/scene/importer/scene_flatbuffers.h"

namespace impeller {
namespace scene {
namespace importer {

class VerticesBuilder {
 public:
  enum class Attribute {
    kPosition,
    kNormal,
    kTangent,
    kTextureCoords,
    kColor,
  };

  enum class ComponentType {
    kSignedByte = 5120,
    kUnsignedByte,
    kSignedShort,
    kUnsignedShort,
    kSignedInt,
    kUnsignedInt,
    kFloat,
  };

  VerticesBuilder();

  void WriteFBVertices(std::vector<fb::Vertex>& vertices) const;

  void SetAttributeFromBuffer(Attribute attribute,
                              ComponentType component_type,
                              const void* buffer_start,
                              size_t stride_bytes,
                              size_t count);

 private:
  struct AttributeProperties {
    size_t offset_bytes;
    size_t size_bytes;
    size_t component_count;
  };

  static std::map<VerticesBuilder::Attribute,
                  VerticesBuilder::AttributeProperties>
      kAttributes;

  struct Vertex {
    Vector3 position;
    Vector3 normal;
    Vector4 tangent;
    Vector2 texture_coords;
    Color color = Color::White();
  };

  std::vector<Vertex> vertices_;

  FML_DISALLOW_COPY_AND_ASSIGN(VerticesBuilder);
};

}  // namespace importer
}  // namespace scene
}  // namespace impeller
