// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/compute_pass.h"

#include <array>
#include <memory>
#include <string>
#include <unordered_map>
#include <utility>

#include "flutter/lib/gpu/binding_set.h"
#include "flutter/lib/gpu/command_buffer.h"
#include "flutter/lib/gpu/shader.h"
#include "fml/memory/ref_ptr.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"
#include "impeller/core/device_buffer_descriptor.h"
#include "impeller/core/sampler_descriptor.h"
#include "impeller/core/texture_descriptor.h"
#include "impeller/renderer/testing/mocks.h"

namespace flutter::gpu {
namespace {

using ::impeller::testing::MockCommandBuffer;
using ::impeller::testing::MockCommandQueue;
using ::impeller::testing::MockComputePass;
using ::impeller::testing::MockDeviceBuffer;
using ::impeller::testing::MockImpellerContext;
using ::impeller::testing::MockRenderPass;
using ::impeller::testing::MockSampler;
using ::impeller::testing::MockTexture;
using ::testing::_;
using ::testing::InSequence;
using ::testing::NiceMock;
using ::testing::Return;
using ::testing::Truly;

// A compute shader declaring one uniform struct ("Params"), one storage
// buffer ("Particles") and one texture ("tex").
fml::RefPtr<Shader> MakeComputeShader() {
  std::unordered_map<std::string, Shader::UniformBinding> uniform_structs;
  uniform_structs["Params"] = Shader::UniformBinding{
      .slot =
          impeller::ShaderUniformSlot{
              .name = "Params", .ext_res_0 = 0, .set = 0, .binding = 0},
      .metadata = impeller::ShaderMetadata{.name = "Params", .members = {}},
      .size_in_bytes = 16,
  };
  std::unordered_map<std::string, Shader::TextureBinding> uniform_textures;
  Shader::TextureBinding texture_binding;
  texture_binding.slot = impeller::SampledImageSlot{
      .name = "tex", .texture_index = 0, .set = 0, .binding = 2};
  texture_binding.metadata =
      impeller::ShaderMetadata{.name = "tex", .members = {}};
  uniform_textures["tex"] = texture_binding;
  std::unordered_map<std::string, Shader::StorageBufferBinding> storage_buffers;
  storage_buffers["Particles"] = Shader::StorageBufferBinding{
      .slot =
          impeller::ShaderUniformSlot{
              .name = "Particles", .ext_res_0 = 1, .set = 0, .binding = 1},
      .metadata = impeller::ShaderMetadata{.name = "Particles", .members = {}},
      .size_in_bytes = 0,
      .runtime_array_stride = 16,
  };
  return Shader::Make("library", "Entrypoint", impeller::ShaderStage::kCompute,
                      /*code_mapping=*/nullptr, /*inputs=*/{}, /*layouts=*/{},
                      std::move(uniform_structs), std::move(uniform_textures),
                      /*descriptor_set_layouts=*/{}, std::move(storage_buffers),
                      std::array<uint32_t, 3>{64, 1, 1});
}

std::shared_ptr<impeller::DeviceBuffer> MakeBuffer(size_t size) {
  impeller::DeviceBufferDescriptor desc;
  desc.size = size;
  return std::make_shared<NiceMock<MockDeviceBuffer>>(desc);
}

// The passes are heap-allocated, since they are ref-counted and assert in
// debug builds when destroyed without a reference.
class FlutterGpuComputePassTest : public ::testing::Test {
 protected:
  void SetUp() override {
    context_ = std::make_shared<NiceMock<MockImpellerContext>>();
    impeller_command_buffer_ =
        std::make_shared<NiceMock<MockCommandBuffer>>(context_);
    command_queue_ = std::make_shared<NiceMock<MockCommandQueue>>();
    ON_CALL(*context_, GetBackendType)
        .WillByDefault(Return(impeller::Context::BackendType::kMetal));
    ON_CALL(*context_, GetCommandQueue).WillByDefault(Return(command_queue_));
    ON_CALL(*impeller_command_buffer_, IsValid).WillByDefault(Return(true));
    command_buffer_ =
        fml::MakeRefCounted<CommandBuffer>(context_, impeller_command_buffer_);

    impeller::TextureDescriptor texture_desc;
    texture_desc.size = impeller::ISize(1, 1);
    texture_ = std::make_shared<NiceMock<MockTexture>>(texture_desc);
    sampler_ = std::make_shared<MockSampler>(impeller::SamplerDescriptor{});
  }

  std::shared_ptr<MockComputePass> MakeImpellerComputePass() {
    auto pass = std::make_shared<NiceMock<MockComputePass>>(context_);
    ON_CALL(*pass, IsValid).WillByDefault(Return(true));
    return pass;
  }

  /// Begins a compute pass that records into `impeller_pass`.
  fml::RefPtr<ComputePass> BeginComputePass(
      const std::shared_ptr<MockComputePass>& impeller_pass) {
    EXPECT_CALL(*impeller_command_buffer_, OnCreateComputePass)
        .WillOnce(Return(impeller_pass));
    auto pass = fml::MakeRefCounted<ComputePass>();
    EXPECT_TRUE(pass->Begin(*command_buffer_));
    return pass;
  }

  impeller::raw_ptr<const impeller::Sampler> Sampler() const {
    return impeller::raw_ptr<const impeller::Sampler>(sampler_);
  }

  std::shared_ptr<NiceMock<MockImpellerContext>> context_;
  std::shared_ptr<NiceMock<MockCommandBuffer>> impeller_command_buffer_;
  std::shared_ptr<NiceMock<MockCommandQueue>> command_queue_;
  fml::RefPtr<CommandBuffer> command_buffer_;
  std::shared_ptr<impeller::Texture> texture_;
  std::shared_ptr<const impeller::Sampler> sampler_;
};

// A compute pass follows the same lifecycle as a render pass: creating it
// ends the open pass, and the next pass ends it.
TEST_F(FlutterGpuComputePassTest, CreatingAndEndingFollowsThePassLifecycle) {
  auto render_pass = std::make_shared<NiceMock<MockRenderPass>>(
      context_, impeller::RenderTarget());
  ON_CALL(*render_pass, IsValid).WillByDefault(Return(true));
  auto compute_a = MakeImpellerComputePass();
  auto compute_b = MakeImpellerComputePass();
  {
    InSequence sequence;
    EXPECT_CALL(*impeller_command_buffer_, OnCreateRenderPass)
        .WillOnce(Return(render_pass));
    EXPECT_CALL(*render_pass, OnEncodeCommands).WillOnce(Return(true));
    EXPECT_CALL(*impeller_command_buffer_, OnCreateComputePass)
        .WillOnce(Return(compute_a));
    EXPECT_CALL(*compute_a, EncodeCommands).WillOnce(Return(true));
    EXPECT_CALL(*impeller_command_buffer_, OnCreateComputePass)
        .WillOnce(Return(compute_b));
    EXPECT_CALL(*compute_b, EncodeCommands).WillOnce(Return(true));
    EXPECT_CALL(*command_queue_, Submit).WillOnce(Return(fml::Status()));
  }

  ASSERT_TRUE(command_buffer_->CreateRenderPass(impeller::RenderTarget()));
  auto pass_a = fml::MakeRefCounted<ComputePass>();
  ASSERT_TRUE(pass_a->Begin(*command_buffer_));
  auto pass_b = fml::MakeRefCounted<ComputePass>();
  ASSERT_TRUE(pass_b->Begin(*command_buffer_));
  // pass_b is still open, so this must not end it.
  EXPECT_TRUE(pass_a->End());
  EXPECT_TRUE(pass_b->End());
  EXPECT_TRUE(pass_b->End());
  EXPECT_TRUE(command_buffer_->Submit());
}

// Bindings made for another shader are kept, but only the dispatched shader's
// own bindings reach the backend, each with its descriptor type.
TEST_F(FlutterGpuComputePassTest, ApplyBindingsBindsTheShadersBindings) {
  auto shader = MakeComputeShader();
  auto other_shader = MakeComputeShader();
  auto impeller_pass = MakeImpellerComputePass();
  auto pass = BeginComputePass(impeller_pass);
  auto params = MakeBuffer(64);
  auto particles = MakeBuffer(64);

  ASSERT_TRUE(pass->BindUniform(*shader, shader->GetUniformStruct("Params"),
                                params, 0, 16));
  ASSERT_TRUE(pass->BindStorageBuffer(
      *shader, shader->GetStorageBuffer("Particles"), particles, 16, 32));
  ASSERT_TRUE(pass->BindTexture(*shader, shader->GetUniformTexture("tex"),
                                texture_, Sampler()));
  ASSERT_TRUE(pass->BindStorageBuffer(
      *other_shader, other_shader->GetStorageBuffer("Particles"), particles, 0,
      16));

  EXPECT_CALL(*impeller_pass,
              BindResource(impeller::ShaderStage::kCompute,
                           impeller::DescriptorType::kUniformBuffer, _,
                           &shader->GetUniformStruct("Params")->metadata, _))
      .WillOnce(Return(true));
  EXPECT_CALL(*impeller_pass,
              BindResource(impeller::ShaderStage::kCompute,
                           impeller::DescriptorType::kStorageBuffer,
                           Truly([](const impeller::ShaderUniformSlot& slot) {
                             return slot.binding == 1u;
                           }),
                           &shader->GetStorageBuffer("Particles")->metadata,
                           Truly([](const impeller::BufferView& view) {
                             return view.GetRange().offset == 16u &&
                                    view.GetRange().length == 32u;
                           })))
      .WillOnce(Return(true));
  EXPECT_CALL(*impeller_pass,
              BindResource(impeller::ShaderStage::kCompute,
                           impeller::DescriptorType::kSampledImage, _,
                           &shader->GetUniformTexture("tex")->metadata,
                           std::shared_ptr<const impeller::Texture>(texture_),
                           Sampler()))
      .WillOnce(Return(true));

  EXPECT_EQ(pass->ApplyBindings(*shader), std::nullopt);
}

// Precedence matches render passes: an individual bind overrides a binding
// set, and a higher set slot overrides a lower one.
TEST_F(FlutterGpuComputePassTest, ApplyBindingsPrefersBindsThenHigherSets) {
  auto shader = MakeComputeShader();
  auto impeller_pass = MakeImpellerComputePass();
  auto pass = BeginComputePass(impeller_pass);
  auto buffer = MakeBuffer(256);

  auto low_set = fml::MakeRefCounted<BindingSet>();
  ASSERT_TRUE(low_set->AddUniform(
      *shader, shader->GetUniformStructIndex("Params"), buffer, 0, 16));
  ASSERT_TRUE(low_set->AddStorageBuffer(
      *shader, shader->GetStorageBufferIndex("Particles"), buffer, 0, 16));
  ASSERT_TRUE(low_set->AddTexture(
      *shader, shader->GetUniformTextureIndex("tex"), texture_, Sampler()));
  auto high_set = fml::MakeRefCounted<BindingSet>();
  ASSERT_TRUE(high_set->AddStorageBuffer(
      *shader, shader->GetStorageBufferIndex("Particles"), buffer, 64, 16));
  pass->BindSet(0, low_set);
  pass->BindSet(1, high_set);
  ASSERT_TRUE(pass->BindUniform(*shader, shader->GetUniformStruct("Params"),
                                buffer, 128, 16));

  auto offset_is = [](size_t offset) {
    return Truly([offset](const impeller::BufferView& view) {
      return view.GetRange().offset == offset;
    });
  };
  EXPECT_CALL(*impeller_pass,
              BindResource(_, impeller::DescriptorType::kUniformBuffer, _, _,
                           offset_is(128)))
      .WillOnce(Return(true));
  EXPECT_CALL(*impeller_pass,
              BindResource(_, impeller::DescriptorType::kStorageBuffer, _, _,
                           offset_is(64)))
      .WillOnce(Return(true));
  EXPECT_CALL(
      *impeller_pass,
      BindResource(_, impeller::DescriptorType::kSampledImage, _, _, _, _))
      .WillOnce(Return(true));

  EXPECT_EQ(pass->ApplyBindings(*shader), std::nullopt);
}

// Dispatching with a binding left empty would read whatever the backend has
// there, so it fails and names the binding instead.
TEST_F(FlutterGpuComputePassTest, ApplyBindingsNamesAMissingBinding) {
  auto shader = MakeComputeShader();
  auto impeller_pass = MakeImpellerComputePass();
  auto pass = BeginComputePass(impeller_pass);
  auto buffer = MakeBuffer(64);
  ASSERT_TRUE(pass->BindUniform(*shader, shader->GetUniformStruct("Params"),
                                buffer, 0, 16));
  ASSERT_TRUE(pass->BindTexture(*shader, shader->GetUniformTexture("tex"),
                                texture_, Sampler()));

  std::optional<std::string> error = pass->ApplyBindings(*shader);
  ASSERT_TRUE(error.has_value());
  EXPECT_EQ(error.value(),
            "The compute shader 'Entrypoint' declares the storage buffer "
            "'Particles', but nothing is bound to it.");

  // Clearing drops individual binds and sets alike.
  ASSERT_TRUE(pass->BindStorageBuffer(
      *shader, shader->GetStorageBuffer("Particles"), buffer, 0, 16));
  EXPECT_EQ(pass->ApplyBindings(*shader), std::nullopt);
  pass->ClearBindings();
  error = pass->ApplyBindings(*shader);
  ASSERT_TRUE(error.has_value());
  EXPECT_EQ(error.value(),
            "The compute shader 'Entrypoint' declares the uniform struct "
            "'Params', but nothing is bound to it.");
}

// Metal removes resources a shader never uses. They are still required, so
// that every backend takes the same bindings, but they are not handed to the
// backend.
TEST_F(FlutterGpuComputePassTest, ApplyBindingsRequiresButSkipsOptimizedOut) {
  std::unordered_map<std::string, Shader::StorageBufferBinding> storage_buffers;
  storage_buffers["Unused"] = Shader::StorageBufferBinding{
      .slot = impeller::ShaderUniformSlot{.name = "Unused",
                                          .ext_res_0 =
                                              impeller::kOptimizedOutBinding,
                                          .set = 0,
                                          .binding = 3},
      .metadata = impeller::ShaderMetadata{.name = "Unused", .members = {}},
      .size_in_bytes = 16,
  };
  auto shader =
      Shader::Make("library", "Entrypoint", impeller::ShaderStage::kCompute,
                   /*code_mapping=*/nullptr, /*inputs=*/{}, /*layouts=*/{},
                   /*uniform_structs=*/{}, /*uniform_textures=*/{},
                   /*descriptor_set_layouts=*/{}, std::move(storage_buffers),
                   std::array<uint32_t, 3>{1, 1, 1});
  auto impeller_pass = MakeImpellerComputePass();
  auto pass = BeginComputePass(impeller_pass);
  EXPECT_CALL(*impeller_pass, BindResource(_, _, _, _, _)).Times(0);

  std::optional<std::string> error = pass->ApplyBindings(*shader);
  ASSERT_TRUE(error.has_value());
  EXPECT_EQ(error.value(),
            "The compute shader 'Entrypoint' declares the storage buffer "
            "'Unused', but nothing is bound to it.");

  ASSERT_TRUE(pass->BindStorageBuffer(
      *shader, shader->GetStorageBuffer("Unused"), MakeBuffer(16), 0, 16));
  EXPECT_EQ(pass->ApplyBindings(*shader), std::nullopt);
}

// Only compute shaders take bindings from a compute pass, and a view must lie
// within its buffer.
TEST_F(FlutterGpuComputePassTest, BindRejectsInvalidBindings) {
  auto shader = MakeComputeShader();
  auto impeller_pass = MakeImpellerComputePass();
  auto pass = BeginComputePass(impeller_pass);
  auto buffer = MakeBuffer(64);

  EXPECT_FALSE(pass->BindStorageBuffer(*shader, nullptr, buffer, 0, 16));
  EXPECT_FALSE(pass->BindStorageBuffer(
      *shader, shader->GetStorageBuffer("Particles"), buffer, 32, 48));
  EXPECT_FALSE(pass->BindStorageBuffer(
      *shader, shader->GetStorageBuffer("Particles"), nullptr, 0, 16));
  EXPECT_FALSE(pass->BindTexture(*shader, shader->GetUniformTexture("tex"),
                                 nullptr, Sampler()));

  auto fragment =
      Shader::Make("library", "Fragment", impeller::ShaderStage::kFragment,
                   /*code_mapping=*/nullptr, /*inputs=*/{}, /*layouts=*/{},
                   /*uniform_structs=*/{}, /*uniform_textures=*/{},
                   /*descriptor_set_layouts=*/{});
  // The binding comes from a compute shader, but the shader is not one.
  EXPECT_FALSE(pass->BindUniform(*fragment, shader->GetUniformStruct("Params"),
                                 buffer, 0, 16));
}

// A dispatch with no workgroups does nothing, like a draw with no vertices,
// and any other dispatch needs a pipeline.
TEST_F(FlutterGpuComputePassTest, DispatchNeedsAPipelineUnlessTheGridIsEmpty) {
  auto impeller_pass = MakeImpellerComputePass();
  auto pass = BeginComputePass(impeller_pass);
  EXPECT_CALL(*impeller_pass, Compute).Times(0);

  EXPECT_EQ(pass->Dispatch({0, 1, 1}), std::nullopt);
  EXPECT_EQ(pass->Dispatch({4, 4, 0}), std::nullopt);
  std::optional<std::string> error = pass->Dispatch({1, 1, 1});
  ASSERT_TRUE(error.has_value());
  EXPECT_EQ(error.value(), "No ComputePipeline is bound.");
}

}  // namespace
}  // namespace flutter::gpu
