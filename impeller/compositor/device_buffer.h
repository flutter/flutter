// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <Metal/Metal.h>

#include <memory>
#include <string>

#include "flutter/fml/macros.h"
#include "impeller/compositor/allocator.h"
#include "impeller/compositor/buffer.h"
#include "impeller/compositor/buffer_view.h"
#include "impeller/compositor/range.h"
#include "impeller/compositor/texture.h"

namespace impeller {

class DeviceBuffer final : public Buffer,
                           public std::enable_shared_from_this<DeviceBuffer> {
 public:
  ~DeviceBuffer();

  [[nodiscard]] bool CopyHostBuffer(const uint8_t* source,
                                    Range source_range,
                                    size_t offset = 0u);

  //----------------------------------------------------------------------------
  /// @brief      Create a texture whose contents are the same as that of this
  ///             buffer. Changes to either the contents of the texture or the
  ///             buffer will be shared. When using buffer backed textures,
  ///             implementations may have to disable certain optimizations.
  ///
  /// @param[in]  desc    The description of the texture.
  /// @param[in]  offset  The offset of the texture data within buffer.
  ///
  /// @return     The texture whose contents are backed by (a part of) this
  ///             buffer.
  ///
  std::shared_ptr<Texture> MakeTexture(TextureDescriptor desc,
                                       size_t offset = 0u) const;

  id<MTLBuffer> GetMTLBuffer() const;

  bool SetLabel(const std::string& label);

  bool SetLabel(const std::string& label, Range range);

  BufferView AsBufferView() const;

 private:
  friend class Allocator;

  const id<MTLBuffer> buffer_;
  const size_t size_;
  const StorageMode mode_;

  DeviceBuffer(id<MTLBuffer> buffer, size_t size, StorageMode mode);

  // |Buffer|
  std::shared_ptr<const DeviceBuffer> GetDeviceBuffer(
      Allocator& allocator) const override;

  FML_DISALLOW_COPY_AND_ASSIGN(DeviceBuffer);
};

}  // namespace impeller
