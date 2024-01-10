// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/core/device_buffer.h"

namespace impeller {

DeviceBuffer::DeviceBuffer(DeviceBufferDescriptor desc) : desc_(desc) {}

DeviceBuffer::~DeviceBuffer() = default;

// |Buffer|
std::shared_ptr<const DeviceBuffer> DeviceBuffer::GetDeviceBuffer(
    Allocator& allocator) const {
  return shared_from_this();
}

BufferView DeviceBuffer::AsBufferView() const {
  BufferView view;
  view.buffer = shared_from_this();
  view.contents = OnGetContents();
  view.range = {0u, desc_.size};
  return view;
}

std::shared_ptr<Texture> DeviceBuffer::AsTexture(
    Allocator& allocator,
    const TextureDescriptor& descriptor,
    uint16_t row_bytes) const {
  auto texture = allocator.CreateTexture(descriptor);
  if (!texture) {
    return nullptr;
  }
  if (!texture->SetContents(std::make_shared<fml::NonOwnedMapping>(
          OnGetContents(), desc_.size))) {
    return nullptr;
  }
  return texture;
}

const DeviceBufferDescriptor& DeviceBuffer::GetDeviceBufferDescriptor() const {
  return desc_;
}

[[nodiscard]] bool DeviceBuffer::CopyHostBuffer(const uint8_t* source,
                                                Range source_range,
                                                size_t offset) {
  if (source_range.length == 0u) {
    // Nothing to copy. Bail.
    return true;
  }

  if (source == nullptr) {
    // Attempted to copy data from a null buffer.
    return false;
  }

  if (desc_.storage_mode != StorageMode::kHostVisible) {
    // One of the storage modes where a transfer queue must be used.
    return false;
  }

  if (offset + source_range.length > desc_.size) {
    // Out of bounds of this buffer.
    return false;
  }

  return OnCopyHostBuffer(source, source_range, offset);
}

}  // namespace impeller
