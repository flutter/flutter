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

TEST(FormatsVKTest, Texture3DMapping) {
  EXPECT_EQ(ToVKImageType(TextureType::kTexture3D), vk::ImageType::e3D);
  EXPECT_EQ(ToVKImageType(TextureType::kTexture2DArray), vk::ImageType::e2D);
  EXPECT_EQ(ToVKImageViewType(TextureType::kTexture3D),
            vk::ImageViewType::e3D);
  EXPECT_EQ(ToVKImageCreateFlags(TextureType::kTexture3D),
            vk::ImageCreateFlags{});
  // Depth slices are not array layers.
  TextureDescriptor desc = {.type = TextureType::kTexture3D, .depth = 16};
  EXPECT_EQ(ToArrayLayerCount(desc), 1u);
}

}  // namespace testing
}  // namespace impeller
