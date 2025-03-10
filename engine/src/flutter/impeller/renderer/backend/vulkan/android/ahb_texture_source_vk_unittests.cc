// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <android/hardware_buffer.h>
#include <memory>

#include "flutter/testing/testing.h"
#include "gtest/gtest.h"
#include "impeller/renderer/backend/vulkan/android/ahb_texture_source_vk.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/surface_context_vk.h"
#include "impeller/toolkit/android/hardware_buffer.h"
#include "impeller/toolkit/android/surface_transaction.h"

namespace impeller::android::testing {

// Set up context.
std::shared_ptr<Context> CreateContext() {
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

  AHardwareBuffer* buffer = nullptr;
  ASSERT_EQ(AHardwareBuffer_allocate(&desc, &buffer), 0);

  auto context_vk = CreateContext();
  ASSERT_TRUE(context_vk);

  AHBTextureSourceVK source(context_vk, buffer, desc);

  EXPECT_TRUE(source.IsValid());
  EXPECT_NE(source.GetYUVConversion(), nullptr);

  context_vk->Shutdown();
}

}  // namespace impeller::android::testing
