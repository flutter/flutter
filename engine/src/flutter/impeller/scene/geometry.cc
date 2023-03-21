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
#include "impeller/renderer/sampler_descriptor.h"
#include "impeller/renderer/sampler_library.h"
#include "impeller/renderer/vertex_buffer.h"
#include "impeller/renderer/vertex_buffer_builder.h"
#include "impeller/scene/importer/scene_flatbuffers.h"
#include "impeller/scene/shaders/skinned.vert.h"
#include "impeller/scene/shaders/unskinned.vert.h"

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

std::shared_ptr<Geometry> Geometry::MakeVertexBuffer(VertexBuffer vertex_buffer,
                                                     bool is_skinned) {
  if (is_skinned) {
    auto result = std::make_shared<SkinnedVertexBufferGeometry>();
    result->SetVertexBuffer(std::move(vertex_buffer));
    return result;
  } else {
    auto result = std::make_shared<UnskinnedVertexBufferGeometry>();
    result->SetVertexBuffer(std::move(vertex_buffer));
    return result;
  }
}

std::shared_ptr<Geometry> Geometry::MakeFromFlatbuffer(
    const fb::MeshPrimitive& mesh,
    Allocator& allocator) {
  IndexType index_type;
  switch (mesh.indices()->type()) {
    case fb::IndexType::k16Bit:
      index_type = IndexType::k16bit;
      break;
    case fb::IndexType::k32Bit:
      index_type = IndexType::k32bit;
      break;
  }

  const uint8_t* vertices_start;
  size_t vertices_bytes;
  bool is_skinned;

  switch (mesh.vertices_type()) {
    case fb::VertexBuffer::UnskinnedVertexBuffer: {
      const auto* vertices =
          mesh.vertices_as_UnskinnedVertexBuffer()->vertices();
      vertices_start = reinterpret_cast<const uint8_t*>(vertices->Get(0));
      vertices_bytes = vertices->size() * sizeof(fb::Vertex);
      is_skinned = false;
      break;
    }
    case fb::VertexBuffer::SkinnedVertexBuffer: {
      const auto* vertices = mesh.vertices_as_SkinnedVertexBuffer()->vertices();
      vertices_start = reinterpret_cast<const uint8_t*>(vertices->Get(0));
      vertices_bytes = vertices->size() * sizeof(fb::SkinnedVertex);
      is_skinned = true;
      break;
    }
    case fb::VertexBuffer::NONE:
      VALIDATION_LOG << "Invalid vertex buffer type.";
      return nullptr;
  }

  const uint8_t* indices_start =
      reinterpret_cast<const uint8_t*>(mesh.indices()->data()->Data());

  const size_t indices_bytes = mesh.indices()->data()->size();
  if (vertices_bytes == 0 || indices_bytes == 0) {
    return nullptr;
  }

  DeviceBufferDescriptor buffer_desc;
  buffer_desc.size = vertices_bytes + indices_bytes;
  buffer_desc.storage_mode = StorageMode::kHostVisible;

  auto buffer = allocator.CreateBuffer(buffer_desc);
  buffer->SetLabel("Mesh vertices+indices");

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
  return MakeVertexBuffer(std::move(vertex_buffer), is_skinned);
}

void Geometry::SetJointsTexture(const std::shared_ptr<Texture>& texture) {}

//------------------------------------------------------------------------------
/// CuboidGeometry
///

CuboidGeometry::CuboidGeometry() = default;

CuboidGeometry::~CuboidGeometry() = default;

void CuboidGeometry::SetSize(Vector3 size) {
  size_ = size;
}

// |Geometry|
GeometryType CuboidGeometry::GetGeometryType() const {
  return GeometryType::kUnskinned;
}

// |Geometry|
VertexBuffer CuboidGeometry::GetVertexBuffer(Allocator& allocator) const {
  VertexBufferBuilder<UnskinnedVertexShader::PerVertexData, uint16_t> builder;
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

// |Geometry|
void CuboidGeometry::BindToCommand(const SceneContext& scene_context,
                                   HostBuffer& buffer,
                                   const Matrix& transform,
                                   Command& command) const {
  command.BindVertices(
      GetVertexBuffer(*scene_context.GetContext()->GetResourceAllocator()));

  UnskinnedVertexShader::FrameInfo info;
  info.mvp = transform;
  UnskinnedVertexShader::BindFrameInfo(command, buffer.EmplaceUniform(info));
}

//------------------------------------------------------------------------------
/// UnskinnedVertexBufferGeometry
///

UnskinnedVertexBufferGeometry::UnskinnedVertexBufferGeometry() = default;

UnskinnedVertexBufferGeometry::~UnskinnedVertexBufferGeometry() = default;

void UnskinnedVertexBufferGeometry::SetVertexBuffer(
    VertexBuffer vertex_buffer) {
  vertex_buffer_ = std::move(vertex_buffer);
}

// |Geometry|
GeometryType UnskinnedVertexBufferGeometry::GetGeometryType() const {
  return GeometryType::kUnskinned;
}

// |Geometry|
VertexBuffer UnskinnedVertexBufferGeometry::GetVertexBuffer(
    Allocator& allocator) const {
  return vertex_buffer_;
}

// |Geometry|
void UnskinnedVertexBufferGeometry::BindToCommand(
    const SceneContext& scene_context,
    HostBuffer& buffer,
    const Matrix& transform,
    Command& command) const {
  command.BindVertices(
      GetVertexBuffer(*scene_context.GetContext()->GetResourceAllocator()));

  UnskinnedVertexShader::FrameInfo info;
  info.mvp = transform;
  UnskinnedVertexShader::BindFrameInfo(command, buffer.EmplaceUniform(info));
}

//------------------------------------------------------------------------------
/// SkinnedVertexBufferGeometry
///

SkinnedVertexBufferGeometry::SkinnedVertexBufferGeometry() = default;

SkinnedVertexBufferGeometry::~SkinnedVertexBufferGeometry() = default;

void SkinnedVertexBufferGeometry::SetVertexBuffer(VertexBuffer vertex_buffer) {
  vertex_buffer_ = std::move(vertex_buffer);
}

// |Geometry|
GeometryType SkinnedVertexBufferGeometry::GetGeometryType() const {
  return GeometryType::kSkinned;
}

// |Geometry|
VertexBuffer SkinnedVertexBufferGeometry::GetVertexBuffer(
    Allocator& allocator) const {
  return vertex_buffer_;
}

// |Geometry|
void SkinnedVertexBufferGeometry::BindToCommand(
    const SceneContext& scene_context,
    HostBuffer& buffer,
    const Matrix& transform,
    Command& command) const {
  command.BindVertices(
      GetVertexBuffer(*scene_context.GetContext()->GetResourceAllocator()));

  SamplerDescriptor sampler_desc;
  sampler_desc.min_filter = MinMagFilter::kNearest;
  sampler_desc.mag_filter = MinMagFilter::kNearest;
  sampler_desc.mip_filter = MipFilter::kNearest;
  sampler_desc.width_address_mode = SamplerAddressMode::kRepeat;
  sampler_desc.label = "NN Repeat";

  SkinnedVertexShader::BindJointsTexture(
      command,
      joints_texture_ ? joints_texture_ : scene_context.GetPlaceholderTexture(),
      scene_context.GetContext()->GetSamplerLibrary()->GetSampler(
          sampler_desc));

  SkinnedVertexShader::FrameInfo info;
  info.mvp = transform;
  info.enable_skinning = joints_texture_ ? 1 : 0;
  info.joint_texture_size =
      joints_texture_ ? joints_texture_->GetSize().width : 1;
  SkinnedVertexShader::BindFrameInfo(command, buffer.EmplaceUniform(info));
}

// |Geometry|
void SkinnedVertexBufferGeometry::SetJointsTexture(
    const std::shared_ptr<Texture>& texture) {
  joints_texture_ = texture;
}
}  // namespace scene
}  // namespace impeller
