// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/render_pipeline.h"

#include "gtest/gtest.h"

#include "flutter/lib/gpu/shader.h"

namespace flutter::gpu {
namespace {

fml::RefPtr<Shader> MakeShader(impeller::ShaderStage stage) {
  return Shader::Make("library", "Entrypoint", stage,
                      /*code_mapping=*/nullptr, /*inputs=*/{}, /*layouts=*/{},
                      /*uniform_structs=*/{}, /*uniform_textures=*/{},
                      /*descriptor_set_layouts=*/{});
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

}  // namespace
}  // namespace flutter::gpu
