// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "impeller/renderer/buffer_view.h"

namespace impeller {

struct VertexBuffer {
  BufferView vertex_buffer;
  BufferView index_buffer;
  size_t index_count = 0u;

  constexpr operator bool() const {
    return static_cast<bool>(vertex_buffer) && static_cast<bool>(index_buffer);
  }
};

}  // namespace impeller
