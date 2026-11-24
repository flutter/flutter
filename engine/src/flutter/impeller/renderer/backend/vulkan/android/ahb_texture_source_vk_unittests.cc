// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <android/hardware_buffer.h>
#include <algorithm>
#include <memory>

#include "flutter/testing/testing.h"
#include "gtest/gtest.h"
#include "impeller/renderer/backend/vulkan/android/ahb_texture_source_vk.h"
#include "impeller/renderer/backend/vulkan/android/android_test_utils.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/shared_object_vk.h"
#include "impeller/renderer/backend/vulkan/surface_context_vk.h"
#include "impeller/renderer/backend/vulkan/test/mock_vulkan.h"
#include "impeller/renderer/backend/vulkan/texture_source_vk.h"
#include "impeller/toolkit/android/hardware_buffer.h"
#include "impeller/toolkit/android/surface_transaction.h"

namespace impeller::android::testing {

using impeller::testing::GetMockVulkanFunctions;
using impeller::testing::MockVulkanContextBuilder;

struct UniqueAHardwareBufferTraits {
  static AHardwareBuffer* InvalidValue() { return nullptr; }
  static bool IsValid(AHardwareBuffer* value) { return value != nullptr; }
  static void Free(AHardwareBuffer* value) { ::AHardwareBuffer_release(value); }
};

using UniqueAHardwareBuffer =
    fml::UniqueObject<AHardwareBuffer*, UniqueAHardwareBufferTraits>;

UniqueAHardwareBuffer AllocateAHardwareBuffer(
    const AHardwareBuffer_Desc& desc) {
  AHardwareBuffer* buffer = nullptr;
  EXPECT_EQ(AHardwareBuffer_allocate(&desc, &buffer), 0);
  return UniqueAHardwareBuffer(buffer);
}

// Set up context.
std::shared_ptr<ContextVK> CreateContext() {
  auto vulkan_dylib = fml::NativeLibrary::Create("libvulkan.so");
  auto instance_proc_addr =
      vulkan_dylib->ResolveFunction<PFN_vkGetInstanceProcAddr>(
          "vkGetInstanceProcAddr");

  if (!instance_proc_addr.has_value()) {
    VALIDATION_LOG << "Could not setup Vulkan proc table.";
    return nullptr;
  }

  impeller::ContextVK::Settings settings;
  settings.proc_address_callback = instance_proc_addr.value();
  settings.shader_libraries_data = {};
  settings.enable_validation = false;
  settings.enable_gpu_tracing = false;
  settings.enable_surface_control = false;

  return ContextVK::Create(std::move(settings));
}

TEST(AndroidVulkanTest, CanImportRGBA) {
  if (!HardwareBuffer::IsAvailableOnPlatform()) {
    GTEST_SKIP() << "Hardware buffers are not supported on this platform.";
  }

  HardwareBufferDescriptor desc;
  desc.size = ISize{1, 1};
  desc.format = HardwareBufferFormat::kR8G8B8A8UNormInt;
  desc.usage = HardwareBufferUsageFlags::kSampledImage;

  auto ahb = std::make_unique<HardwareBuffer>(desc);
  ASSERT_TRUE(ahb);
  auto context_vk = CreateContext();
  ASSERT_TRUE(context_vk);

  AHBTextureSourceVK source(context_vk, std::move(ahb),
                            /*is_swapchain_image=*/false);

  EXPECT_TRUE(source.IsValid());
  EXPECT_EQ(source.GetYUVConversion(), nullptr);

  context_vk->Shutdown();
}

TEST(AndroidVulkanTest, CanImportWithYUB) {
  if (!HardwareBuffer::IsAvailableOnPlatform()) {
    GTEST_SKIP() << "Hardware buffers are not supported on this platform.";
  }

  AHardwareBuffer_Desc desc;
  desc.width = 16;
  desc.height = 16;
  desc.format = AHARDWAREBUFFER_FORMAT_Y8Cb8Cr8_420;
  desc.stride = 0;
  desc.layers = 1;
  desc.rfu0 = 0;
  desc.rfu1 = 0;
  desc.usage = AHARDWAREBUFFER_USAGE_GPU_SAMPLED_IMAGE |
               AHARDWAREBUFFER_USAGE_CPU_WRITE_MASK |
               AHARDWAREBUFFER_USAGE_CPU_READ_MASK;

  EXPECT_EQ(AHardwareBuffer_isSupported(&desc), 1);

  UniqueAHardwareBuffer buffer = AllocateAHardwareBuffer(desc);
  ASSERT_TRUE(buffer.is_valid());

  auto context_vk = CreateContext();
  ASSERT_TRUE(context_vk);

  AHBTextureSourceVK source(context_vk, buffer.get(), desc);

  EXPECT_TRUE(source.IsValid());
  EXPECT_NE(source.GetYUVConversion(), nullptr);

  context_vk->Shutdown();
}

TEST(AndroidVulkanTest, CreateImageViewForOpaqueAlpha) {
  if (!HardwareBuffer::IsAvailableOnPlatform()) {
    GTEST_SKIP() << "Hardware buffers are not supported on this platform.";
  }

  AHardwareBuffer_Desc desc;
  desc.width = 16;
  desc.height = 16;
  desc.format = AHARDWAREBUFFER_FORMAT_R8G8B8X8_UNORM;
  desc.stride = 0;
  desc.layers = 1;
  desc.rfu0 = 0;
  desc.rfu1 = 0;
  desc.usage = AHARDWAREBUFFER_USAGE_GPU_SAMPLED_IMAGE |
               AHARDWAREBUFFER_USAGE_CPU_WRITE_MASK |
               AHARDWAREBUFFER_USAGE_CPU_READ_MASK;

  EXPECT_EQ(AHardwareBuffer_isSupported(&desc), 1);

  UniqueAHardwareBuffer buffer = AllocateAHardwareBuffer(desc);
  ASSERT_TRUE(buffer.is_valid());

  auto context_vk = CreateContext();
  ASSERT_TRUE(context_vk);

  AHBTextureSourceVK::AHBProperties ahb_props;
  ASSERT_EQ(context_vk->GetDevice().getAndroidHardwareBufferPropertiesANDROID(
                buffer.get(), &ahb_props.get()),
            vk::Result::eSuccess);

  auto image = AHBTextureSourceVK::CreateVKImageWrapperForAndroidHarwareBuffer(
      context_vk->GetDevice(), ahb_props, desc);
  ASSERT_TRUE(image);

  auto image_info = AHBTextureSourceVK::CreateImageViewInfo(
      image.get(), nullptr, ahb_props, desc);

  EXPECT_EQ(image_info.get().components.a, vk::ComponentSwizzle::eOne);

  context_vk->Shutdown();
}

TEST(AndroidVulkanTest, TextureSourceDeleteAfterContextDelete) {
  AHardwareBuffer_Desc desc;
  desc.width = 16;
  desc.height = 16;
  desc.format = AHARDWAREBUFFER_FORMAT_R8G8B8X8_UNORM;
  desc.stride = 0;
  desc.layers = 1;
  desc.rfu0 = 0;
  desc.rfu1 = 0;
  desc.usage = AHARDWAREBUFFER_USAGE_GPU_SAMPLED_IMAGE |
               AHARDWAREBUFFER_USAGE_CPU_WRITE_MASK |
               AHARDWAREBUFFER_USAGE_CPU_READ_MASK;

  EXPECT_EQ(AHardwareBuffer_isSupported(&desc), 1);

  UniqueAHardwareBuffer buffer = AllocateAHardwareBuffer(desc);
  ASSERT_TRUE(buffer.is_valid());

  auto context = MockVulkanContextBuilder()
                     .SetDeviceExtensions(kAndroidDeviceExtensions)
                     .Build();

  ASSERT_TRUE(context);

  auto texture =
      std::make_shared<AHBTextureSourceVK>(context, buffer.get(), desc);
  ASSERT_TRUE(texture->IsValid());

  // Populate cached frame data (framebuffer and render pass). Unlike allocated
  // textures, AHBTextureSourceVK does not retain DeviceHolderVK, so destroying
  // the texture after the context must not invoke vkDestroyFramebuffer or
  // vkDestroyRenderPass on the destroyed VkDevice.
  auto framebuffer =
      context->GetDevice().createFramebufferUnique(vk::FramebufferCreateInfo{});
  ASSERT_EQ(framebuffer.result, vk::Result::eSuccess);
  auto render_pass =
      context->GetDevice().createRenderPassUnique(vk::RenderPassCreateInfo{});
  ASSERT_EQ(render_pass.result, vk::Result::eSuccess);
  texture->SetCachedFrameData(
      FramebufferAndRenderPass{
          .framebuffer = MakeSharedVK(std::move(framebuffer.value),
                                      context->GetDeviceHolder()),
          .render_pass = MakeSharedVK(std::move(render_pass.value),
                                      context->GetDeviceHolder()),
      },
      SampleCount::kCount1,
      /*mip_level=*/0,
      /*slice=*/0);

  auto called = GetMockVulkanFunctions(context->GetDevice());

  // Delete the context and its VkDevice.
  context->Shutdown();
  context.reset();

  EXPECT_NE(std::find(called->begin(), called->end(), "vkDestroyDevice"),
            called->end());

  // Delete the AHBTextureSourceVK and verify that the destructor does not call
  // Vulkan APIs on a VkDevice that is no longer valid.
  texture.reset();

  EXPECT_EQ(std::find(called->begin(), called->end(), "vkDestroyFramebuffer"),
            called->end());
  EXPECT_EQ(std::find(called->begin(), called->end(), "vkDestroyRenderPass"),
            called->end());
}

}  // namespace impeller::android::testing
