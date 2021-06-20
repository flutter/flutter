// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/compositor/device_buffer.h"

#include <Foundation/Foundation.h>

namespace impeller {

DeviceBuffer::DeviceBuffer(id<MTLBuffer> buffer, size_t size, StorageMode mode)
    : buffer_(buffer), size_(size), mode_(mode) {}

DeviceBuffer::~DeviceBuffer() = default;

id<MTLBuffer> DeviceBuffer::GetMTLBuffer() const {
  return buffer_;
}

[[nodiscard]] bool DeviceBuffer::CopyHostBuffer(const uint8_t* source,
                                                Range source_range,
                                                size_t offset) {
  if (offset + source_range.length > size_) {
    // Out of bounds of this buffer.
    return false;
  }

  auto dest = static_cast<uint8_t*>(buffer_.contents);

  if (!dest) {
    // Probably StorageMode::kDevicePrivate.
    return false;
  }

  ::memcpy(dest + offset, source + source_range.offset, source_range.length);

  [buffer_ didModifyRange:NSMakeRange(offset, source_range.length)];

  return true;
}

// |Buffer|
std::shared_ptr<const DeviceBuffer> DeviceBuffer::GetDeviceBuffer(
    Allocator& allocator) const {
  return shared_from_this();
}

bool DeviceBuffer::SetLabel(const std::string& label) {
  if (label.empty()) {
    return false;
  }
  [buffer_ setLabel:@(label.c_str())];
  return true;
}

bool DeviceBuffer::SetLabel(const std::string& label, Range range) {
  if (label.empty()) {
    return false;
  }
  [buffer_ addDebugMarker:@(label.c_str())
                    range:NSMakeRange(range.offset, range.length)];
  return true;
}

}  // namespace impeller
