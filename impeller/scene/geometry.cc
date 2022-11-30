// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/scene/geometry.h"

#include <memory>

#include "impeller/geometry/point.h"
#include "impeller/geometry/vector.h"
#include "impeller/renderer/formats.h"
#include "impeller/renderer/vertex_buffer_builder.h"
#include "impeller/scene/shaders/geometry.vert.h"

namespace impeller {
namespace scene {

//------------------------------------------------------------------------------
/// Geometry
///

std::shared_ptr<CuboidGeometry> Geometry::MakeCuboid(Vector3 size) {
  auto result = std::make_shared<CuboidGeometry>();
  result->SetSize(size);
  return result;
}

//------------------------------------------------------------------------------
/// CuboidGeometry
///

void CuboidGeometry::SetSize(Vector3 size) {
  size_ = size;
}

VertexBuffer CuboidGeometry::GetVertexBuffer(Allocator& allocator) const {
  VertexBufferBuilder<GeometryVertexShader::PerVertexData, uint16_t> builder;
  // Layout: position, normal, tangent, uv
  builder.AddVertices({
      // Front.
      {Vector3(0, 0, 0), Vector3(0, 0, -1), Vector3(1, 0, 0), Point(0, 0)},
      {Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(1, 0, 0), Point(1, 0)},
      {Vector3(1, 1, 0), Vector3(0, 0, -1), Vector3(1, 0, 0), Point(1, 1)},
      {Vector3(1, 1, 0), Vector3(0, 0, -1), Vector3(1, 0, 0), Point(1, 1)},
      {Vector3(0, 1, 0), Vector3(0, 0, -1), Vector3(1, 0, 0), Point(0, 1)},
      {Vector3(0, 0, 0), Vector3(0, 0, -1), Vector3(1, 0, 0), Point(0, 0)},
  });
  return builder.CreateVertexBuffer(allocator);
}

}  // namespace scene
}  // namespace impeller
