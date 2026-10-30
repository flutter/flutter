// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>
#include <optional>

#include "flutter/testing/testing.h"  // IWYU pragma: keep
#include "gtest/gtest.h"
#include "impeller/core/formats.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
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

namespace {
std::optional<VkSubpassDependency> FindIncomingExternalDependency(
    VkDevice device) {
  for (const VkSubpassDependency& dependency :
       GetLastRenderPassDependencies(device)) {
    if (dependency.srcSubpass == VK_SUBPASS_EXTERNAL &&
        dependency.dstSubpass == 0u) {
      return dependency;
    }
  }
  return std::nullopt;
}
}  // namespace

// https://github.com/flutter/flutter/issues/195599
// https://github.com/flutter/flutter/issues/194987
TEST(RenderPassBuilder, IncomingDependencyCoversDepthStencilAttachment) {
  RenderPassBuilderVK builder = RenderPassBuilderVK();
  const std::shared_ptr<ContextVK> context = MockVulkanContextBuilder().Build();

  builder.SetColorAttachment(0, PixelFormat::kR8G8B8A8UNormInt,
                             SampleCount::kCount1, LoadAction::kClear,
                             StoreAction::kStore);
  builder.SetDepthStencilAttachment(PixelFormat::kD24UnormS8Uint,
                                    SampleCount::kCount1, LoadAction::kClear,
                                    StoreAction::kStore);

  vk::UniqueRenderPass render_pass = builder.Build(context->GetDevice());
  ASSERT_TRUE(!!render_pass);

  std::optional<VkSubpassDependency> incoming =
      FindIncomingExternalDependency(context->GetDevice());
  ASSERT_TRUE(incoming.has_value());

  // An earlier pass's depth/stencil writes and storeOp happen in the fragment
  // test stages, so they must be in the source scope.
  EXPECT_TRUE(incoming->srcStageMask &
              VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT);
  EXPECT_TRUE(incoming->srcStageMask &
              VK_PIPELINE_STAGE_LATE_FRAGMENT_TESTS_BIT);
  EXPECT_TRUE(incoming->srcAccessMask &
              VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT);

  // This pass's depth/stencil loadOp and accesses happen in the fragment test
  // stages, so they must be in the destination scope.
  EXPECT_TRUE(incoming->dstStageMask &
              VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT);
  EXPECT_TRUE(incoming->dstStageMask &
              VK_PIPELINE_STAGE_LATE_FRAGMENT_TESTS_BIT);
  EXPECT_TRUE(incoming->dstAccessMask &
              VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_READ_BIT);
  EXPECT_TRUE(incoming->dstAccessMask &
              VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT);

  // Color attachment synchronization is preserved.
  EXPECT_TRUE(incoming->srcStageMask &
              VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT);
  EXPECT_TRUE(incoming->dstStageMask &
              VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT);
}

TEST(RenderPassBuilder, IncomingDependencyOmitsDepthStagesWithoutDepthStencil) {
  RenderPassBuilderVK builder = RenderPassBuilderVK();
  const std::shared_ptr<ContextVK> context = MockVulkanContextBuilder().Build();

  builder.SetColorAttachment(0, PixelFormat::kR8G8B8A8UNormInt,
                             SampleCount::kCount1, LoadAction::kClear,
                             StoreAction::kStore);

  vk::UniqueRenderPass render_pass = builder.Build(context->GetDevice());
  ASSERT_TRUE(!!render_pass);

  std::optional<VkSubpassDependency> incoming =
      FindIncomingExternalDependency(context->GetDevice());
  ASSERT_TRUE(incoming.has_value());

  // Color-only passes shouldn't wait on the fragment test stages.
  EXPECT_EQ(incoming->srcStageMask,
            static_cast<VkPipelineStageFlags>(
                VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT |
                VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT));
  EXPECT_EQ(incoming->srcAccessMask,
            static_cast<VkAccessFlags>(VK_ACCESS_SHADER_READ_BIT |
                                       VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT));
  EXPECT_EQ(incoming->dstStageMask,
            static_cast<VkPipelineStageFlags>(
                VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT));
  EXPECT_EQ(incoming->dstAccessMask,
            static_cast<VkAccessFlags>(VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT));
}

}  // namespace testing
}  // namespace impeller
