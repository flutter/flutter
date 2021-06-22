// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <initializer_list>
#include <map>
#include <vector>

#include "flutter/fml/macros.h"
#include "impeller/compositor/host_buffer.h"
#include "impeller/geometry/vector.h"

namespace impeller {

class VertexBufferBuilder {
 public:
  VertexBufferBuilder();

  ~VertexBufferBuilder();

  VertexBufferBuilder& AddVertices(std::initializer_list<Vector3> vertices);

  BufferView CreateVertexBuffer(HostBuffer& buffer) const;

  BufferView CreateIndexBuffer(HostBuffer& buffer) const;

  size_t GetIndexCount() const;

 private:
  // This is a placeholder till vertex de-duplication can be implemented. The
  // current implementation is a very dumb placeholder.
  std::vector<Vector3> vertices_;

  FML_DISALLOW_COPY_AND_ASSIGN(VertexBufferBuilder);
};

}  // namespace impeller
