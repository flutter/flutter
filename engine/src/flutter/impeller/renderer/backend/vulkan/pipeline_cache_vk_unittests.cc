// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <algorithm>
#include <memory>
#include <string>
#include <vector>

#include "flutter/fml/file.h"
#include "flutter/testing/testing.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/pipeline_cache_vk.h"
#include "impeller/renderer/backend/vulkan/pipeline_library_vk.h"
#include "impeller/renderer/backend/vulkan/test/mock_vulkan.h"

namespace impeller {
namespace testing {

TEST(PipelineCacheVKTest, PersistCacheToDiskIsSafeAfterDeviceDestruction) {
  fml::ScopedTemporaryDirectory temp_dir;
  std::shared_ptr<PipelineCacheVK> pso_cache;
  std::shared_ptr<std::vector<std::string>> functions;
  {
    std::shared_ptr<ContextVK> context =
        MockVulkanContextBuilder()
            .SetSettingsCallback([&temp_dir](ContextVK::Settings& settings) {
              settings.cache_directory = fml::Duplicate(temp_dir.fd().get());
            })
            .Build();
    ASSERT_NE(context, nullptr);
    pso_cache =
        PipelineLibraryVK::Cast(*context->GetPipelineLibrary()).GetPSOCache();
    ASSERT_NE(pso_cache, nullptr);
    functions = GetMockVulkanFunctions(context->GetDevice());
    context->Shutdown();
  }

  // The cache outlives the context (as it can while a persist task is running
  // on a worker thread), so the device has already been destroyed.
  ASSERT_EQ(std::count(functions->begin(), functions->end(), "vkDestroyDevice"),
            1);
  pso_cache->PersistCacheToDisk();
  EXPECT_EQ(std::count(functions->begin(), functions->end(),
                       "vkGetPipelineCacheData"),
            0);
  EXPECT_FALSE(fml::FileExists(temp_dir.fd(), "flutter.impeller.vkcache"));
}

}  // namespace testing
}  // namespace impeller
