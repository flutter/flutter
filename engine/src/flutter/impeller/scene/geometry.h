// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/macros.h"
#include "impeller/core/allocator.h"
#include "impeller/core/device_buffer.h"
#include "impeller/core/host_buffer.h"
#include "impeller/core/vertex_buffer.h"
#include "impeller/geometry/matrix.h"
#include "impeller/geometry/vector.h"
#include "impeller/renderer/command.h"
#include "impeller/scene/importer/scene_flatbuffers.h"
#include "impeller/scene/pipeline_key.h"
#include "impeller/scene/scene_context.h"

namespace impeller {
namespace scene {

class CuboidGeometry;
class UnskinnedVertexBufferGeometry;

class Geometry {
 public:
  virtual ~Geometry();

  static std::shared_ptr<CuboidGeometry> MakeCuboid(Vector3 size);

  static std::shared_ptr<Geometry> MakeVertexBuffer(VertexBuffer vertex_buffer,
                                                    bool is_skinned);

  static std::shared_ptr<Geometry> MakeFromFlatbuffer(
      const fb::MeshPrimitive& mesh,
      Allocator& allocator);

  virtual GeometryType GetGeometryType() const = 0;

  virtual VertexBuffer GetVertexBuffer(Allocator& allocator) const = 0;

  virtual void BindToCommand(const SceneContext& scene_context,
                             HostBuffer& buffer,
                             const Matrix& transform,
                             Command& command) const = 0;

  virtual void SetJointsTexture(const std::shared_ptr<Texture>& texture);
};

class CuboidGeometry final : public Geometry {
 public:
  CuboidGeometry();

  ~CuboidGeometry() override;

  void SetSize(Vector3 size);

  // |Geometry|
  GeometryType GetGeometryType() const override;

  // |Geometry|
  VertexBuffer GetVertexBuffer(Allocator& allocator) const override;

  // |Geometry|
  void BindToCommand(const SceneContext& scene_context,
                     HostBuffer& buffer,
                     const Matrix& transform,
                     Command& command) const override;

 private:
  Vector3 size_;

  FML_DISALLOW_COPY_AND_ASSIGN(CuboidGeometry);
};

class UnskinnedVertexBufferGeometry final : public Geometry {
 public:
  UnskinnedVertexBufferGeometry();

  ~UnskinnedVertexBufferGeometry() override;

  void SetVertexBuffer(VertexBuffer vertex_buffer);

  // |Geometry|
  GeometryType GetGeometryType() const override;

  // |Geometry|
  VertexBuffer GetVertexBuffer(Allocator& allocator) const override;

  // |Geometry|
  void BindToCommand(const SceneContext& scene_context,
                     HostBuffer& buffer,
                     const Matrix& transform,
                     Command& command) const override;

 private:
  VertexBuffer vertex_buffer_;

  FML_DISALLOW_COPY_AND_ASSIGN(UnskinnedVertexBufferGeometry);
};

class SkinnedVertexBufferGeometry final : public Geometry {
 public:
  SkinnedVertexBufferGeometry();

  ~SkinnedVertexBufferGeometry() override;

  void SetVertexBuffer(VertexBuffer vertex_buffer);

  // |Geometry|
  GeometryType GetGeometryType() const override;

  // |Geometry|
  VertexBuffer GetVertexBuffer(Allocator& allocator) const override;

  // |Geometry|
  void BindToCommand(const SceneContext& scene_context,
                     HostBuffer& buffer,
                     const Matrix& transform,
                     Command& command) const override;

  // |Geometry|
  void SetJointsTexture(const std::shared_ptr<Texture>& texture) override;

 private:
  VertexBuffer vertex_buffer_;
  std::shared_ptr<Texture> joints_texture_;

  FML_DISALLOW_COPY_AND_ASSIGN(SkinnedVertexBufferGeometry);
};

}  // namespace scene
}  // namespace impeller
