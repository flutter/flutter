// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <algorithm>
#include <memory>
#include <string>
#include <vector>
#include "flutter/testing/testing.h"  // IWYU pragma: keep
#include "gtest/gtest.h"
#include "impeller/core/formats.h"
#include "impeller/core/sampler_descriptor.h"
#include "impeller/renderer/backend/vulkan/command_pool_vk.h"
#include "impeller/renderer/backend/vulkan/sampler_library_vk.h"
#include "impeller/renderer/backend/vulkan/sampler_vk.h"
#include "impeller/renderer/backend/vulkan/test/mock_vulkan.h"
#include "impeller/renderer/backend/vulkan/yuv_conversion_library_vk.h"

namespace impeller {
namespace testing {

TEST(SamplerLibraryVK, MaxAnisotropyIsClampedToTheDeviceLimit) {
  auto const context = MockVulkanContextBuilder().Build();

  std::shared_ptr<SamplerLibrary> library = std::make_shared<SamplerLibraryVK>(
      context->GetDeviceHolder(), /*max_sampler_anisotropy=*/4u);

  SamplerDescriptor desc;
  desc.min_filter = MinMagFilter::kLinear;
  desc.mag_filter = MinMagFilter::kLinear;
  desc.mip_filter = MipFilter::kLinear;
  desc.max_anisotropy = 16;

  auto sampler = library->GetSampler(desc);
  EXPECT_EQ(sampler->GetDescriptor().max_anisotropy, 4u);

  // Clamped values share a cache entry.
  desc.max_anisotropy = 8;
  EXPECT_EQ(library->GetSampler(desc), sampler);
}

TEST(SamplerLibraryVK, MaxAnisotropyIsDisabledWhenUnsupported) {
  auto const context = MockVulkanContextBuilder().Build();

  std::shared_ptr<SamplerLibrary> library = std::make_shared<SamplerLibraryVK>(
      context->GetDeviceHolder(), /*max_sampler_anisotropy=*/1u);

  SamplerDescriptor desc;
  desc.min_filter = MinMagFilter::kLinear;
  desc.mag_filter = MinMagFilter::kLinear;
  desc.mip_filter = MipFilter::kLinear;
  desc.max_anisotropy = 16;

  auto sampler = library->GetSampler(desc);
  EXPECT_EQ(sampler->GetDescriptor().max_anisotropy, 1u);
}

TEST(SamplerLibraryVK, SamplerReleasesHandleAfterDeviceIsDestroyed) {
  std::shared_ptr<SamplerVK> sampler;
  std::shared_ptr<YUVConversionVK> conversion;
  std::shared_ptr<std::vector<std::string>> called;
  {
    auto context = MockVulkanContextBuilder().Build();
    ASSERT_TRUE(context);
    called = GetMockVulkanFunctions(context->GetDevice());

    SamplerDescriptor desc;
    desc.min_filter = MinMagFilter::kLinear;
    desc.mag_filter = MinMagFilter::kLinear;
    desc.mip_filter = MipFilter::kLinear;

    sampler = std::make_shared<SamplerVK>(context->GetDeviceHolder(), desc);
    ASSERT_TRUE(sampler->GetSampler());

    conversion = context->GetYUVConversionLibrary()->GetConversion(
        YUVConversionDescriptorVK{});
    ASSERT_TRUE(conversion);
    ASSERT_TRUE(conversion->IsValid());

    context->Shutdown();
  }

  // SamplerVK must not retain DeviceHolderVK strongly, so VkDevice is already
  // destroyed.
  EXPECT_NE(std::find(called->begin(), called->end(), "vkDestroyDevice"),
            called->end());

  // Creating a conversion variant after device teardown must fail safely.
  EXPECT_EQ(sampler->CreateVariantForConversion(conversion), nullptr);

  // Destroying the sampler after device teardown must not call
  // vkDestroySampler on the dead VkDevice.
  sampler.reset();
  conversion.reset();
  EXPECT_EQ(std::find(called->begin(), called->end(), "vkDestroySampler"),
            called->end());
}

}  // namespace testing
}  // namespace impeller
