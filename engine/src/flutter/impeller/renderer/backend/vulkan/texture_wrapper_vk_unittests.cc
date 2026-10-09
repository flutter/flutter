// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"
#include "impeller/core/formats.h"
#include "impeller/core/texture_descriptor.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/test/mock_vulkan.h"
#include "impeller/renderer/backend/vulkan/texture_vk.h"
#include "impeller/renderer/backend/vulkan/texture_wrapper_vk.h"

namespace impeller {
namespace testing {

TEST(TextureWrapperVKTest, WrapTextureSuccessAndDestructionProc) {
  std::shared_ptr<ContextVK> context = MockVulkanContextBuilder().Build();
  ASSERT_TRUE(context);

  TextureDescriptor desc;
  desc.format = PixelFormat::kR8G8B8A8UNormInt;
  desc.size = ISize{100, 100};
  desc.storage_mode = StorageMode::kDevicePrivate;
  desc.usage = TextureUsage::kRenderTarget;

  bool destroyed = false;
  vk::Image raw_image(reinterpret_cast<VkImage>(0x12345));

  {
    auto texture = WrapTextureVK(context, desc, raw_image,
                                 [&destroyed]() { destroyed = true; });
    ASSERT_NE(texture, nullptr);
    EXPECT_EQ(texture->GetTextureDescriptor().size, (ISize{100, 100}));
    EXPECT_EQ(texture->GetTextureDescriptor().format,
              PixelFormat::kR8G8B8A8UNormInt);
    EXPECT_FALSE(destroyed);
  }

  EXPECT_TRUE(destroyed);
}

TEST(TextureWrapperVKTest, WrapTextureInvalidArguments) {
  std::shared_ptr<ContextVK> context = MockVulkanContextBuilder().Build();
  ASSERT_TRUE(context);

  TextureDescriptor desc;
  desc.format = PixelFormat::kR8G8B8A8UNormInt;
  desc.size = ISize{100, 100};

  // Null context.
  EXPECT_EQ(WrapTextureVK(nullptr, desc,
                          vk::Image(reinterpret_cast<VkImage>(0x12345))),
            nullptr);

  // Null image.
  EXPECT_EQ(WrapTextureVK(context, desc, vk::Image(VK_NULL_HANDLE)), nullptr);
}

}  // namespace testing
}  // namespace impeller
