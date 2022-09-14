// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "impeller/renderer/vertex_buffer_builder.h"
#include "impeller/tessellator/tessellator.h"

namespace impeller {

template <typename PerVertexData>
VertexBuffer CreateSolidFillVertices(const Path& path, HostBuffer& buffer) {
  VertexBufferBuilder<PerVertexData> vtx_builder;

  auto tesselation_result = Tessellator{}.Tessellate(
      path.GetFillType(), path.CreatePolyline(),
      [&vtx_builder](auto point) { vtx_builder.AppendVertex({point}); });
  if (tesselation_result != Tessellator::Result::kSuccess) {
    return {};
  }

  return vtx_builder.CreateVertexBuffer(buffer);
}

}  // namespace impeller
