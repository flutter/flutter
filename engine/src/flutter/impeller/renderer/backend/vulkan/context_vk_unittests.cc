// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/testing/testing.h"  // IWYU pragma: keep
#include "impeller/base/validation.h"
#include "impeller/core/formats.h"
#include "impeller/renderer/backend/vulkan/command_pool_vk.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/test/mock_vulkan.h"

namespace impeller {
namespace testing {

TEST(ContextVKTest, CommonHardwareConcurrencyConfigurations) {
  EXPECT_EQ(ContextVK::ChooseThreadCountForWorkers(100u), 4u);
  EXPECT_EQ(ContextVK::ChooseThreadCountForWorkers(9u), 4u);
  EXPECT_EQ(ContextVK::ChooseThreadCountForWorkers(8u), 4u);
  EXPECT_EQ(ContextVK::ChooseThreadCountForWorkers(7u), 3u);
  EXPECT_EQ(ContextVK::ChooseThreadCountForWorkers(6u), 3u);
  EXPECT_EQ(ContextVK::ChooseThreadCountForWorkers(5u), 2u);
  EXPECT_EQ(ContextVK::ChooseThreadCountForWorkers(4u), 2u);
  EXPECT_EQ(ContextVK::ChooseThreadCountForWorkers(3u), 1u);
  EXPECT_EQ(ContextVK::ChooseThreadCountForWorkers(2u), 1u);
  EXPECT_EQ(ContextVK::ChooseThreadCountForWorkers(1u), 1u);
}

TEST(ContextVKTest, DeletesCommandPools) {
  std::weak_ptr<ContextVK> weak_context;
  std::weak_ptr<CommandPoolVK> weak_pool;
  {
    std::shared_ptr<ContextVK> context = MockVulkanContextBuilder().Build();
    auto const pool = context->GetCommandPoolRecycler()->Get();
    weak_pool = pool;
    weak_context = context;
    ASSERT_TRUE(weak_pool.lock());
    ASSERT_TRUE(weak_context.lock());
  }
  ASSERT_FALSE(weak_pool.lock());
  ASSERT_FALSE(weak_context.lock());
}

TEST(ContextVKTest, DeletesCommandPoolsOnAllThreads) {
  std::weak_ptr<ContextVK> weak_context;
  std::weak_ptr<CommandPoolVK> weak_pool_main;

  std::shared_ptr<ContextVK> context = MockVulkanContextBuilder().Build();
  weak_pool_main = context->GetCommandPoolRecycler()->Get();
  weak_context = context;
  ASSERT_TRUE(weak_pool_main.lock());
  ASSERT_TRUE(weak_context.lock());

  // Start a second thread that obtains a command pool.
  fml::AutoResetWaitableEvent latch1, latch2;
  std::weak_ptr<CommandPoolVK> weak_pool_thread;
  std::thread thread([&]() {
    weak_pool_thread = context->GetCommandPoolRecycler()->Get();
    latch1.Signal();
    latch2.Wait();
  });

  // Delete the ContextVK on the main thread.
  latch1.Wait();
  context.reset();
  ASSERT_FALSE(weak_pool_main.lock());
  ASSERT_FALSE(weak_context.lock());

  // Stop the second thread and check that its command pool has been deleted.
  latch2.Signal();
  thread.join();
  ASSERT_FALSE(weak_pool_thread.lock());
}

TEST(ContextVKTest, DeletePipelineAfterContext) {
  std::shared_ptr<Pipeline<PipelineDescriptor>> pipeline;
  std::shared_ptr<std::vector<std::string>> functions;
  {
    std::shared_ptr<ContextVK> context = MockVulkanContextBuilder().Build();
    PipelineDescriptor pipeline_desc;
    pipeline_desc.SetVertexDescriptor(std::make_shared<VertexDescriptor>());
    PipelineFuture<PipelineDescriptor> pipeline_future =
        context->GetPipelineLibrary()->GetPipeline(pipeline_desc);
    pipeline = pipeline_future.Get();
    ASSERT_TRUE(pipeline);
    functions = GetMockVulkanFunctions(context->GetDevice());
    ASSERT_TRUE(std::find(functions->begin(), functions->end(),
                          "vkCreateGraphicsPipelines") != functions->end());
  }
  ASSERT_TRUE(std::find(functions->begin(), functions->end(),
                        "vkDestroyDevice") != functions->end());
}

TEST(ContextVKTest, DeleteShaderFunctionAfterContext) {
  std::shared_ptr<const ShaderFunction> shader_function;
  std::shared_ptr<std::vector<std::string>> functions;
  {
    std::shared_ptr<ContextVK> context = MockVulkanContextBuilder().Build();
    PipelineDescriptor pipeline_desc;
    pipeline_desc.SetVertexDescriptor(std::make_shared<VertexDescriptor>());
    std::vector<uint8_t> data = {0x03, 0x02, 0x23, 0x07};
    context->GetShaderLibrary()->RegisterFunction(
        "foobar_fragment_main", ShaderStage::kFragment,
        std::make_shared<fml::DataMapping>(data), [](bool) {});
    shader_function = context->GetShaderLibrary()->GetFunction(
        "foobar_fragment_main", ShaderStage::kFragment);
    ASSERT_TRUE(shader_function);
    functions = GetMockVulkanFunctions(context->GetDevice());
    ASSERT_TRUE(std::find(functions->begin(), functions->end(),
                          "vkCreateShaderModule") != functions->end());
  }
  ASSERT_TRUE(std::find(functions->begin(), functions->end(),
                        "vkDestroyDevice") != functions->end());
}

TEST(ContextVKTest, DeletePipelineLibraryAfterContext) {
  std::shared_ptr<PipelineLibrary> pipeline_library;
  std::shared_ptr<std::vector<std::string>> functions;
  {
    std::shared_ptr<ContextVK> context = MockVulkanContextBuilder().Build();
    PipelineDescriptor pipeline_desc;
    pipeline_desc.SetVertexDescriptor(std::make_shared<VertexDescriptor>());
    pipeline_library = context->GetPipelineLibrary();
    functions = GetMockVulkanFunctions(context->GetDevice());
    ASSERT_TRUE(std::find(functions->begin(), functions->end(),
                          "vkCreatePipelineCache") != functions->end());
  }
  ASSERT_TRUE(std::find(functions->begin(), functions->end(),
                        "vkDestroyDevice") != functions->end());
}

TEST(ContextVKTest, CanCreateContextInAbsenceOfValidationLayers) {
  // The mocked methods don't report the presence of a validation layer but we
  // explicitly ask for validation. Context creation should continue anyway.
  auto context = MockVulkanContextBuilder()
                     .SetSettingsCallback([](auto& settings) {
                       settings.enable_validation = true;
                     })
                     .Build();
  ASSERT_NE(context, nullptr);
  const CapabilitiesVK* capabilites_vk =
      reinterpret_cast<const CapabilitiesVK*>(context->GetCapabilities().get());
  ASSERT_FALSE(capabilites_vk->AreValidationsEnabled());
}

TEST(ContextVKTest, CanCreateContextWithValidationLayers) {
  auto context =
      MockVulkanContextBuilder()
          .SetSettingsCallback(
              [](auto& settings) { settings.enable_validation = true; })
          .SetInstanceExtensions(
              {"VK_KHR_surface", "VK_MVK_macos_surface", "VK_EXT_debug_utils"})
          .SetInstanceLayers({"VK_LAYER_KHRONOS_validation"})
          .Build();
  ASSERT_NE(context, nullptr);
  const CapabilitiesVK* capabilites_vk =
      reinterpret_cast<const CapabilitiesVK*>(context->GetCapabilities().get());
  ASSERT_TRUE(capabilites_vk->AreValidationsEnabled());
}

// In Impeller's 2D renderer, we no longer use stencil-only formats. They're
// less widely supported than combined depth-stencil formats, so make sure we
// don't fail initialization if we can't find a suitable stencil format.
TEST(CapabilitiesVKTest, ContextInitializesWithNoStencilFormat) {
  const std::shared_ptr<ContextVK> context =
      MockVulkanContextBuilder()
          .SetPhysicalDeviceFormatPropertiesCallback(
              [](VkPhysicalDevice physicalDevice, VkFormat format,
                 VkFormatProperties* pFormatProperties) {
                if (format == VK_FORMAT_B8G8R8A8_UNORM) {
                  pFormatProperties->optimalTilingFeatures =
                      static_cast<VkFormatFeatureFlags>(
                          vk::FormatFeatureFlagBits::eColorAttachment);
                } else if (format == VK_FORMAT_D32_SFLOAT_S8_UINT) {
                  pFormatProperties->optimalTilingFeatures =
                      static_cast<VkFormatFeatureFlags>(
                          vk::FormatFeatureFlagBits::eDepthStencilAttachment);
                }
                // Ignore just the stencil format.
              })
          .Build();
  ASSERT_NE(context, nullptr);
  const CapabilitiesVK* capabilites_vk =
      reinterpret_cast<const CapabilitiesVK*>(context->GetCapabilities().get());
  ASSERT_EQ(capabilites_vk->GetDefaultDepthStencilFormat(),
            PixelFormat::kD32FloatS8UInt);
  ASSERT_EQ(capabilites_vk->GetDefaultStencilFormat(),
            PixelFormat::kD32FloatS8UInt);
}

// Impeller's 2D renderer relies on hardware support for a combined
// depth-stencil format (widely supported). So fail initialization if a suitable
// one couldn't be found. That way we have an opportunity to fallback to
// OpenGLES.
TEST(CapabilitiesVKTest,
     ContextFailsInitializationForNoCombinedDepthStencilFormat) {
  ScopedValidationDisable disable_validation;
  const std::shared_ptr<ContextVK> context =
      MockVulkanContextBuilder()
          .SetPhysicalDeviceFormatPropertiesCallback(
              [](VkPhysicalDevice physicalDevice, VkFormat format,
                 VkFormatProperties* pFormatProperties) {
                if (format == VK_FORMAT_B8G8R8A8_UNORM) {
                  pFormatProperties->optimalTilingFeatures =
                      static_cast<VkFormatFeatureFlags>(
                          vk::FormatFeatureFlagBits::eColorAttachment);
                }
                // Ignore combined depth-stencil formats.
              })
          .Build();
  ASSERT_EQ(context, nullptr);
}

TEST(ContextVKTest, WarmUpFunctionCreatesRenderPass) {
  const std::shared_ptr<ContextVK> context = MockVulkanContextBuilder().Build();

  context->SetOffscreenFormat(PixelFormat::kR8G8B8A8UNormInt);
  context->InitializeCommonlyUsedShadersIfNeeded();

  auto functions = GetMockVulkanFunctions(context->GetDevice());
  ASSERT_TRUE(std::find(functions->begin(), functions->end(),
                        "vkCreateRenderPass") != functions->end());
}

}  // namespace testing
}  // namespace impeller
