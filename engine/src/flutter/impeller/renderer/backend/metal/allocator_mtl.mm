// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/metal/allocator_mtl.h"

#include "flutter/fml/build_config.h"
#include "flutter/fml/logging.h"
#include "impeller/base/validation.h"
#include "impeller/renderer/backend/metal/device_buffer_mtl.h"
#include "impeller/renderer/backend/metal/formats_mtl.h"
#include "impeller/renderer/backend/metal/texture_mtl.h"
#include "impeller/renderer/buffer.h"

namespace impeller {

AllocatorMTL::AllocatorMTL(id<MTLDevice> device, std::string label)
    : device_(device), allocator_label_(std::move(label)) {
  if (!device_) {
    return;
  }

  is_valid_ = true;
}

AllocatorMTL::~AllocatorMTL() = default;

bool AllocatorMTL::IsValid() const {
  return is_valid_;
}

static MTLResourceOptions ToMTLResourceOptions(StorageMode type) {
  switch (type) {
    case StorageMode::kHostVisible:
#if FML_OS_IOS
      return MTLResourceStorageModeShared;
#else
      return MTLResourceStorageModeManaged;
#endif
    case StorageMode::kDevicePrivate:
      return MTLResourceStorageModePrivate;
    case StorageMode::kDeviceTransient:
#if FML_OS_IOS
      if (@available(iOS 10.0, *)) {
        return MTLResourceStorageModeMemoryless;
      } else {
        return MTLResourceStorageModePrivate;
      }
#else
      return MTLResourceStorageModePrivate;
#endif
  }

  return MTLResourceStorageModePrivate;
}

static MTLStorageMode ToMTLStorageMode(StorageMode mode) {
  switch (mode) {
    case StorageMode::kHostVisible:
#if FML_OS_IOS
      return MTLStorageModeShared;
#else
      return MTLStorageModeManaged;
#endif
    case StorageMode::kDevicePrivate:
      return MTLStorageModePrivate;
    case StorageMode::kDeviceTransient:
#if FML_OS_IOS
      if (@available(iOS 10.0, *)) {
        return MTLStorageModeMemoryless;
      } else {
        return MTLStorageModePrivate;
      }
#else
      return MTLStorageModePrivate;
#endif
  }
  return MTLStorageModeShared;
}

std::shared_ptr<DeviceBuffer> AllocatorMTL::CreateBuffer(StorageMode mode,
                                                         size_t length) {
  auto buffer = [device_ newBufferWithLength:length
                                     options:ToMTLResourceOptions(mode)];
  if (!buffer) {
    return nullptr;
  }
  return std::shared_ptr<DeviceBufferMTL>(
      new DeviceBufferMTL(buffer, length, mode));
}

std::shared_ptr<Texture> AllocatorMTL::CreateTexture(
    StorageMode mode,
    const TextureDescriptor& desc) {
  if (!IsValid()) {
    return nullptr;
  }

  auto mtl_texture_desc = ToMTLTextureDescriptor(desc);

  if (!mtl_texture_desc) {
    VALIDATION_LOG << "Texture descriptor was invalid.";
    return nullptr;
  }

  mtl_texture_desc.storageMode = ToMTLStorageMode(mode);
  auto texture = [device_ newTextureWithDescriptor:mtl_texture_desc];
  if (!texture) {
    return nullptr;
  }
  return std::make_shared<TextureMTL>(desc, texture);
}

}  // namespace impeller
