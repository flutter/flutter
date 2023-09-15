// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>

#include "flutter/testing/testing.h"
#include "impeller/core/allocator.h"
#include "impeller/core/texture_descriptor.h"
#include "impeller/entity/render_target_cache.h"
#include "impeller/renderer/testing/mocks.h"

namespace impeller {
namespace testing {

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
      const TextureDescriptor& desc) override {
    if (should_fail) {
      return nullptr;
    }
    return std::make_shared<MockTexture>(desc);
  };

  bool should_fail = false;
};

TEST(RenderTargetCacheTest, CachesUsedTexturesAcrossFrames) {
  auto allocator = std::make_shared<TestAllocator>();
  auto render_target_cache = RenderTargetCache(allocator);
  auto desc = TextureDescriptor{
      .format = PixelFormat::kR8G8B8A8UNormInt,
      .size = ISize(100, 100),
      .usage = static_cast<TextureUsageMask>(TextureUsage::kRenderTarget)};

  render_target_cache.Start();
  // Create two textures of the same exact size/shape. Both should be marked
  // as used this frame, so the cached data set will contain two.
  render_target_cache.CreateTexture(desc);
  render_target_cache.CreateTexture(desc);

  ASSERT_EQ(render_target_cache.CachedTextureCount(), 2u);

  render_target_cache.End();
  render_target_cache.Start();

  // Next frame, only create one texture. The set will still contain two,
  // but one will be removed at the end of the frame.
  render_target_cache.CreateTexture(desc);
  ASSERT_EQ(render_target_cache.CachedTextureCount(), 2u);

  render_target_cache.End();
  ASSERT_EQ(render_target_cache.CachedTextureCount(), 1u);
}

TEST(RenderTargetCacheTest, DoesNotPersistFailedAllocations) {
  auto allocator = std::make_shared<TestAllocator>();
  auto render_target_cache = RenderTargetCache(allocator);
  auto desc = TextureDescriptor{
      .format = PixelFormat::kR8G8B8A8UNormInt,
      .size = ISize(100, 100),
      .usage = static_cast<TextureUsageMask>(TextureUsage::kRenderTarget)};

  render_target_cache.Start();
  allocator->should_fail = true;

  ASSERT_EQ(render_target_cache.CreateTexture(desc), nullptr);
  ASSERT_EQ(render_target_cache.CachedTextureCount(), 0u);
}

}  // namespace testing
}  // namespace impeller
