// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"
#include "impeller/renderer/backend/vulkan/command_pool_vk.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/test/mock_vulkan.h"

namespace impeller {
namespace testing {

TEST(ContextVKTest, DeletesCommandPools) {
  std::weak_ptr<ContextVK> weak_context;
  std::weak_ptr<CommandPoolVK> weak_pool;
  {
    std::shared_ptr<ContextVK> context = CreateMockVulkanContext();
    std::shared_ptr<CommandPoolVK> pool =
        CommandPoolVK::GetThreadLocal(context.get());
    weak_pool = pool;
    weak_context = context;
    ASSERT_TRUE(weak_pool.lock());
    ASSERT_TRUE(weak_context.lock());
  }
  ASSERT_FALSE(weak_pool.lock());
  ASSERT_FALSE(weak_context.lock());
}

}  // namespace testing
}  // namespace impeller
