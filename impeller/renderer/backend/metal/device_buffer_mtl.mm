// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/metal/device_buffer_mtl.h"

#include "flutter/fml/logging.h"
#include "impeller/base/validation.h"
#include "impeller/renderer/backend/metal/formats_mtl.h"
#include "impeller/renderer/backend/metal/texture_mtl.h"

namespace impeller {

DeviceBufferMTL::DeviceBufferMTL(DeviceBufferDescriptor desc,
                                 id<MTLBuffer> buffer,
                                 MTLStorageMode storage_mode)
    : DeviceBuffer(desc), buffer_(buffer), storage_mode_(storage_mode) {}

DeviceBufferMTL::~DeviceBufferMTL() = default;

id<MTLBuffer> DeviceBufferMTL::GetMTLBuffer() const {
  return buffer_;
}

uint8_t* DeviceBufferMTL::OnGetContents() const {
  if (storage_mode_ != MTLStorageModeShared) {
    return nullptr;
  }
  return reinterpret_cast<uint8_t*>(buffer_.contents);
}

std::shared_ptr<Texture> DeviceBufferMTL::AsTexture(
    Allocator& allocator,
    const TextureDescriptor& descriptor,
    uint16_t row_bytes) const {
  auto mtl_texture_desc = ToMTLTextureDescriptor(descriptor);

  if (!mtl_texture_desc) {
    VALIDATION_LOG << "Texture descriptor was invalid.";
    return nullptr;
  }

  if (@available(iOS 13.0, macos 10.15, *)) {
    mtl_texture_desc.resourceOptions = buffer_.resourceOptions;
  }

  auto texture = [buffer_ newTextureWithDescriptor:mtl_texture_desc
                                            offset:0
                                       bytesPerRow:row_bytes];
  if (!texture) {
    return nullptr;
  }
  return std::make_shared<TextureMTL>(descriptor, texture);
}

[[nodiscard]] bool DeviceBufferMTL::OnCopyHostBuffer(const uint8_t* source,
                                                     Range source_range,
                                                     size_t offset) {
  auto dest = static_cast<uint8_t*>(buffer_.contents);

  if (!dest) {
    return false;
  }

  if (source) {
    ::memmove(dest + offset, source + source_range.offset, source_range.length);
  }

// MTLStorageModeManaged is never present on always returns false on iOS. But
// the compiler is mad that `didModifyRange:` appears in a TU meant for iOS. So,
// just compile it away.
#if !FML_OS_IOS
  if (storage_mode_ == MTLStorageModeManaged) {
    [buffer_ didModifyRange:NSMakeRange(offset, source_range.length)];
  }
#endif

  return true;
}

bool DeviceBufferMTL::SetLabel(const std::string& label) {
  if (label.empty()) {
    return false;
  }
  [buffer_ setLabel:@(label.c_str())];
  return true;
}

bool DeviceBufferMTL::SetLabel(const std::string& label, Range range) {
  if (label.empty()) {
    return false;
  }
  [buffer_ addDebugMarker:@(label.c_str())
                    range:NSMakeRange(range.offset, range.length)];
  return true;
}

}  // namespace impeller
