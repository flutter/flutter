// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <cstddef>
#include <future>

#include "flutter/fml/make_copyable.h"
#include "flutter/testing/testing.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"
#include "impeller/base/allocation.h"
#include "impeller/base/validation.h"
#include "impeller/core/runtime_types.h"
#include "impeller/core/shader_types.h"
#include "impeller/entity/runtime_effect.vert.h"
#include "impeller/playground/playground.h"
#include "impeller/renderer/pipeline_descriptor.h"
#include "impeller/renderer/pipeline_library.h"
#include "impeller/renderer/shader_library.h"
#include "impeller/runtime_stage/runtime_stage.h"
#include "impeller/runtime_stage/runtime_stage_flatbuffers.h"
#include "impeller/runtime_stage/runtime_stage_playground.h"
#include "runtime_stage_types_flatbuffers.h"
#include "third_party/abseil-cpp/absl/status/status_matchers.h"

namespace impeller {
namespace testing {

using RuntimeStageTest = RuntimeStagePlayground;
INSTANTIATE_PLAYGROUND_SUITE(RuntimeStageTest);

TEST_P(RuntimeStageTest, CanReadValidBlob) {
  const std::shared_ptr<fml::Mapping> fixture =
      flutter::testing::OpenFixtureAsMapping("ink_sparkle.frag.iplr");
  ASSERT_TRUE(fixture);
  ASSERT_GT(fixture->GetSize(), 0u);
  auto stages = RuntimeStage::DecodeRuntimeStages(fixture);
  ABSL_ASSERT_OK(stages);
  auto stage =
      stages.value()[PlaygroundBackendToRuntimeStageBackend(GetBackend())];
  ASSERT_TRUE(stage);
  ASSERT_EQ(stage->GetShaderStage(), RuntimeShaderStage::kFragment);
}

TEST_P(RuntimeStageTest, RejectInvalidFormatVersion) {
  flatbuffers::FlatBufferBuilder builder;
  fb::RuntimeStagesBuilder stages_builder(builder);
  stages_builder.add_format_version(0);
  auto stages = stages_builder.Finish();
  builder.Finish(stages, fb::RuntimeStagesIdentifier());
  auto mapping = std::make_shared<fml::NonOwnedMapping>(
      builder.GetBufferPointer(), builder.GetSize());
  auto runtime_stages = RuntimeStage::DecodeRuntimeStages(mapping);
  EXPECT_FALSE(runtime_stages.ok());
  EXPECT_EQ(runtime_stages.status().code(), absl::StatusCode::kInvalidArgument);
}

TEST_P(RuntimeStageTest, CanRejectInvalidBlob) {
  ScopedValidationDisable disable_validation;
  const std::shared_ptr<fml::Mapping> fixture =
      flutter::testing::OpenFixtureAsMapping("ink_sparkle.frag.iplr");
  ASSERT_TRUE(fixture);
  auto junk_allocation = std::make_shared<Allocation>();
  ASSERT_TRUE(junk_allocation->Truncate(Bytes{fixture->GetSize()}, false));
  // Not meant to be secure. Just reject obviously bad blobs using magic
  // numbers.
  ::memset(junk_allocation->GetBuffer(), 127,
           junk_allocation->GetLength().GetByteSize());
  auto stages = RuntimeStage::DecodeRuntimeStages(
      CreateMappingFromAllocation(junk_allocation));
  ASSERT_FALSE(stages.ok());
}

TEST_P(RuntimeStageTest, CanReadUniforms) {
  const std::shared_ptr<fml::Mapping> fixture =
      flutter::testing::OpenFixtureAsMapping(
          "all_supported_uniforms.frag.iplr");
  ASSERT_TRUE(fixture);
  ASSERT_GT(fixture->GetSize(), 0u);
  auto stages = RuntimeStage::DecodeRuntimeStages(fixture);
  ABSL_ASSERT_OK(stages);
  auto stage =
      stages.value()[PlaygroundBackendToRuntimeStageBackend(GetBackend())];

  ASSERT_TRUE(stage);
  switch (GetBackend()) {
    case PlaygroundBackend::kMetal:
      [[fallthrough]];
    case PlaygroundBackend::kOpenGLES: {
      ASSERT_EQ(stage->GetUniforms().size(), 14u);
      {
        // uFloat
        auto uni = stage->GetUniform("uFloat");
        ASSERT_NE(uni, nullptr);
        EXPECT_EQ(uni->dimensions.rows, 1u);
        EXPECT_EQ(uni->dimensions.cols, 1u);
        EXPECT_EQ(uni->location, 0u);
        EXPECT_EQ(uni->type, RuntimeUniformType::kFloat);
        EXPECT_TRUE(uni->padding_layout.empty());
      }
      {
        // uVec2
        auto uni = stage->GetUniform("uVec2");
        ASSERT_NE(uni, nullptr);
        EXPECT_EQ(uni->dimensions.rows, 2u);
        EXPECT_EQ(uni->dimensions.cols, 1u);
        EXPECT_EQ(uni->location, 1u);
        EXPECT_EQ(uni->type, RuntimeUniformType::kFloat);
        EXPECT_TRUE(uni->padding_layout.empty());
      }
      {
        // uVec3
        auto uni = stage->GetUniform("uVec3");
        ASSERT_NE(uni, nullptr);
        EXPECT_EQ(uni->dimensions.rows, 3u);
        EXPECT_EQ(uni->dimensions.cols, 1u);
        EXPECT_EQ(uni->location, 2u);
        EXPECT_EQ(uni->type, RuntimeUniformType::kFloat);
        auto padding = uni->padding_layout;
        if (GetBackend() == PlaygroundBackend::kMetal) {
          EXPECT_EQ(padding.size(), 4u);
          EXPECT_EQ(padding[0], RuntimePaddingType::kFloat);
          EXPECT_EQ(padding[1], RuntimePaddingType::kFloat);
          EXPECT_EQ(padding[2], RuntimePaddingType::kFloat);
          EXPECT_EQ(padding[3], RuntimePaddingType::kPadding);
        } else {
          EXPECT_TRUE(padding.empty());
        }
      }
      {
        // uVec4
        auto uni = stage->GetUniform("uVec4");
        ASSERT_NE(uni, nullptr);
        EXPECT_EQ(uni->dimensions.rows, 4u);
        EXPECT_EQ(uni->dimensions.cols, 1u);
        EXPECT_EQ(uni->location, 3u);
        EXPECT_EQ(uni->type, RuntimeUniformType::kFloat);
        EXPECT_TRUE(uni->padding_layout.empty());
      }
      {
        // uMat2
        auto uni = stage->GetUniform("uMat2");
        ASSERT_NE(uni, nullptr);
        EXPECT_EQ(uni->dimensions.rows, 2u);
        EXPECT_EQ(uni->dimensions.cols, 2u);
        EXPECT_EQ(uni->location, 4u);
        EXPECT_EQ(uni->type, RuntimeUniformType::kFloat);
        EXPECT_TRUE(uni->padding_layout.empty());
      }
      {
        // uMat3
        auto uni = stage->GetUniform("uMat3");
        ASSERT_NE(uni, nullptr);
        EXPECT_EQ(uni->dimensions.rows, 3u);
        EXPECT_EQ(uni->dimensions.cols, 3u);
        EXPECT_EQ(uni->location, 5u);
        EXPECT_EQ(uni->type, RuntimeUniformType::kFloat);
      }
      {
        // uMat4
        auto uni = stage->GetUniform("uMat4");
        ASSERT_NE(uni, nullptr);
        EXPECT_EQ(uni->dimensions.rows, 4u);
        EXPECT_EQ(uni->dimensions.cols, 4u);
        EXPECT_EQ(uni->location, 6u);
        EXPECT_EQ(uni->type, RuntimeUniformType::kFloat);
        EXPECT_TRUE(uni->padding_layout.empty());
      }
      {
        // uFloatArray
        auto uni = stage->GetUniform("uFloatArray");
        ASSERT_NE(uni, nullptr);
        EXPECT_EQ(uni->dimensions.rows, 1u);
        EXPECT_EQ(uni->dimensions.cols, 1u);
        EXPECT_EQ(uni->location, 7u);
        EXPECT_EQ(uni->type, RuntimeUniformType::kFloat);
        EXPECT_TRUE(uni->padding_layout.empty());
      }
      {
        auto uni = stage->GetUniform("uVec2Array");
        ASSERT_NE(uni, nullptr);
        EXPECT_EQ(uni->dimensions.rows, 2u);
        EXPECT_EQ(uni->dimensions.cols, 1u);
        EXPECT_EQ(uni->location, 9u);
        EXPECT_EQ(uni->type, RuntimeUniformType::kFloat);
        EXPECT_TRUE(uni->padding_layout.empty());
      }
      {
        // uVec3Array
        auto uni = stage->GetUniform("uVec3Array");
        ASSERT_NE(uni, nullptr);
        EXPECT_EQ(uni->dimensions.rows, 3u);
        EXPECT_EQ(uni->dimensions.cols, 1u);
        EXPECT_EQ(uni->location, 11u);
        EXPECT_EQ(uni->type, RuntimeUniformType::kFloat);
      }
      {
        // uVec4Array
        auto uni = stage->GetUniform("uVec4Array");
        ASSERT_NE(uni, nullptr);
        EXPECT_EQ(uni->dimensions.rows, 4u);
        EXPECT_EQ(uni->dimensions.cols, 1u);
        EXPECT_EQ(uni->location, 13u);
        EXPECT_EQ(uni->type, RuntimeUniformType::kFloat);
        EXPECT_TRUE(uni->padding_layout.empty());
      }
      {
        // uMat2Array
        auto uni = stage->GetUniform("uMat2Array");
        ASSERT_NE(uni, nullptr);
        EXPECT_EQ(uni->dimensions.rows, 2u);
        EXPECT_EQ(uni->dimensions.cols, 2u);
        EXPECT_EQ(uni->location, 15u);
        EXPECT_EQ(uni->type, RuntimeUniformType::kFloat);
        EXPECT_TRUE(uni->padding_layout.empty());
      }
      {
        // uMat3Array
        auto uni = stage->GetUniform("uMat3Array");
        ASSERT_NE(uni, nullptr);
        EXPECT_EQ(uni->dimensions.rows, 3u);
        EXPECT_EQ(uni->dimensions.cols, 3u);
        EXPECT_EQ(uni->location, 17u);
        EXPECT_EQ(uni->type, RuntimeUniformType::kFloat);
      }
      {
        // uMat4Array
        auto uni = stage->GetUniform("uMat4Array");
        ASSERT_NE(uni, nullptr);
        EXPECT_EQ(uni->dimensions.rows, 4u);
        EXPECT_EQ(uni->dimensions.cols, 4u);
        EXPECT_EQ(uni->location, 19u);
        EXPECT_EQ(uni->type, RuntimeUniformType::kFloat);
        EXPECT_TRUE(uni->padding_layout.empty());
      }
      break;
    }
    case PlaygroundBackend::kVulkan: {
      EXPECT_EQ(stage->GetUniforms().size(), 1u);
      const RuntimeUniformDescription* uni =
          stage->GetUniform(RuntimeStage::kVulkanUBOName);
      ASSERT_TRUE(uni);
      EXPECT_EQ(uni->type, RuntimeUniformType::kStruct);
      EXPECT_EQ(uni->struct_float_count, 35u);

      EXPECT_EQ(uni->GetGPUSize(), 640u);
      std::vector<RuntimePaddingType> layout(uni->GetGPUSize() / sizeof(float),
                                             RuntimePaddingType::kFloat);
      // uFloat and uVec2 are packed into a vec4 with 1 byte of padding between.
      layout[1] = RuntimePaddingType::kPadding;
      // uVec3 is packed as a vec4 with 1 byte of padding.
      layout[7] = RuntimePaddingType::kPadding;
      // uMat2 is packed as two vec4s, with the last 2 bytes of each being
      // padding.
      layout[14] = RuntimePaddingType::kPadding;
      layout[15] = RuntimePaddingType::kPadding;
      layout[18] = RuntimePaddingType::kPadding;
      layout[19] = RuntimePaddingType::kPadding;
      // uMat3 is packed as 3 vec4s, with the last 3 bytes being padding
      layout[29] = RuntimePaddingType::kPadding;
      layout[30] = RuntimePaddingType::kPadding;
      layout[31] = RuntimePaddingType::kPadding;
      // uFloatArray is packed as 2 vec4s, with the last 3 bytes of each
      // being padding.
      layout[49] = RuntimePaddingType::kPadding;
      layout[50] = RuntimePaddingType::kPadding;
      layout[51] = RuntimePaddingType::kPadding;
      layout[53] = RuntimePaddingType::kPadding;
      layout[54] = RuntimePaddingType::kPadding;
      layout[55] = RuntimePaddingType::kPadding;
      // uVec2Array is packed as 2 vec4s, with 2 bytes of padding at the end of
      // each.
      layout[58] = RuntimePaddingType::kPadding;
      layout[59] = RuntimePaddingType::kPadding;
      layout[62] = RuntimePaddingType::kPadding;
      layout[63] = RuntimePaddingType::kPadding;
      // uVec3Array is packed as 2 vec4s, with the last byte of each as padding.
      layout[67] = RuntimePaddingType::kPadding;
      layout[71] = RuntimePaddingType::kPadding;
      // uVec4Array has no padding.
      // uMat2Array[2] is packed as 4 vec4s, With the last 2 bytes of each being
      // padding. padding.
      layout[82] = RuntimePaddingType::kPadding;
      layout[83] = RuntimePaddingType::kPadding;
      layout[86] = RuntimePaddingType::kPadding;
      layout[87] = RuntimePaddingType::kPadding;
      layout[90] = RuntimePaddingType::kPadding;
      layout[91] = RuntimePaddingType::kPadding;
      layout[94] = RuntimePaddingType::kPadding;
      layout[95] = RuntimePaddingType::kPadding;
      // uMat3Array[2] is packed as 6 vec4s, with the last 3 bytes of the 3rd
      // and 6th being padding.
      layout[105] = RuntimePaddingType::kPadding;
      layout[106] = RuntimePaddingType::kPadding;
      layout[107] = RuntimePaddingType::kPadding;
      layout[117] = RuntimePaddingType::kPadding;
      layout[118] = RuntimePaddingType::kPadding;
      layout[119] = RuntimePaddingType::kPadding;
      // uMat4Array[2] is packed as 8 vec4s with no padding.
      layout[152] = RuntimePaddingType::kPadding;
      layout[153] = RuntimePaddingType::kPadding;
      layout[154] = RuntimePaddingType::kPadding;
      layout[155] = RuntimePaddingType::kPadding;
      layout[156] = RuntimePaddingType::kPadding;
      layout[157] = RuntimePaddingType::kPadding;
      layout[158] = RuntimePaddingType::kPadding;
      layout[159] = RuntimePaddingType::kPadding;

      EXPECT_THAT(uni->padding_layout, ::testing::ElementsAreArray(layout));

      std::vector<std::pair<std::string, unsigned int>> expected_uniforms = {
          {"uFloat", 4},      {"uVec2", 8},       {"uVec3", 12},
          {"uVec4", 16},      {"uMat2", 16},      {"uMat3", 36},
          {"uMat4", 64},      {"uFloatArray", 8}, {"uVec2Array", 16},
          {"uVec3Array", 24}, {"uVec4Array", 32}, {"uMat2Array", 32},
          {"uMat3Array", 72}, {"uMat4Array", 128}};

      ASSERT_EQ(uni->struct_fields.size(), expected_uniforms.size());

      for (size_t i = 0; i < expected_uniforms.size(); ++i) {
        const auto& element = uni->struct_fields[i];
        const auto& expected = expected_uniforms[i];

        EXPECT_EQ(element.name, expected.first) << "index: " << i;
        EXPECT_EQ(element.byte_size, expected.second) << "index: " << i;
      }
      break;
    }
  }
}

TEST_P(RuntimeStageTest, CanReadUniformsSamplerBeforeUBO) {
  if (GetBackend() != PlaygroundBackend::kVulkan) {
    GTEST_SKIP() << "Test only relevant for Vulkan";
  }
  const std::shared_ptr<fml::Mapping> fixture =
      flutter::testing::OpenFixtureAsMapping(
          "uniforms_and_sampler_1.frag.iplr");
  ASSERT_TRUE(fixture);
  ASSERT_GT(fixture->GetSize(), 0u);
  auto stages = RuntimeStage::DecodeRuntimeStages(fixture);
  ABSL_ASSERT_OK(stages);
  auto stage =
      stages.value()[PlaygroundBackendToRuntimeStageBackend(GetBackend())];

  EXPECT_EQ(stage->GetUniforms().size(), 2u);
  auto uni = stage->GetUniform(RuntimeStage::kVulkanUBOName);
  ASSERT_TRUE(uni);
  // Struct must be offset at 65.
  EXPECT_EQ(uni->type, RuntimeUniformType::kStruct);
  EXPECT_EQ(uni->binding, 65u);
  // Sampler should be offset at 64 but due to current bug
  // has offset of 0, the correct offset is computed at runtime.
  auto sampler_uniform = stage->GetUniform("u_texture");
  EXPECT_EQ(sampler_uniform->type, RuntimeUniformType::kSampledImage);
  EXPECT_EQ(sampler_uniform->binding, 64u);
}

TEST_P(RuntimeStageTest, CanReadUniformsSamplerAfterUBO) {
  if (GetBackend() != PlaygroundBackend::kVulkan) {
    GTEST_SKIP() << "Test only relevant for Vulkan";
  }
  const std::shared_ptr<fml::Mapping> fixture =
      flutter::testing::OpenFixtureAsMapping(
          "uniforms_and_sampler_2.frag.iplr");
  ASSERT_TRUE(fixture);
  ASSERT_GT(fixture->GetSize(), 0u);
  auto stages = RuntimeStage::DecodeRuntimeStages(fixture);
  ABSL_ASSERT_OK(stages);
  auto stage =
      stages.value()[PlaygroundBackendToRuntimeStageBackend(GetBackend())];

  EXPECT_EQ(stage->GetUniforms().size(), 2u);
  auto uni = stage->GetUniform(RuntimeStage::kVulkanUBOName);
  ASSERT_TRUE(uni);
  // Struct must be offset at 45.
  EXPECT_EQ(uni->type, RuntimeUniformType::kStruct);
  EXPECT_EQ(uni->binding, 64u);
  // Sampler should be offset at 64 but due to current bug
  // has offset of 0, the correct offset is computed at runtime.
  auto sampler_uniform = stage->GetUniform("u_texture");
  EXPECT_EQ(sampler_uniform->type, RuntimeUniformType::kSampledImage);
  EXPECT_EQ(sampler_uniform->binding, 65u);
}

TEST_P(RuntimeStageTest, CanRegisterStage) {
  const std::shared_ptr<fml::Mapping> fixture =
      flutter::testing::OpenFixtureAsMapping("ink_sparkle.frag.iplr");
  ASSERT_TRUE(fixture);
  ASSERT_GT(fixture->GetSize(), 0u);
  auto stages = RuntimeStage::DecodeRuntimeStages(fixture);
  ABSL_ASSERT_OK(stages);
  auto stage =
      stages.value()[PlaygroundBackendToRuntimeStageBackend(GetBackend())];
  ASSERT_TRUE(stage);
  std::promise<bool> registration;
  auto future = registration.get_future();
  auto library = GetContext()->GetShaderLibrary();
  library->RegisterFunction(
      stage->GetEntrypoint(),                  //
      ToShaderStage(stage->GetShaderStage()),  //
      stage->GetCodeMapping(),                 //
      fml::MakeCopyable([reg = std::move(registration)](bool result) mutable {
        reg.set_value(result);
      }));
  ASSERT_TRUE(future.get());
  {
    auto function =
        library->GetFunction(stage->GetEntrypoint(), ShaderStage::kFragment);
    ASSERT_NE(function, nullptr);
  }

  // Check if unregistering works.

  library->UnregisterFunction(stage->GetEntrypoint(), ShaderStage::kFragment);
  {
    auto function =
        library->GetFunction(stage->GetEntrypoint(), ShaderStage::kFragment);
    ASSERT_EQ(function, nullptr);
  }
}

TEST_P(RuntimeStageTest, CanCreatePipelineFromRuntimeStage) {
  auto stages_result = OpenAssetAsRuntimeStage("ink_sparkle.frag.iplr");
  ABSL_ASSERT_OK(stages_result);
  auto stage =
      stages_result
          .value()[PlaygroundBackendToRuntimeStageBackend(GetBackend())];

  ASSERT_TRUE(stage);
  ASSERT_NE(stage, nullptr);
  ASSERT_TRUE(RegisterStage(*stage));
  auto library = GetContext()->GetShaderLibrary();
  using VS = RuntimeEffectVertexShader;
  PipelineDescriptor desc;
  desc.SetLabel("Runtime Stage InkSparkle");
  desc.AddStageEntrypoint(
      library->GetFunction(VS::kEntrypointName, ShaderStage::kVertex));
  desc.AddStageEntrypoint(
      library->GetFunction(stage->GetEntrypoint(), ShaderStage::kFragment));
  auto vertex_descriptor = std::make_shared<VertexDescriptor>();
  vertex_descriptor->SetStageInputs(VS::kAllShaderStageInputs,
                                    VS::kInterleavedBufferLayout);

  std::array<DescriptorSetLayout, 2> descriptor_set_layouts = {
      VS::kDescriptorSetLayouts[0],
      DescriptorSetLayout{
          .binding = 64u,
          .descriptor_type = DescriptorType::kUniformBuffer,
          .shader_stage = ShaderStage::kFragment,
      },
  };
  vertex_descriptor->RegisterDescriptorSetLayouts(descriptor_set_layouts);

  desc.SetVertexDescriptor(std::move(vertex_descriptor));
  ColorAttachmentDescriptor color0;
  color0.format = GetContext()->GetCapabilities()->GetDefaultColorFormat();
  StencilAttachmentDescriptor stencil0;
  stencil0.stencil_compare = CompareFunction::kEqual;
  desc.SetColorAttachmentDescriptor(0u, color0);
  desc.SetStencilAttachmentDescriptors(stencil0);
  const auto stencil_fmt =
      GetContext()->GetCapabilities()->GetDefaultStencilFormat();
  desc.SetStencilPixelFormat(stencil_fmt);
  auto pipeline = GetContext()->GetPipelineLibrary()->GetPipeline(desc).Get();
  ASSERT_NE(pipeline, nullptr);
}

TEST_P(RuntimeStageTest, ContainsExpectedShaderTypes) {
  auto stages_result = OpenAssetAsRuntimeStage("ink_sparkle.frag.iplr");
  ABSL_ASSERT_OK(stages_result);
  auto stages = stages_result.value();
  // Right now, SkSL gets implicitly bundled regardless of what the build rule
  // for this test requested. After
  // https://github.com/flutter/flutter/issues/138919, this may require a build
  // rule change or a new test.
  EXPECT_TRUE(stages[RuntimeStageBackend::kSkSL]);

  EXPECT_TRUE(stages[RuntimeStageBackend::kOpenGLES]);
  EXPECT_TRUE(stages[RuntimeStageBackend::kMetal]);
  EXPECT_TRUE(stages[RuntimeStageBackend::kVulkan]);
}

}  // namespace testing
}  // namespace impeller
