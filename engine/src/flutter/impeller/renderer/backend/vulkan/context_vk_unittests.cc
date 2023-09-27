// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/testing/testing.h"  // IWYU pragma: keep
#include "impeller/renderer/backend/vulkan/command_pool_vk.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/test/mock_vulkan.h"

namespace impeller {
namespace testing {

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
        "foobar", ShaderStage::kFragment,
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

}  // namespace testing
}  // namespace impeller
