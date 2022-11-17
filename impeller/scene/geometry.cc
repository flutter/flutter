// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/scene/geometry.h"

#include <memory>

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

VertexBuffer CuboidGeometry::GetVertexBuffer(
    std::shared_ptr<Allocator>& allocator) const {
  return {};
}

}  // namespace scene
}  // namespace impeller
