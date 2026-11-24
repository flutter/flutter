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

TEST(FormatsVKTest, Float16FormatMapping) {
  EXPECT_EQ(ToVKImageFormat(PixelFormat::kR16Float), vk::Format::eR16Sfloat);
  EXPECT_EQ(ToVKImageFormat(PixelFormat::kR16G16Float),
            vk::Format::eR16G16Sfloat);
  EXPECT_EQ(ToPixelFormat(vk::Format::eR16Sfloat), PixelFormat::kR16Float);
  EXPECT_EQ(ToPixelFormat(vk::Format::eR16G16Sfloat),
            PixelFormat::kR16G16Float);
  EXPECT_EQ(ToVKImageAspectFlags(PixelFormat::kR16Float),
            vk::ImageAspectFlags(vk::ImageAspectFlagBits::eColor));
  EXPECT_FALSE(PixelFormatIsDepthStencil(PixelFormat::kR16G16Float));
}

}  // namespace testing
}  // namespace impeller
