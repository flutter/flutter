// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <Metal/Metal.h>

#include "flutter/fml/macros.h"
#include "impeller/renderer/allocator.h"

namespace impeller {

class AllocatorMTL final : public Allocator {
 public:
  AllocatorMTL();

  // |Allocator|
  ~AllocatorMTL() override;

 private:
  friend class ContextMTL;

  // In the prototype, we are going to be allocating resources directly with the
  // MTLDevice APIs. But, in the future, this could be backed by named heaps
  // with specific limits.
  id<MTLDevice> device_;
  std::string allocator_label_;
  bool is_valid_ = false;

  AllocatorMTL(id<MTLDevice> device, std::string label);

  // |Allocator|
  bool IsValid() const;

  // |Allocator|
  std::shared_ptr<DeviceBuffer> CreateBuffer(StorageMode mode,
                                             size_t length) override;

  // |Allocator|
  std::shared_ptr<Texture> CreateTexture(
      StorageMode mode,
      const TextureDescriptor& desc) override;

  FML_DISALLOW_COPY_AND_ASSIGN(AllocatorMTL);
};

}  // namespace impeller
