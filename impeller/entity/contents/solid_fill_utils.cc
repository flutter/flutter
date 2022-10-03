// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/solid_fill_utils.h"

#include "impeller/geometry/path.h"
#include "impeller/renderer/device_buffer.h"
#include "impeller/renderer/host_buffer.h"
#include "impeller/tessellator/tessellator.h"

namespace impeller {

VertexBuffer CreateSolidFillVertices(std::shared_ptr<Tessellator> tessellator,
                                     const Path& path,
                                     HostBuffer& buffer) {
  VertexBuffer vertex_buffer;
  auto tesselation_result = tessellator->TessellateBuilder(
      path.GetFillType(), path.CreatePolyline(),
      [&vertex_buffer, &buffer](const float* vertices, size_t vertices_count,
                                const uint16_t* indices, size_t indices_count) {
        vertex_buffer.vertex_buffer = buffer.Emplace(
            vertices, vertices_count * sizeof(float), alignof(float));
        vertex_buffer.index_buffer = buffer.Emplace(
            indices, indices_count * sizeof(uint16_t), alignof(uint16_t));
        vertex_buffer.index_count = indices_count;
        vertex_buffer.index_type = IndexType::k16bit;
        return true;
      });
  if (tesselation_result != Tessellator::Result::kSuccess) {
    return {};
  }
  return vertex_buffer;
}

}  // namespace impeller
