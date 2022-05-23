// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/gles/allocator_gles.h"

#include <memory>

#include "impeller/base/allocation.h"
#include "impeller/base/config.h"
#include "impeller/renderer/backend/gles/device_buffer_gles.h"
#include "impeller/renderer/backend/gles/texture_gles.h"

namespace impeller {

AllocatorGLES::AllocatorGLES(ReactorGLES::Ref reactor)
    : reactor_(std::move(reactor)), is_valid_(true) {}

// |Allocator|
AllocatorGLES::~AllocatorGLES() = default;

// |Allocator|
bool AllocatorGLES::IsValid() const {
  return is_valid_;
}

// |Allocator|
std::shared_ptr<DeviceBuffer> AllocatorGLES::CreateBuffer(StorageMode mode,
                                                          size_t length) {
  auto backing_store = std::make_shared<Allocation>();
  if (!backing_store->Truncate(length)) {
    return nullptr;
  }
  return std::make_shared<DeviceBufferGLES>(reactor_, std::move(backing_store),
                                            length, mode);
}

// |Allocator|
std::shared_ptr<Texture> AllocatorGLES::CreateTexture(
    StorageMode mode,
    const TextureDescriptor& desc) {
  return std::make_shared<TextureGLES>(reactor_, std::move(desc));
}

}  // namespace impeller
