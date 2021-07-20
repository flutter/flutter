// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <optional>

#include "impeller/compositor/formats.h"
#include "impeller/geometry/size.h"
#include "impeller/image/decompressed_image.h"

namespace impeller {

struct TextureDescriptor {
  PixelFormat format = PixelFormat::kUnknown;
  ISize size;
  size_t mip_count = 1u;  // Size::MipCount is usually appropriate.
  TextureUsageMask usage =
      static_cast<TextureUsageMask>(TextureUsage::kShaderRead);

  constexpr size_t GetSizeOfBaseMipLevel() const {
    if (!IsValid()) {
      return 0u;
    }
    return size.Area() * BytesPerPixelForPixelFormat(format);
  }

  constexpr size_t GetBytesPerRow() const {
    if (!IsValid()) {
      return 0u;
    }
    return size.width * BytesPerPixelForPixelFormat(format);
  }

  bool IsValid() const {
    return format != PixelFormat::kUnknown &&  //
           size.IsPositive() &&                //
           mip_count >= 1u                     //
        ;
  }
};

}  // namespace impeller
