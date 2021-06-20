// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <algorithm>
#include <memory>
#include <type_traits>

#include "flutter/fml/macros.h"
#include "impeller/compositor/buffer.h"
#include "impeller/compositor/buffer_view.h"

namespace impeller {

class HostBuffer final : public std::enable_shared_from_this<HostBuffer>,
                         public Buffer {
 public:
  // |Buffer|
  virtual ~HostBuffer();

  static std::shared_ptr<HostBuffer> Create();

  size_t GetLength() const;

  size_t GetReservedLength() const;

  template <class T, class = std::enable_if_t<std::is_standard_layout_v<T>>>
  [[nodiscard]] BufferView Emplace(const T& t) {
    return Emplace(reinterpret_cast<const void*>(&t), sizeof(T), alignof(T));
  }

  [[nodiscard]] BufferView Emplace(const void* buffer,
                                   size_t length,
                                   size_t align);

  [[nodiscard]] bool Truncate(size_t length);

 private:
  mutable std::shared_ptr<DeviceBuffer> device_buffer_;
  mutable size_t device_buffer_generation_ = 0u;
  uint8_t* buffer_ = nullptr;
  size_t length_ = 0;
  size_t reserved_ = 0;
  size_t generation_ = 1u;

  // |Buffer|
  std::shared_ptr<const DeviceBuffer> GetDeviceBuffer(
      Allocator& allocator) const override;

  [[nodiscard]] BufferView Emplace(const void* buffer, size_t length);

  [[nodiscard]] bool Reserve(size_t reserved);

  [[nodiscard]] bool ReserveNPOT(size_t reserved);

  HostBuffer();

  FML_DISALLOW_COPY_AND_ASSIGN(HostBuffer);
};

}  // namespace impeller
