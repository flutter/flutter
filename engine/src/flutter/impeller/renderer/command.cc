// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/command.h"

#include "impeller/base/validation.h"
#include "impeller/core/formats.h"

namespace impeller {

bool Command::BindVertices(const VertexBuffer& buffer) {
  if (buffer.index_type == IndexType::kUnknown) {
    VALIDATION_LOG << "Cannot bind vertex buffer with an unknown index type.";
    return false;
  }

  vertex_buffers = {buffer.vertex_buffer};
  vertex_buffer_count = 1u;
  element_count = buffer.vertex_count;
  index_buffer = buffer.index_buffer;
  index_type = buffer.index_type;
  return true;
}

}  // namespace impeller
