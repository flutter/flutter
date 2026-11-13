// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/recording.h"

#include <future>
#include <memory>
#include <string>
#include <thread>
#include <unordered_map>
#include <vector>

#include "flutter/fml/synchronization/count_down_latch.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/fml/thread.h"
#include "flutter/lib/gpu/binding_set.h"
#include "flutter/lib/gpu/command_buffer.h"
#include "flutter/lib/gpu/context.h"
#include "flutter/lib/gpu/device_buffer.h"
#include "flutter/lib/gpu/render_pass.h"
#include "flutter/lib/gpu/render_pipeline.h"
#include "flutter/lib/gpu/replay.h"
#include "flutter/lib/gpu/shader.h"
#include "flutter/lib/gpu/texture.h"
#include "fml/memory/ref_ptr.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"
#include "impeller/base/validation.h"
#include "impeller/core/device_buffer_descriptor.h"
#include "impeller/core/sampler_descriptor.h"
#include "impeller/core/texture_descriptor.h"
#include "impeller/renderer/pipeline.h"
#include "impeller/renderer/shader_function.h"
#include "impeller/renderer/shader_library.h"
#include "impeller/renderer/testing/mocks.h"

namespace flutter::gpu {
namespace {

using ::impeller::testing::MockCommandBuffer;
using ::impeller::testing::MockCommandQueue;
using ::impeller::testing::MockDeviceBuffer;
using ::impeller::testing::MockImpellerContext;
using ::impeller::testing::MockPipelineLibrary;
using ::impeller::testing::MockSampler;
using ::impeller::testing::MockSamplerLibrary;
using ::impeller::testing::MockTexture;
using ::testing::_;
using ::testing::NiceMock;
using ::testing::Return;

class FakeShaderFunction : public impeller::ShaderFunction {
 public:
  explicit FakeShaderFunction(impeller::ShaderStage stage)
      : ShaderFunction(impeller::UniqueID(), "function", stage) {}
};

// Resolves every name, unless told not to.
class FakeShaderLibrary : public impeller::ShaderLibrary {
 public:
  bool IsValid() const override { return true; }

  std::shared_ptr<const impeller::ShaderFunction> GetFunction(
      std::string_view name,
      impeller::ShaderStage stage) override {
    if (!resolves) {
      return nullptr;
    }
    return std::make_shared<FakeShaderFunction>(stage);
  }

  void RegisterFunction(std::string name,
                        impeller::ShaderStage stage,
                        std::shared_ptr<fml::Mapping> code,
                        RegistrationCallback callback) override {
    callback(true);
  }

  void UnregisterFunction(std::string name,
                          impeller::ShaderStage stage) override {}

  bool resolves = true;
};

class FakePipeline : public impeller::Pipeline<impeller::PipelineDescriptor> {
 public:
  explicit FakePipeline(const impeller::PipelineDescriptor& desc)
      : Pipeline(std::weak_ptr<impeller::PipelineLibrary>(), desc) {}

  bool IsValid() const override { return true; }
};

// A render pass that logs what a test wants to look at.
class FakeRenderPass : public impeller::RenderPass {
 public:
  FakeRenderPass(std::shared_ptr<const impeller::Context> context,
                 const impeller::RenderTarget& target)
      : RenderPass(std::move(context), target) {}

  bool IsValid() const override { return true; }

  void OnSetLabel(std::string_view label) override {}

  bool OnEncodeCommands(const impeller::Context& context) const override {
    return true;
  }

  void SetPipeline(impeller::PipelineRef pipeline) override { pipelines++; }

  void SetStencilReference(uint32_t value) override {
    stencil_reference = value;
  }

  void SetViewport(impeller::Viewport viewport) override {}

  void SetScissor(impeller::IRect32 scissor) override {}

  void SetElementCount(size_t count) override { element_count = count; }

  void SetInstanceCount(size_t count) override {}

  bool SetVertexBuffer(impeller::BufferView vertex_buffers[],
                       size_t vertex_buffer_count) override {
    last_vertex_buffer_count = vertex_buffer_count;
    return true;
  }

  bool SetIndexBuffer(impeller::BufferView index_buffer,
                      impeller::IndexType index_type) override {
    last_index_type = index_type;
    return true;
  }

  bool BindResource(impeller::ShaderStage stage,
                    impeller::DescriptorType type,
                    const impeller::ShaderUniformSlot& slot,
                    const impeller::ShaderMetadata* metadata,
                    impeller::BufferView view) override {
    if (log_binds) {
      buffer_offsets.push_back(view.GetRange().offset);
    }
    binds++;
    return true;
  }

  bool BindResource(
      impeller::ShaderStage stage,
      impeller::DescriptorType type,
      const impeller::SampledImageSlot& slot,
      const impeller::ShaderMetadata* metadata,
      std::shared_ptr<const impeller::Texture> texture,
      impeller::raw_ptr<const impeller::Sampler> sampler) override {
    binds++;
    return true;
  }

  absl::Status Draw() override {
    draws++;
    if (log_binds) {
      binds_per_draw.push_back(binds);
    }
    binds = 0;
    return absl::OkStatus();
  }

  bool log_binds = false;
  std::vector<size_t> buffer_offsets;
  std::vector<size_t> binds_per_draw;
  size_t binds = 0;
  size_t draws = 0;
  size_t pipelines = 0;
  size_t element_count = 0;
  size_t last_vertex_buffer_count = 0;
  impeller::IndexType last_index_type = impeller::IndexType::kUnknown;
  uint32_t stencil_reference = 0;
};

fml::RefPtr<Shader> MakeShader(impeller::ShaderStage stage) {
  std::unordered_map<std::string, Shader::UniformBinding> uniform_structs;
  for (const char* name : {"FrameInfo", "NodeInfo"}) {
    uniform_structs[name] = Shader::UniformBinding{
        .slot = impeller::ShaderUniformSlot{.name = name},
        .metadata = impeller::ShaderMetadata{.name = name, .members = {}},
        .size_in_bytes = 64,
    };
  }
  std::unordered_map<std::string, Shader::TextureBinding> uniform_textures;
  Shader::TextureBinding texture_binding;
  texture_binding.slot = impeller::SampledImageSlot{.name = "tex"};
  texture_binding.metadata =
      impeller::ShaderMetadata{.name = "tex", .members = {}};
  uniform_textures["tex"] = texture_binding;
  return Shader::Make("library", "Entrypoint", stage,
                      /*code_mapping=*/nullptr, /*inputs=*/{}, /*layouts=*/{},
                      std::move(uniform_structs), std::move(uniform_textures),
                      /*descriptor_set_layouts=*/{});
}

class FlutterGpuRecordingTest : public ::testing::Test {
 protected:
  void SetUp() override {
    context_ = std::make_shared<NiceMock<MockImpellerContext>>();
    impeller_command_buffer_ =
        std::make_shared<NiceMock<MockCommandBuffer>>(context_);
    command_queue_ = std::make_shared<NiceMock<MockCommandQueue>>();
    sampler_library_ = std::make_shared<NiceMock<MockSamplerLibrary>>();
    pipeline_library_ = std::make_shared<NiceMock<MockPipelineLibrary>>();
    shader_library_ = std::make_shared<FakeShaderLibrary>();
    sampler_ = std::make_shared<MockSampler>(impeller::SamplerDescriptor{});

    ON_CALL(*context_, GetBackendType)
        .WillByDefault(Return(impeller::Context::BackendType::kMetal));
    ON_CALL(*context_, GetCommandQueue).WillByDefault(Return(command_queue_));
    ON_CALL(*context_, GetSamplerLibrary)
        .WillByDefault(Return(sampler_library_));
    ON_CALL(*context_, GetPipelineLibrary)
        .WillByDefault(Return(pipeline_library_));
    ON_CALL(*context_, GetShaderLibrary).WillByDefault(Return(shader_library_));
    ON_CALL(*context_, CreateCommandBuffer)
        .WillByDefault(Return(impeller_command_buffer_));
    ON_CALL(*impeller_command_buffer_, IsValid).WillByDefault(Return(true));
    ON_CALL(*impeller_command_buffer_, OnCreateRenderPass)
        .WillByDefault([this](const impeller::RenderTarget& target) {
          last_pass_ = std::make_shared<FakeRenderPass>(context_, target);
          return last_pass_;
        });
    ON_CALL(*sampler_library_, GetSampler)
        .WillByDefault(
            Return(impeller::raw_ptr<const impeller::Sampler>(sampler_)));
    ON_CALL(*pipeline_library_, GetPipeline(_, _, _))
        .WillByDefault([this](impeller::PipelineDescriptor descriptor,
                              bool async, bool threadsafe) {
          std::promise<
              std::shared_ptr<impeller::Pipeline<impeller::PipelineDescriptor>>>
              promise;
          promise.set_value(build_fails_
                                ? nullptr
                                : std::make_shared<FakePipeline>(descriptor));
          return impeller::PipelineFuture<impeller::PipelineDescriptor>{
              descriptor, promise.get_future().share()};
        });
    // The GPU finishes immediately.
    ON_CALL(*command_queue_, Submit(_, _))
        .WillByDefault(
            [](const std::vector<std::shared_ptr<impeller::CommandBuffer>>&,
               const impeller::CommandQueue::CompletionCallback& callback) {
              if (callback) {
                callback(impeller::CommandBuffer::Status::kCompleted);
              }
              return absl::OkStatus();
            });

    vertex_ = MakeShader(impeller::ShaderStage::kVertex);
    fragment_ = MakeShader(impeller::ShaderStage::kFragment);
    pipeline_ = fml::MakeRefCounted<RenderPipeline>(
        vertex_, fragment_, vertex_->CreateVertexDescriptor());
    buffer_ = MakeBuffer(4096);
    texture_ = MakeTexture();
  }

  // Default actions can form a cycle through the context.
  void TearDown() override { ::testing::Mock::VerifyAndClear(context_.get()); }

  fml::RefPtr<DeviceBuffer> MakeBuffer(size_t size) {
    impeller::DeviceBufferDescriptor desc;
    desc.size = size;
    return fml::MakeRefCounted<DeviceBuffer>(
        std::make_shared<NiceMock<MockDeviceBuffer>>(desc));
  }

  fml::RefPtr<Texture> MakeTexture() {
    impeller::TextureDescriptor desc;
    desc.size = impeller::ISize(4, 4);
    desc.format = impeller::PixelFormat::kR8G8B8A8UNormInt;
    desc.storage_mode = impeller::StorageMode::kDevicePrivate;
    auto texture = std::make_shared<NiceMock<MockTexture>>(desc);
    ON_CALL(*texture, IsValid).WillByDefault(Return(true));
    ON_CALL(*texture, GetSize).WillByDefault(Return(desc.size));
    return fml::MakeRefCounted<Texture>(texture);
  }

  fml::RefPtr<RenderPass> MakePass() {
    impeller::ColorAttachment color;
    color.texture = texture_->GetTexture();
    color.load_action = impeller::LoadAction::kClear;
    color.store_action = impeller::StoreAction::kStore;
    auto pass = fml::MakeRefCounted<RenderPass>();
    pass->GetRenderTarget().SetColorAttachment(color, 0);
    return pass;
  }

  // What a renderer does per draw: rebinds everything from scratch, re-sends
  // its state, and changes the state partway through.
  void RecordDraws(RenderPass& pass, size_t draws) {
    const impeller::SamplerDescriptor sampler;
    for (size_t i = 0; i < draws; i++) {
      pass.ClearBindings();
      pass.SetPipeline(pipeline_);
      pass.SetCullMode(i % 2 == 0 ? impeller::CullMode::kBackFace
                                  : impeller::CullMode::kFrontFace);
      pass.BindVertexBuffer(0, *buffer_, 0, 1024);
      pass.BindIndexBuffer(*buffer_, 1024, 1024, impeller::IndexType::k16bit);
      pass.BindUniform(*vertex_, vertex_->GetUniformStructAt(0), *buffer_, 0,
                       64);
      pass.BindUniform(*vertex_, vertex_->GetUniformStructAt(1), *buffer_,
                       64 * (i % 8), 64);
      pass.BindUniform(*fragment_, fragment_->GetUniformStructAt(0), *buffer_,
                       0, 64);
      pass.BindTexture(*fragment_, fragment_->GetUniformTextureAt(0), *texture_,
                       sampler);
      pass.SetStencilReference(static_cast<uint32_t>(i));
      EXPECT_TRUE(pass.Draw(36, 1, /*indexed=*/true));
    }
  }

  std::shared_ptr<NiceMock<MockImpellerContext>> context_;
  std::shared_ptr<NiceMock<MockCommandBuffer>> impeller_command_buffer_;
  std::shared_ptr<NiceMock<MockCommandQueue>> command_queue_;
  std::shared_ptr<NiceMock<MockSamplerLibrary>> sampler_library_;
  std::shared_ptr<NiceMock<MockPipelineLibrary>> pipeline_library_;
  std::shared_ptr<FakeShaderLibrary> shader_library_;
  std::shared_ptr<const impeller::Sampler> sampler_;
  std::shared_ptr<FakeRenderPass> last_pass_;
  fml::RefPtr<Shader> vertex_;
  fml::RefPtr<Shader> fragment_;
  fml::RefPtr<RenderPipeline> pipeline_;
  fml::RefPtr<DeviceBuffer> buffer_;
  fml::RefPtr<Texture> texture_;
  bool build_fails_ = false;
};

// A build failure is only discovered at replay. That draw is dropped, and later
// draws with the same state fail when recorded, so the caller sees it.
TEST_F(FlutterGpuRecordingTest, KnownBuildFailuresFailDrawsWhenRecorded) {
  impeller::ScopedValidationDisable disable_validation;
  build_fails_ = true;

  auto first_buffer = fml::MakeRefCounted<CommandBuffer>(context_);
  auto first = MakePass();
  ASSERT_TRUE(first->Begin(*first_buffer));
  first->SetPipeline(pipeline_);
  EXPECT_TRUE(first->Draw(3, 1, /*indexed=*/false));
  first->End();
  EXPECT_EQ(last_pass_->draws, 0u);
  EXPECT_TRUE(first_buffer->Submit());

  auto second_buffer = fml::MakeRefCounted<CommandBuffer>(context_);
  auto second = MakePass();
  ASSERT_TRUE(second->Begin(*second_buffer));
  second->SetPipeline(pipeline_);
  EXPECT_FALSE(second->Draw(3, 1, /*indexed=*/false));

  // Different state is unaffected.
  second->SetCullMode(impeller::CullMode::kFrontFace);
  EXPECT_TRUE(second->Draw(3, 1, /*indexed=*/false));
  second->End();
}

// An individual bind overrides a set member by coming after it, and sets go in
// slots, so rebinding one per draw must not accumulate bindings.
TEST_F(FlutterGpuRecordingTest, ReplayFollowsBindingRules) {
  auto command_buffer = fml::MakeRefCounted<CommandBuffer>(context_);
  auto pass = MakePass();
  ASSERT_TRUE(pass->Begin(*command_buffer));
  pass->SetPipeline(pipeline_);

  auto set = fml::MakeRefCounted<BindingSet>();
  ASSERT_TRUE(set->AddUniform(*vertex_, 0, buffer_->GetBuffer(), 256, 64));
  pass->BindSet(0, set);
  pass->BindSet(0, set);
  pass->BindSet(RenderPass::kMaxBindingSets, set);
  pass->BindUniform(*vertex_, vertex_->GetUniformStructAt(0), *buffer_, 512,
                    64);
  // Rebinding replaces the earlier bind of the same binding.
  pass->BindUniform(*vertex_, vertex_->GetUniformStructAt(0), *buffer_, 576,
                    64);
  EXPECT_TRUE(pass->Draw(3, 1, /*indexed=*/false));

  // Bindings persist across draws until cleared.
  EXPECT_TRUE(pass->Draw(3, 1, /*indexed=*/false));
  pass->ClearBindings();
  EXPECT_TRUE(pass->Draw(3, 1, /*indexed=*/false));

  // The pass is created when it is replayed, so logging starts at the first
  // bind through a recording replayed here.
  PassRecording* recording = pass->GetRecordingForTesting();
  FakeRenderPass target(context_, recording->render_target);
  target.log_binds = true;
  ReplayQueue queue(context_, nullptr);
  queue.GetReplayer().ReplayRender(*recording, target);

  EXPECT_THAT(target.buffer_offsets,
              ::testing::ElementsAre(256u, 576u, 256u, 576u));
  EXPECT_THAT(target.binds_per_draw, ::testing::ElementsAre(2u, 2u, 0u));
  pass->End();
}

TEST_F(FlutterGpuRecordingTest, ReplayKeepsDrawState) {
  auto command_buffer = fml::MakeRefCounted<CommandBuffer>(context_);
  auto pass = MakePass();
  ASSERT_TRUE(pass->Begin(*command_buffer));
  pass->SetPipeline(pipeline_);
  pass->BindVertexBuffer(0, *buffer_, 0, 64);
  pass->BindVertexBuffer(1, *buffer_, 64, 64);
  pass->BindIndexBuffer(*buffer_, 128, 64, impeller::IndexType::k32bit);
  pass->SetStencilReference(7u);
  EXPECT_TRUE(pass->Draw(9, 1, /*indexed=*/true));

  PassRecording* recording = pass->GetRecordingForTesting();
  FakeRenderPass target(context_, recording->render_target);
  ReplayQueue queue(context_, nullptr);
  queue.GetReplayer().ReplayRender(*recording, target);

  EXPECT_EQ(target.element_count, 9u);
  EXPECT_EQ(target.last_vertex_buffer_count, 2u);
  EXPECT_EQ(target.last_index_type, impeller::IndexType::k32bit);
  EXPECT_EQ(target.stencil_reference, 7u);
  pass->End();
}

// Ops are visited in order however many chunks they span.
TEST(FlutterGpuOpStreamTest, ForEachCrossesChunks) {
  OpStream stream;
  constexpr uint32_t kOps = 10000;
  static_assert(kOps * sizeof(SetStencilReferenceOp) > RecordingChunk::kSize);
  for (uint32_t i = 0; i < kOps; i++) {
    stream.Append<SetStencilReferenceOp>()->reference = i;
  }

  uint32_t next = 0;
  stream.ForEach([&](const OpHeader& header) {
    ASSERT_EQ(header.op, RecordedOp::kSetStencilReference);
    EXPECT_EQ(static_cast<const SetStencilReferenceOp&>(header).reference,
              next);
    next++;
  });
  EXPECT_EQ(next, kOps);

  stream.Reset();
  stream.ForEach([](const OpHeader& header) { FAIL(); });
}

TEST(FlutterGpuSamplerKeyTest, KeysRoundTrip) {
  impeller::SamplerDescriptor sampler;
  sampler.min_filter = impeller::MinMagFilter::kLinear;
  sampler.mag_filter = impeller::MinMagFilter::kLinear;
  sampler.mip_filter = impeller::MipFilter::kLinear;
  sampler.width_address_mode = impeller::SamplerAddressMode::kRepeat;
  sampler.height_address_mode = impeller::SamplerAddressMode::kMirror;
  sampler.max_anisotropy = 8;
  const uint64_t key = impeller::SamplerDescriptor::ToKey(sampler);
  EXPECT_EQ(impeller::SamplerDescriptor::ToKey(
                impeller::SamplerDescriptor::FromKey(key)),
            key);
}

// The point of recording: a pass is encoded while the next is being recorded,
// without waiting for the command buffer to be submitted.
TEST_F(FlutterGpuRecordingTest, EndedPassesEncodeBeforeSubmit) {
  fml::Thread replay_thread("replay");
  auto queue =
      std::make_shared<ReplayQueue>(context_, replay_thread.GetTaskRunner());

  fml::AutoResetWaitableEvent encoded;
  std::thread::id encoded_on;
  ON_CALL(*impeller_command_buffer_, OnCreateRenderPass)
      .WillByDefault([&](const impeller::RenderTarget& target) {
        encoded_on = std::this_thread::get_id();
        encoded.Signal();
        return std::make_shared<FakeRenderPass>(context_, target);
      });

  auto command_buffer = fml::MakeRefCounted<CommandBuffer>(context_, queue);
  auto pass = MakePass();
  ASSERT_TRUE(pass->Begin(*command_buffer));
  RecordDraws(*pass, 10);
  pass->End();

  encoded.Wait();
  EXPECT_NE(encoded_on, std::this_thread::get_id());

  fml::AutoResetWaitableEvent completed;
  EXPECT_TRUE(command_buffer->Submit(
      [&completed](impeller::CommandBuffer::Status status) {
        EXPECT_EQ(status, impeller::CommandBuffer::Status::kCompleted);
        completed.Signal();
      }));
  completed.Wait();
  replay_thread.Join();
}

}  // namespace
}  // namespace flutter::gpu
