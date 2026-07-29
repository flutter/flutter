// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>
#include "flutter/testing/testing.h"  // IWYU pragma: keep
#include "gtest/gtest.h"
#include "impeller/core/formats.h"
#include "impeller/core/sampler_descriptor.h"
#include "impeller/renderer/backend/vulkan/command_pool_vk.h"
#include "impeller/renderer/backend/vulkan/sampler_library_vk.h"
#include "impeller/renderer/backend/vulkan/test/mock_vulkan.h"
#include "impeller/renderer/backend/vulkan/workarounds_vk.h"

namespace impeller {
namespace testing {

TEST(SamplerLibraryVK, WorkaroundsCanDisableReadingFromMipLevels) {
  auto const context = MockVulkanContextBuilder().Build();

  auto library_vk = std::make_shared<SamplerLibraryVK>(
      context->GetDeviceHolder(), /*max_sampler_anisotropy=*/1u);
  std::shared_ptr<SamplerLibrary> library = library_vk;

  SamplerDescriptor desc;
  desc.mip_filter = MipFilter::kLinear;

  auto sampler = library->GetSampler(desc);
  EXPECT_EQ(sampler->GetDescriptor().mip_filter, MipFilter::kLinear);

  // Apply mips disabled workaround.
  library_vk->ApplyWorkarounds(WorkaroundsVK{.broken_mipmap_generation = true});

  sampler = library->GetSampler(desc);
  EXPECT_EQ(sampler->GetDescriptor().mip_filter, MipFilter::kBase);
}

TEST(SamplerLibraryVK, WorkaroundsPreserveManuallyMippedSampling) {
  auto const context = MockVulkanContextBuilder().Build();

  auto library_vk = std::make_shared<SamplerLibraryVK>(
      context->GetDeviceHolder(), /*max_sampler_anisotropy=*/1u);
  std::shared_ptr<SamplerLibrary> library = library_vk;

  library_vk->ApplyWorkarounds(WorkaroundsVK{.broken_mipmap_generation = true});

  // A hand-uploaded mip chain opts out of the base-mip clamp and keeps its
  // requested filtering.
  SamplerDescriptor manual;
  manual.mip_filter = MipFilter::kLinear;
  manual.allow_manual_mip_sampling = true;
  EXPECT_EQ(library->GetSampler(manual)->GetDescriptor().mip_filter,
            MipFilter::kLinear);

  // A generated (or default) chain is still clamped to the base level, so the
  // corruption the workaround guards against stays hidden.
  SamplerDescriptor generated;
  generated.mip_filter = MipFilter::kLinear;
  EXPECT_EQ(library->GetSampler(generated)->GetDescriptor().mip_filter,
            MipFilter::kBase);
}

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

}  // namespace testing
}  // namespace impeller
