// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <algorithm>
#include <memory>
#include <string>
#include <type_traits>

#include "flutter/fml/macros.h"
#include "impeller/base/allocation.h"
#include "impeller/compositor/buffer.h"
#include "impeller/compositor/buffer_view.h"
#include "impeller/compositor/platform.h"

namespace impeller {

class HostBuffer final : public std::enable_shared_from_this<HostBuffer>,
                         public Allocation,
                         public Buffer {
 public:
  static std::shared_ptr<HostBuffer> Create();

  // |Buffer|
  virtual ~HostBuffer();

  void SetLabel(std::string label);

  template <class T, class = std::enable_if_t<std::is_standard_layout_v<T>>>
  [[nodiscard]] BufferView EmplaceUniform(const T& t) {
    return Emplace(reinterpret_cast<const void*>(&t), sizeof(T),
                   std::max(alignof(T), DefaultUniformAlignment()));
  }

  template <class T, class = std::enable_if_t<std::is_standard_layout_v<T>>>
  [[nodiscard]] BufferView Emplace(const T& t) {
    return Emplace(reinterpret_cast<const void*>(&t), sizeof(T), alignof(T));
  }

  [[nodiscard]] BufferView Emplace(const void* buffer,
                                   size_t length,
                                   size_t align);

 private:
  mutable std::shared_ptr<DeviceBuffer> device_buffer_;
  mutable size_t device_buffer_generation_ = 0u;
  size_t generation_ = 1u;
  std::string label_;

  // |Buffer|
  std::shared_ptr<const DeviceBuffer> GetDeviceBuffer(
      Allocator& allocator) const override;

  [[nodiscard]] BufferView Emplace(const void* buffer, size_t length);

  HostBuffer();

  FML_DISALLOW_COPY_AND_ASSIGN(HostBuffer);
};

}  // namespace impeller
