// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/device_buffer.h"

namespace impeller {

DeviceBuffer::DeviceBuffer(size_t size, StorageMode mode)
    : size_(size), mode_(mode) {}

DeviceBuffer::~DeviceBuffer() = default;

// |Buffer|
std::shared_ptr<const DeviceBuffer> DeviceBuffer::GetDeviceBuffer(
    Allocator& allocator) const {
  return shared_from_this();
}

BufferView DeviceBuffer::AsBufferView() const {
  BufferView view;
  view.buffer = shared_from_this();
  view.range = {0u, size_};
  return view;
}

}  // namespace impeller
