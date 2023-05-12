// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <initializer_list>
#include <map>
#include <vector>

#include "flutter/fml/macros.h"
#include "impeller/base/strings.h"
#include "impeller/core/allocator.h"
#include "impeller/core/device_buffer.h"
#include "impeller/core/formats.h"
#include "impeller/core/host_buffer.h"
#include "impeller/core/vertex_buffer.h"
#include "impeller/geometry/vector.h"

namespace impeller {

template <class VertexType_, class IndexType_ = uint16_t>
class VertexBufferBuilder {
 public:
  using VertexType = VertexType_;
  using IndexType = IndexType_;

  VertexBufferBuilder() = default;

  ~VertexBufferBuilder() = default;

  constexpr impeller::IndexType GetIndexType() const {
    if (indices_.size() == 0) {
      return impeller::IndexType::kNone;
    }
    if constexpr (sizeof(IndexType) == 2) {
      return impeller::IndexType::k16bit;
    }
    if (sizeof(IndexType) == 4) {
      return impeller::IndexType::k32bit;
    }
    return impeller::IndexType::kUnknown;
  }

  void SetLabel(std::string label) { label_ = std::move(label); }

  void Reserve(size_t count) { return vertices_.reserve(count); }

  void ReserveIndices(size_t count) { return indices_.reserve(count); }

  bool HasVertices() const { return !vertices_.empty(); }

  size_t GetVertexCount() const { return vertices_.size(); }

  size_t GetIndexCount() const {
    return indices_.size() > 0 ? indices_.size() : vertices_.size();
  }

  VertexBufferBuilder& AppendVertex(VertexType_ vertex) {
    vertices_.emplace_back(std::move(vertex));
    return *this;
  }

  VertexBufferBuilder& AddVertices(
      std::initializer_list<VertexType_> vertices) {
    vertices_.reserve(vertices.size());
    for (auto& vertex : vertices) {
      vertices_.emplace_back(std::move(vertex));
    }
    return *this;
  }

  VertexBufferBuilder& AppendIndex(IndexType_ index) {
    indices_.emplace_back(index);
    return *this;
  }

  VertexBuffer CreateVertexBuffer(HostBuffer& host_buffer) const {
    VertexBuffer buffer;
    buffer.vertex_buffer = CreateVertexBufferView(host_buffer);
    buffer.index_buffer = CreateIndexBufferView(host_buffer);
    buffer.vertex_count = GetIndexCount();
    buffer.index_type = GetIndexType();
    return buffer;
  };

  VertexBuffer CreateVertexBuffer(Allocator& device_allocator) const {
    VertexBuffer buffer;
    // This can be merged into a single allocation.
    buffer.vertex_buffer = CreateVertexBufferView(device_allocator);
    buffer.index_buffer = CreateIndexBufferView(device_allocator);
    buffer.vertex_count = GetIndexCount();
    buffer.index_type = GetIndexType();
    return buffer;
  };

  void IterateVertices(const std::function<void(VertexType&)>& iterator) {
    for (auto& vertex : vertices_) {
      iterator(vertex);
    }
  }

 private:
  std::vector<VertexType> vertices_;
  std::vector<IndexType> indices_;
  std::string label_;

  BufferView CreateVertexBufferView(HostBuffer& buffer) const {
    return buffer.Emplace(vertices_.data(),
                          vertices_.size() * sizeof(VertexType),
                          alignof(VertexType));
  }

  BufferView CreateVertexBufferView(Allocator& allocator) const {
    auto buffer = allocator.CreateBufferWithCopy(
        reinterpret_cast<const uint8_t*>(vertices_.data()),
        vertices_.size() * sizeof(VertexType));
    if (!buffer) {
      return {};
    }
    if (!label_.empty()) {
      buffer->SetLabel(SPrintF("%s Vertices", label_.c_str()));
    }
    return buffer->AsBufferView();
  }

  std::vector<IndexType> CreateIndexBuffer() const { return indices_; }

  BufferView CreateIndexBufferView(HostBuffer& buffer) const {
    const auto index_buffer = CreateIndexBuffer();
    if (index_buffer.size() == 0) {
      return {};
    }
    return buffer.Emplace(index_buffer.data(),
                          index_buffer.size() * sizeof(IndexType),
                          alignof(IndexType));
  }

  BufferView CreateIndexBufferView(Allocator& allocator) const {
    const auto index_buffer = CreateIndexBuffer();
    if (index_buffer.size() == 0) {
      return {};
    }
    auto buffer = allocator.CreateBufferWithCopy(
        reinterpret_cast<const uint8_t*>(index_buffer.data()),
        index_buffer.size() * sizeof(IndexType));
    if (!buffer) {
      return {};
    }
    if (!label_.empty()) {
      buffer->SetLabel(SPrintF("%s Indices", label_.c_str()));
    }
    return buffer->AsBufferView();
  }
};

}  // namespace impeller
