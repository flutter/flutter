// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/scene/importer/vertices_builder.h"

#include <cstdint>
#include <cstring>
#include <limits>
#include <memory>
#include <type_traits>

#include "flutter/fml/logging.h"
#include "impeller/scene/importer/conversions.h"
#include "impeller/scene/importer/scene_flatbuffers.h"

namespace impeller {
namespace scene {
namespace importer {

//------------------------------------------------------------------------------
/// VerticesBuilder
///

std::unique_ptr<VerticesBuilder> VerticesBuilder::MakeUnskinned() {
  return std::make_unique<UnskinnedVerticesBuilder>();
}

std::unique_ptr<VerticesBuilder> VerticesBuilder::MakeSkinned() {
  return std::make_unique<SkinnedVerticesBuilder>();
}

VerticesBuilder::VerticesBuilder() = default;

VerticesBuilder::~VerticesBuilder() = default;

/// @brief  Reads a numeric component from `source` and returns a 32bit float.
///         If `normalized` is `true`, signed SourceTypes convert to a range of
///         -1 to 1, and unsigned SourceTypes convert to a range of 0 to 1.
template <typename SourceType>
static Scalar ToScalar(const void* source, size_t index, bool normalized) {
  const SourceType* s = reinterpret_cast<const SourceType*>(source) + index;
  Scalar result = static_cast<Scalar>(*s);
  if (normalized) {
    constexpr SourceType divisor = std::is_integral_v<SourceType>
                                       ? std::numeric_limits<SourceType>::max()
                                       : 1;
    result = static_cast<Scalar>(*s) / static_cast<Scalar>(divisor);
  }
  return result;
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
    *(destination + component_i) =
        component.convert_proc(source, component_i, true);
  }
}

/// @brief  A ComponentWriter which converts four vertex indices to scalars.
static void JointsAttributeWriter(
    Scalar* destination,
    const void* source,
    const VerticesBuilder::ComponentProperties& component,
    const VerticesBuilder::AttributeProperties& attribute) {
  FML_DCHECK(attribute.component_count == 4);
  for (int i = 0; i < 4; i++) {
    *(destination + i) = component.convert_proc(source, i, false);
  }
}

std::map<VerticesBuilder::AttributeType, VerticesBuilder::AttributeProperties>
    VerticesBuilder::kAttributeTypes = {
        {VerticesBuilder::AttributeType::kPosition,
         {.offset_bytes = offsetof(UnskinnedVerticesBuilder::Vertex, position),
          .size_bytes = sizeof(UnskinnedVerticesBuilder::Vertex::position),
          .component_count = 3,
          .write_proc = PassthroughAttributeWriter}},
        {VerticesBuilder::AttributeType::kNormal,
         {.offset_bytes = offsetof(UnskinnedVerticesBuilder::Vertex, normal),
          .size_bytes = sizeof(UnskinnedVerticesBuilder::Vertex::normal),
          .component_count = 3,
          .write_proc = PassthroughAttributeWriter}},
        {VerticesBuilder::AttributeType::kTangent,
         {.offset_bytes = offsetof(UnskinnedVerticesBuilder::Vertex, tangent),
          .size_bytes = sizeof(UnskinnedVerticesBuilder::Vertex::tangent),
          .component_count = 4,
          .write_proc = PassthroughAttributeWriter}},
        {VerticesBuilder::AttributeType::kTextureCoords,
         {.offset_bytes =
              offsetof(UnskinnedVerticesBuilder::Vertex, texture_coords),
          .size_bytes =
              sizeof(UnskinnedVerticesBuilder::Vertex::texture_coords),
          .component_count = 2,
          .write_proc = PassthroughAttributeWriter}},
        {VerticesBuilder::AttributeType::kColor,
         {.offset_bytes = offsetof(UnskinnedVerticesBuilder::Vertex, color),
          .size_bytes = sizeof(UnskinnedVerticesBuilder::Vertex::color),
          .component_count = 4,
          .write_proc = PassthroughAttributeWriter}},
        {VerticesBuilder::AttributeType::kJoints,
         {.offset_bytes = offsetof(SkinnedVerticesBuilder::Vertex, joints),
          .size_bytes = sizeof(SkinnedVerticesBuilder::Vertex::joints),
          .component_count = 4,
          .write_proc = JointsAttributeWriter}},
        {VerticesBuilder::AttributeType::kWeights,
         {.offset_bytes = offsetof(SkinnedVerticesBuilder::Vertex, weights),
          .size_bytes = sizeof(SkinnedVerticesBuilder::Vertex::weights),
          .component_count = 4,
          .write_proc = JointsAttributeWriter}}};

static std::map<VerticesBuilder::ComponentType,
                VerticesBuilder::ComponentProperties>
    kComponentTypes = {
        {VerticesBuilder::ComponentType::kSignedByte,
         {.size_bytes = sizeof(int8_t), .convert_proc = ToScalar<int8_t>}},
        {VerticesBuilder::ComponentType::kUnsignedByte,
         {.size_bytes = sizeof(int8_t), .convert_proc = ToScalar<uint8_t>}},
        {VerticesBuilder::ComponentType::kSignedShort,
         {.size_bytes = sizeof(int16_t), .convert_proc = ToScalar<int16_t>}},
        {VerticesBuilder::ComponentType::kUnsignedShort,
         {.size_bytes = sizeof(int16_t), .convert_proc = ToScalar<uint16_t>}},
        {VerticesBuilder::ComponentType::kSignedInt,
         {.size_bytes = sizeof(int32_t), .convert_proc = ToScalar<int32_t>}},
        {VerticesBuilder::ComponentType::kUnsignedInt,
         {.size_bytes = sizeof(int32_t), .convert_proc = ToScalar<uint32_t>}},
        {VerticesBuilder::ComponentType::kFloat,
         {.size_bytes = sizeof(float), .convert_proc = ToScalar<float>}},
};

void VerticesBuilder::WriteAttribute(void* destination,
                                     size_t destination_stride_bytes,
                                     AttributeType attribute,
                                     ComponentType component_type,
                                     const void* source,
                                     size_t attribute_stride_bytes,
                                     size_t attribute_count) {
  const ComponentProperties& component_props = kComponentTypes[component_type];
  const AttributeProperties& attribute_props = kAttributeTypes[attribute];
  for (size_t i = 0; i < attribute_count; i++) {
    const uint8_t* src =
        reinterpret_cast<const uint8_t*>(source) + attribute_stride_bytes * i;
    uint8_t* dst = reinterpret_cast<uint8_t*>(destination) +
                   i * destination_stride_bytes + attribute_props.offset_bytes;

    attribute_props.write_proc(reinterpret_cast<Scalar*>(dst), src,
                               component_props, attribute_props);
  }
}

//------------------------------------------------------------------------------
/// UnskinnedVerticesBuilder
///

UnskinnedVerticesBuilder::UnskinnedVerticesBuilder() = default;

UnskinnedVerticesBuilder::~UnskinnedVerticesBuilder() = default;

void UnskinnedVerticesBuilder::WriteFBVertices(
    fb::MeshPrimitiveT& primitive) const {
  auto vertex_buffer = fb::UnskinnedVertexBufferT();
  vertex_buffer.vertices.resize(0);
  for (auto& v : vertices_) {
    vertex_buffer.vertices.push_back(fb::Vertex(
        ToFBVec3(v.position), ToFBVec3(v.normal), ToFBVec4(v.tangent),
        ToFBVec2(v.texture_coords), ToFBColor(v.color)));
  }
  primitive.vertices.Set(std::move(vertex_buffer));
}

void UnskinnedVerticesBuilder::SetAttributeFromBuffer(
    AttributeType attribute,
    ComponentType component_type,
    const void* buffer_start,
    size_t attribute_stride_bytes,
    size_t attribute_count) {
  if (attribute_count > vertices_.size()) {
    vertices_.resize(attribute_count, Vertex());
  }
  WriteAttribute(vertices_.data(),        // destination
                 sizeof(Vertex),          // destination_stride_bytes
                 attribute,               // attribute
                 component_type,          // component_type
                 buffer_start,            // source
                 attribute_stride_bytes,  // attribute_stride_bytes
                 attribute_count);        // attribute_count
}

//------------------------------------------------------------------------------
/// SkinnedVerticesBuilder
///

SkinnedVerticesBuilder::SkinnedVerticesBuilder() = default;

SkinnedVerticesBuilder::~SkinnedVerticesBuilder() = default;

void SkinnedVerticesBuilder::WriteFBVertices(
    fb::MeshPrimitiveT& primitive) const {
  auto vertex_buffer = fb::SkinnedVertexBufferT();
  vertex_buffer.vertices.resize(0);
  for (auto& v : vertices_) {
    auto unskinned_attributes = fb::Vertex(
        ToFBVec3(v.vertex.position), ToFBVec3(v.vertex.normal),
        ToFBVec4(v.vertex.tangent), ToFBVec2(v.vertex.texture_coords),
        ToFBColor(v.vertex.color));
    vertex_buffer.vertices.push_back(fb::SkinnedVertex(
        unskinned_attributes, ToFBVec4(v.joints), ToFBVec4(v.weights)));
  }
  primitive.vertices.Set(std::move(vertex_buffer));
}

void SkinnedVerticesBuilder::SetAttributeFromBuffer(
    AttributeType attribute,
    ComponentType component_type,
    const void* buffer_start,
    size_t attribute_stride_bytes,
    size_t attribute_count) {
  if (attribute_count > vertices_.size()) {
    vertices_.resize(attribute_count, Vertex());
  }
  WriteAttribute(vertices_.data(),        // destination
                 sizeof(Vertex),          // destination_stride_bytes
                 attribute,               // attribute
                 component_type,          // component_type
                 buffer_start,            // source
                 attribute_stride_bytes,  // attribute_stride_bytes
                 attribute_count);        // attribute_count
}

}  // namespace importer
}  // namespace scene
}  // namespace impeller
