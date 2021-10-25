// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>
#include <string>

#include "flutter/fml/macros.h"
#include "impeller/renderer/allocator.h"
#include "impeller/renderer/buffer.h"
#include "impeller/renderer/buffer_view.h"
#include "impeller/renderer/range.h"
#include "impeller/renderer/texture.h"

namespace impeller {

class DeviceBuffer : public Buffer,
                     public std::enable_shared_from_this<DeviceBuffer> {
 public:
  virtual ~DeviceBuffer();

  [[nodiscard]] virtual bool CopyHostBuffer(const uint8_t* source,
                                            Range source_range,
                                            size_t offset = 0u) = 0;

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
  virtual std::shared_ptr<Texture> MakeTexture(TextureDescriptor desc,
                                               size_t offset = 0u) const = 0;

  virtual bool SetLabel(const std::string& label) = 0;

  virtual bool SetLabel(const std::string& label, Range range) = 0;

  virtual BufferView AsBufferView() const = 0;

 protected:
  DeviceBuffer();

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(DeviceBuffer);
};

}  // namespace impeller
