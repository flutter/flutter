// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/compositor/device_buffer.h"

#include "flutter/fml/logging.h"
#include "impeller/compositor/formats_metal.h"

namespace impeller {

DeviceBuffer::DeviceBuffer(id<MTLBuffer> buffer, size_t size, StorageMode mode)
    : buffer_(buffer), size_(size), mode_(mode) {}

DeviceBuffer::~DeviceBuffer() = default;

id<MTLBuffer> DeviceBuffer::GetMTLBuffer() const {
  return buffer_;
}

std::shared_ptr<Texture> DeviceBuffer::MakeTexture(TextureDescriptor desc,
                                                   size_t offset) const {
  if (!desc.IsValid() || !buffer_) {
    return nullptr;
  }

  // Avoid overruns.
  if (offset + desc.GetSizeOfBaseMipLevel() > size_) {
    FML_DLOG(ERROR) << "Avoiding buffer overrun when creating texture.";
    return nullptr;
  }

  auto mtl_desc = [[MTLTextureDescriptor alloc] init];
  mtl_desc.pixelFormat = ToMTLPixelFormat(desc.format);
  mtl_desc.width = desc.size.width;
  mtl_desc.height = desc.size.height;
  mtl_desc.mipmapLevelCount = desc.mip_count;

  auto texture = [buffer_ newTextureWithDescriptor:mtl_desc
                                            offset:offset
                                       bytesPerRow:desc.GetBytesPerRow()];
  if (!texture) {
    return nullptr;
  }

  return std::make_shared<Texture>(texture);
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

  ::memmove(dest + offset, source + source_range.offset, source_range.length);

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

BufferView DeviceBuffer::AsBufferView() const {
  BufferView view;
  view.buffer = shared_from_this();
  view.range = {0u, size_};
  return view;
}

}  // namespace impeller
