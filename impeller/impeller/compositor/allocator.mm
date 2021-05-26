// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/compositor/allocator.h"

#include "impeller/compositor/buffer.h"

namespace impeller {

Allocator::Allocator(id<MTLDevice> device, StorageMode type, std::string label)
    : device_(device), mode_(type), allocator_label_(std::move(label)) {}

Allocator::~Allocator() = default;

static MTLResourceOptions ResourceOptionsFromStorageType(StorageMode type) {
  switch (type) {
    case StorageMode::kHostCoherent:
      return MTLResourceStorageModeManaged;
    case StorageMode::kDevicePrivate:
      return MTLResourceStorageModePrivate;
  }
}

std::shared_ptr<Buffer> Allocator::CreateBuffer(size_t length,
                                                std::string label) {
  auto buffer =
      [device_ newBufferWithLength:length
                           options:ResourceOptionsFromStorageType(mode_)];
  if (!buffer) {
    return nullptr;
  }
  buffer.label = @(label.c_str());
  return std::shared_ptr<Buffer>(new Buffer(buffer, length, mode_, label));
}

}  // namespace impeller
