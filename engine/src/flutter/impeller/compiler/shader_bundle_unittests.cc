// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gtest/gtest.h"
#include "impeller/compiler/shader_bundle.h"

#include "flutter/testing/testing.h"
#include "impeller/compiler/source_options.h"
#include "impeller/compiler/types.h"
#include "impeller/runtime_stage/runtime_stage_types_flatbuffers.h"
#include "impeller/shader_bundle/shader_bundle_flatbuffers.h"

namespace impeller {
namespace compiler {
namespace testing {

const std::string kUnlitFragmentBundleConfig =
    "\"UnlitFragment\": {\"type\": \"fragment\", \"file\": "
    "\"shaders/flutter_gpu_unlit.frag\"}";
const std::string kUnlitVertexBundleConfig =
    "\"UnlitVertex\": {\"type\": \"vertex\", \"file\": "
    "\"shaders/flutter_gpu_unlit.vert\"}";

TEST(ShaderBundleTest, ParseShaderBundleConfigFailsForInvalidJSON) {
  std::string bundle = "";
  std::stringstream error;
  auto result = ParseShaderBundleConfig(bundle, error);
  ASSERT_FALSE(result.has_value());
  ASSERT_STREQ(error.str().c_str(),
               "The shader bundle is not a valid JSON object.\n");
}

TEST(ShaderBundleTest, ParseShaderBundleConfigFailsWhenEntryNotObject) {
  std::string bundle = "{\"UnlitVertex\": []}";
  std::stringstream error;
  auto result = ParseShaderBundleConfig(bundle, error);
  ASSERT_FALSE(result.has_value());
  ASSERT_STREQ(
      error.str().c_str(),
      "Invalid shader entry \"UnlitVertex\": Entry is not a JSON object.\n");
}

TEST(ShaderBundleTest, ParseShaderBundleConfigFailsWhenMissingFile) {
  std::string bundle = "{\"UnlitVertex\": {\"type\": \"vertex\"}}";
  std::stringstream error;
  auto result = ParseShaderBundleConfig(bundle, error);
  ASSERT_FALSE(result.has_value());
  ASSERT_STREQ(error.str().c_str(),
               "Invalid shader entry \"UnlitVertex\": Missing required "
               "\"file\" field.\n");
}

TEST(ShaderBundleTest, ParseShaderBundleConfigFailsWhenMissingType) {
  std::string bundle =
      "{\"UnlitVertex\": {\"file\": \"shaders/flutter_gpu_unlit.vert\"}}";
  std::stringstream error;
  auto result = ParseShaderBundleConfig(bundle, error);
  ASSERT_FALSE(result.has_value());
  ASSERT_STREQ(error.str().c_str(),
               "Invalid shader entry \"UnlitVertex\": Missing required "
               "\"type\" field.\n");
}

TEST(ShaderBundleTest, ParseShaderBundleConfigFailsForInvalidType) {
  std::string bundle =
      "{\"UnlitVertex\": {\"type\": \"invalid\", \"file\": "
      "\"shaders/flutter_gpu_unlit.vert\"}}";
  std::stringstream error;
  auto result = ParseShaderBundleConfig(bundle, error);
  ASSERT_FALSE(result.has_value());
  ASSERT_STREQ(error.str().c_str(),
               "Invalid shader entry \"UnlitVertex\": Shader type "
               "\"invalid\" is unknown.\n");
}

TEST(ShaderBundleTest, ParseShaderBundleConfigFailsForInvalidLanguage) {
  std::string bundle =
      "{\"UnlitVertex\": {\"type\": \"vertex\", \"language\": \"invalid\", "
      "\"file\": \"shaders/flutter_gpu_unlit.vert\"}}";
  std::stringstream error;
  auto result = ParseShaderBundleConfig(bundle, error);
  ASSERT_FALSE(result.has_value());
  ASSERT_STREQ(error.str().c_str(),
               "Invalid shader entry \"UnlitVertex\": Unknown language type "
               "\"invalid\".\n");
}

TEST(ShaderBundleTest, ParseShaderBundleConfigReturnsExpectedConfig) {
  std::string bundle =
      "{" + kUnlitVertexBundleConfig + ", " + kUnlitFragmentBundleConfig + "}";
  std::stringstream error;
  auto result = ParseShaderBundleConfig(bundle, error);
  ASSERT_TRUE(result.has_value());
  ASSERT_STREQ(error.str().c_str(), "");

  // NOLINTBEGIN(bugprone-unchecked-optional-access)
  auto maybe_vertex = result->find("UnlitVertex");
  auto maybe_fragment = result->find("UnlitFragment");
  ASSERT_TRUE(maybe_vertex != result->end());
  ASSERT_TRUE(maybe_fragment != result->end());
  auto vertex = maybe_vertex->second;
  auto fragment = maybe_fragment->second;
  // NOLINTEND(bugprone-unchecked-optional-access)

  EXPECT_EQ(vertex.type, SourceType::kVertexShader);
  EXPECT_EQ(vertex.language, SourceLanguage::kGLSL);
  EXPECT_STREQ(vertex.entry_point.c_str(), "main");
  EXPECT_STREQ(vertex.source_file_name.c_str(),
               "shaders/flutter_gpu_unlit.vert");

  EXPECT_EQ(fragment.type, SourceType::kFragmentShader);
  EXPECT_EQ(fragment.language, SourceLanguage::kGLSL);
  EXPECT_STREQ(fragment.entry_point.c_str(), "main");
  EXPECT_STREQ(fragment.source_file_name.c_str(),
               "shaders/flutter_gpu_unlit.frag");
}

template <typename T>
const T* FindByName(const std::vector<std::unique_ptr<T>>& collection,
                    const std::string& name) {
  const auto maybe = std::find_if(
      collection.begin(), collection.end(),
      [&name](const std::unique_ptr<T>& value) { return value->name == name; });
  if (maybe == collection.end()) {
    return nullptr;
  }
  return maybe->get();
}

TEST(ShaderBundleTest, GenerateShaderBundleFlatbufferProducesCorrectResult) {
  std::string fixtures_path = flutter::testing::GetFixturesPath();
  std::string config =
      "{\"UnlitFragment\": {\"type\": \"fragment\", \"file\": \"" +
      fixtures_path +
      "/flutter_gpu_unlit.frag\"}, \"UnlitVertex\": {\"type\": "
      "\"vertex\", \"file\": \"" +
      fixtures_path + "/flutter_gpu_unlit.vert\"}}";

  SourceOptions options;
  options.target_platform = TargetPlatform::kRuntimeStageMetal;
  options.source_language = SourceLanguage::kGLSL;

  std::optional<fb::ShaderBundleT> bundle =
      GenerateShaderBundleFlatbuffer(config, options);
  ASSERT_TRUE(bundle.has_value());

  // NOLINTNEXTLINE(bugprone-unchecked-optional-access)
  const auto& shaders = bundle->shaders;
  const auto* vertex = FindByName(shaders, "UnlitVertex");
  const auto* fragment = FindByName(shaders, "UnlitFragment");
  ASSERT_NE(vertex, nullptr);
  ASSERT_NE(fragment, nullptr);

  // --------------------------------------------------------------------------
  /// Verify vertex shader.
  ///

  EXPECT_TRUE(vertex->shader->metal);
  EXPECT_STREQ(vertex->shader->metal->entrypoint.c_str(),
               "flutter_gpu_unlit_vertex_main");
  EXPECT_EQ(vertex->shader->metal->stage, fb::Stage::kVertex);

  // Inputs.
  ASSERT_EQ(vertex->shader->metal->inputs.size(), 1u);
  const auto& v_in_position = vertex->shader->metal->inputs[0];
  EXPECT_STREQ(v_in_position->name.c_str(), "position");
  EXPECT_EQ(v_in_position->location, 0u);
  EXPECT_EQ(v_in_position->set, 0u);
  EXPECT_EQ(v_in_position->binding, 0u);
  EXPECT_EQ(v_in_position->type, fb::InputDataType::kFloat);
  EXPECT_EQ(v_in_position->bit_width, 32u);
  EXPECT_EQ(v_in_position->vec_size, 2u);
  EXPECT_EQ(v_in_position->columns, 1u);
  EXPECT_EQ(v_in_position->offset, 0u);

  // Uniforms.
  ASSERT_EQ(vertex->shader->metal->uniforms.size(), 2u);
  const auto* v_mvp = FindByName(vertex->shader->metal->uniforms, "mvp");
  ASSERT_NE(v_mvp, nullptr);
  EXPECT_EQ(v_mvp->location, 0u);
  EXPECT_EQ(v_mvp->type, fb::UniformDataType::kFloat);
  EXPECT_EQ(v_mvp->bit_width, 32u);
  EXPECT_EQ(v_mvp->rows, 4u);
  EXPECT_EQ(v_mvp->columns, 4u);
  EXPECT_EQ(v_mvp->array_elements, 0u);
  const auto* v_color = FindByName(vertex->shader->metal->uniforms, "color");
  ASSERT_NE(v_color, nullptr);
  EXPECT_EQ(v_color->location, 1u);
  EXPECT_EQ(v_color->type, fb::UniformDataType::kFloat);
  EXPECT_EQ(v_color->bit_width, 32u);
  EXPECT_EQ(v_color->rows, 4u);
  EXPECT_EQ(v_color->columns, 1u);
  EXPECT_EQ(v_color->array_elements, 0u);

  // --------------------------------------------------------------------------
  /// Verify fragment shader.
  ///

  EXPECT_TRUE(fragment->shader->metal);
  EXPECT_STREQ(fragment->shader->metal->entrypoint.c_str(),
               "flutter_gpu_unlit_fragment_main");
  EXPECT_EQ(fragment->shader->metal->stage, fb::Stage::kFragment);

  // Inputs (not recorded for fragment shaders).
  ASSERT_EQ(fragment->shader->metal->inputs.size(), 0u);

  // Uniforms.
  ASSERT_EQ(fragment->shader->metal->inputs.size(), 0u);
}

}  // namespace testing
}  // namespace compiler
}  // namespace impeller
