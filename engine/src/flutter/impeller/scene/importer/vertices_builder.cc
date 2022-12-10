// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/scene/importer/vertices_builder.h"

#include <cstring>
#include <limits>
#include <type_traits>

#include "flutter/fml/logging.h"
#include "impeller/scene/importer/conversions.h"
#include "impeller/scene/importer/scene_flatbuffers.h"

namespace impeller {
namespace scene {
namespace importer {

VerticesBuilder::VerticesBuilder() = default;

void VerticesBuilder::WriteFBVertices(std::vector<fb::Vertex>& vertices) const {
  vertices.resize(0);
  for (auto& v : vertices_) {
    vertices.push_back(fb::Vertex(
        ToFBVec3(v.position), ToFBVec3(v.normal), ToFBVec4(v.tangent),
        ToFBVec2(v.texture_coords), ToFBColor(v.color)));
  }
}

/// @brief  Reads a numeric component from `source` and returns a 32bit float.
///         Signed SourceTypes convert to a range of -1 to 1, and unsigned
///         SourceTypes convert to a range of 0 to 1.
template <typename SourceType>
static Scalar ToNormalizedScalar(const void* source, size_t index) {
  constexpr SourceType divisor = std::is_integral_v<SourceType>
                                     ? std::numeric_limits<SourceType>::max()
                                     : 1;
  const SourceType* s = reinterpret_cast<const SourceType*>(source) + index;
  return static_cast<Scalar>(*s) / static_cast<Scalar>(divisor);
}

/// @brief  A ComponentWriter which simply converts all of an attribute's
///         components to normalized scalar form.
static void PassthroughAttributeWriter(
    Scalar* destination,
    const void* source,
    const VerticesBuilder::ComponentProperties& component,
    const VerticesBuilder::AttributeProperties& attribute) {
  FML_DCHECK(attribute.size_bytes ==
             attribute.component_count * sizeof(Scalar));
  for (size_t component_i = 0; component_i < attribute.component_count;
       component_i++) {
    *(destination + component_i) = component.convert_proc(source, component_i);
  }
}

/// @brief  A ComponentWriter which converts a Vector3 position from
///         right-handed GLTF space to left-handed Impeller space.
static void PositionAttributeWriter(
    Scalar* destination,
    const void* source,
    const VerticesBuilder::ComponentProperties& component,
    const VerticesBuilder::AttributeProperties& attribute) {
  FML_DCHECK(attribute.component_count == 3);
  *(destination + 0) = component.convert_proc(source, 0);
  *(destination + 1) = component.convert_proc(source, 1);
  *(destination + 2) = -component.convert_proc(source, 2);
}

std::map<VerticesBuilder::AttributeType, VerticesBuilder::AttributeProperties>
    VerticesBuilder::kAttributeTypes = {
        {VerticesBuilder::AttributeType::kPosition,
         {.offset_bytes = offsetof(Vertex, position),
          .size_bytes = sizeof(Vertex::position),
          .component_count = 3,
          .write_proc = PositionAttributeWriter}},
        {VerticesBuilder::AttributeType::kNormal,
         {.offset_bytes = offsetof(Vertex, normal),
          .size_bytes = sizeof(Vertex::normal),
          .component_count = 3,
          .write_proc = PassthroughAttributeWriter}},
        {VerticesBuilder::AttributeType::kTangent,
         {.offset_bytes = offsetof(Vertex, tangent),
          .size_bytes = sizeof(Vertex::tangent),
          .component_count = 4,
          .write_proc = PassthroughAttributeWriter}},
        {VerticesBuilder::AttributeType::kTextureCoords,
         {.offset_bytes = offsetof(Vertex, texture_coords),
          .size_bytes = sizeof(Vertex::texture_coords),
          .component_count = 2,
          .write_proc = PassthroughAttributeWriter}},
        {VerticesBuilder::AttributeType::kColor,
         {.offset_bytes = offsetof(Vertex, color),
          .size_bytes = sizeof(Vertex::color),
          .component_count = 4,
          .write_proc = PassthroughAttributeWriter}}};

static std::map<VerticesBuilder::ComponentType,
                VerticesBuilder::ComponentProperties>
    kComponentTypes = {
        {VerticesBuilder::ComponentType::kSignedByte,
         {.size_bytes = sizeof(int8_t),
          .convert_proc = ToNormalizedScalar<int8_t>}},
        {VerticesBuilder::ComponentType::kUnsignedByte,
         {.size_bytes = sizeof(int8_t),
          .convert_proc = ToNormalizedScalar<uint8_t>}},
        {VerticesBuilder::ComponentType::kSignedShort,
         {.size_bytes = sizeof(int16_t),
          .convert_proc = ToNormalizedScalar<int16_t>}},
        {VerticesBuilder::ComponentType::kUnsignedShort,
         {.size_bytes = sizeof(int16_t),
          .convert_proc = ToNormalizedScalar<uint16_t>}},
        {VerticesBuilder::ComponentType::kSignedInt,
         {.size_bytes = sizeof(int32_t),
          .convert_proc = ToNormalizedScalar<int32_t>}},
        {VerticesBuilder::ComponentType::kUnsignedInt,
         {.size_bytes = sizeof(int32_t),
          .convert_proc = ToNormalizedScalar<uint32_t>}},
        {VerticesBuilder::ComponentType::kFloat,
         {.size_bytes = sizeof(float),
          .convert_proc = ToNormalizedScalar<float>}},
};

void VerticesBuilder::SetAttributeFromBuffer(AttributeType attribute,
                                             ComponentType component_type,
                                             const void* buffer_start,
                                             size_t attribute_stride_bytes,
                                             size_t attribute_count) {
  if (attribute_count > vertices_.size()) {
    vertices_.resize(attribute_count, Vertex());
  }

  const ComponentProperties& component_props = kComponentTypes[component_type];
  const AttributeProperties& attribute_props = kAttributeTypes[attribute];
  for (size_t i = 0; i < attribute_count; i++) {
    const uint8_t* source = reinterpret_cast<const uint8_t*>(buffer_start) +
                            attribute_stride_bytes * i;
    uint8_t* destination = reinterpret_cast<uint8_t*>(&vertices_.data()[i]) +
                           attribute_props.offset_bytes;

    attribute_props.write_proc(reinterpret_cast<Scalar*>(destination), source,
                               component_props, attribute_props);
  }
}

}  // namespace importer
}  // namespace scene
}  // namespace impeller
