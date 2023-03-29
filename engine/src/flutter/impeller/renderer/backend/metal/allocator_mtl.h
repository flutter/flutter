// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <Metal/Metal.h>

#include "flutter/fml/macros.h"
#include "impeller/core/allocator.h"

namespace impeller {

class AllocatorMTL final : public Allocator {
 public:
  AllocatorMTL();

  // |Allocator|
  ~AllocatorMTL() override;

 private:
  friend class ContextMTL;

  id<MTLDevice> device_;
  std::string allocator_label_;
  bool supports_memoryless_targets_ = false;
  bool supports_uma_ = false;
  bool is_valid_ = false;
  ISize max_texture_supported_;

  AllocatorMTL(id<MTLDevice> device, std::string label);

  // |Allocator|
  bool IsValid() const;

  // |Allocator|
  std::shared_ptr<DeviceBuffer> OnCreateBuffer(
      const DeviceBufferDescriptor& desc) override;

  // |Allocator|
  std::shared_ptr<Texture> OnCreateTexture(
      const TextureDescriptor& desc) override;

  // |Allocator|
  uint16_t MinimumBytesPerRow(PixelFormat format) const override;

  // |Allocator|
  ISize GetMaxTextureSizeSupported() const override;

  FML_DISALLOW_COPY_AND_ASSIGN(AllocatorMTL);
};

}  // namespace impeller
