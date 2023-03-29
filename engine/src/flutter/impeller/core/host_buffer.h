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
#include "impeller/core/buffer.h"
#include "impeller/core/buffer_view.h"
#include "impeller/core/platform.h"

namespace impeller {

class HostBuffer final : public std::enable_shared_from_this<HostBuffer>,
                         public Allocation,
                         public Buffer {
 public:
  static std::shared_ptr<HostBuffer> Create();

  // |Buffer|
  virtual ~HostBuffer();

  void SetLabel(std::string label);

  //----------------------------------------------------------------------------
  /// @brief      Emplace uniform data onto the host buffer. Ensure that backend
  ///             specific uniform alignment requirements are respected.
  ///
  /// @param[in]  uniform     The uniform struct to emplace onto the buffer.
  ///
  /// @tparam     UniformType The type of the uniform struct.
  ///
  /// @return     The buffer view.
  ///
  template <class UniformType,
            class = std::enable_if_t<std::is_standard_layout_v<UniformType>>>
  [[nodiscard]] BufferView EmplaceUniform(const UniformType& uniform) {
    const auto alignment =
        std::max(alignof(UniformType), DefaultUniformAlignment());
    return Emplace(reinterpret_cast<const void*>(&uniform),  // buffer
                   sizeof(UniformType),                      // size
                   alignment                                 // alignment
    );
  }

  //----------------------------------------------------------------------------
  /// @brief      Emplace storage buffer data onto the host buffer. Ensure that
  ///             backend specific uniform alignment requirements are respected.
  ///
  /// @param[in]  uniform     The storage buffer to emplace onto the buffer.
  ///
  /// @tparam     StorageBufferType The type of the shader storage buffer.
  ///
  /// @return     The buffer view.
  ///
  template <
      class StorageBufferType,
      class = std::enable_if_t<std::is_standard_layout_v<StorageBufferType>>>
  [[nodiscard]] BufferView EmplaceStorageBuffer(
      const StorageBufferType& buffer) {
    const auto alignment =
        std::max(alignof(StorageBufferType), DefaultUniformAlignment());
    return Emplace(&buffer,                    // buffer
                   sizeof(StorageBufferType),  // size
                   alignment                   // alignment
    );
  }

  //----------------------------------------------------------------------------
  /// @brief      Emplace non-uniform data (like contiguous vertices) onto the
  ///             host buffer.
  ///
  /// @param[in]  buffer        The buffer data.
  ///
  /// @tparam     BufferType    The type of the buffer data.
  ///
  /// @return     The buffer view.
  ///
  template <class BufferType,
            class = std::enable_if_t<std::is_standard_layout_v<BufferType>>>
  [[nodiscard]] BufferView Emplace(const BufferType& buffer) {
    return Emplace(reinterpret_cast<const void*>(&buffer),  // buffer
                   sizeof(BufferType),                      // size
                   alignof(BufferType)                      // alignment
    );
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
