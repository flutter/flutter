// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <optional>

#include "impeller/core/formats.h"
#include "impeller/geometry/size.h"
#include "impeller/image/decompressed_image.h"

namespace impeller {

//------------------------------------------------------------------------------
/// @brief      Additional compression to apply to a texture. This value is
///             ignored on platforms which do not support it.
///
///             Lossy compression is only supported on iOS 15+ on A15 chips.
enum class CompressionType {
  kLossless,
  kLossy,
};
//------------------------------------------------------------------------------
/// @brief      A lightweight object that describes the attributes of a texture
///             that can then used an allocator to create that texture.
///
struct TextureDescriptor {
  StorageMode storage_mode = StorageMode::kDeviceTransient;
  TextureType type = TextureType::kTexture2D;
  PixelFormat format = PixelFormat::kUnknown;
  ISize size;
  size_t mip_count = 1u;  // Size::MipCount is usually appropriate.
  TextureUsageMask usage =
      static_cast<TextureUsageMask>(TextureUsage::kShaderRead);
  SampleCount sample_count = SampleCount::kCount1;
  CompressionType compression_type = CompressionType::kLossless;

  constexpr size_t GetByteSizeOfBaseMipLevel() const {
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

  constexpr bool SamplingOptionsAreValid() const {
    const auto count = static_cast<uint64_t>(sample_count);
    return IsMultisampleCapable(type) ? count > 1 : count == 1;
  }

  constexpr bool IsValid() const {
    return format != PixelFormat::kUnknown &&  //
           size.IsPositive() &&                //
           mip_count >= 1u &&                  //
           SamplingOptionsAreValid();
  }
};

}  // namespace impeller
