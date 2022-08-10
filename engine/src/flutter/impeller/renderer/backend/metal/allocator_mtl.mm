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

static bool DeviceSupportsMemorylessTargets(id<MTLDevice> device) {
  // Refer to the "Memoryless render targets" feature in the table below:
  // https://developer.apple.com/metal/Metal-Feature-Set-Tables.pdf
  if (@available(ios 13.0, tvos 13.0, macos 10.15, *)) {
    return [device supportsFamily:MTLGPUFamilyApple2];
  } else {
#if FML_OS_IOS
    // This is perhaps redundant. But, just in case we somehow get into a case
    // where Impeller runs on iOS versions less than 8.0 and/or without A8
    // GPUs, we explicitly check feature set support.
    return [device supportsFeatureSet:MTLFeatureSet_iOS_GPUFamily2_v1];
#else
    // MacOS devices with Apple GPUs are only available with macos 10.15 and
    // above. So, if we are here, it is safe to assume that memory-less targets
    // are not supported.
    return false;
#endif
  }
  FML_UNREACHABLE();
}

static bool DeviceHasUnifiedMemoryArchitecture(id<MTLDevice> device) {
  if (@available(ios 13.0, tvos 13.0, macOS 10.15, *)) {
    return [device hasUnifiedMemory];
  } else {
#if FML_OS_IOS
    // iOS devices where the availability check can fail always have had UMA.
    return true;
#else
    // Mac devices where the availability check can fail have never had UMA.
    return false;
#endif
  }
  FML_UNREACHABLE();
}

AllocatorMTL::AllocatorMTL(id<MTLDevice> device, std::string label)
    : device_(device), allocator_label_(std::move(label)) {
  if (!device_) {
    return;
  }

  supports_memoryless_targets_ = DeviceSupportsMemorylessTargets(device_);
  supports_uma_ = DeviceHasUnifiedMemoryArchitecture(device_);

  is_valid_ = true;
}

AllocatorMTL::~AllocatorMTL() = default;

bool AllocatorMTL::IsValid() const {
  return is_valid_;
}

static MTLResourceOptions ToMTLResourceOptions(StorageMode type,
                                               bool supports_memoryless_targets,
                                               bool supports_uma) {
  switch (type) {
    case StorageMode::kHostVisible:
#if FML_OS_IOS
      return MTLResourceStorageModeShared;
#else
      if (supports_uma) {
        return MTLResourceStorageModeShared;
      } else {
        return MTLResourceStorageModeManaged;
      }
#endif
    case StorageMode::kDevicePrivate:
      return MTLResourceStorageModePrivate;
    case StorageMode::kDeviceTransient:
      if (supports_memoryless_targets) {
        // Device may support but the OS has not been updated.
        if (@available(macOS 11.0, *)) {
          return MTLResourceStorageModeMemoryless;
        } else {
          return MTLResourceStorageModePrivate;
        }
      } else {
        return MTLResourceStorageModePrivate;
      }
      FML_UNREACHABLE();
  }
  FML_UNREACHABLE();
}

static MTLStorageMode ToMTLStorageMode(StorageMode mode,
                                       bool supports_memoryless_targets,
                                       bool supports_uma) {
  switch (mode) {
    case StorageMode::kHostVisible:
#if FML_OS_IOS
      return MTLStorageModeShared;
#else
      if (supports_uma) {
        return MTLStorageModeShared;
      } else {
        return MTLStorageModeManaged;
      }
#endif
    case StorageMode::kDevicePrivate:
      return MTLStorageModePrivate;
    case StorageMode::kDeviceTransient:
      if (supports_memoryless_targets) {
        // Device may support but the OS has not been updated.
        if (@available(macOS 11.0, *)) {
          return MTLStorageModeMemoryless;
        } else {
          return MTLStorageModePrivate;
        }
      } else {
        return MTLStorageModePrivate;
      }
      FML_UNREACHABLE();
  }
  FML_UNREACHABLE();
}

std::shared_ptr<DeviceBuffer> AllocatorMTL::CreateBuffer(StorageMode mode,
                                                         size_t length) {
  const auto resource_options =
      ToMTLResourceOptions(mode, supports_memoryless_targets_, supports_uma_);
  const auto storage_mode =
      ToMTLStorageMode(mode, supports_memoryless_targets_, supports_uma_);

  auto buffer = [device_ newBufferWithLength:length options:resource_options];
  if (!buffer) {
    return nullptr;
  }
  return std::shared_ptr<DeviceBufferMTL>(new DeviceBufferMTL(buffer,       //
                                                              length,       //
                                                              mode,         //
                                                              storage_mode  //
                                                              ));
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

  mtl_texture_desc.storageMode =
      ToMTLStorageMode(mode, supports_memoryless_targets_, supports_uma_);
  auto texture = [device_ newTextureWithDescriptor:mtl_texture_desc];
  if (!texture) {
    return nullptr;
  }
  return std::make_shared<TextureMTL>(desc, texture);
}

}  // namespace impeller
