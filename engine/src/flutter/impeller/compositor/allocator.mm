// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/compositor/allocator.h"

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
    case StorageMode::kHostCoherent:
      return MTLResourceStorageModeManaged;
    case StorageMode::kDevicePrivate:
      return MTLResourceStorageModePrivate;
  }
}

std::shared_ptr<DeviceBuffer> Allocator::CreateBufferWithCopy(
    const uint8_t* buffer,
    size_t length) {
  auto new_buffer = CreateBuffer(StorageMode::kHostCoherent, length);

  if (!new_buffer) {
    return nullptr;
  }

  auto entire_range = Range{0, length};

  if (!new_buffer->CopyHostBuffer(buffer, entire_range)) {
    return nullptr;
  }

  return new_buffer;
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
