// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <cstdint>
#include <future>
#include <memory>
#include <utility>
#include <vector>

#include "fml/logging.h"
#include "gtest/gtest.h"

#include "impeller/base/backend_cast.h"
#include "impeller/base/comparable.h"
#include "impeller/core/allocator.h"
#include "impeller/core/device_buffer_descriptor.h"
#include "impeller/core/formats.h"
#include "impeller/core/texture_descriptor.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/test/recording_render_pass.h"
#include "impeller/geometry/color.h"
#include "impeller/renderer/capabilities.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/command_queue.h"
#include "impeller/renderer/pipeline.h"
#include "impeller/renderer/pipeline_descriptor.h"
#include "impeller/renderer/pipeline_library.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/shader_function.h"
#include "impeller/renderer/shader_library.h"

namespace impeller {
namespace testing {

namespace {
class FakeTexture : public Texture {
 public:
  explicit FakeTexture(const TextureDescriptor& desc) : Texture(desc) {}

  ~FakeTexture() override {}

  void SetLabel(std::string_view label) {}

  bool IsValid() const override { return true; }

  ISize GetSize() const override { return {1, 1}; }

  Scalar GetYCoordScale() const override { return 1.0; }

  bool OnSetContents(const uint8_t* contents,
                     size_t length,
                     size_t slice) override {
    if (GetTextureDescriptor().GetByteSizeOfBaseMipLevel() != length) {
      return false;
    }
    did_set_contents = true;
    return true;
  }

  bool OnSetContents(std::shared_ptr<const fml::Mapping> mapping,
                     size_t slice) override {
    did_set_contents = true;
    return true;
  }

  bool did_set_contents = false;
};

class FakeAllocator : public Allocator,
                      public BackendCast<FakeAllocator, Allocator> {
 public:
  FakeAllocator() : Allocator() {}

  uint16_t MinimumBytesPerRow(PixelFormat format) const override { return 0; }
  ISize GetMaxTextureSizeSupported() const override { return ISize(1, 1); }

  std::shared_ptr<DeviceBuffer> OnCreateBuffer(
      const DeviceBufferDescriptor& desc) override {
    return nullptr;
  }
  std::shared_ptr<Texture> OnCreateTexture(
      const TextureDescriptor& desc) override {
    if (desc.size == ISize{1, 1}) {
      auto result = std::make_shared<FakeTexture>(desc);
      textures.push_back(result);
      return result;
    }
    return nullptr;
  }

  std::vector<std::shared_ptr<FakeTexture>> textures = {};
};

class FakePipeline : public Pipeline<PipelineDescriptor> {
 public:
  FakePipeline(std::weak_ptr<PipelineLibrary> library,
               const PipelineDescriptor& desc)
      : Pipeline(std::move(library), desc) {}

  ~FakePipeline() override {}

  bool IsValid() const override { return true; }
};

class FakeComputePipeline : public Pipeline<ComputePipelineDescriptor> {
 public:
  FakeComputePipeline(std::weak_ptr<PipelineLibrary> library,
                      const ComputePipelineDescriptor& desc)
      : Pipeline(std::move(library), desc) {}

  ~FakeComputePipeline() override {}

  bool IsValid() const override { return true; }
};

class FakePipelineLibrary : public PipelineLibrary {
 public:
  FakePipelineLibrary() {}

  ~FakePipelineLibrary() override {}

  bool IsValid() const override { return true; }

  PipelineFuture<PipelineDescriptor> GetPipeline(
      PipelineDescriptor descriptor) override {
    auto pipeline =
        std::make_shared<FakePipeline>(weak_from_this(), descriptor);
    std::promise<std::shared_ptr<Pipeline<PipelineDescriptor>>> promise;
    promise.set_value(std::move(pipeline));
    return PipelineFuture<PipelineDescriptor>{
        .descriptor = descriptor,
        .future =
            std::shared_future<std::shared_ptr<Pipeline<PipelineDescriptor>>>(
                promise.get_future())};
  }

  PipelineFuture<ComputePipelineDescriptor> GetPipeline(
      ComputePipelineDescriptor descriptor) override {
    auto pipeline =
        std::make_shared<FakeComputePipeline>(weak_from_this(), descriptor);
    std::promise<std::shared_ptr<Pipeline<ComputePipelineDescriptor>>> promise;
    promise.set_value(std::move(pipeline));
    return PipelineFuture<ComputePipelineDescriptor>{
        .descriptor = descriptor,
        .future = std::shared_future<
            std::shared_ptr<Pipeline<ComputePipelineDescriptor>>>(
            promise.get_future())};
  }

  void RemovePipelinesWithEntryPoint(
      std::shared_ptr<const ShaderFunction> function) {}
};

class FakeShaderFunction : public ShaderFunction {
 public:
  FakeShaderFunction(UniqueID parent_library_id,
                     std::string name,
                     ShaderStage stage)
      : ShaderFunction(parent_library_id, std::move(name), stage){};

  ~FakeShaderFunction() override {}
};

class FakeShaderLibrary : public ShaderLibrary {
 public:
  ~FakeShaderLibrary() override {}

  bool IsValid() const override { return true; }

  std::shared_ptr<const ShaderFunction> GetFunction(std::string_view name,
                                                    ShaderStage stage) {
    return std::make_shared<FakeShaderFunction>(UniqueID{}, std::string(name),
                                                stage);
  }

  void RegisterFunction(std::string name,
                        ShaderStage stage,
                        std::shared_ptr<fml::Mapping> code,
                        RegistrationCallback callback) override {}

  void UnregisterFunction(std::string name, ShaderStage stage) override {}
};

class FakeCommandBuffer : public CommandBuffer {
 public:
  explicit FakeCommandBuffer(std::weak_ptr<const Context> context)
      : CommandBuffer(std::move(context)) {}

  ~FakeCommandBuffer() {}

  bool IsValid() const override { return true; }

  void SetLabel(const std::string& label) const override {}

  std::shared_ptr<RenderPass> OnCreateRenderPass(
      RenderTarget render_target) override {
    return std::make_shared<RecordingRenderPass>(nullptr, context_.lock(),
                                                 render_target);
  }

  std::shared_ptr<BlitPass> OnCreateBlitPass() override { FML_UNREACHABLE() }

  virtual bool OnSubmitCommands(CompletionCallback callback) { return true; }

  void OnWaitUntilScheduled() {}

  std::shared_ptr<ComputePass> OnCreateComputePass() override {
    FML_UNREACHABLE();
  }
};

class FakeContext : public Context,
                    public std::enable_shared_from_this<FakeContext> {
 public:
  explicit FakeContext(
      const std::string& gpu_model = "",
      PixelFormat default_color_format = PixelFormat::kR8G8B8A8UNormInt)
      : Context(),
        allocator_(std::make_shared<FakeAllocator>()),
        capabilities_(std::shared_ptr<Capabilities>(
            CapabilitiesBuilder()
                .SetDefaultColorFormat(default_color_format)
                .Build())),
        pipelines_(std::make_shared<FakePipelineLibrary>()),
        queue_(std::make_shared<CommandQueue>()),
        shader_library_(std::make_shared<FakeShaderLibrary>()),
        gpu_model_(gpu_model) {}

  BackendType GetBackendType() const override { return BackendType::kVulkan; }
  std::string DescribeGpuModel() const override { return gpu_model_; }
  bool IsValid() const override { return true; }
  const std::shared_ptr<const Capabilities>& GetCapabilities() const override {
    return capabilities_;
  }
  std::shared_ptr<Allocator> GetResourceAllocator() const override {
    return allocator_;
  }
  std::shared_ptr<ShaderLibrary> GetShaderLibrary() const {
    return shader_library_;
  }
  std::shared_ptr<SamplerLibrary> GetSamplerLibrary() const { return nullptr; }
  std::shared_ptr<PipelineLibrary> GetPipelineLibrary() const {
    return pipelines_;
  }
  std::shared_ptr<CommandQueue> GetCommandQueue() const { return queue_; }
  std::shared_ptr<CommandBuffer> CreateCommandBuffer() const {
    return std::make_shared<FakeCommandBuffer>(shared_from_this());
  }
  void Shutdown() {}

 private:
  std::shared_ptr<Allocator> allocator_;
  std::shared_ptr<const Capabilities> capabilities_;
  std::shared_ptr<FakePipelineLibrary> pipelines_;
  std::shared_ptr<CommandQueue> queue_;
  std::shared_ptr<ShaderLibrary> shader_library_;
  std::string gpu_model_;
};
}  // namespace

TEST(ContentContext, CachesPipelines) {
  auto context = std::make_shared<FakeContext>();

  auto create_callback = [&]() {
    return std::make_shared<FakePipeline>(context->GetPipelineLibrary(),
                                          PipelineDescriptor{});
  };

  ContentContext content_context(context, nullptr);
  ContentContextOptions optionsA{.blend_mode = BlendMode::kSourceOver};
  ContentContextOptions optionsB{.blend_mode = BlendMode::kSource};

  auto pipelineA = content_context.GetCachedRuntimeEffectPipeline(
      "A", optionsA, create_callback);

  auto pipelineA2 = content_context.GetCachedRuntimeEffectPipeline(
      "A", optionsA, create_callback);

  auto pipelineA3 = content_context.GetCachedRuntimeEffectPipeline(
      "A", optionsB, create_callback);

  auto pipelineB = content_context.GetCachedRuntimeEffectPipeline(
      "B", optionsB, create_callback);

  ASSERT_EQ(pipelineA.get(), pipelineA2.get());
  ASSERT_NE(pipelineA.get(), pipelineA3.get());
  ASSERT_NE(pipelineB.get(), pipelineA.get());
}

TEST(ContentContext, InvalidatesAllPipelinesWithSameUniqueNameOnClear) {
  auto context = std::make_shared<FakeContext>();
  ContentContext content_context(context, nullptr);
  ContentContextOptions optionsA{.blend_mode = BlendMode::kSourceOver};
  ContentContextOptions optionsB{.blend_mode = BlendMode::kSource};

  auto create_callback = [&]() {
    return std::make_shared<FakePipeline>(context->GetPipelineLibrary(),
                                          PipelineDescriptor{});
  };

  auto pipelineA = content_context.GetCachedRuntimeEffectPipeline(
      "A", optionsA, create_callback);

  auto pipelineA2 = content_context.GetCachedRuntimeEffectPipeline(
      "A", optionsB, create_callback);

  auto pipelineB = content_context.GetCachedRuntimeEffectPipeline(
      "B", optionsB, create_callback);

  ASSERT_TRUE(pipelineA);
  ASSERT_TRUE(pipelineA2);
  ASSERT_TRUE(pipelineB);

  ASSERT_EQ(pipelineA, content_context.GetCachedRuntimeEffectPipeline(
                           "A", optionsA, create_callback));
  ASSERT_EQ(pipelineA2, content_context.GetCachedRuntimeEffectPipeline(
                            "A", optionsB, create_callback));
  ASSERT_EQ(pipelineB, content_context.GetCachedRuntimeEffectPipeline(
                           "B", optionsB, create_callback));

  content_context.ClearCachedRuntimeEffectPipeline("A");

  ASSERT_NE(pipelineA, content_context.GetCachedRuntimeEffectPipeline(
                           "A", optionsA, create_callback));
  ASSERT_NE(pipelineA2, content_context.GetCachedRuntimeEffectPipeline(
                            "A", optionsB, create_callback));
  ASSERT_EQ(pipelineB, content_context.GetCachedRuntimeEffectPipeline(
                           "B", optionsB, create_callback));

  content_context.ClearCachedRuntimeEffectPipeline("B");

  ASSERT_NE(pipelineB, content_context.GetCachedRuntimeEffectPipeline(
                           "B", optionsB, create_callback));
}

TEST(ContentContext, InitializeCommonlyUsedShadersIfNeeded) {
  ScopedValidationFatal fatal_validations;
  // Set a pixel format that is larger than 32bpp.
  auto context = std::make_shared<FakeContext>("Mali G70",
                                               PixelFormat::kR16G16B16A16Float);
  ContentContext content_context(context, nullptr);

  FakeAllocator& fake_allocator =
      FakeAllocator::Cast(*context->GetResourceAllocator());

#if IMPELLER_ENABLE_3D
  EXPECT_EQ(fake_allocator.textures.size(), 2u);
#else
  EXPECT_EQ(fake_allocator.textures.size(), 1u);
#endif  // IMPELLER_ENABLE_3D
}

}  // namespace testing
}  // namespace impeller
