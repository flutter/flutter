// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "impeller/core/buffer_view.h"
#include "impeller/core/formats.h"

namespace impeller {

struct VertexBuffer {
  BufferView vertex_buffer;
  BufferView index_buffer;
  // The total count of vertices, either in the vertex_buffer if the
  // index_type is IndexType::kNone or in the index_buffer otherwise.
  size_t vertex_count = 0u;
  IndexType index_type = IndexType::kUnknown;

  constexpr operator bool() const {
    return static_cast<bool>(vertex_buffer) &&
           (index_type == IndexType::kNone || static_cast<bool>(index_buffer));
  }
};

}  // namespace impeller
