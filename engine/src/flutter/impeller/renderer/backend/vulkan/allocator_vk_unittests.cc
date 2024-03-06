// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"  // IWYU pragma: keep
#include "flutter_vma/flutter_vma.h"
#include "gtest/gtest.h"
#include "impeller/core/formats.h"
#include "impeller/renderer/backend/vulkan/allocator_vk.h"
#include "third_party/vulkan-deps/vulkan-headers/src/include/vulkan/vulkan_enums.hpp"

namespace impeller {
namespace testing {

TEST(AllocatorVK, BufferCreateFlags) {
  EXPECT_EQ(AllocatorVK::ToVmaAllocationBufferCreateFlags(
                StorageMode::kDevicePrivate, /*readback=*/false),
            0u);
  EXPECT_EQ(AllocatorVK::ToVmaAllocationBufferCreateFlags(
                StorageMode::kDeviceTransient, /*readback=*/false),
            0u);
  uint32_t expected_flags =
      VMA_ALLOCATION_CREATE_HOST_ACCESS_SEQUENTIAL_WRITE_BIT |
      VMA_ALLOCATION_CREATE_MAPPED_BIT;
  EXPECT_EQ(AllocatorVK::ToVmaAllocationBufferCreateFlags(
                StorageMode::kHostVisible, /*readback=*/false),
            expected_flags);

  expected_flags = VMA_ALLOCATION_CREATE_HOST_ACCESS_RANDOM_BIT |
                   VMA_ALLOCATION_CREATE_MAPPED_BIT;
  EXPECT_EQ(AllocatorVK::ToVmaAllocationBufferCreateFlags(
                StorageMode::kHostVisible, /*readback=*/true),
            expected_flags);
}

TEST(AllocatorVK, BufferMemoryPropertyFlags) {
  EXPECT_EQ(
      AllocatorVK::ToVKBufferMemoryPropertyFlags(StorageMode::kDevicePrivate),
      vk::MemoryPropertyFlagBits::eDeviceLocal);
  EXPECT_EQ(
      AllocatorVK::ToVKBufferMemoryPropertyFlags(StorageMode::kDeviceTransient),
      vk::MemoryPropertyFlagBits::eLazilyAllocated);
  EXPECT_EQ(
      AllocatorVK::ToVKBufferMemoryPropertyFlags(StorageMode::kHostVisible),
      vk::MemoryPropertyFlagBits::eHostVisible);
}

TEST(AllocatorVK, ImageUsageFlags) {
  // Color Format
  EXPECT_EQ(AllocatorVK::ToVKImageUsageFlags(
                PixelFormat::kR8G8B8A8UNormInt,                              //
                static_cast<TextureUsageMask>(TextureUsage::kRenderTarget),  //
                StorageMode::kDevicePrivate,                                 //
                /*supports_memoryless_textures=*/true                        //
                ),
            vk::ImageUsageFlagBits::eColorAttachment |
                vk::ImageUsageFlagBits::eInputAttachment |
                vk::ImageUsageFlagBits::eTransferSrc |
                vk::ImageUsageFlagBits::eTransferDst);

  EXPECT_EQ(AllocatorVK::ToVKImageUsageFlags(
                PixelFormat::kR8G8B8A8UNormInt,                              //
                static_cast<TextureUsageMask>(TextureUsage::kRenderTarget),  //
                StorageMode::kDeviceTransient,                               //
                /*supports_memoryless_textures=*/true                        //
                ),
            vk::ImageUsageFlagBits::eColorAttachment |
                vk::ImageUsageFlagBits::eInputAttachment |
                vk::ImageUsageFlagBits::eTransientAttachment);

  // Depth+Stencil Format
  EXPECT_EQ(AllocatorVK::ToVKImageUsageFlags(
                PixelFormat::kD24UnormS8Uint,                                //
                static_cast<TextureUsageMask>(TextureUsage::kRenderTarget),  //
                StorageMode::kDevicePrivate,                                 //
                /*supports_memoryless_textures=*/true                        //
                ),
            vk::ImageUsageFlagBits::eDepthStencilAttachment |
                vk::ImageUsageFlagBits::eTransferSrc |
                vk::ImageUsageFlagBits::eTransferDst);

  EXPECT_EQ(AllocatorVK::ToVKImageUsageFlags(
                PixelFormat::kD24UnormS8Uint,                                //
                static_cast<TextureUsageMask>(TextureUsage::kRenderTarget),  //
                StorageMode::kDeviceTransient,                               //
                /*supports_memoryless_textures=*/true                        //
                ),
            vk::ImageUsageFlagBits::eDepthStencilAttachment |
                vk::ImageUsageFlagBits::eTransientAttachment);
}

TEST(AllocatorVK, TextureMemoryPropertyFlags) {
  EXPECT_EQ(
      AllocatorVK::ToVKTextureMemoryPropertyFlags(
          StorageMode::kDevicePrivate, /*supports_memoryless_textures=*/true),
      vk::MemoryPropertyFlagBits::eDeviceLocal);
}

}  // namespace testing
}  // namespace impeller