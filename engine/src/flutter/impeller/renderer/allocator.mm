// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/allocator.h"

#include "flutter/fml/build_config.h"
#include "flutter/fml/logging.h"
#include "impeller/renderer/buffer.h"
#include "impeller/renderer/device_buffer.h"
#include "impeller/renderer/formats_metal.h"

namespace impeller {

Allocator::Allocator(id<MTLDevice> device, std::string label)
    : device_(device), allocator_label_(std::move(label)) {
  if (!device_) {
    return;
  }

  is_valid_ = true;
}

Allocator::~Allocator() = default;

bool Allocator::IsValid() const {
  return is_valid_;
}

static MTLResourceOptions ToMTLResourceOptions(StorageMode type) {
  switch (type) {
    case StorageMode::kHostVisible:
#if OS_IOS
      return MTLResourceStorageModeShared;
#else
      return MTLResourceStorageModeManaged;
#endif
    case StorageMode::kDevicePrivate:
      return MTLResourceStorageModePrivate;
    case StorageMode::kDeviceTransient:
#if OS_IOS
      return MTLResourceStorageModeMemoryless;
#else
      return MTLResourceStorageModePrivate;
#endif
  }

  return MTLResourceStorageModePrivate;
}

static MTLStorageMode ToMTLStorageMode(StorageMode mode) {
  switch (mode) {
    case StorageMode::kHostVisible:
#if OS_IOS
      return MTLStorageModeShared;
#else
      return MTLStorageModeManaged;
#endif
    case StorageMode::kDevicePrivate:
      return MTLStorageModePrivate;
    case StorageMode::kDeviceTransient:
#if OS_IOS
      return MTLStorageModeMemoryless;
#else
      return MTLStorageModePrivate;
#endif
  }
  return MTLStorageModeShared;
}

bool Allocator::RequiresExplicitHostSynchronization(StorageMode mode) {
  if (mode != StorageMode::kHostVisible) {
    return false;
  }

#if OS_IOS
  // StorageMode::kHostVisible is MTLStorageModeShared already.
  return false;
#else
  // StorageMode::kHostVisible is MTLResourceStorageModeManaged.
  return true;
#endif
}

std::shared_ptr<DeviceBuffer> Allocator::CreateBuffer(StorageMode mode,
                                                      size_t length) {
  auto buffer = [device_ newBufferWithLength:length
                                     options:ToMTLResourceOptions(mode)];
  if (!buffer) {
    return nullptr;
  }
  return std::shared_ptr<DeviceBuffer>(new DeviceBuffer(buffer, length, mode));
}

std::shared_ptr<DeviceBuffer> Allocator::CreateBufferWithCopy(
    const uint8_t* buffer,
    size_t length) {
  auto new_buffer = CreateBuffer(StorageMode::kHostVisible, length);

  if (!new_buffer) {
    return nullptr;
  }

  auto entire_range = Range{0, length};

  if (!new_buffer->CopyHostBuffer(buffer, entire_range)) {
    return nullptr;
  }

  return new_buffer;
}

std::shared_ptr<DeviceBuffer> Allocator::CreateBufferWithCopy(
    const fml::Mapping& mapping) {
  return CreateBufferWithCopy(mapping.GetMapping(), mapping.GetSize());
}

std::shared_ptr<Texture> Allocator::CreateTexture(
    StorageMode mode,
    const TextureDescriptor& desc) {
  if (!IsValid()) {
    return nullptr;
  }

  auto mtl_texture_desc = ToMTLTextureDescriptor(desc);
  mtl_texture_desc.storageMode = ToMTLStorageMode(mode);
  auto texture = [device_ newTextureWithDescriptor:mtl_texture_desc];
  if (!texture) {
    return nullptr;
  }
  return std::make_shared<Texture>(desc, texture);
}

}  // namespace impeller
