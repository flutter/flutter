// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/scene/geometry.h"

#include <iostream>
#include <memory>
#include <ostream>

#include "impeller/geometry/point.h"
#include "impeller/geometry/vector.h"
#include "impeller/renderer/device_buffer_descriptor.h"
#include "impeller/renderer/formats.h"
#include "impeller/renderer/vertex_buffer.h"
#include "impeller/renderer/vertex_buffer_builder.h"
#include "impeller/scene/importer/scene_flatbuffers.h"
#include "impeller/scene/shaders/geometry.vert.h"
#include "third_party/flatbuffers/include/flatbuffers/vector.h"

namespace impeller {
namespace scene {

//------------------------------------------------------------------------------
/// Geometry
///

Geometry::~Geometry() = default;

std::shared_ptr<CuboidGeometry> Geometry::MakeCuboid(Vector3 size) {
  auto result = std::make_shared<CuboidGeometry>();
  result->SetSize(size);
  return result;
}

std::shared_ptr<VertexBufferGeometry> Geometry::MakeVertexBuffer(
    VertexBuffer vertex_buffer) {
  auto result = std::make_shared<VertexBufferGeometry>();
  result->SetVertexBuffer(std::move(vertex_buffer));
  return result;
}

std::shared_ptr<VertexBufferGeometry> Geometry::MakeFromFBMesh(
    const fb::StaticMesh& mesh,
    Allocator& allocator) {
  IndexType index_type;
  switch (mesh.indices()->type()) {
    case fb::IndicesType::k16Bit:
      index_type = IndexType::k16bit;
      break;
    case fb::IndicesType::k32Bit:
      index_type = IndexType::k32bit;
      break;
  }

  const size_t vertices_bytes = mesh.vertices()->size() * sizeof(fb::Vertex);
  const size_t indices_bytes = mesh.indices()->data()->size();
  if (vertices_bytes == 0 || indices_bytes == 0) {
    return nullptr;
  }

  DeviceBufferDescriptor buffer_desc;
  buffer_desc.size = vertices_bytes * indices_bytes;
  buffer_desc.storage_mode = StorageMode::kHostVisible;

  auto buffer = allocator.CreateBuffer(buffer_desc);
  buffer->SetLabel("Mesh vertices+indices");

  const uint8_t* vertices_start =
      reinterpret_cast<const uint8_t*>(mesh.vertices()->Get(0));
  const uint8_t* indices_start =
      reinterpret_cast<const uint8_t*>(mesh.indices()->data()->Data());

  if (!buffer->CopyHostBuffer(vertices_start, Range(0, vertices_bytes))) {
    return nullptr;
  }
  if (!buffer->CopyHostBuffer(indices_start, Range(0, indices_bytes),
                              vertices_bytes)) {
    return nullptr;
  }

  VertexBuffer vertex_buffer = {
      .vertex_buffer = {.buffer = buffer, .range = Range(0, vertices_bytes)},
      .index_buffer = {.buffer = buffer,
                       .range = Range(vertices_bytes, indices_bytes)},
      .index_count = mesh.indices()->count(),
      .index_type = index_type,
  };
  return MakeVertexBuffer(std::move(vertex_buffer));
}

//------------------------------------------------------------------------------
/// CuboidGeometry
///

CuboidGeometry::CuboidGeometry() = default;

CuboidGeometry::~CuboidGeometry() = default;

void CuboidGeometry::SetSize(Vector3 size) {
  size_ = size;
}

VertexBuffer CuboidGeometry::GetVertexBuffer(Allocator& allocator) const {
  VertexBufferBuilder<GeometryVertexShader::PerVertexData, uint16_t> builder;
  // Layout: position, normal, tangent, uv
  builder.AddVertices({
      // Front.
      {Vector3(0, 0, 0), Vector3(0, 0, -1), Vector3(1, 0, 0), Point(0, 0),
       Color::White()},
      {Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(1, 0, 0), Point(1, 0),
       Color::White()},
      {Vector3(1, 1, 0), Vector3(0, 0, -1), Vector3(1, 0, 0), Point(1, 1),
       Color::White()},
      {Vector3(1, 1, 0), Vector3(0, 0, -1), Vector3(1, 0, 0), Point(1, 1),
       Color::White()},
      {Vector3(0, 1, 0), Vector3(0, 0, -1), Vector3(1, 0, 0), Point(0, 1),
       Color::White()},
      {Vector3(0, 0, 0), Vector3(0, 0, -1), Vector3(1, 0, 0), Point(0, 0),
       Color::White()},
  });
  return builder.CreateVertexBuffer(allocator);
}

//------------------------------------------------------------------------------
/// VertexBufferGeometry
///

VertexBufferGeometry::VertexBufferGeometry() = default;

VertexBufferGeometry::~VertexBufferGeometry() = default;

void VertexBufferGeometry::SetVertexBuffer(VertexBuffer vertex_buffer) {
  vertex_buffer_ = std::move(vertex_buffer);
}

VertexBuffer VertexBufferGeometry::GetVertexBuffer(Allocator& allocator) const {
  return vertex_buffer_;
}

}  // namespace scene
}  // namespace impeller
