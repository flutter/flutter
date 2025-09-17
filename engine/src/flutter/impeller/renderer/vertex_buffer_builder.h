// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_VERTEX_BUFFER_BUILDER_H_
#define FLUTTER_IMPELLER_RENDERER_VERTEX_BUFFER_BUILDER_H_

#include <format>
#include <initializer_list>
#include <memory>
#include <type_traits>
#include <vector>

#include "impeller/core/allocator.h"
#include "impeller/core/device_buffer.h"
#include "impeller/core/formats.h"
#include "impeller/core/host_buffer.h"
#include "impeller/core/vertex_buffer.h"

namespace impeller {

/// @brief Create an index-less vertex buffer from a fixed size array.
template <class VertexType, size_t size>
VertexBuffer CreateVertexBuffer(std::array<VertexType, size> input,
                                HostBuffer& data_host_buffer) {
  return VertexBuffer{
      .vertex_buffer = data_host_buffer.Emplace(
          input.data(), sizeof(VertexType) * size, alignof(VertexType)),
      .vertex_count = size,
      .index_type = IndexType::kNone,
  };
}

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

  void SetLabel(const std::string& label) { label_ = label; }

  void Reserve(size_t count) { return vertices_.reserve(count); }

  void ReserveIndices(size_t count) { return indices_.reserve(count); }

  bool HasVertices() const { return !vertices_.empty(); }

  size_t GetVertexCount() const { return vertices_.size(); }

  size_t GetIndexCount() const {
    return indices_.size() > 0 ? indices_.size() : vertices_.size();
  }

  const VertexType& Last() const {
    FML_DCHECK(!vertices_.empty());
    return vertices_.back();
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

  VertexBuffer CreateVertexBuffer(HostBuffer& data_host_buffer,
                                  HostBuffer& indexes_host_buffer) const {
    VertexBuffer buffer;
    buffer.vertex_buffer = CreateVertexBufferView(data_host_buffer);
    buffer.index_buffer = CreateIndexBufferView(indexes_host_buffer);
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

  BufferView CreateVertexBufferView(HostBuffer& data_host_buffer) const {
    return data_host_buffer.Emplace(vertices_.data(),
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
      buffer->SetLabel(std::format("{} Vertices", label_));
    }
    return DeviceBuffer::AsBufferView(std::move(buffer));
  }

  std::vector<IndexType> CreateIndexBuffer() const { return indices_; }

  BufferView CreateIndexBufferView(HostBuffer& indexes_host_buffer) const {
    const auto index_buffer = CreateIndexBuffer();
    if (index_buffer.size() == 0) {
      return {};
    }
    return indexes_host_buffer.Emplace(index_buffer.data(),
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
      buffer->SetLabel(std::format("{} Indices", label_));
    }
    return DeviceBuffer::AsBufferView(std::move(buffer));
  }
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_VERTEX_BUFFER_BUILDER_H_
