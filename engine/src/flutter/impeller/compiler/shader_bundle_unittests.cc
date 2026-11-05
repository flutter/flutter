// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gtest/gtest.h"
#include "impeller/compiler/shader_bundle.h"

#include "flutter/testing/testing.h"
#include "impeller/compiler/source_options.h"
#include "impeller/compiler/types.h"
#include "impeller/core/shader_types.h"
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

  std::optional<fb::shaderbundle::ShaderBundleT> bundle =
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

  EXPECT_STREQ(vertex->metal_desktop->entrypoint.c_str(),
               "flutter_gpu_unlit_vertex_main");
  EXPECT_EQ(vertex->metal_desktop->stage,
            fb::shaderbundle::ShaderStage::kVertex);

  // Inputs.
  ASSERT_EQ(vertex->metal_desktop->inputs.size(), 1u);
  const auto& v_in_position = vertex->metal_desktop->inputs[0];
  EXPECT_STREQ(v_in_position->name.c_str(), "position");
  EXPECT_EQ(v_in_position->location, 0u);
  EXPECT_EQ(v_in_position->set, 0u);
  EXPECT_EQ(v_in_position->binding, 0u);
  EXPECT_EQ(v_in_position->type, fb::shaderbundle::InputDataType::kFloat);
  EXPECT_EQ(v_in_position->bit_width, 32u);
  EXPECT_EQ(v_in_position->vec_size, 2u);
  EXPECT_EQ(v_in_position->columns, 1u);
  EXPECT_EQ(v_in_position->offset, 0u);

  // Uniforms.
  ASSERT_EQ(vertex->metal_desktop->uniform_structs.size(), 1u);
  const auto* vert_info =
      FindByName(vertex->metal_desktop->uniform_structs, "VertInfo");
  ASSERT_NE(vert_info, nullptr);
  EXPECT_EQ(vert_info->ext_res_0, 0u);
  EXPECT_EQ(vert_info->set, 0u);
  EXPECT_EQ(vert_info->binding, 0u);
  ASSERT_EQ(vert_info->fields.size(), 2u);
  const auto& mvp = vert_info->fields[0];
  EXPECT_STREQ(mvp->name.c_str(), "mvp");
  EXPECT_EQ(mvp->type, fb::shaderbundle::UniformDataType::kFloat);
  EXPECT_EQ(mvp->offset_in_bytes, 0u);
  EXPECT_EQ(mvp->element_size_in_bytes, 64u);
  EXPECT_EQ(mvp->total_size_in_bytes, 64u);
  EXPECT_EQ(mvp->array_elements, 0u);
  EXPECT_EQ(mvp->vec_size, 4u);
  EXPECT_EQ(mvp->columns, 4u);
  const auto& color = vert_info->fields[1];
  EXPECT_STREQ(color->name.c_str(), "color");
  EXPECT_EQ(color->type, fb::shaderbundle::UniformDataType::kFloat);
  EXPECT_EQ(color->offset_in_bytes, 64u);
  EXPECT_EQ(color->element_size_in_bytes, 16u);
  EXPECT_EQ(color->total_size_in_bytes, 16u);
  EXPECT_EQ(color->array_elements, 0u);
  EXPECT_EQ(color->vec_size, 4u);
  EXPECT_EQ(color->columns, 1u);

  // --------------------------------------------------------------------------
  /// Verify fragment shader.
  ///

  EXPECT_STREQ(fragment->metal_desktop->entrypoint.c_str(),
               "flutter_gpu_unlit_fragment_main");
  EXPECT_EQ(fragment->metal_desktop->stage,
            fb::shaderbundle::ShaderStage::kFragment);

  // Inputs (not recorded for fragment shaders).
  ASSERT_EQ(fragment->metal_desktop->inputs.size(), 0u);

  // Uniforms.
  ASSERT_EQ(fragment->metal_desktop->inputs.size(), 0u);
}

TEST(ShaderBundleTest,
     GenerateShaderBundleFlatbufferReportsSourceFilesAsDependencies) {
  std::string fixtures_path = flutter::testing::GetFixturesPath();
  const std::string fragment_path = fixtures_path + "/flutter_gpu_unlit.frag";
  const std::string vertex_path = fixtures_path + "/flutter_gpu_unlit.vert";
  std::string config =
      "{\"UnlitFragment\": {\"type\": \"fragment\", \"file\":\"" +
      fragment_path +
      "\"}, \"UnlitVertex\": {\"type\": \"vertex\", \"file\": \"" +
      vertex_path + "\"}}";

  SourceOptions options;
  options.target_platform = TargetPlatform::kRuntimeStageMetal;
  options.source_language = SourceLanguage::kGLSL;

  std::set<std::string> dependencies;
  std::optional<fb::shaderbundle::ShaderBundleT> bundle =
      GenerateShaderBundleFlatbuffer(config, options, &dependencies);
  ASSERT_TRUE(bundle.has_value());

  // Every primary source file referenced by the bundle config should
  // appear in the dependency set, deduplicated across the multiple
  // target-platform compiles of each shader. The fixtures used here
  // don't contain `#include` directives, so the dependency set
  // contains exactly the two source files.
  EXPECT_NE(dependencies.find(fragment_path), dependencies.end());
  EXPECT_NE(dependencies.find(vertex_path), dependencies.end());
}

TEST(ShaderBundleTest,
     GenerateShaderBundleFlatbufferIgnoresNullDependencyCollector) {
  // Passing nullptr as the dependency collector is supported and is
  // the default behaviour for callers that don't need a depfile.
  std::string fixtures_path = flutter::testing::GetFixturesPath();
  std::string config =
      "{\"UnlitFragment\": {\"type\": \"fragment\", \"file\": \"" +
      fixtures_path +
      "/flutter_gpu_unlit.frag\"}, \"UnlitVertex\": {\"type\": \"vertex\", "
      "\"file\": \"" +
      fixtures_path + "/flutter_gpu_unlit.vert\"}}";

  SourceOptions options;
  options.target_platform = TargetPlatform::kRuntimeStageMetal;
  options.source_language = SourceLanguage::kGLSL;

  std::optional<fb::shaderbundle::ShaderBundleT> bundle =
      GenerateShaderBundleFlatbuffer(config, options, /*out_dependencies=*/
                                     nullptr);
  ASSERT_TRUE(bundle.has_value());
}

TEST(ShaderBundleTest, DeriveShaderFloatTypeFromDimensions) {
  // Non-float types always map to nullopt.
  EXPECT_EQ(DeriveShaderFloatType(ShaderType::kSignedInt, 1, 1), std::nullopt);
  EXPECT_EQ(DeriveShaderFloatType(ShaderType::kUnsignedInt, 4, 1),
            std::nullopt);
  EXPECT_EQ(DeriveShaderFloatType(ShaderType::kBoolean, 1, 1), std::nullopt);

  // Scalar and vector floats (columns == 1).
  EXPECT_EQ(DeriveShaderFloatType(ShaderType::kFloat, 1, 1),
            ShaderFloatType::kFloat);
  EXPECT_EQ(DeriveShaderFloatType(ShaderType::kFloat, 2, 1),
            ShaderFloatType::kVec2);
  EXPECT_EQ(DeriveShaderFloatType(ShaderType::kFloat, 3, 1),
            ShaderFloatType::kVec3);
  EXPECT_EQ(DeriveShaderFloatType(ShaderType::kFloat, 4, 1),
            ShaderFloatType::kVec4);

  // Square matrices (vec_size == columns).
  EXPECT_EQ(DeriveShaderFloatType(ShaderType::kFloat, 2, 2),
            ShaderFloatType::kMat2);
  EXPECT_EQ(DeriveShaderFloatType(ShaderType::kFloat, 3, 3),
            ShaderFloatType::kMat3);
  EXPECT_EQ(DeriveShaderFloatType(ShaderType::kFloat, 4, 4),
            ShaderFloatType::kMat4);

  // Non-square matrices and unsupported shapes return nullopt.
  EXPECT_EQ(DeriveShaderFloatType(ShaderType::kFloat, 3, 2), std::nullopt);
  EXPECT_EQ(DeriveShaderFloatType(ShaderType::kFloat, 2, 3), std::nullopt);
  EXPECT_EQ(DeriveShaderFloatType(ShaderType::kFloat, 5, 1), std::nullopt);

  // Zero values (legacy bundle defaults) map to nullopt.
  EXPECT_EQ(DeriveShaderFloatType(ShaderType::kFloat, 0, 0), std::nullopt);
  EXPECT_EQ(DeriveShaderFloatType(ShaderType::kFloat, 0, 1), std::nullopt);
  EXPECT_EQ(DeriveShaderFloatType(ShaderType::kFloat, 1, 0), std::nullopt);
}

TEST(ShaderBundleTest, TargetPlatformDefinesMatchEachBackend) {
  EXPECT_EQ(GetShaderBundleTargetPlatformDefines(TargetPlatform::kMetalIOS),
            (std::vector<std::string_view>{"IMPELLER_TARGET_METAL",
                                           "IMPELLER_TARGET_METAL_IOS"}));
  EXPECT_EQ(GetShaderBundleTargetPlatformDefines(TargetPlatform::kMetalDesktop),
            (std::vector<std::string_view>{"IMPELLER_TARGET_METAL",
                                           "IMPELLER_TARGET_METAL_DESKTOP"}));
  EXPECT_EQ(GetShaderBundleTargetPlatformDefines(TargetPlatform::kOpenGLES),
            (std::vector<std::string_view>{"IMPELLER_TARGET_OPENGLES"}));
  EXPECT_EQ(
      GetShaderBundleTargetPlatformDefines(TargetPlatform::kOpenGLDesktop),
      (std::vector<std::string_view>{"IMPELLER_TARGET_OPENGL"}));
  EXPECT_EQ(GetShaderBundleTargetPlatformDefines(TargetPlatform::kVulkan),
            (std::vector<std::string_view>{"IMPELLER_TARGET_VULKAN"}));

  // Runtime stages and SkSL receive their defines elsewhere; the shader bundle
  // adds none for them.
  EXPECT_TRUE(
      GetShaderBundleTargetPlatformDefines(TargetPlatform::kRuntimeStageVulkan)
          .empty());
  EXPECT_TRUE(
      GetShaderBundleTargetPlatformDefines(TargetPlatform::kUnknown).empty());
}

TEST(ShaderBundleTest, InjectsTargetDefinesDuringCompilation) {
  // `check_gles_definition.frag` contains an invalid token guarded by
  // `#ifdef IMPELLER_TARGET_OPENGLES`. Bundling it must fail because the
  // OpenGLES backend now receives that define and compiles the error branch.
  // Without the injected define the OpenGLES backend would compile cleanly.
  std::string fixtures_path = flutter::testing::GetFixturesPath();
  std::string config = "{\"Probe\": {\"type\": \"fragment\", \"file\": \"" +
                       fixtures_path + "/check_gles_definition.frag\"}}";

  SourceOptions options;
  options.target_platform = TargetPlatform::kRuntimeStageMetal;
  options.source_language = SourceLanguage::kGLSL;

  std::optional<fb::shaderbundle::ShaderBundleT> bundle =
      GenerateShaderBundleFlatbuffer(config, options);
  EXPECT_FALSE(bundle.has_value());
}

static std::optional<fb::shaderbundle::ShaderBundleT> GenerateComputeBundle(
    const std::string& fixture_name) {
  std::string config = "{\"Compute\": {\"type\": \"compute\", \"file\": \"" +
                       std::string(flutter::testing::GetFixturesPath()) + "/" +
                       fixture_name + "\"}}";
  SourceOptions options;
  options.target_platform = TargetPlatform::kRuntimeStageMetal;
  options.source_language = SourceLanguage::kGLSL;
  return GenerateShaderBundleFlatbuffer(config, options);
}

TEST(ShaderBundleTest, GenerateShaderBundleFlatbufferReflectsComputeShader) {
  std::optional<fb::shaderbundle::ShaderBundleT> bundle =
      GenerateComputeBundle("flutter_gpu_compute.comp");
  ASSERT_TRUE(bundle.has_value());
  // NOLINTNEXTLINE(bugprone-unchecked-optional-access)
  const auto* compute = FindByName(bundle->shaders, "Compute");
  ASSERT_NE(compute, nullptr);

  // Every backend gets a variant, including OpenGL ES and desktop OpenGL.
  const std::vector<const fb::shaderbundle::BackendShaderT*> variants = {
      compute->metal_ios.get(), compute->metal_desktop.get(),
      compute->opengl_es.get(), compute->opengl_desktop.get(),
      compute->vulkan.get()};
  for (const auto* variant : variants) {
    ASSERT_NE(variant, nullptr);
    EXPECT_EQ(variant->stage, fb::shaderbundle::ShaderStage::kCompute);
    ASSERT_NE(variant->workgroup_size, nullptr);
    EXPECT_EQ(variant->workgroup_size->x(), 8u);
    EXPECT_EQ(variant->workgroup_size->y(), 4u);
    EXPECT_EQ(variant->workgroup_size->z(), 2u);

    const auto* input = FindByName(variant->storage_buffers, "InputData");
    ASSERT_NE(input, nullptr);
    EXPECT_EQ(input->binding, 0u);
    EXPECT_EQ(input->access, fb::shaderbundle::ShaderResourceAccess::kReadOnly);
    EXPECT_EQ(input->size_in_bytes, 16u);
    EXPECT_EQ(input->runtime_array_stride, 16u);

    const auto* output = FindByName(variant->storage_buffers, "OutputData");
    ASSERT_NE(output, nullptr);
    EXPECT_EQ(output->binding, 1u);
    EXPECT_EQ(output->access,
              fb::shaderbundle::ShaderResourceAccess::kWriteOnly);
    EXPECT_EQ(output->size_in_bytes, 0u);
    EXPECT_EQ(output->runtime_array_stride, 16u);

    const auto* accumulator =
        FindByName(variant->storage_buffers, "Accumulator");
    ASSERT_NE(accumulator, nullptr);
    EXPECT_EQ(accumulator->binding, 2u);
    EXPECT_EQ(accumulator->access,
              fb::shaderbundle::ShaderResourceAccess::kReadWrite);
    EXPECT_EQ(accumulator->size_in_bytes, 16u);
    EXPECT_EQ(accumulator->runtime_array_stride, 0u);

    // Uniform blocks are still reflected separately.
    EXPECT_NE(FindByName(variant->uniform_structs, "Params"), nullptr);
  }

  // Vulkan binds by binding number, so the extended resource index is the
  // binding itself.
  for (const auto& storage_buffer : compute->vulkan->storage_buffers) {
    EXPECT_EQ(storage_buffer->ext_res_0, storage_buffer->binding);
  }

  // Metal assigns buffer indices only to live resources. The storage buffer
  // whose read is overwritten is dead and carries the optimized-out sentinel.
  const auto* unused =
      FindByName(compute->metal_desktop->storage_buffers, "Unused");
  ASSERT_NE(unused, nullptr);
  EXPECT_EQ(unused->ext_res_0, kOptimizedOutBinding);
  const auto* live =
      FindByName(compute->metal_desktop->storage_buffers, "InputData");
  ASSERT_NE(live, nullptr);
  EXPECT_NE(live->ext_res_0, kOptimizedOutBinding);

  // The OpenGL variants are emitted at the first versions with compute.
  const auto starts_with = [](const std::vector<uint8_t>& code,
                              const std::string& prefix) {
    return code.size() >= prefix.size() &&
           std::equal(prefix.begin(), prefix.end(), code.begin());
  };
  EXPECT_TRUE(starts_with(compute->opengl_es->shader, "#version 310 es"));
  EXPECT_TRUE(starts_with(compute->opengl_desktop->shader, "#version 430"));
}

TEST(ShaderBundleTest, ComputeMetadataRoundTripsThroughSerialization) {
  std::optional<fb::shaderbundle::ShaderBundleT> bundle =
      GenerateComputeBundle("flutter_gpu_compute.comp");
  ASSERT_TRUE(bundle.has_value());

  flatbuffers::FlatBufferBuilder builder;
  // NOLINTNEXTLINE(bugprone-unchecked-optional-access)
  builder.Finish(fb::shaderbundle::ShaderBundle::Pack(builder, &bundle.value()),
                 fb::shaderbundle::ShaderBundleIdentifier());
  flatbuffers::Verifier verifier(builder.GetBufferPointer(), builder.GetSize());
  ASSERT_TRUE(fb::shaderbundle::VerifyShaderBundleBuffer(verifier));

  const auto* read =
      fb::shaderbundle::GetShaderBundle(builder.GetBufferPointer());
  EXPECT_EQ(read->format_version(),
            static_cast<uint32_t>(
                fb::shaderbundle::ShaderBundleFormatVersion::kVersion));
  ASSERT_EQ(read->shaders()->size(), 1u);
  const auto* vulkan = read->shaders()->Get(0)->vulkan();
  ASSERT_NE(vulkan, nullptr);
  ASSERT_NE(vulkan->workgroup_size(), nullptr);
  EXPECT_EQ(vulkan->workgroup_size()->x(), 8u);
  EXPECT_EQ(vulkan->workgroup_size()->y(), 4u);
  EXPECT_EQ(vulkan->workgroup_size()->z(), 2u);
  ASSERT_NE(vulkan->storage_buffers(), nullptr);
  bool found_output = false;
  for (const auto* storage_buffer : *vulkan->storage_buffers()) {
    if (storage_buffer->name()->str() == "OutputData") {
      found_output = true;
      EXPECT_EQ(storage_buffer->access(),
                fb::shaderbundle::ShaderResourceAccess::kWriteOnly);
      EXPECT_EQ(storage_buffer->runtime_array_stride(), 16u);
    }
  }
  EXPECT_TRUE(found_output);
}

TEST(ShaderBundleTest, RejectsComputeShaderWithSpecializedWorkgroupSize) {
  EXPECT_FALSE(
      GenerateComputeBundle("flutter_gpu_compute_specialized_size.comp")
          .has_value());
}

TEST(ShaderBundleTest, RenderShadersCarryNoComputeMetadata) {
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

  std::optional<fb::shaderbundle::ShaderBundleT> bundle =
      GenerateShaderBundleFlatbuffer(config, options);
  ASSERT_TRUE(bundle.has_value());
  // NOLINTNEXTLINE(bugprone-unchecked-optional-access)
  for (const auto& shader : bundle->shaders) {
    EXPECT_EQ(shader->vulkan->workgroup_size, nullptr);
    EXPECT_TRUE(shader->vulkan->storage_buffers.empty());
  }
}

}  // namespace testing
}  // namespace compiler
}  // namespace impeller
