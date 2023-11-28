// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"  // IWYU pragma: keep.
#include "fml/synchronization/waitable_event.h"
#include "impeller/renderer/backend/vulkan/descriptor_pool_vk.h"
#include "impeller/renderer/backend/vulkan/resource_manager_vk.h"
#include "impeller/renderer/backend/vulkan/test/mock_vulkan.h"

namespace impeller {
namespace testing {

TEST(DescriptorPoolRecyclerVKTest, GetDescriptorPoolRecyclerCreatesNewPools) {
  auto const context = MockVulkanContextBuilder().Build();

  auto const [pool1, _] = context->GetDescriptorPoolRecycler()->Get(1024);
  auto const [pool2, __] = context->GetDescriptorPoolRecycler()->Get(1024);

  // The two descriptor pools should be different.
  EXPECT_NE(pool1.get(), pool2.get());

  context->Shutdown();
}

TEST(DescriptorPoolRecyclerVKTest, DescriptorPoolCapacityIsRoundedUp) {
  auto const context = MockVulkanContextBuilder().Build();
  auto const [pool1, capacity] = context->GetDescriptorPoolRecycler()->Get(1);

  // Rounds up to a minimum of 64.
  EXPECT_EQ(capacity, 64u);

  auto const [pool2, capacity_2] =
      context->GetDescriptorPoolRecycler()->Get(1023);

  // Rounds up to the next power of two.
  EXPECT_EQ(capacity_2, 1024u);

  context->Shutdown();
}

namespace {

// Invokes the provided callback when the destructor is called.
//
// Can be moved, but not copied.
class DeathRattle final {
 public:
  explicit DeathRattle(std::function<void()> callback)
      : callback_(std::move(callback)) {}

  DeathRattle(DeathRattle&&) = default;
  DeathRattle& operator=(DeathRattle&&) = default;

  ~DeathRattle() { callback_(); }

 private:
  std::function<void()> callback_;
};

}  // namespace

TEST(DescriptorPoolRecyclerVKTest, ReclaimMakesDescriptorPoolAvailable) {
  auto const context = MockVulkanContextBuilder().Build();

  {
    // Fetch a pool (which will be created).
    auto pool = DescriptorPoolVK(context);
    pool.AllocateDescriptorSets(1024, 1024, {});
  }

  // Add something to the resource manager and have it notify us when it's
  // destroyed. That should give us a non-flaky signal that the pool has been
  // reclaimed as well.
  auto waiter = fml::AutoResetWaitableEvent();
  auto rattle = DeathRattle([&waiter]() { waiter.Signal(); });
  {
    UniqueResourceVKT<DeathRattle> resource(context->GetResourceManager(),
                                            std::move(rattle));
  }
  waiter.Wait();

  auto const [pool, _] = context->GetDescriptorPoolRecycler()->Get(1024);

  // Now check that we only ever created one pool.
  auto const called = GetMockVulkanFunctions(context->GetDevice());
  EXPECT_EQ(
      std::count(called->begin(), called->end(), "vkCreateDescriptorPool"), 1u);

  context->Shutdown();
}

}  // namespace testing
}  // namespace impeller
