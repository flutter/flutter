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

}  // namespace testing
}  // namespace impeller
