// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/compositor/vertex_buffer.h"

namespace impeller {

VertexBufferBuilder::VertexBufferBuilder() = default;

VertexBufferBuilder::~VertexBufferBuilder() = default;

size_t VertexBufferBuilder::GetIndexCount() const {
  return vertices_.size();
}

VertexBufferBuilder& VertexBufferBuilder::AddVertices(
    std::initializer_list<Vector3> vertices) {
  for (const auto& vertex : vertices) {
    vertices_.push_back(vertex);
  }
  return *this;
}

BufferView VertexBufferBuilder::CreateVertexBuffer(HostBuffer& buffer) const {
  return buffer.Emplace(
      vertices_.data(),
      vertices_.size() * sizeof(decltype(vertices_)::value_type),
      alignof(decltype(vertices_)::value_type));
}

BufferView VertexBufferBuilder::CreateIndexBuffer(HostBuffer& buffer) const {
  // Soooo dumb! We don't actually need an index buffer right now. But we will
  // once de-duplication is done.
  std::vector<uint32_t> index_buffer;
  for (size_t i = 0; i < vertices_.size(); i++) {
    index_buffer.push_back(i);
  }
  return buffer.Emplace(
      index_buffer.data(),
      index_buffer.size() * sizeof(decltype(index_buffer)::value_type),
      alignof(decltype(index_buffer)::value_type));
}

}  // namespace impeller
