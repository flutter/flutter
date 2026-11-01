// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"  // IWYU pragma: keep
#include "gtest/gtest.h"
#include "impeller/core/formats.h"
#include "impeller/renderer/backend/vulkan/render_pass_builder_vk.h"
#include "impeller/renderer/backend/vulkan/test/mock_vulkan.h"
#include "vulkan/vulkan_enums.hpp"

namespace impeller {
namespace testing {

TEST(RenderPassBuilder, CreatesRenderPassWithNoDepthStencil) {
  RenderPassBuilderVK builder = RenderPassBuilderVK();
  auto const context = MockVulkanContextBuilder().Build();

  // Create a single color attachment with a transient depth stencil.
  builder.SetColorAttachment(0, PixelFormat::kR8G8B8A8UNormInt,
                             SampleCount::kCount1, LoadAction::kClear,
                             StoreAction::kStore);

  auto render_pass = builder.Build(context->GetDevice());

  EXPECT_TRUE(!!render_pass);
  EXPECT_FALSE(builder.GetDepthStencil().has_value());
}

TEST(RenderPassBuilder, RenderPassWithLoadOpUsesCurrentLayout) {
  RenderPassBuilderVK builder = RenderPassBuilderVK();
  auto const context = MockVulkanContextBuilder().Build();

  builder.SetColorAttachment(0, PixelFormat::kR8G8B8A8UNormInt,
                             SampleCount::kCount1, LoadAction::kLoad,
                             StoreAction::kStore,
                             vk::ImageLayout::eColorAttachmentOptimal);

  auto render_pass = builder.Build(context->GetDevice());

  EXPECT_TRUE(!!render_pass);

  std::optional<vk::AttachmentDescription> maybe_color = builder.GetColor0();
  ASSERT_TRUE(maybe_color.has_value());
  if (!maybe_color.has_value()) {
    return;
  }
  vk::AttachmentDescription color = maybe_color.value();

  EXPECT_EQ(color.initialLayout, vk::ImageLayout::eColorAttachmentOptimal);
  EXPECT_EQ(color.finalLayout, vk::ImageLayout::eShaderReadOnlyOptimal);
  EXPECT_EQ(color.loadOp, vk::AttachmentLoadOp::eLoad);
  EXPECT_EQ(color.storeOp, vk::AttachmentStoreOp::eStore);
}

TEST(RenderPassBuilder, CreatesRenderPassWithCombinedDepthStencil) {
  RenderPassBuilderVK builder = RenderPassBuilderVK();
  auto const context = MockVulkanContextBuilder().Build();

  // Create a single color attachment with a transient depth stencil.
  builder.SetColorAttachment(0, PixelFormat::kR8G8B8A8UNormInt,
                             SampleCount::kCount1, LoadAction::kClear,
                             StoreAction::kStore, vk::ImageLayout::eGeneral);
  builder.SetDepthStencilAttachment(PixelFormat::kD24UnormS8Uint,
                                    SampleCount::kCount1, LoadAction::kDontCare,
                                    StoreAction::kDontCare);

  auto render_pass = builder.Build(context->GetDevice());

  EXPECT_TRUE(!!render_pass);

  std::optional<vk::AttachmentDescription> maybe_color = builder.GetColor0();
  ASSERT_TRUE(maybe_color.has_value());
  if (!maybe_color.has_value()) {
    return;
  }
  vk::AttachmentDescription color = maybe_color.value();

  EXPECT_EQ(color.initialLayout, vk::ImageLayout::eUndefined);
  EXPECT_EQ(color.finalLayout, vk::ImageLayout::eShaderReadOnlyOptimal);
  EXPECT_EQ(color.loadOp, vk::AttachmentLoadOp::eClear);
  EXPECT_EQ(color.storeOp, vk::AttachmentStoreOp::eStore);

  std::optional<vk::AttachmentDescription> maybe_depth_stencil =
      builder.GetDepthStencil();
  ASSERT_TRUE(maybe_depth_stencil.has_value());
  if (!maybe_depth_stencil.has_value()) {
    return;
  }
  vk::AttachmentDescription depth_stencil = maybe_depth_stencil.value();

  EXPECT_EQ(depth_stencil.initialLayout, vk::ImageLayout::eUndefined);
  EXPECT_EQ(depth_stencil.finalLayout,
            vk::ImageLayout::eDepthStencilAttachmentOptimal);
  EXPECT_EQ(depth_stencil.loadOp, vk::AttachmentLoadOp::eDontCare);
  EXPECT_EQ(depth_stencil.storeOp, vk::AttachmentStoreOp::eDontCare);
  EXPECT_EQ(depth_stencil.stencilLoadOp, vk::AttachmentLoadOp::eDontCare);
  EXPECT_EQ(depth_stencil.stencilStoreOp, vk::AttachmentStoreOp::eDontCare);
}

TEST(RenderPassBuilder, CreatesRenderPassWithOnlyStencil) {
  RenderPassBuilderVK builder = RenderPassBuilderVK();
  auto const context = MockVulkanContextBuilder().Build();

  // Create a single color attachment with a transient depth stencil.
  builder.SetColorAttachment(0, PixelFormat::kR8G8B8A8UNormInt,
                             SampleCount::kCount1, LoadAction::kClear,
                             StoreAction::kStore);
  builder.SetStencilAttachment(PixelFormat::kS8UInt, SampleCount::kCount1,
                               LoadAction::kDontCare, StoreAction::kDontCare);

  auto render_pass = builder.Build(context->GetDevice());

  EXPECT_TRUE(!!render_pass);

  std::optional<vk::AttachmentDescription> maybe_depth_stencil =
      builder.GetDepthStencil();
  ASSERT_TRUE(maybe_depth_stencil.has_value());
  if (!maybe_depth_stencil.has_value()) {
    return;
  }
  vk::AttachmentDescription depth_stencil = maybe_depth_stencil.value();

  EXPECT_EQ(depth_stencil.initialLayout, vk::ImageLayout::eUndefined);
  EXPECT_EQ(depth_stencil.finalLayout,
            vk::ImageLayout::eDepthStencilAttachmentOptimal);
  EXPECT_EQ(depth_stencil.loadOp, vk::AttachmentLoadOp::eDontCare);
  EXPECT_EQ(depth_stencil.storeOp, vk::AttachmentStoreOp::eDontCare);
  EXPECT_EQ(depth_stencil.stencilLoadOp, vk::AttachmentLoadOp::eDontCare);
  EXPECT_EQ(depth_stencil.stencilStoreOp, vk::AttachmentStoreOp::eDontCare);
}

TEST(RenderPassBuilder, CreatesMSAAResolveWithCorrectStore) {
  RenderPassBuilderVK builder = RenderPassBuilderVK();
  auto const context = MockVulkanContextBuilder().Build();

  // Create an MSAA color attachment.
  builder.SetColorAttachment(0, PixelFormat::kR8G8B8A8UNormInt,
                             SampleCount::kCount4, LoadAction::kClear,
                             StoreAction::kMultisampleResolve);

  auto render_pass = builder.Build(context->GetDevice());

  EXPECT_TRUE(!!render_pass);

  auto maybe_color = builder.GetColor0();
  ASSERT_TRUE(maybe_color.has_value());
  if (!maybe_color.has_value()) {
    return;
  }
  vk::AttachmentDescription color = maybe_color.value();

  // MSAA Texture.
  EXPECT_EQ(color.initialLayout, vk::ImageLayout::eUndefined);
  EXPECT_EQ(color.finalLayout, vk::ImageLayout::eGeneral);
  EXPECT_EQ(color.loadOp, vk::AttachmentLoadOp::eClear);
  EXPECT_EQ(color.storeOp, vk::AttachmentStoreOp::eDontCare);

  auto maybe_resolve = builder.GetColor0Resolve();
  ASSERT_TRUE(maybe_resolve.has_value());
  if (!maybe_resolve.has_value()) {
    return;
  }
  vk::AttachmentDescription resolve = maybe_resolve.value();

  // MSAA Resolve Texture.
  EXPECT_EQ(resolve.initialLayout, vk::ImageLayout::eUndefined);
  EXPECT_EQ(resolve.finalLayout, vk::ImageLayout::eShaderReadOnlyOptimal);
  EXPECT_EQ(resolve.loadOp, vk::AttachmentLoadOp::eClear);
  EXPECT_EQ(resolve.storeOp, vk::AttachmentStoreOp::eStore);
}

TEST(RenderPassBuilder, ExternalDependencyCoversDepthStencilClear) {
  RenderPassBuilderVK builder = RenderPassBuilderVK();
  auto const context = MockVulkanContextBuilder().Build();

  builder.SetColorAttachment(0, PixelFormat::kR8G8B8A8UNormInt,
                             SampleCount::kCount1, LoadAction::kClear,
                             StoreAction::kStore);
  builder.SetDepthStencilAttachment(PixelFormat::kD24UnormS8Uint,
                                    SampleCount::kCount1, LoadAction::kClear,
                                    StoreAction::kDontCare);

  auto render_pass = builder.Build(context->GetDevice());
  ASSERT_TRUE(!!render_pass);

  std::optional<VkSubpassDependency> external;
  for (const auto& dependency :
       GetLastRenderPassDependencies(context->GetDevice())) {
    if (dependency.srcSubpass == VK_SUBPASS_EXTERNAL &&
        dependency.dstSubpass == 0u) {
      external = dependency;
    }
  }
  ASSERT_TRUE(external.has_value());

  // The depth/stencil clear runs in the fragment test stages. The incoming
  // dependency must order it after earlier depth/stencil writes, not only
  // after color writes.
  EXPECT_EQ(external->srcStageMask,
            static_cast<VkPipelineStageFlags>(
                VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT |
                VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT |
                VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT |
                VK_PIPELINE_STAGE_LATE_FRAGMENT_TESTS_BIT));
  EXPECT_EQ(
      external->srcAccessMask,
      static_cast<VkAccessFlags>(VK_ACCESS_SHADER_READ_BIT |
                                 VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT |
                                 VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT));
  EXPECT_EQ(external->dstStageMask,
            static_cast<VkPipelineStageFlags>(
                VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT |
                VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT |
                VK_PIPELINE_STAGE_LATE_FRAGMENT_TESTS_BIT));
  EXPECT_EQ(
      external->dstAccessMask,
      static_cast<VkAccessFlags>(VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT |
                                 VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_READ_BIT |
                                 VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT));
}

TEST(RenderPassBuilder, ExternalDependencyOmitsDepthStagesWithoutDepthStencil) {
  RenderPassBuilderVK builder = RenderPassBuilderVK();
  auto const context = MockVulkanContextBuilder().Build();

  builder.SetColorAttachment(0, PixelFormat::kR8G8B8A8UNormInt,
                             SampleCount::kCount1, LoadAction::kClear,
                             StoreAction::kStore);

  auto render_pass = builder.Build(context->GetDevice());
  ASSERT_TRUE(!!render_pass);

  std::optional<VkSubpassDependency> external;
  for (const auto& dependency :
       GetLastRenderPassDependencies(context->GetDevice())) {
    if (dependency.srcSubpass == VK_SUBPASS_EXTERNAL &&
        dependency.dstSubpass == 0u) {
      external = dependency;
    }
  }
  ASSERT_TRUE(external.has_value());

  // Without a depth/stencil attachment, the incoming dependency has nothing
  // to order in the fragment test stages, so it keeps the color-only masks.
  EXPECT_EQ(external->srcStageMask,
            static_cast<VkPipelineStageFlags>(
                VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT |
                VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT));
  EXPECT_EQ(external->srcAccessMask,
            static_cast<VkAccessFlags>(VK_ACCESS_SHADER_READ_BIT |
                                       VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT));
  EXPECT_EQ(external->dstStageMask,
            static_cast<VkPipelineStageFlags>(
                VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT));
  EXPECT_EQ(external->dstAccessMask,
            static_cast<VkAccessFlags>(VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT));
}

}  // namespace testing
}  // namespace impeller
