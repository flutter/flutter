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
#include "impeller/renderer/backend/vulkan/shared_object_vk.h"
#include "impeller/renderer/backend/vulkan/test/mock_vulkan.h"
#include "impeller/renderer/backend/vulkan/texture_vk.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/render_target.h"
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

TEST(AllocatorVKTest, ShutdownReleasesDeviceAndInvalidatesResources) {
  std::shared_ptr<Texture> texture;
  std::shared_ptr<DeviceBuffer> buffer;
  std::weak_ptr<Allocator> weak_allocator;
  std::weak_ptr<DeviceHolderVK> weak_device_holder;
  std::shared_ptr<std::vector<std::string>> called;
  {
    auto const context = MockVulkanContextBuilder().Build();
    ASSERT_TRUE(context);
    called = GetMockVulkanFunctions(context->GetDevice());
    weak_allocator = context->GetResourceAllocator();
    weak_device_holder = context->GetDeviceHolder();
    auto allocator = context->GetResourceAllocator();

    texture = allocator->CreateTexture(TextureDescriptor{
        .storage_mode = StorageMode::kDevicePrivate,
        .format = PixelFormat::kR8G8B8A8UNormInt,
        .size = {64, 64},
        .usage = TextureUsage::kRenderTarget | TextureUsage::kShaderRead,
    });
    ASSERT_TRUE(texture);

    buffer = allocator->CreateBuffer(DeviceBufferDescriptor{
        .storage_mode = StorageMode::kHostVisible,
        .size = 64,
    });
    ASSERT_TRUE(buffer);
    EXPECT_NE(buffer->OnGetContents(), nullptr);
    uint8_t init_byte = 7;
    EXPECT_TRUE(buffer->CopyHostBuffer(&init_byte, Range{0, 1}));

    {
      RenderTarget render_target;
      ColorAttachment color0;
      color0.texture = texture;
      render_target.SetColorAttachment(color0, 0);

      auto cmd_buffer = context->CreateCommandBuffer();
      ASSERT_TRUE(cmd_buffer);
      auto render_pass = cmd_buffer->CreateRenderPass(render_target);
      ASSERT_TRUE(render_pass);
      render_pass->EncodeCommands();
    }

    context->Shutdown();
  }

  // ~ContextVK() must invalidate all tracked textures and buffers so that
  // surviving handles do not keep AllocatorVK or DeviceHolderVK alive.
  EXPECT_TRUE(weak_allocator.expired());
  EXPECT_TRUE(weak_device_holder.expired());

  auto destroy_fb =
      std::find(called->begin(), called->end(), "vkDestroyFramebuffer");
  auto destroy_rp =
      std::find(called->begin(), called->end(), "vkDestroyRenderPass");
  auto destroy_image_view =
      std::find(called->begin(), called->end(), "vkDestroyImageView");
  auto destroy_image =
      std::find(called->begin(), called->end(), "vkDestroyImage");
  auto destroy_buffer =
      std::find(called->begin(), called->end(), "vkDestroyBuffer");
  auto destroy_device =
      std::find(called->begin(), called->end(), "vkDestroyDevice");
  EXPECT_NE(destroy_fb, called->end());
  EXPECT_NE(destroy_rp, called->end());
  EXPECT_NE(destroy_image_view, called->end());
  EXPECT_NE(destroy_image, called->end());
  EXPECT_NE(destroy_buffer, called->end());
  EXPECT_NE(destroy_device, called->end());
  EXPECT_LT(destroy_fb, destroy_device);
  EXPECT_LT(destroy_rp, destroy_device);
  EXPECT_LT(destroy_image_view, destroy_device);
  EXPECT_LT(destroy_image, destroy_device);
  EXPECT_LT(destroy_buffer, destroy_device);
  EXPECT_EQ(std::find(destroy_device, called->end(), "vkDestroyFramebuffer"),
            called->end());
  EXPECT_EQ(std::find(destroy_device, called->end(), "vkDestroyRenderPass"),
            called->end());
  EXPECT_EQ(std::find(destroy_device, called->end(), "vkDestroyImageView"),
            called->end());
  EXPECT_EQ(std::find(destroy_device, called->end(), "vkDestroyImage"),
            called->end());
  EXPECT_EQ(std::find(destroy_device, called->end(), "vkDestroyBuffer"),
            called->end());

  // Post-shutdown access on invalidated handles must degrade to safe no-ops.
  EXPECT_FALSE(texture->IsValid());
  const auto& texture_vk = TextureVK::Cast(*texture);
  EXPECT_EQ(texture_vk.GetImage(), vk::Image{});
  EXPECT_EQ(texture_vk.GetImageView(), vk::ImageView{});
  EXPECT_EQ(texture_vk.GetRenderTargetView(), vk::ImageView{});

  const auto& buffer_vk = DeviceBufferVK::Cast(*buffer);
  EXPECT_EQ(buffer_vk.GetBuffer(), vk::Buffer{});
  EXPECT_EQ(buffer->OnGetContents(), nullptr);
  uint8_t byte = 42;
  EXPECT_FALSE(buffer->CopyHostBuffer(&byte, Range{0, 1}));
  buffer->Flush();
  buffer->Invalidate();

  const size_t calls_before_reset = called->size();
  texture.reset();
  buffer.reset();
  EXPECT_EQ(called->size(), calls_before_reset);
}

TEST(AllocatorVKTest, DestroyingContextWithoutShutdownInvalidatesResources) {
  std::shared_ptr<Texture> texture;
  std::shared_ptr<DeviceBuffer> buffer;
  std::weak_ptr<Allocator> weak_allocator;
  std::weak_ptr<DeviceHolderVK> weak_device_holder;
  std::shared_ptr<std::vector<std::string>> called;
  {
    auto const context = MockVulkanContextBuilder().Build();
    ASSERT_TRUE(context);
    called = GetMockVulkanFunctions(context->GetDevice());
    weak_allocator = context->GetResourceAllocator();
    weak_device_holder = context->GetDeviceHolder();

    texture = context->GetResourceAllocator()->CreateTexture(TextureDescriptor{
        .storage_mode = StorageMode::kDevicePrivate,
        .format = PixelFormat::kR8G8B8A8UNormInt,
        .size = {1, 1},
    });
    buffer =
        context->GetResourceAllocator()->CreateBuffer(DeviceBufferDescriptor{
            .storage_mode = StorageMode::kDevicePrivate,
            .size = 64,
        });
    ASSERT_TRUE(texture);
    ASSERT_TRUE(buffer);
    // Intentionally omit context->Shutdown().
  }

  EXPECT_TRUE(weak_allocator.expired());
  EXPECT_TRUE(weak_device_holder.expired());

  auto destroy_image =
      std::find(called->begin(), called->end(), "vkDestroyImage");
  auto destroy_buffer =
      std::find(called->begin(), called->end(), "vkDestroyBuffer");
  auto destroy_device =
      std::find(called->begin(), called->end(), "vkDestroyDevice");
  EXPECT_NE(destroy_image, called->end());
  EXPECT_NE(destroy_buffer, called->end());
  EXPECT_NE(destroy_device, called->end());
  EXPECT_LT(destroy_image, destroy_device);
  EXPECT_LT(destroy_buffer, destroy_device);

  texture.reset();
  buffer.reset();
}

TEST(AllocatorVKTest, PostShutdownAllocatorReturnsNull) {
  std::shared_ptr<Allocator> allocator;
  {
    auto const context = MockVulkanContextBuilder().Build();
    ASSERT_TRUE(context);
    allocator = context->GetResourceAllocator();
    context->Shutdown();
  }

  EXPECT_EQ(allocator->CreateTexture(TextureDescriptor{
                .storage_mode = StorageMode::kDevicePrivate,
                .format = PixelFormat::kR8G8B8A8UNormInt,
                .size = {1, 1},
            }),
            nullptr);
  EXPECT_EQ(allocator->CreateBuffer(DeviceBufferDescriptor{
                .storage_mode = StorageMode::kDevicePrivate,
                .size = 64,
            }),
            nullptr);
  EXPECT_EQ(allocator->DebugGetHeapUsage().GetByteSize(), 0u);
}

TEST(AllocatorVKTest, ExternalAllocatorSurvivingContextWithoutShutdown) {
  std::shared_ptr<Allocator> allocator;
  std::shared_ptr<Texture> texture;
  std::shared_ptr<DeviceBuffer> buffer;
  std::weak_ptr<DeviceHolderVK> weak_device_holder;
  std::shared_ptr<std::vector<std::string>> called;
  {
    auto const context = MockVulkanContextBuilder().Build();
    ASSERT_TRUE(context);
    called = GetMockVulkanFunctions(context->GetDevice());
    weak_device_holder = context->GetDeviceHolder();
    allocator = context->GetResourceAllocator();

    texture = allocator->CreateTexture(TextureDescriptor{
        .storage_mode = StorageMode::kDevicePrivate,
        .format = PixelFormat::kR8G8B8A8UNormInt,
        .size = {1, 1},
    });
    buffer = allocator->CreateBuffer(DeviceBufferDescriptor{
        .storage_mode = StorageMode::kDevicePrivate,
        .size = 64,
    });
    ASSERT_TRUE(texture);
    ASSERT_TRUE(buffer);
    // Intentionally omit context->Shutdown() while holding |allocator|.
  }

  EXPECT_TRUE(weak_device_holder.expired());
  EXPECT_FALSE(texture->IsValid());
  auto destroy_device =
      std::find(called->begin(), called->end(), "vkDestroyDevice");
  EXPECT_NE(destroy_device, called->end());
  EXPECT_EQ(std::find(destroy_device, called->end(), "vkDestroyImage"),
            called->end());
  EXPECT_EQ(std::find(destroy_device, called->end(), "vkDestroyBuffer"),
            called->end());

  EXPECT_EQ(allocator->CreateTexture(TextureDescriptor{
                .storage_mode = StorageMode::kDevicePrivate,
                .format = PixelFormat::kR8G8B8A8UNormInt,
                .size = {1, 1},
            }),
            nullptr);
  EXPECT_EQ(allocator->CreateBuffer(DeviceBufferDescriptor{
                .storage_mode = StorageMode::kDevicePrivate,
                .size = 64,
            }),
            nullptr);
  EXPECT_EQ(allocator->DebugGetHeapUsage().GetByteSize(), 0u);

  const size_t calls_before_reset = called->size();
  texture.reset();
  buffer.reset();
  allocator.reset();
  EXPECT_EQ(called->size(), calls_before_reset);
}

TEST(AllocatorVKTest, DoubleShutdownIsSafe) {
  auto const context = MockVulkanContextBuilder().Build();
  ASSERT_TRUE(context);
  auto texture =
      context->GetResourceAllocator()->CreateTexture(TextureDescriptor{
          .storage_mode = StorageMode::kDevicePrivate,
          .format = PixelFormat::kR8G8B8A8UNormInt,
          .size = {1, 1},
      });
  ASSERT_TRUE(texture);
  context->Shutdown();
  context->Shutdown();
}

TEST(AllocatorVKTest, ShutdownWithPinnedContextKeepsResourcesValid) {
  auto context = MockVulkanContextBuilder().Build();
  ASSERT_TRUE(context);
  auto texture =
      context->GetResourceAllocator()->CreateTexture(TextureDescriptor{
          .storage_mode = StorageMode::kDevicePrivate,
          .format = PixelFormat::kR8G8B8A8UNormInt,
          .size = {1, 1},
      });
  auto buffer =
      context->GetResourceAllocator()->CreateBuffer(DeviceBufferDescriptor{
          .storage_mode = StorageMode::kHostVisible,
          .size = 64,
      });
  ASSERT_TRUE(texture);
  ASSERT_TRUE(buffer);

  // Calling Shutdown() while a strong ContextVK reference (such as an
  // in-flight ImageDecoderImpeller task) is still alive must not unmap host
  // buffers or invalidate VMA handles prematurely.
  context->Shutdown();
  EXPECT_TRUE(texture->IsValid());
  EXPECT_NE(buffer->OnGetContents(), nullptr);
  uint8_t byte = 9;
  EXPECT_TRUE(buffer->CopyHostBuffer(&byte, Range{0, 1}));

  // Once the last ContextVK reference drops, ~ContextVK() sweeps everything.
  context.reset();
  EXPECT_FALSE(texture->IsValid());
  EXPECT_EQ(buffer->OnGetContents(), nullptr);
  EXPECT_FALSE(buffer->CopyHostBuffer(&byte, Range{0, 1}));
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

TEST(AllocatorVKTest,
     AllocatedTextureSourceClearsFrameDataBeforeDeviceIsDestroyed) {
  std::shared_ptr<Texture> texture;
  std::shared_ptr<std::vector<std::string>> called;
  {
    auto context = MockVulkanContextBuilder().Build();
    ASSERT_TRUE(context);
    called = GetMockVulkanFunctions(context->GetDevice());

    texture = context->GetResourceAllocator()->CreateTexture(TextureDescriptor{
        .storage_mode = StorageMode::kDevicePrivate,
        .format = PixelFormat::kR8G8B8A8UNormInt,
        .size = {64, 64},
        .usage = TextureUsage::kRenderTarget | TextureUsage::kShaderRead,
    });
    ASSERT_TRUE(texture);

    {
      RenderTarget render_target;
      ColorAttachment color0;
      color0.texture = texture;
      render_target.SetColorAttachment(color0, 0);

      auto cmd_buffer = context->CreateCommandBuffer();
      ASSERT_TRUE(cmd_buffer);
      auto render_pass = cmd_buffer->CreateRenderPass(render_target);
      ASSERT_TRUE(render_pass);
      render_pass->EncodeCommands();
    }

    context->Shutdown();
  }

  // ~ContextVK() sweeps tracked textures and clears their cached frame_data_
  // before the VkDevice is destroyed, so dropping |texture| afterward is a
  // safe no-op.
  auto destroy_fb =
      std::find(called->begin(), called->end(), "vkDestroyFramebuffer");
  auto destroy_rp =
      std::find(called->begin(), called->end(), "vkDestroyRenderPass");
  auto destroy_device =
      std::find(called->begin(), called->end(), "vkDestroyDevice");
  EXPECT_NE(destroy_fb, called->end());
  EXPECT_NE(destroy_rp, called->end());
  EXPECT_NE(destroy_device, called->end());
  EXPECT_LT(destroy_fb, destroy_device);
  EXPECT_LT(destroy_rp, destroy_device);

  const size_t calls_before_reset = called->size();
  texture.reset();
  EXPECT_EQ(called->size(), calls_before_reset);
}

TEST(AllocatorVKTest, SharedObjectReleasesHandleAfterDeviceIsDestroyed) {
  SharedHandleVK<vk::Framebuffer> shared_framebuffer;
  std::shared_ptr<std::vector<std::string>> called;
  {
    auto context = MockVulkanContextBuilder().Build();
    ASSERT_TRUE(context);
    called = GetMockVulkanFunctions(context->GetDevice());

    auto framebuffer = context->GetDevice().createFramebufferUnique(
        vk::FramebufferCreateInfo{});
    ASSERT_EQ(framebuffer.result, vk::Result::eSuccess);
    shared_framebuffer =
        MakeSharedVK(std::move(framebuffer.value), context->GetDeviceHolder());
    ASSERT_TRUE(shared_framebuffer);

    context->Shutdown();
  }

  // The context and its VkDevice must already be destroyed (SharedObjectVKT
  // must not retain DeviceHolderVK strongly).
  EXPECT_NE(std::find(called->begin(), called->end(), "vkDestroyDevice"),
            called->end());

  // Releasing the shared handle must not call vkDestroyFramebuffer on the dead
  // VkDevice.
  shared_framebuffer.reset();
  EXPECT_EQ(std::find(called->begin(), called->end(), "vkDestroyFramebuffer"),
            called->end());
}

}  // namespace testing
}  // namespace impeller
