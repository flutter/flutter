// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>
#include <string_view>

#include "flutter/testing/testing.h"  // IWYU pragma: keep
#include "gtest/gtest.h"
#include "impeller/core/allocator.h"
#include "impeller/core/formats.h"
#include "impeller/core/texture_descriptor.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/test/mock_vulkan.h"
#include "impeller/renderer/backend/vulkan/texture_vk.h"

namespace impeller {
namespace testing {
namespace {

// Qualcomm devices generate corrupt mip levels; ARM ones do not.
constexpr uint32_t kQualcommVendorID = 0x168C;
constexpr uint32_t kARMVendorID = 0x13B5;

std::shared_ptr<ContextVK> MakeContext(std::string_view device_name,
                                       uint32_t vendor_id) {
  return MockVulkanContextBuilder()
      .SetPhysicalPropertiesCallback(
          [device_name, vendor_id](VkPhysicalDevice device,
                                   VkPhysicalDeviceProperties* prop) {
            prop->vendorID = vendor_id;
            device_name.copy(prop->deviceName, device_name.size());
            prop->deviceType = VK_PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU;
          })
      .Build();
}

std::shared_ptr<Texture> MakeTexture(const std::shared_ptr<ContextVK>& context,
                                     size_t mip_count) {
  return context->GetResourceAllocator()->CreateTexture(TextureDescriptor{
      .storage_mode = StorageMode::kDevicePrivate,
      .format = PixelFormat::kR8G8B8A8UNormInt,
      .size = {8, 8},
      .mip_count = mip_count,
      .usage = TextureUsage::kShaderRead,
  });
}

}  // namespace

TEST(TextureVKTest, SampledViewDropsMipsGeneratedByABrokenDriver) {
  auto const context = MakeContext("Adreno (TM) 750", kQualcommVendorID);
  auto texture = MakeTexture(context, /*mip_count=*/4u);
  ASSERT_TRUE(texture);
  auto& texture_vk = TextureVK::Cast(*texture);

  // Levels uploaded by hand are trustworthy, so the full view is used.
  EXPECT_EQ(texture_vk.GetSampledImageView(), texture_vk.GetImageView());

  // Levels this driver generated are not.
  texture_vk.SetMipMapGenerated();
  EXPECT_NE(texture_vk.GetSampledImageView(), texture_vk.GetImageView());
  EXPECT_NE(texture_vk.GetSampledImageView(), vk::ImageView{});
}

TEST(TextureVKTest, SampledViewKeepsMipsOnAWorkingDriver) {
  auto const context = MakeContext("Mali-G51", kARMVendorID);
  auto texture = MakeTexture(context, /*mip_count=*/4u);
  ASSERT_TRUE(texture);
  auto& texture_vk = TextureVK::Cast(*texture);

  texture_vk.SetMipMapGenerated();
  EXPECT_EQ(texture_vk.GetSampledImageView(), texture_vk.GetImageView());
}

TEST(TextureVKTest, SampledViewIsTheFullViewWithoutMips) {
  auto const context = MakeContext("Adreno (TM) 750", kQualcommVendorID);
  auto texture = MakeTexture(context, /*mip_count=*/1u);
  ASSERT_TRUE(texture);
  auto& texture_vk = TextureVK::Cast(*texture);

  texture_vk.SetMipMapGenerated();
  EXPECT_EQ(texture_vk.GetSampledImageView(), texture_vk.GetImageView());
}

}  // namespace testing
}  // namespace impeller
