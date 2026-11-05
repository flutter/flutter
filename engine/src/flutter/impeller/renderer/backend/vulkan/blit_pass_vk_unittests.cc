// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"
#include "fml/macros.h"
#include "impeller/renderer/backend/vulkan/blit_pass_vk.h"
#include "impeller/renderer/backend/vulkan/command_buffer_vk.h"
#include "impeller/renderer/backend/vulkan/test/mock_vulkan.h"

namespace impeller {

TEST(BlitPassVKTest, MipmapGenerationTransitionsAllLevelsCorrectly) {
  auto context = testing::MockVulkanContextBuilder().Build();
  ASSERT_TRUE(context->IsValid());

  auto cmd_buffer = context->CreateCommandBuffer();
  ASSERT_TRUE(cmd_buffer);
  auto blit_pass = cmd_buffer->CreateBlitPass();
  ASSERT_TRUE(blit_pass);

  auto vk_blit_pass = reinterpret_cast<BlitPassVK*>(blit_pass.get());
  auto vk_cmd_buffer = reinterpret_cast<CommandBufferVK*>(cmd_buffer.get());

  TextureDescriptor desc;
  desc.size = ISize(100, 65);
  desc.format = PixelFormat::kR8G8B8A8UNormInt;
  desc.mip_count = 6;
  auto texture = context->GetResourceAllocator()->CreateTexture(desc);
  ASSERT_TRUE(texture);

  ASSERT_TRUE(vk_blit_pass->OnGenerateMipmapCommand(texture, "TestMipmap"));

  auto& barriers =
      testing::GetImageMemoryBarriers(vk_cmd_buffer->GetCommandBuffer());

  ASSERT_EQ(barriers.size(), 8u);

  EXPECT_EQ(barriers[0].oldLayout, VK_IMAGE_LAYOUT_UNDEFINED);
  EXPECT_EQ(barriers[0].newLayout, VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL);
  EXPECT_EQ(barriers[0].subresourceRange.baseMipLevel, 0u);
  EXPECT_EQ(barriers[0].subresourceRange.levelCount, 6u);

  for (uint32_t i = 1; i < 7; ++i) {
    EXPECT_EQ(barriers[i].oldLayout, VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL) << i;
    EXPECT_EQ(barriers[i].newLayout, VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL) << i;
    EXPECT_EQ(barriers[i].subresourceRange.baseMipLevel, i - 1) << i;
    EXPECT_EQ(barriers[i].subresourceRange.levelCount, 1u) << i;
  }

  EXPECT_EQ(barriers[7].oldLayout, VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL);
  EXPECT_EQ(barriers[7].newLayout, VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL);
  EXPECT_EQ(barriers[7].subresourceRange.baseMipLevel, 0u);
  EXPECT_EQ(barriers[7].subresourceRange.levelCount, 6u);
}

}  // namespace impeller
