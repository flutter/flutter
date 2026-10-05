// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>

#include "flutter/testing/testing.h"
#include "impeller/base/validation.h"
#include "impeller/core/allocator.h"
#include "impeller/core/formats.h"
#include "impeller/core/texture_descriptor.h"
#include "impeller/entity/entity_playground.h"
#include "impeller/entity/render_target_cache.h"
#include "impeller/playground/playground_test.h"
#include "impeller/renderer/testing/mocks.h"

namespace impeller {
namespace testing {

using RenderTargetCacheTest = EntityPlayground;
INSTANTIATE_PLAYGROUND_SUITE(RenderTargetCacheTest);

class TestAllocator : public Allocator {
 public:
  TestAllocator() = default;

  ~TestAllocator() = default;

  ISize GetMaxTextureSizeSupported() const override {
    return ISize(1024, 1024);
  };

  std::shared_ptr<DeviceBuffer> OnCreateBuffer(
      const DeviceBufferDescriptor& desc) override {
    if (should_fail) {
      return nullptr;
    }
    return std::make_shared<MockDeviceBuffer>(desc);
  };

  virtual std::shared_ptr<Texture> OnCreateTexture(
      const TextureDescriptor& desc,
      bool threadsafe) override {
    if (should_fail) {
      return nullptr;
    }
    return std::make_shared<MockTexture>(desc);
  };

  bool should_fail = false;
};

TEST_P(RenderTargetCacheTest, CachesUsedTexturesAcrossFrames) {
  auto render_target_cache = RenderTargetCache(
      GetContext()->GetResourceAllocator(), /*keep_alive_frame_count=*/0);

  render_target_cache.Start();
  // Create two render targets of the same exact size/shape. Both should be
  // marked as used this frame, so the cached data set will contain two.
  render_target_cache.CreateOffscreen(*GetContext(), {100, 100}, 1);
  render_target_cache.CreateOffscreen(*GetContext(), {100, 100}, 1);

  EXPECT_EQ(render_target_cache.CachedTextureCount(), 2u);

  render_target_cache.End();
  render_target_cache.Start();

  // Next frame, only create one texture. The set will still contain two,
  // but one will be removed at the end of the frame.
  render_target_cache.CreateOffscreen(*GetContext(), {100, 100}, 1);
  EXPECT_EQ(render_target_cache.CachedTextureCount(), 2u);

  render_target_cache.End();
  EXPECT_EQ(render_target_cache.CachedTextureCount(), 1u);
}

TEST_P(RenderTargetCacheTest, CachesUsedTexturesAcrossFramesWithKeepAlive) {
  auto render_target_cache = RenderTargetCache(
      GetContext()->GetResourceAllocator(), /*keep_alive_frame_count=*/3);

  render_target_cache.Start();
  // Create two render targets of the same exact size/shape. Both should be
  // marked as used this frame, so the cached data set will contain two.
  render_target_cache.CreateOffscreen(*GetContext(), {100, 100}, 1);
  render_target_cache.CreateOffscreen(*GetContext(), {100, 100}, 1);

  EXPECT_EQ(render_target_cache.CachedTextureCount(), 2u);

  render_target_cache.End();
  render_target_cache.Start();

  // The unused texture is kept alive until the keep alive countdown
  // reaches 0.
  EXPECT_EQ(render_target_cache.CachedTextureCount(), 2u);

  for (auto i = 0; i < 3; i++) {
    render_target_cache.Start();
    render_target_cache.End();
    EXPECT_EQ(render_target_cache.CachedTextureCount(), 2u);
  }
  // After the countdown has elapsed the texture is removed.
  render_target_cache.Start();
  render_target_cache.End();
  EXPECT_EQ(render_target_cache.CachedTextureCount(), 0u);
}

TEST_P(RenderTargetCacheTest, DoesNotPersistFailedAllocations) {
  ScopedValidationDisable disable;
  auto allocator = std::make_shared<TestAllocator>();
  auto render_target_cache =
      RenderTargetCache(allocator, /*keep_alive_frame_count=*/0);

  render_target_cache.Start();
  allocator->should_fail = true;

  auto render_target =
      render_target_cache.CreateOffscreen(*GetContext(), {100, 100}, 1);

  EXPECT_FALSE(render_target.IsValid());
  EXPECT_EQ(render_target_cache.CachedTextureCount(), 0u);
}

TEST_P(RenderTargetCacheTest, CachedTextureGetsNewAttachmentConfig) {
  auto render_target_cache = RenderTargetCache(
      GetContext()->GetResourceAllocator(), /*keep_alive_frame_count=*/0);

  render_target_cache.Start();
  RenderTarget::AttachmentConfig color_attachment_config =
      RenderTarget::kDefaultColorAttachmentConfig;
  RenderTarget target1 = render_target_cache.CreateOffscreen(
      *GetContext(), {100, 100}, 1, "Offscreen1", color_attachment_config);
  render_target_cache.End();

  render_target_cache.Start();
  color_attachment_config.clear_color = Color::Red();
  RenderTarget target2 = render_target_cache.CreateOffscreen(
      *GetContext(), {100, 100}, 1, "Offscreen2", color_attachment_config);
  render_target_cache.End();

  ColorAttachment color1 = target1.GetColorAttachment(0);
  ColorAttachment color2 = target2.GetColorAttachment(0);
  // The second color attachment should reuse the first attachment's texture
  // but with attributes from the second AttachmentConfig.
  EXPECT_EQ(color2.texture, color1.texture);
  EXPECT_EQ(color2.clear_color, Color::Red());
}

TEST_P(RenderTargetCacheTest, CreateWithEmptySize) {
  auto render_target_cache = RenderTargetCache(
      GetContext()->GetResourceAllocator(), /*keep_alive_frame_count=*/0);

  render_target_cache.Start();
  RenderTarget empty_target =
      render_target_cache.CreateOffscreen(*GetContext(), {100, 0}, 1);
  RenderTarget empty_target_msaa =
      render_target_cache.CreateOffscreenMSAA(*GetContext(), {0, 0}, 1);
  render_target_cache.End();

  {
    ScopedValidationDisable disable_validation;
    EXPECT_FALSE(empty_target.IsValid());
    EXPECT_FALSE(empty_target_msaa.IsValid());
  }
}

TEST_P(RenderTargetCacheTest, EvictsIdleRenderTargetsOverBudget) {
  auto render_target_cache =
      RenderTargetCache(GetContext()->GetResourceAllocator(),
                        /*keep_alive_frame_count=*/4,
                        /*cache_budget_bytes=*/1);

  render_target_cache.Start();
  render_target_cache.CreateOffscreen(*GetContext(), {100, 100}, 1);
  render_target_cache.End();

  // The render target was used this frame, so it is retained even though the
  // cache is over budget.
  EXPECT_EQ(render_target_cache.CachedTextureCount(), 1u);

  render_target_cache.Start();
  render_target_cache.End();

  // Now that it is idle it is released, despite the keep alive count not
  // having elapsed.
  EXPECT_EQ(render_target_cache.CachedTextureCount(), 0u);
}

TEST_P(RenderTargetCacheTest, EvictsLeastRecentlyUsedRenderTargetFirst) {
  // Measure a single render target so the budget can be expressed in terms of
  // how many render targets fit within it.
  size_t single_target_bytes = 0u;
  {
    auto probe = RenderTargetCache(GetContext()->GetResourceAllocator());
    probe.Start();
    probe.CreateOffscreen(*GetContext(), {100, 100}, 1);
    probe.End();
    single_target_bytes = probe.CachedTextureBytes();
    ASSERT_GT(single_target_bytes, 0u);
  }

  // A budget with room for one of the two render targets.
  auto render_target_cache =
      RenderTargetCache(GetContext()->GetResourceAllocator(),
                        /*keep_alive_frame_count=*/4,
                        /*cache_budget_bytes=*/single_target_bytes);

  render_target_cache.Start();
  RenderTarget first =
      render_target_cache.CreateOffscreen(*GetContext(), {100, 100}, 1);
  RenderTarget second =
      render_target_cache.CreateOffscreen(*GetContext(), {100, 100}, 1);
  render_target_cache.End();
  EXPECT_EQ(render_target_cache.CachedTextureCount(), 2u);

  // Reuse the first render target, making the second one the least recently
  // used.
  render_target_cache.Start();
  RenderTarget reused =
      render_target_cache.CreateOffscreen(*GetContext(), {100, 100}, 1);
  EXPECT_EQ(reused.GetColorAttachment(0).texture,
            first.GetColorAttachment(0).texture);
  render_target_cache.End();

  // The least recently used render target is evicted to fit the budget, and
  // the one used this frame is kept.
  ASSERT_EQ(render_target_cache.CachedTextureCount(), 1u);
  EXPECT_EQ(render_target_cache.GetRenderTargetDataBegin()
                ->render_target.GetColorAttachment(0)
                .texture,
            first.GetColorAttachment(0).texture);
  EXPECT_NE(render_target_cache.GetRenderTargetDataBegin()
                ->render_target.GetColorAttachment(0)
                .texture,
            second.GetColorAttachment(0).texture);
}

TEST_P(RenderTargetCacheTest, DerivedBudgetScalesWithLargestRenderTarget) {
  auto render_target_cache =
      RenderTargetCache(GetContext()->GetResourceAllocator());

  // With nothing allocated the budget is the minimum.
  EXPECT_EQ(render_target_cache.GetCacheBudgetBytes(),
            RenderTargetCache::kMinimumCacheBudgetBytes);

  render_target_cache.Start();
  render_target_cache.CreateOffscreen(*GetContext(), {2048, 2048}, 1);
  render_target_cache.End();

  // A render target larger than the minimum budget scales it up.
  ASSERT_GT(render_target_cache.CachedTextureBytes(),
            RenderTargetCache::kMinimumCacheBudgetBytes);
  EXPECT_EQ(render_target_cache.GetCacheBudgetBytes(),
            RenderTargetCache::kCacheBudgetMultiplier *
                render_target_cache.CachedTextureBytes());
}

TEST_P(RenderTargetCacheTest, SmallRenderTargetsAreNotEvictedByDerivedBudget) {
  auto render_target_cache =
      RenderTargetCache(GetContext()->GetResourceAllocator());

  render_target_cache.Start();
  render_target_cache.CreateOffscreen(*GetContext(), {100, 100}, 1);
  render_target_cache.CreateOffscreen(*GetContext(), {100, 100}, 1);
  render_target_cache.End();

  // These fit well within the minimum budget, so the keep alive count remains
  // the only thing governing their lifetime.
  ASSERT_LT(render_target_cache.CachedTextureBytes(),
            RenderTargetCache::kMinimumCacheBudgetBytes);
  render_target_cache.Start();
  render_target_cache.End();
  EXPECT_EQ(render_target_cache.CachedTextureCount(), 2u);
}

}  // namespace testing
}  // namespace impeller
