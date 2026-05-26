// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_CORE_TEXTURE_DESCRIPTOR_H_
#define FLUTTER_IMPELLER_CORE_TEXTURE_DESCRIPTOR_H_

#include <cstdint>
#include "impeller/core/formats.h"
#include "impeller/geometry/size.h"

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

constexpr const char* CompressionTypeToString(CompressionType type) {
  switch (type) {
    case CompressionType::kLossless:
      return "Lossless";
    case CompressionType::kLossy:
      return "Lossy";
  }
  FML_UNREACHABLE();
}

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
  TextureUsageMask usage = TextureUsage::kShaderRead;
  SampleCount sample_count = SampleCount::kCount1;
  CompressionType compression_type = CompressionType::kLossless;

  /// @brief The number of bytes required to store an image of the given texel
  ///        dimensions in this format. Block-compressed formats round the
  ///        dimensions up to whole blocks.
  constexpr size_t GetByteSizeForDimensions(int64_t width,
                                            int64_t height) const {
    return BytesForTextureRegion(format, width, height);
  }

  constexpr size_t GetByteSizeOfBaseMipLevel() const {
    if (!IsValid()) {
      return 0u;
    }
    return GetByteSizeForDimensions(size.width, size.height);
  }

  constexpr size_t GetByteSizeOfAllMipLevels() const {
    if (!IsValid()) {
      return 0u;
    }
    size_t result = 0u;
    int64_t width = size.width;
    int64_t height = size.height;
    for (auto i = 0u; i < mip_count; i++) {
      result += GetByteSizeForDimensions(width, height);
      width /= 2;
      height /= 2;
    }
    return result;
  }

  constexpr size_t GetBytesPerRow() const {
    if (!IsValid()) {
      return 0u;
    }
    const size_t block_width = CompressedBlockWidthForPixelFormat(format);
    const size_t w = size.width <= 0 ? 0u : static_cast<size_t>(size.width);
    const size_t blocks_wide = (w + block_width - 1u) / block_width;
    return blocks_wide * BytesPerBlockForPixelFormat(format);
  }

  constexpr bool SamplingOptionsAreValid() const {
    const auto count = static_cast<uint64_t>(sample_count);
    return IsMultisampleCapable(type) ? count > 1 : count == 1;
  }

  constexpr bool operator==(const TextureDescriptor& other) const = default;

  constexpr bool IsValid() const {
    return format != PixelFormat::kUnknown &&  //
           !size.IsEmpty() &&                  //
           mip_count >= 1u &&                  //
           SamplingOptionsAreValid();
  }
};

std::string TextureDescriptorToString(const TextureDescriptor& desc);

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_CORE_TEXTURE_DESCRIPTOR_H_
