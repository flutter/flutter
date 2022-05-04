// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/allocator.h"

#include "impeller/renderer/device_buffer.h"
#include "impeller/renderer/range.h"

namespace impeller {

Allocator::Allocator() = default;

Allocator::~Allocator() = default;

bool Allocator::RequiresExplicitHostSynchronization(StorageMode mode) {
  if (mode != StorageMode::kHostVisible) {
    return false;
  }

#if FML_OS_IOS
  // StorageMode::kHostVisible is MTLStorageModeShared already.
  return false;
#else   // FML_OS_IOS
  // StorageMode::kHostVisible is MTLResourceStorageModeManaged.
  return true;
#endif  // FML_OS_IOS
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

}  // namespace impeller
