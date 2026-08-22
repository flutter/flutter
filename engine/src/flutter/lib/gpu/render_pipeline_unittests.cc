// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/render_pipeline.h"

#include "gtest/gtest.h"

#include <optional>
#include <utility>

#include "flutter/lib/gpu/shader.h"

namespace flutter::gpu {
namespace {

fml::RefPtr<Shader> MakeShader(
    impeller::ShaderStage stage,
    std::optional<Shader::PushConstantBinding> push_constants = std::nullopt) {
  return Shader::Make("library", "Entrypoint", stage,
                      /*code_mapping=*/nullptr, /*inputs=*/{}, /*layouts=*/{},
                      /*uniform_structs=*/{}, /*uniform_textures=*/{},
                      /*descriptor_set_layouts=*/{}, std::move(push_constants));
}

Shader::PushConstantBinding MakePushConstantBlock(size_t size_in_bytes) {
  return Shader::PushConstantBinding{
      .slot =
          impeller::ShaderPushConstantSlot{
              .name = "DrawInfo",
              .ext_res_0 = 0u,
              .size_in_bytes = size_in_bytes,
          },
      .metadata = impeller::ShaderMetadata{.name = "DrawInfo", .members = {}},
  };
}

// Pairing shaders of the wrong stages previously constructed a pipeline that
// only failed at first draw, deep inside backend pipeline compilation; the
// stages must be rejected with an error at creation instead.
TEST(FlutterGpuRenderPipelineTest, ValidatesShaderStages) {
  auto vertex = MakeShader(impeller::ShaderStage::kVertex);
  auto fragment = MakeShader(impeller::ShaderStage::kFragment);

  EXPECT_EQ(ValidateRenderPipelineShaderStages(*vertex, *fragment), nullptr);

  const char* swapped = ValidateRenderPipelineShaderStages(*fragment, *vertex);
  ASSERT_NE(swapped, nullptr);
  EXPECT_NE(std::string(swapped).find("vertex"), std::string::npos);

  const char* two_vertex = ValidateRenderPipelineShaderStages(*vertex, *vertex);
  ASSERT_NE(two_vertex, nullptr);
  EXPECT_NE(std::string(two_vertex).find("fragment"), std::string::npos);
}

// A shader reflects its push constant block independently of its uniform
// structs, and the member lookup is scoped to that block.
TEST(FlutterGpuRenderPipelineTest, ReflectsPushConstantBlock) {
  auto without = MakeShader(impeller::ShaderStage::kVertex);
  EXPECT_EQ(without->GetPushConstantBlock(), nullptr);

  auto with = MakeShader(impeller::ShaderStage::kVertex,
                         MakePushConstantBlock(/*size_in_bytes=*/80u));
  const auto* block = with->GetPushConstantBlock();
  ASSERT_NE(block, nullptr);
  EXPECT_EQ(block->slot.size_in_bytes, 80u);
  EXPECT_EQ(block->GetMemberMetadata("missing"), nullptr);
}

}  // namespace
}  // namespace flutter::gpu
