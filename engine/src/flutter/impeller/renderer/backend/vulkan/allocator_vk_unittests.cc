// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <algorithm>

#include "flutter/testing/testing.h"  // IWYU pragma: keep
#include "gtest/gtest.h"
#include "impeller/base/allocation_size.h"
#include "impeller/core/allocator.h"
#include "impeller/core/device_buffer.h"
#include "impeller/core/device_buffer_descriptor.h"
#include "impeller/core/formats.h"
#include "impeller/renderer/backend/vulkan/allocator_vk.h"
#include "impeller/renderer/backend/vulkan/device_buffer_vk.h"
#include "impeller/renderer/backend/vulkan/test/mock_vulkan.h"
#include "vulkan/vulkan_enums.hpp"

namespace impeller {
namespace testing {

TEST(AllocatorVKTest, ToVKImageUsageFlags) {
  EXPECT_EQ(AllocatorVK::ToVKImageUsageFlags(
                PixelFormat::kR8G8B8A8UNormInt,
                static_cast<TextureUsageMask>(TextureUsage::kRenderTarget),
                StorageMode::kDeviceTransient,
                /*supports_memoryless_textures=*/true),
            vk::ImageUsageFlagBits::eInputAttachment |
                vk::ImageUsageFlagBits::eColorAttachment |
                vk::ImageUsageFlagBits::eTransientAttachment);

  EXPECT_EQ(AllocatorVK::ToVKImageUsageFlags(
                PixelFormat::kD24UnormS8Uint,
                static_cast<TextureUsageMask>(TextureUsage::kRenderTarget),
                StorageMode::kDeviceTransient,
                /*supports_memoryless_textures=*/true),
            vk::ImageUsageFlagBits::eDepthStencilAttachment |
                vk::ImageUsageFlagBits::eTransientAttachment);
}

TEST(AllocatorVKTest, MemoryTypeSelectionSingleHeap) {
  vk::PhysicalDeviceMemoryProperties properties;
  properties.memoryTypeCount = 1;
  properties.memoryHeapCount = 1;
  properties.memoryTypes[0].heapIndex = 0;
  properties.memoryTypes[0].propertyFlags =
      vk::MemoryPropertyFlagBits::eDeviceLocal;
  properties.memoryHeaps[0].size = 1024 * 1024 * 1024;
  properties.memoryHeaps[0].flags = vk::MemoryHeapFlagBits::eDeviceLocal;

  EXPECT_EQ(AllocatorVK::FindMemoryTypeIndex(1, properties), 0);
  EXPECT_EQ(AllocatorVK::FindMemoryTypeIndex(2, properties), -1);
  EXPECT_EQ(AllocatorVK::FindMemoryTypeIndex(3, properties), 0);
}

TEST(AllocatorVKTest, MemoryTypeSelectionTwoHeap) {
  vk::PhysicalDeviceMemoryProperties properties;
  properties.memoryTypeCount = 2;
  properties.memoryHeapCount = 2;
  properties.memoryTypes[0].heapIndex = 0;
  properties.memoryTypes[0].propertyFlags =
      vk::MemoryPropertyFlagBits::eHostVisible;
  properties.memoryHeaps[0].size = 1024 * 1024 * 1024;
  properties.memoryHeaps[0].flags = vk::MemoryHeapFlagBits::eDeviceLocal;

  properties.memoryTypes[1].heapIndex = 1;
  properties.memoryTypes[1].propertyFlags =
      vk::MemoryPropertyFlagBits::eDeviceLocal;
  properties.memoryHeaps[1].size = 1024 * 1024 * 1024;
  properties.memoryHeaps[1].flags = vk::MemoryHeapFlagBits::eDeviceLocal;

  // First fails because this only looks for eDeviceLocal.
  EXPECT_EQ(AllocatorVK::FindMemoryTypeIndex(1, properties), -1);
  EXPECT_EQ(AllocatorVK::FindMemoryTypeIndex(2, properties), 1);
  EXPECT_EQ(AllocatorVK::FindMemoryTypeIndex(3, properties), 1);
  EXPECT_EQ(AllocatorVK::FindMemoryTypeIndex(4, properties), -1);
}

TEST(AllocatorVKTest, ImageResourceKeepsVulkanDeviceAlive) {
  std::shared_ptr<Texture> texture;
  std::weak_ptr<Allocator> weak_allocator;
  {
    auto const context = MockVulkanContextBuilder().Build();
    weak_allocator = context->GetResourceAllocator();
    auto allocator = context->GetResourceAllocator();

    texture = allocator->CreateTexture(TextureDescriptor{
        .storage_mode = StorageMode::kDevicePrivate,
        .format = PixelFormat::kR8G8B8A8UNormInt,
        .size = {1, 1},
    });
    context->Shutdown();
  }

  ASSERT_TRUE(weak_allocator.lock());
}

TEST(AllocatorVKTest, RetriesUncompressedOnCompressionExhausted) {
  // Advertise fixed-rate compression support, then force the first (compressed)
  // vkCreateImage to fail with VK_ERROR_COMPRESSION_EXHAUSTED_EXT, as the
  // PowerVR driver does when its fixed-rate-compression resources are depleted.
  auto const context =
      MockVulkanContextBuilder()
          .SetDeviceExtensions(
              {"VK_KHR_swapchain", "VK_EXT_image_compression_control"})
          .SetCompressionExhaustedCreateImageFailures(1)
          .Build();
  ASSERT_TRUE(context);
  auto allocator = context->GetResourceAllocator();
  ASSERT_TRUE(allocator);

  // A lossy (fixed-rate-compressed) render target. The first compressed
  // allocation fails with COMPRESSION_EXHAUSTED; the allocator must retry
  // without compression and still produce a valid texture instead of returning
  // null (a null render target previously crashed the raster thread).
  auto texture = allocator->CreateTexture(TextureDescriptor{
      .storage_mode = StorageMode::kDevicePrivate,
      .format = PixelFormat::kR8G8B8A8UNormInt,
      .size = {64, 64},
      .usage = TextureUsage::kRenderTarget | TextureUsage::kShaderRead,
      .compression_type = CompressionType::kLossy,
  });

  ASSERT_TRUE(texture);
  EXPECT_TRUE(texture->IsValid());

  // vkCreateImage was called twice: the compressed attempt (which failed with
  // COMPRESSION_EXHAUSTED) and the uncompressed retry (which succeeded).
  auto const called = GetMockVulkanFunctions(context->GetDevice());
  EXPECT_EQ(std::count(called->begin(), called->end(), "vkCreateImage"), 2);
}

#ifdef IMPELLER_DEBUG

TEST(AllocatorVKTest, RecreateSwapchainWhenSizeChanges) {
  auto const context = MockVulkanContextBuilder().Build();
  auto allocator = context->GetResourceAllocator();

  EXPECT_EQ(reinterpret_cast<AllocatorVK*>(allocator.get())
                ->DebugGetHeapUsage()
                .GetByteSize(),
            0u);

  allocator->CreateBuffer(DeviceBufferDescriptor{
      .storage_mode = StorageMode::kDevicePrivate,
      .size = 1024,
  });

  // Usage increases beyond the size of the allocated buffer since VMA will
  // first allocate large blocks of memory and then suballocate small memory
  // allocations.
  EXPECT_EQ(reinterpret_cast<AllocatorVK*>(allocator.get())
                ->DebugGetHeapUsage()
                .ConvertTo<MebiBytes>()
                .GetSize(),
            16u);
}

#endif  // IMPELLER_DEBUG

}  // namespace testing
}  // namespace impeller
