// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <cstdint>

#include "fml/logging.h"
#include "gtest/gtest.h"

#include "impeller/core/allocator.h"
#include "impeller/core/device_buffer_descriptor.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/geometry/color.h"
#include "impeller/renderer/capabilities.h"
#include "impeller/renderer/command_queue.h"
#include "impeller/renderer/pipeline.h"
#include "impeller/renderer/pipeline_descriptor.h"

namespace impeller {
namespace testing {

class FakeAllocator : public Allocator {
 public:
  FakeAllocator() : Allocator() {}

  uint16_t MinimumBytesPerRow(PixelFormat format) const override { return 0; }
  ISize GetMaxTextureSizeSupported() const override { return ISize(); }

  std::shared_ptr<DeviceBuffer> OnCreateBuffer(
      const DeviceBufferDescriptor& desc) override {
    return nullptr;
  }
  std::shared_ptr<Texture> OnCreateTexture(
      const TextureDescriptor& desc) override {
    return nullptr;
  }
};

class FakeContext : public Context {
 public:
  FakeContext() : Context(), allocator_(std::make_shared<FakeAllocator>()) {}

  BackendType GetBackendType() const override { return BackendType::kVulkan; }
  std::string DescribeGpuModel() const override { return ""; }
  bool IsValid() const override { return false; }
  const std::shared_ptr<const Capabilities>& GetCapabilities() const override {
    return capabilities_;
  }
  std::shared_ptr<Allocator> GetResourceAllocator() const override {
    return allocator_;
  }
  std::shared_ptr<ShaderLibrary> GetShaderLibrary() const { return nullptr; }
  std::shared_ptr<SamplerLibrary> GetSamplerLibrary() const { return nullptr; }
  std::shared_ptr<PipelineLibrary> GetPipelineLibrary() const {
    return nullptr;
  }
  std::shared_ptr<CommandQueue> GetCommandQueue() const { FML_UNREACHABLE(); }
  std::shared_ptr<CommandBuffer> CreateCommandBuffer() const { return nullptr; }
  void Shutdown() {}

 private:
  std::shared_ptr<Allocator> allocator_;
  std::shared_ptr<const Capabilities> capabilities_;
};

class FakePipeline : public Pipeline<PipelineDescriptor> {
 public:
  FakePipeline() : Pipeline({}, PipelineDescriptor{}) {}

  bool IsValid() const override { return false; }
};

static std::shared_ptr<FakePipeline> CreateFakePipelineCallback() {
  return std::make_shared<FakePipeline>();
}

TEST(ContentContext, CachesPipelines) {
  auto context = std::make_shared<FakeContext>();
  ContentContext content_context(context, nullptr);
  ContentContextOptions optionsA{.blend_mode = BlendMode::kSourceOver};
  ContentContextOptions optionsB{.blend_mode = BlendMode::kSource};

  auto pipelineA = content_context.GetCachedRuntimeEffectPipeline(
      "A", optionsA, CreateFakePipelineCallback);

  auto pipelineA2 = content_context.GetCachedRuntimeEffectPipeline(
      "A", optionsA, CreateFakePipelineCallback);

  auto pipelineA3 = content_context.GetCachedRuntimeEffectPipeline(
      "A", optionsB, CreateFakePipelineCallback);

  auto pipelineB = content_context.GetCachedRuntimeEffectPipeline(
      "B", optionsB, CreateFakePipelineCallback);

  ASSERT_EQ(pipelineA.get(), pipelineA2.get());
  ASSERT_NE(pipelineA.get(), pipelineA3.get());
  ASSERT_NE(pipelineB.get(), pipelineA.get());
}

TEST(ContentContext, InvalidatesAllPipelinesWithSameUniqueNameOnClear) {
  auto context = std::make_shared<FakeContext>();
  ContentContext content_context(context, nullptr);
  ContentContextOptions optionsA{.blend_mode = BlendMode::kSourceOver};
  ContentContextOptions optionsB{.blend_mode = BlendMode::kSource};

  auto pipelineA = content_context.GetCachedRuntimeEffectPipeline(
      "A", optionsA, CreateFakePipelineCallback);

  auto pipelineA2 = content_context.GetCachedRuntimeEffectPipeline(
      "A", optionsB, CreateFakePipelineCallback);

  auto pipelineB = content_context.GetCachedRuntimeEffectPipeline(
      "B", optionsB, CreateFakePipelineCallback);

  ASSERT_TRUE(pipelineA);
  ASSERT_TRUE(pipelineA2);
  ASSERT_TRUE(pipelineB);

  ASSERT_EQ(pipelineA, content_context.GetCachedRuntimeEffectPipeline(
                           "A", optionsA, CreateFakePipelineCallback));
  ASSERT_EQ(pipelineA2, content_context.GetCachedRuntimeEffectPipeline(
                            "A", optionsB, CreateFakePipelineCallback));
  ASSERT_EQ(pipelineB, content_context.GetCachedRuntimeEffectPipeline(
                           "B", optionsB, CreateFakePipelineCallback));

  content_context.ClearCachedRuntimeEffectPipeline("A");

  ASSERT_NE(pipelineA, content_context.GetCachedRuntimeEffectPipeline(
                           "A", optionsA, CreateFakePipelineCallback));
  ASSERT_NE(pipelineA2, content_context.GetCachedRuntimeEffectPipeline(
                            "A", optionsB, CreateFakePipelineCallback));
  ASSERT_EQ(pipelineB, content_context.GetCachedRuntimeEffectPipeline(
                           "B", optionsB, CreateFakePipelineCallback));

  content_context.ClearCachedRuntimeEffectPipeline("B");

  ASSERT_NE(pipelineB, content_context.GetCachedRuntimeEffectPipeline(
                           "B", optionsB, CreateFakePipelineCallback));
}

}  // namespace testing
}  // namespace impeller
