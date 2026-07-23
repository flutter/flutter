// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>
#include "flutter/testing/testing.h"
#include "impeller/core/allocator.h"
#include "impeller/core/formats.h"
#include "impeller/core/texture_descriptor.h"
#include "impeller/geometry/size.h"
#include "impeller/renderer/testing/mocks.h"

namespace impeller {
namespace testing {

TEST(AllocatorTest, TextureDescriptorCompatibility) {
  // Size.
  {
    TextureDescriptor desc_a = {.size = ISize(100, 100)};
    TextureDescriptor desc_b = {.size = ISize(100, 100)};
    TextureDescriptor desc_c = {.size = ISize(101, 100)};

    ASSERT_EQ(desc_a, desc_b);
    ASSERT_NE(desc_a, desc_c);
  }
  // Storage Mode.
  {
    TextureDescriptor desc_a = {.storage_mode = StorageMode::kDevicePrivate};
    TextureDescriptor desc_b = {.storage_mode = StorageMode::kDevicePrivate};
    TextureDescriptor desc_c = {.storage_mode = StorageMode::kHostVisible};

    ASSERT_EQ(desc_a, desc_b);
    ASSERT_NE(desc_a, desc_c);
  }
  // Format.
  {
    TextureDescriptor desc_a = {.format = PixelFormat::kR8G8B8A8UNormInt};
    TextureDescriptor desc_b = {.format = PixelFormat::kR8G8B8A8UNormInt};
    TextureDescriptor desc_c = {.format = PixelFormat::kB10G10R10A10XR};

    ASSERT_EQ(desc_a, desc_b);
    ASSERT_NE(desc_a, desc_c);
  }
  // Sample Count.
  {
    TextureDescriptor desc_a = {.sample_count = SampleCount::kCount4};
    TextureDescriptor desc_b = {.sample_count = SampleCount::kCount4};
    TextureDescriptor desc_c = {.sample_count = SampleCount::kCount1};

    ASSERT_EQ(desc_a, desc_b);
    ASSERT_NE(desc_a, desc_c);
  }
  // Sample Count.
  {
    TextureDescriptor desc_a = {.type = TextureType::kTexture2DMultisample};
    TextureDescriptor desc_b = {.type = TextureType::kTexture2DMultisample};
    TextureDescriptor desc_c = {.type = TextureType::kTexture2D};

    ASSERT_EQ(desc_a, desc_b);
    ASSERT_NE(desc_a, desc_c);
  }
  // Compression.
  {
    TextureDescriptor desc_a = {.compression_type = CompressionType::kLossless};
    TextureDescriptor desc_b = {.compression_type = CompressionType::kLossless};
    TextureDescriptor desc_c = {.compression_type = CompressionType::kLossy};

    ASSERT_EQ(desc_a, desc_b);
    ASSERT_NE(desc_a, desc_c);
  }
  // Mip Count.
  {
    TextureDescriptor desc_a = {.mip_count = 1};
    TextureDescriptor desc_b = {.mip_count = 1};
    TextureDescriptor desc_c = {.mip_count = 4};

    ASSERT_EQ(desc_a, desc_b);
    ASSERT_NE(desc_a, desc_c);
  }
}

TEST(AllocatorTest, RangeTest) {
  {
    Range a = Range{0, 10};
    Range b = Range{10, 20};
    auto merged = a.Merge(b);

    EXPECT_EQ(merged.offset, 0u);
    EXPECT_EQ(merged.length, 30u);
  }

  {
    Range a = Range{0, 10};
    Range b = Range{100, 20};
    auto merged = a.Merge(b);

    EXPECT_EQ(merged.offset, 0u);
    EXPECT_EQ(merged.length, 120u);
  }

  {
    Range a = Range{0, 10};
    Range b = Range{100, 20};
    auto merged = b.Merge(a);

    EXPECT_EQ(merged.offset, 0u);
    EXPECT_EQ(merged.length, 120u);
  }

  {
    Range a = Range{0, 10};
    Range b = Range{100, 0};
    auto merged = b.Merge(a);

    EXPECT_EQ(merged.offset, 0u);
    EXPECT_EQ(merged.length, 10u);
  }

  {
    Range a = Range{0, 10};
    Range b = Range{0, 10};
    auto merged = b.Merge(a);

    EXPECT_EQ(merged.offset, 0u);
    EXPECT_EQ(merged.length, 10u);
  }
}

TEST(AllocatorTest, CompressedFormatClassification) {
  EXPECT_FALSE(IsCompressed(PixelFormat::kR8G8B8A8UNormInt));
  EXPECT_FALSE(IsCompressed(PixelFormat::kR32Float));
  EXPECT_TRUE(IsCompressed(PixelFormat::kBC1RGBAUNormInt));
  EXPECT_TRUE(IsCompressed(PixelFormat::kETC2RGBA8UNormInt));
  EXPECT_TRUE(IsCompressed(PixelFormat::kASTC8x8LDR));
  EXPECT_TRUE(IsCompressed(PixelFormat::kASTC4x4HDR));

  EXPECT_EQ(CompressedTextureFamilyForFormat(PixelFormat::kBC7RGBAUNormInt),
            CompressedTextureFamily::kBC);
  EXPECT_EQ(CompressedTextureFamilyForFormat(PixelFormat::kETC2RGB8UNormInt),
            CompressedTextureFamily::kETC2);
  EXPECT_EQ(CompressedTextureFamilyForFormat(PixelFormat::kASTC4x4LDR),
            CompressedTextureFamily::kASTC);
  EXPECT_EQ(CompressedTextureFamilyForFormat(PixelFormat::kASTC8x8HDR),
            CompressedTextureFamily::kASTCHDR);
}

TEST(AllocatorTest, CompressedFormatBlockMath) {
  // Block dimensions: everything here is 4x4 except ASTC 8x8.
  EXPECT_EQ(CompressedBlockWidthForPixelFormat(PixelFormat::kBC1RGBAUNormInt),
            4u);
  EXPECT_EQ(CompressedBlockWidthForPixelFormat(PixelFormat::kASTC8x8LDR), 8u);
  EXPECT_EQ(CompressedBlockHeightForPixelFormat(PixelFormat::kASTC8x8LDR), 8u);
  EXPECT_EQ(CompressedBlockWidthForPixelFormat(PixelFormat::kASTC4x4HDR), 4u);
  EXPECT_EQ(CompressedBlockHeightForPixelFormat(PixelFormat::kASTC8x8HDR), 8u);
  // Uncompressed formats report a 1x1 block.
  EXPECT_EQ(CompressedBlockWidthForPixelFormat(PixelFormat::kR8G8B8A8UNormInt),
            1u);

  // Bytes per block: BC1/ETC2-RGB8 are 8 bytes, the rest here are 16.
  EXPECT_EQ(BytesPerBlockForPixelFormat(PixelFormat::kBC1RGBAUNormInt), 8u);
  EXPECT_EQ(BytesPerBlockForPixelFormat(PixelFormat::kETC2RGB8UNormInt), 8u);
  EXPECT_EQ(BytesPerBlockForPixelFormat(PixelFormat::kBC3RGBAUNormInt), 16u);
  EXPECT_EQ(BytesPerBlockForPixelFormat(PixelFormat::kASTC4x4LDR), 16u);
  EXPECT_EQ(BytesPerBlockForPixelFormat(PixelFormat::kASTC8x8HDR), 16u);
  // Uncompressed falls back to bytes-per-pixel.
  EXPECT_EQ(BytesPerBlockForPixelFormat(PixelFormat::kR8G8B8A8UNormInt), 4u);
}

TEST(AllocatorTest, CompressedFormatRegionByteSizes) {
  // BC1: 4x4 blocks of 8 bytes. Dimensions round up to whole blocks.
  EXPECT_EQ(BytesForTextureRegion(PixelFormat::kBC1RGBAUNormInt, 4, 4), 8u);
  EXPECT_EQ(BytesForTextureRegion(PixelFormat::kBC1RGBAUNormInt, 8, 8), 32u);
  EXPECT_EQ(BytesForTextureRegion(PixelFormat::kBC1RGBAUNormInt, 5, 5), 32u);
  EXPECT_EQ(BytesPerRowForTextureWidth(PixelFormat::kBC1RGBAUNormInt, 8), 16u);

  // ASTC 8x8: a single 16-byte block covers up to 8x8 texels.
  EXPECT_EQ(BytesForTextureRegion(PixelFormat::kASTC8x8LDR, 8, 8), 16u);
  EXPECT_EQ(BytesForTextureRegion(PixelFormat::kASTC8x8LDR, 9, 9), 64u);

  // Uncompressed math is unchanged: width * height * bytes-per-pixel.
  EXPECT_EQ(BytesForTextureRegion(PixelFormat::kR8G8B8A8UNormInt, 100, 100),
            40000u);
  EXPECT_EQ(BytesPerRowForTextureWidth(PixelFormat::kR8G8B8A8UNormInt, 100),
            400u);
}

TEST(AllocatorTest, CompressedTextureDescriptorByteSizes) {
  {
    TextureDescriptor desc = {.format = PixelFormat::kBC1RGBAUNormInt,
                              .size = ISize(8, 8)};
    EXPECT_EQ(desc.GetByteSizeOfBaseMipLevel(), 32u);
    EXPECT_EQ(desc.GetBytesPerRow(), 16u);
  }
  {
    TextureDescriptor desc = {.format = PixelFormat::kASTC8x8LDR,
                              .size = ISize(16, 16)};
    EXPECT_EQ(desc.GetByteSizeOfBaseMipLevel(), 64u);
  }
}

}  // namespace testing
}  // namespace impeller
