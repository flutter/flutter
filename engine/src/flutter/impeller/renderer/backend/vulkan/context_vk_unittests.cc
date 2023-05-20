// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"
#include "impeller/renderer/backend/vulkan/command_pool_vk.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/test/mock_vulkan.h"

namespace impeller {
namespace testing {

TEST(ContextVKTest, DeletesCommandPools) {
  std::weak_ptr<ContextVK> weak_context;
  std::weak_ptr<CommandPoolVK> weak_pool;
  {
    std::shared_ptr<ContextVK> context = CreateMockVulkanContext();
    std::shared_ptr<CommandPoolVK> pool =
        CommandPoolVK::GetThreadLocal(context.get());
    weak_pool = pool;
    weak_context = context;
    ASSERT_TRUE(weak_pool.lock());
    ASSERT_TRUE(weak_context.lock());
  }
  ASSERT_FALSE(weak_pool.lock());
  ASSERT_FALSE(weak_context.lock());
}

TEST(ContextVKTest, DeletePipelineAfterContext) {
  std::shared_ptr<Pipeline<PipelineDescriptor>> pipeline;
  std::shared_ptr<std::vector<std::string>> functions;
  {
    std::shared_ptr<ContextVK> context = CreateMockVulkanContext();
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
    std::shared_ptr<ContextVK> context = CreateMockVulkanContext();
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
    std::shared_ptr<ContextVK> context = CreateMockVulkanContext();
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

}  // namespace testing
}  // namespace impeller
