// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/binding_set.h"

#include <memory>
#include <string>
#include <unordered_map>
#include <utility>

#include "gtest/gtest.h"

#include "flutter/lib/gpu/shader.h"
#include "impeller/core/device_buffer_descriptor.h"
#include "impeller/core/sampler_descriptor.h"
#include "impeller/core/texture_descriptor.h"
#include "impeller/renderer/testing/mocks.h"

namespace flutter::gpu {
namespace {

constexpr size_t kFrameInfoExtRes0 = 3;
constexpr size_t kTextureIndex = 2;

// A shader declaring one uniform struct ("FrameInfo") and one texture
// ("tex"), which is all a binding set resolves against.
fml::RefPtr<Shader> MakeShader(impeller::ShaderStage stage) {
  std::unordered_map<std::string, Shader::UniformBinding> uniform_structs;
  uniform_structs["FrameInfo"] = Shader::UniformBinding{
      .slot =
          impeller::ShaderUniformSlot{
              .name = "FrameInfo",
              .ext_res_0 = kFrameInfoExtRes0,
              .set = 0,
              .binding = 0,
          },
      .metadata = impeller::ShaderMetadata{.name = "FrameInfo", .members = {}},
      .size_in_bytes = 64,
  };

  std::unordered_map<std::string, Shader::TextureBinding> uniform_textures;
  Shader::TextureBinding texture_binding;
  texture_binding.slot = impeller::SampledImageSlot{
      .name = "tex",
      .texture_index = kTextureIndex,
      .set = 0,
      .binding = 1,
  };
  texture_binding.metadata =
      impeller::ShaderMetadata{.name = "tex", .members = {}};
  uniform_textures["tex"] = texture_binding;

  return Shader::Make("library", "Entrypoint", stage,
                      /*code_mapping=*/nullptr, /*inputs=*/{}, /*layouts=*/{},
                      std::move(uniform_structs), std::move(uniform_textures),
                      /*descriptor_set_layouts=*/{});
}

std::shared_ptr<impeller::DeviceBuffer> MakeBuffer(size_t size) {
  impeller::DeviceBufferDescriptor desc;
  desc.size = size;
  return std::make_shared<impeller::testing::MockDeviceBuffer>(desc);
}

std::shared_ptr<impeller::Texture> MakeTexture() {
  impeller::TextureDescriptor desc;
  desc.size = impeller::ISize{1, 1};
  return std::make_shared<impeller::testing::MockTexture>(desc);
}

// A set resolves each entry against the shader's reflection data once, so the
// slot and the borrowed metadata must both come from the shader's binding.
TEST(FlutterGpuBindingSetTest, AddUniformResolvesTheShaderBinding) {
  auto shader = MakeShader(impeller::ShaderStage::kVertex);
  auto set = fml::MakeRefCounted<BindingSet>();
  auto buffer = MakeBuffer(128);

  EXPECT_TRUE(set->AddUniform(*shader, /*uniform_struct_index=*/0, buffer,
                              /*offset_in_bytes=*/16,
                              /*length_in_bytes=*/64));

  ASSERT_EQ(set->GetBufferBindings().size(), 1u);
  const BindingSet::BufferBinding& binding = set->GetBufferBindings()[0];
  EXPECT_EQ(binding.stage, impeller::ShaderStage::kVertex);
  EXPECT_EQ(binding.slot.ext_res_0, kFrameInfoExtRes0);
  ASSERT_NE(binding.metadata, nullptr);
  EXPECT_EQ(binding.metadata->name, "FrameInfo");
  EXPECT_EQ(binding.view.GetRange().offset, 16u);
  EXPECT_EQ(binding.view.GetRange().length, 64u);
}

// An index outside the shader's binding order names no uniform, so the entry
// must be rejected rather than resolved to whatever is at that address.
TEST(FlutterGpuBindingSetTest, AddUniformRejectsAnOutOfRangeIndex) {
  auto shader = MakeShader(impeller::ShaderStage::kFragment);
  auto set = fml::MakeRefCounted<BindingSet>();
  auto buffer = MakeBuffer(128);

  EXPECT_FALSE(set->AddUniform(*shader, /*uniform_struct_index=*/1, buffer,
                               /*offset_in_bytes=*/0,
                               /*length_in_bytes=*/64));
  EXPECT_FALSE(set->AddUniform(*shader, /*uniform_struct_index=*/-1, buffer,
                               /*offset_in_bytes=*/0,
                               /*length_in_bytes=*/64));
  EXPECT_TRUE(set->GetBufferBindings().empty());
}

// The set outlives the call that created it, so an out of bounds view would
// only fail at draw time on a backend that bothers to check. Reject it here.
TEST(FlutterGpuBindingSetTest, AddUniformRejectsAViewPastTheEndOfTheBuffer) {
  auto shader = MakeShader(impeller::ShaderStage::kVertex);
  auto set = fml::MakeRefCounted<BindingSet>();
  auto buffer = MakeBuffer(64);

  EXPECT_FALSE(set->AddUniform(*shader, /*uniform_struct_index=*/0, buffer,
                               /*offset_in_bytes=*/32,
                               /*length_in_bytes=*/64));
  EXPECT_FALSE(set->AddUniform(*shader, /*uniform_struct_index=*/0,
                               /*buffer=*/nullptr, /*offset_in_bytes=*/0,
                               /*length_in_bytes=*/64));
  EXPECT_TRUE(set->GetBufferBindings().empty());
}

// Only the vertex and fragment stages take bindings from a render pass.
TEST(FlutterGpuBindingSetTest, AddRejectsNonRenderStages) {
  auto shader = MakeShader(impeller::ShaderStage::kCompute);
  auto set = fml::MakeRefCounted<BindingSet>();
  auto buffer = MakeBuffer(128);

  EXPECT_FALSE(set->AddUniform(*shader, /*uniform_struct_index=*/0, buffer,
                               /*offset_in_bytes=*/0,
                               /*length_in_bytes=*/64));
  EXPECT_TRUE(set->GetBufferBindings().empty());
}

TEST(FlutterGpuBindingSetTest, AddTextureResolvesTheShaderBinding) {
  auto shader = MakeShader(impeller::ShaderStage::kFragment);
  auto set = fml::MakeRefCounted<BindingSet>();
  auto texture = MakeTexture();
  std::shared_ptr<const impeller::Sampler> sampler =
      std::make_shared<impeller::testing::MockSampler>(
          impeller::SamplerDescriptor{});

  EXPECT_TRUE(
      set->AddTexture(*shader, /*uniform_texture_index=*/0, texture,
                      impeller::raw_ptr<const impeller::Sampler>(sampler)));

  ASSERT_EQ(set->GetTextureBindings().size(), 1u);
  const BindingSet::TextureBinding& binding = set->GetTextureBindings()[0];
  EXPECT_EQ(binding.stage, impeller::ShaderStage::kFragment);
  EXPECT_EQ(binding.slot.texture_index, kTextureIndex);
  ASSERT_NE(binding.metadata, nullptr);
  EXPECT_EQ(binding.metadata->name, "tex");
  EXPECT_EQ(binding.texture, texture);
}

TEST(FlutterGpuBindingSetTest, AddTextureRejectsAnOutOfRangeIndex) {
  auto shader = MakeShader(impeller::ShaderStage::kFragment);
  auto set = fml::MakeRefCounted<BindingSet>();
  auto texture = MakeTexture();
  std::shared_ptr<const impeller::Sampler> sampler =
      std::make_shared<impeller::testing::MockSampler>(
          impeller::SamplerDescriptor{});

  EXPECT_FALSE(
      set->AddTexture(*shader, /*uniform_texture_index=*/1, texture,
                      impeller::raw_ptr<const impeller::Sampler>(sampler)));
  EXPECT_TRUE(set->GetTextureBindings().empty());
}

// A shader hot reload replaces the reflection data the bindings point into,
// so the set has to be emptied before it is repopulated.
TEST(FlutterGpuBindingSetTest, ClearDropsEveryBinding) {
  auto shader = MakeShader(impeller::ShaderStage::kFragment);
  auto set = fml::MakeRefCounted<BindingSet>();
  auto buffer = MakeBuffer(128);
  auto texture = MakeTexture();
  std::shared_ptr<const impeller::Sampler> sampler =
      std::make_shared<impeller::testing::MockSampler>(
          impeller::SamplerDescriptor{});

  ASSERT_TRUE(set->AddUniform(*shader, /*uniform_struct_index=*/0, buffer,
                              /*offset_in_bytes=*/0, /*length_in_bytes=*/64));
  ASSERT_TRUE(
      set->AddTexture(*shader, /*uniform_texture_index=*/0, texture,
                      impeller::raw_ptr<const impeller::Sampler>(sampler)));

  set->Clear();

  EXPECT_TRUE(set->GetBufferBindings().empty());
  EXPECT_TRUE(set->GetTextureBindings().empty());
}

}  // namespace
}  // namespace flutter::gpu
