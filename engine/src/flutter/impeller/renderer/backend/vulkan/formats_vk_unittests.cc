// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gtest/gtest.h"  // IWYU pragma: keep
#include "impeller/renderer/backend/vulkan/formats_vk.h"

namespace impeller {
namespace testing {

TEST(FormatsVKTest, DescriptorMapping) {
  EXPECT_EQ(ToVKDescriptorType(DescriptorType::kSampledImage),
            vk::DescriptorType::eCombinedImageSampler);
  EXPECT_EQ(ToVKDescriptorType(DescriptorType::kUniformBuffer),
            vk::DescriptorType::eUniformBuffer);
  EXPECT_EQ(ToVKDescriptorType(DescriptorType::kStorageBuffer),
            vk::DescriptorType::eStorageBuffer);
  EXPECT_EQ(ToVKDescriptorType(DescriptorType::kImage),
            vk::DescriptorType::eSampledImage);
  EXPECT_EQ(ToVKDescriptorType(DescriptorType::kSampler),
            vk::DescriptorType::eSampler);
  EXPECT_EQ(ToVKDescriptorType(DescriptorType::kInputAttachment),
            vk::DescriptorType::eInputAttachment);
}

TEST(FormatsVKTest, Gray8Mapping) {
  EXPECT_EQ(ToVKImageFormat(PixelFormat::kGray8UNormInt), vk::Format::eR8Unorm);

  const vk::ComponentMapping mapping =
      ToVKComponentMapping(PixelFormat::kGray8UNormInt);
  EXPECT_EQ(mapping.r, vk::ComponentSwizzle::eR);
  EXPECT_EQ(mapping.g, vk::ComponentSwizzle::eR);
  EXPECT_EQ(mapping.b, vk::ComponentSwizzle::eR);
  EXPECT_EQ(mapping.a, vk::ComponentSwizzle::eOne);
}

}  // namespace testing
}  // namespace impeller
