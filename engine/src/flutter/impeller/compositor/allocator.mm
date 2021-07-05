// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/compositor/allocator.h"

#include "flutter/fml/build_config.h"
#include "flutter/fml/logging.h"
#include "impeller/compositor/buffer.h"
#include "impeller/compositor/device_buffer.h"

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

static MTLResourceOptions ResourceOptionsFromStorageType(StorageMode type) {
  switch (type) {
    case StorageMode::kHostVisible:
#if OS_IOS
      return MTLStorageModeShared;
#else
      return MTLResourceStorageModeManaged;
#endif
    case StorageMode::kDevicePrivate:
      return MTLResourceStorageModePrivate;
    case StorageMode::kDeviceTransient:
#if OS_IOS
      return MTLStorageModeMemoryless;
#else
      return MTLResourceStorageModePrivate;
#endif
  }
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

std::shared_ptr<DeviceBuffer> Allocator::CreateBuffer(StorageMode mode,
                                                      size_t length) {
  auto buffer =
      [device_ newBufferWithLength:length
                           options:ResourceOptionsFromStorageType(mode)];
  if (!buffer) {
    return nullptr;
  }
  return std::shared_ptr<DeviceBuffer>(new DeviceBuffer(buffer, length, mode));
}

}  // namespace impeller
