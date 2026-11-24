// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <sys/types.h>
#include <algorithm>
#include <array>
#include <cstring>
#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "flutter/fml/file.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/fml/time/time_delta.h"
#include "gtest/gtest.h"
#include "impeller/renderer/backend/vulkan/pipeline_cache_vk.h"
#include "impeller/renderer/backend/vulkan/pipeline_library_vk.h"
#include "impeller/renderer/backend/vulkan/surface_context_vk.h"
#include "impeller/renderer/backend/vulkan/test/mock_vulkan.h"
#include "impeller/renderer/pipeline_descriptor.h"
#include "impeller/renderer/surface.h"
#include "impeller/renderer/vertex_descriptor.h"

namespace impeller {
namespace testing {

namespace {
vk::UniqueSurfaceKHR CreateSurface(const ContextVK& context) {
#if FML_OS_DARWIN
  impeller::vk::MetalSurfaceCreateInfoEXT createInfo = {};
  auto [result, surface] =
      context.GetInstance().createMetalSurfaceEXTUnique(createInfo);
  FML_DCHECK(result == vk::Result::eSuccess);
  return std::move(surface);
#else
  return {};
#endif  // FML_OS_DARWIN
}
}  // namespace

TEST(SurfaceContextVK, TearsDownSwapchain) {
  SetSwapchainImageSize({100, 100});
  std::shared_ptr<ContextVK> context = MockVulkanContextBuilder().Build();

  vk::UniqueSurfaceKHR surface = CreateSurface(*context);
  SurfaceContextVK surface_context(context);

  EXPECT_TRUE(surface_context.SetWindowSurface(std::move(surface), {100, 100}));
  EXPECT_NE(surface_context.AcquireNextSurface(), nullptr);

  surface_context.TeardownSwapchain();

  EXPECT_EQ(surface_context.AcquireNextSurface(), nullptr);
}

TEST(SurfaceContextVK, ForwardsSubmissionTracker) {
  std::shared_ptr<ContextVK> context = MockVulkanContextBuilder().Build();
  SurfaceContextVK surface_context(context);

  EXPECT_NE(surface_context.GetSubmissionTracker(), nullptr);
  EXPECT_EQ(surface_context.GetSubmissionTracker(),
            context->GetSubmissionTracker());
}

TEST(SurfaceContextVK, TeardownSwapchainPersistsDirtyPipelineCache) {
  SetSwapchainImageSize({100, 100});
  fml::ScopedTemporaryDirectory temp_dir;
  fml::AutoResetWaitableEvent entered_persist;
  std::shared_ptr<ContextVK> context =
      MockVulkanContextBuilder()
          .SetSettingsCallback([&temp_dir](ContextVK::Settings& settings) {
            settings.cache_directory = fml::Duplicate(temp_dir.fd().get());
          })
          .SetGetPipelineCacheDataCallback(
              [&entered_persist](VkDevice, VkPipelineCache, size_t* data_size,
                                 void* data) -> VkResult {
                constexpr std::array<uint8_t, 4> kCacheData = {7, 8, 9, 10};
                if (!data) {
                  *data_size = kCacheData.size();
                  return VK_SUCCESS;
                }
                const size_t copy_size =
                    std::min(*data_size, kCacheData.size());
                std::memcpy(data, kCacheData.data(), copy_size);
                *data_size = copy_size;
                entered_persist.Signal();
                return VK_SUCCESS;
              })
          .Build();
  ASSERT_NE(context, nullptr);

  SurfaceContextVK surface_context(context);
  EXPECT_TRUE(
      surface_context.SetWindowSurface(CreateSurface(*context), {100, 100}));
  EXPECT_NE(surface_context.AcquireNextSurface(), nullptr);

  // Requesting a new pipeline marks the pipeline cache as dirty.
  PipelineDescriptor desc;
  desc.SetVertexDescriptor(std::make_shared<VertexDescriptor>());
  auto pipeline = surface_context.GetPipelineLibrary()
                      ->GetPipeline(desc, /*async=*/false)
                      .Get();
  ASSERT_NE(pipeline, nullptr);

  auto functions = GetMockVulkanFunctions(context->GetDevice());
  const auto count_persist_calls = [&functions]() {
    return std::count(functions->begin(), functions->end(),
                      "vkGetPipelineCacheData");
  };
  // Only 1 frame was acquired, so the periodic persist has not run yet.
  EXPECT_EQ(count_persist_calls(), 0);
  EXPECT_FALSE(fml::FileExists(temp_dir.fd(), "flutter.impeller.vkcache"));

  surface_context.TeardownSwapchain();
  // Wait for the persist that TeardownSwapchain posted to the worker thread.
  ASSERT_FALSE(
      entered_persist.WaitWithTimeout(fml::TimeDelta::FromSeconds(30)));
  // Persists are serialized, so this blocks until the background persist has
  // finished writing to disk.
  PipelineLibraryVK::Cast(*context->GetPipelineLibrary())
      .GetPSOCache()
      ->PersistCacheToDisk();

  EXPECT_TRUE(fml::FileExists(temp_dir.fd(), "flutter.impeller.vkcache"));
  // A size query and a data copy each for the teardown persist and the
  // synchronizing persist above.
  EXPECT_EQ(count_persist_calls(), 4);
  surface_context.Shutdown();
}

}  // namespace testing
}  // namespace impeller
