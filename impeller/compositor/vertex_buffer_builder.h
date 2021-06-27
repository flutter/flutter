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

template <class VertexType_, class IndexType_ = uint32_t>
class VertexBufferBuilder {
 public:
  using VertexType = VertexType_;
  using IndexType = IndexType_;

  VertexBufferBuilder() = default;

  ~VertexBufferBuilder() = default;

  VertexBufferBuilder& AddVertices(
      std::initializer_list<VertexType_> vertices) {
    for (const auto& vertex : vertices) {
      vertices_.push_back(vertex);
    }
    return *this;
  }

  BufferView CreateVertexBuffer(HostBuffer& buffer) const {
    return buffer.Emplace(vertices_.data(),
                          vertices_.size() * sizeof(VertexType),
                          alignof(VertexType));
  }

  BufferView CreateIndexBuffer(HostBuffer& buffer) const {
    // So dumb! We don't actually need an index buffer right now. But we will
    // once de-duplication is done. So assume this is always done.
    std::vector<IndexType> index_buffer;
    for (size_t i = 0; i < vertices_.size(); i++) {
      index_buffer.push_back(i);
    }
    return buffer.Emplace(index_buffer.data(),
                          index_buffer.size() * sizeof(IndexType),
                          alignof(IndexType));
  }

  size_t GetIndexCount() const { return vertices_.size(); }

 private:
  // This is a placeholder till vertex de-duplication can be implemented. The
  // current implementation is a very dumb placeholder.
  std::vector<VertexType> vertices_;
};

}  // namespace impeller
