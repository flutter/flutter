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

TEST(ShaderBundleTest, TargetSupportsShaderTypeSkipsOnlyGLCompute) {
  for (const auto type :
       {SourceType::kVertexShader, SourceType::kFragmentShader,
        SourceType::kComputeShader}) {
    EXPECT_TRUE(
        ShaderBundleTargetSupportsShaderType(TargetPlatform::kMetalIOS, type));
    EXPECT_TRUE(ShaderBundleTargetSupportsShaderType(
        TargetPlatform::kMetalDesktop, type));
    EXPECT_TRUE(
        ShaderBundleTargetSupportsShaderType(TargetPlatform::kVulkan, type));
  }
  for (const auto platform :
       {TargetPlatform::kOpenGLES, TargetPlatform::kOpenGLDesktop}) {
    EXPECT_TRUE(ShaderBundleTargetSupportsShaderType(
        platform, SourceType::kVertexShader));
    EXPECT_TRUE(ShaderBundleTargetSupportsShaderType(
        platform, SourceType::kFragmentShader));
    EXPECT_FALSE(ShaderBundleTargetSupportsShaderType(
        platform, SourceType::kComputeShader));
  }
}

// A bundle with a compute shader next to a graphics shader.
static std::string ComputeAndFragmentBundleConfig() {
  const std::string fixtures_path = flutter::testing::GetFixturesPath();
  return "{\"Compute\": {\"type\": \"compute\", \"file\": \"" + fixtures_path +
         "/flutter_gpu_compute.comp\"}, \"UnlitFragment\": {\"type\": "
         "\"fragment\", \"file\": \"" +
         fixtures_path + "/flutter_gpu_unlit.frag\"}}";
}

// Checks the compute-specific reflection of one backend variant of
// `flutter_gpu_compute.comp`.
static void ExpectComputeReflection(
    const fb::shaderbundle::BackendShaderT& backend) {
  EXPECT_EQ(backend.stage, fb::shaderbundle::ShaderStage::kCompute);
  EXPECT_EQ(backend.workgroup_size_x, 8u);
  EXPECT_EQ(backend.workgroup_size_y, 4u);
  EXPECT_EQ(backend.workgroup_size_z, 2u);

  ASSERT_EQ(backend.storage_buffers.size(), 3u);
  const auto* input = FindByName(backend.storage_buffers, "InputData");
  const auto* output = FindByName(backend.storage_buffers, "OutputData");
  const auto* accumulator = FindByName(backend.storage_buffers, "Accumulator");
  ASSERT_NE(input, nullptr);
  ASSERT_NE(output, nullptr);
  ASSERT_NE(accumulator, nullptr);

  EXPECT_EQ(input->set, 0u);
  EXPECT_EQ(input->binding, 0u);
  EXPECT_EQ(input->access, fb::shaderbundle::StorageBufferAccess::kRead);
  EXPECT_EQ(output->set, 0u);
  EXPECT_EQ(output->binding, 1u);
  // A `writeonly` buffer still has to be bound writable.
  EXPECT_EQ(output->access, fb::shaderbundle::StorageBufferAccess::kReadWrite);
  EXPECT_EQ(accumulator->set, 0u);
  EXPECT_EQ(accumulator->binding, 2u);
  EXPECT_EQ(accumulator->access,
            fb::shaderbundle::StorageBufferAccess::kReadWrite);

  // Each storage buffer gets its own backend resource index.
  EXPECT_NE(input->ext_res_0, output->ext_res_0);
  EXPECT_NE(input->ext_res_0, accumulator->ext_res_0);
  EXPECT_NE(output->ext_res_0, accumulator->ext_res_0);
}

TEST(ShaderBundleTest, GenerateShaderBundleFlatbufferBuildsComputeShader) {
  SourceOptions options;
  options.target_platform = TargetPlatform::kRuntimeStageMetal;
  options.source_language = SourceLanguage::kGLSL;

  std::optional<fb::shaderbundle::ShaderBundleT> bundle =
      GenerateShaderBundleFlatbuffer(ComputeAndFragmentBundleConfig(), options);
  ASSERT_TRUE(bundle.has_value());

  // NOLINTNEXTLINE(bugprone-unchecked-optional-access)
  const auto& shaders = bundle->shaders;
  const auto* compute = FindByName(shaders, "Compute");
  const auto* fragment = FindByName(shaders, "UnlitFragment");
  ASSERT_NE(compute, nullptr);
  ASSERT_NE(fragment, nullptr);

  // The compute shader is bundled for Metal and Vulkan only. The OpenGL
  // variants are skipped rather than failing the bundle.
  ASSERT_NE(compute->metal_ios, nullptr);
  ASSERT_NE(compute->metal_desktop, nullptr);
  ASSERT_NE(compute->vulkan, nullptr);
  EXPECT_EQ(compute->opengl_es, nullptr);
  EXPECT_EQ(compute->opengl_desktop, nullptr);

  ExpectComputeReflection(*compute->metal_ios);
  ExpectComputeReflection(*compute->metal_desktop);
  ExpectComputeReflection(*compute->vulkan);

  // Vulkan resources are addressed by their descriptor binding.
  for (const auto& buffer : compute->vulkan->storage_buffers) {
    EXPECT_EQ(buffer->ext_res_0, buffer->binding);
  }

  // Graphics shaders in the same bundle keep every backend variant, and carry
  // no compute metadata.
  ASSERT_NE(fragment->metal_ios, nullptr);
  ASSERT_NE(fragment->metal_desktop, nullptr);
  ASSERT_NE(fragment->opengl_es, nullptr);
  ASSERT_NE(fragment->opengl_desktop, nullptr);
  ASSERT_NE(fragment->vulkan, nullptr);
  EXPECT_EQ(fragment->metal_desktop->workgroup_size_x, 0u);
  EXPECT_EQ(fragment->metal_desktop->workgroup_size_y, 0u);
  EXPECT_EQ(fragment->metal_desktop->workgroup_size_z, 0u);
  EXPECT_TRUE(fragment->metal_desktop->storage_buffers.empty());
}

// Finds the storage buffer named `name` in a serialized backend shader.
static const fb::shaderbundle::ShaderStorageBuffer* FindStorageBuffer(
    const fb::shaderbundle::BackendShader& backend,
    const std::string& name) {
  if (backend.storage_buffers() == nullptr) {
    return nullptr;
  }
  for (const auto* buffer : *backend.storage_buffers()) {
    if (buffer->name() != nullptr && buffer->name()->str() == name) {
      return buffer;
    }
  }
  return nullptr;
}

TEST(ShaderBundleTest, ComputeMetadataRoundTripsThroughSerialization) {
  SourceOptions options;
  options.target_platform = TargetPlatform::kRuntimeStageMetal;
  options.source_language = SourceLanguage::kGLSL;

  std::optional<fb::shaderbundle::ShaderBundleT> bundle =
      GenerateShaderBundleFlatbuffer(ComputeAndFragmentBundleConfig(), options);
  ASSERT_TRUE(bundle.has_value());

  // Serialize the same way `GenerateShaderBundle` writes the bundle to disk.
  flatbuffers::FlatBufferBuilder builder;
  // NOLINTNEXTLINE(bugprone-unchecked-optional-access)
  builder.Finish(fb::shaderbundle::ShaderBundle::Pack(builder, &bundle.value()),
                 fb::shaderbundle::ShaderBundleIdentifier());

  // Read it back the way the Flutter GPU runtime does.
  flatbuffers::Verifier verifier(builder.GetBufferPointer(), builder.GetSize());
  ASSERT_TRUE(fb::shaderbundle::VerifyShaderBundleBuffer(verifier));
  const auto* serialized =
      fb::shaderbundle::GetShaderBundle(builder.GetBufferPointer());
  ASSERT_NE(serialized, nullptr);
  ASSERT_NE(serialized->shaders(), nullptr);

  const fb::shaderbundle::Shader* compute = nullptr;
  for (const auto* shader : *serialized->shaders()) {
    if (shader->name() != nullptr && shader->name()->str() == "Compute") {
      compute = shader;
    }
  }
  ASSERT_NE(compute, nullptr);
  EXPECT_EQ(compute->opengl_es(), nullptr);
  EXPECT_EQ(compute->opengl_desktop(), nullptr);

  for (const auto* backend :
       {compute->metal_ios(), compute->metal_desktop(), compute->vulkan()}) {
    ASSERT_NE(backend, nullptr);
    EXPECT_EQ(backend->stage(), fb::shaderbundle::ShaderStage::kCompute);
    EXPECT_EQ(backend->workgroup_size_x(), 8u);
    EXPECT_EQ(backend->workgroup_size_y(), 4u);
    EXPECT_EQ(backend->workgroup_size_z(), 2u);

    ASSERT_NE(backend->storage_buffers(), nullptr);
    EXPECT_EQ(backend->storage_buffers()->size(), 3u);
    const auto* input = FindStorageBuffer(*backend, "InputData");
    const auto* output = FindStorageBuffer(*backend, "OutputData");
    const auto* accumulator = FindStorageBuffer(*backend, "Accumulator");
    ASSERT_NE(input, nullptr);
    ASSERT_NE(output, nullptr);
    ASSERT_NE(accumulator, nullptr);
    EXPECT_EQ(input->binding(), 0u);
    EXPECT_EQ(input->access(), fb::shaderbundle::StorageBufferAccess::kRead);
    EXPECT_EQ(output->binding(), 1u);
    EXPECT_EQ(output->access(),
              fb::shaderbundle::StorageBufferAccess::kReadWrite);
    EXPECT_EQ(accumulator->binding(), 2u);
    EXPECT_EQ(accumulator->access(),
              fb::shaderbundle::StorageBufferAccess::kReadWrite);
  }

  // The object API reproduces the original metadata after unpacking.
  std::unique_ptr<fb::shaderbundle::ShaderBundleT> unpacked(
      serialized->UnPack());
  ASSERT_NE(unpacked, nullptr);
  const auto* unpacked_compute = FindByName(unpacked->shaders, "Compute");
  ASSERT_NE(unpacked_compute, nullptr);
  ASSERT_NE(unpacked_compute->metal_desktop, nullptr);
  ASSERT_NE(unpacked_compute->vulkan, nullptr);
  ExpectComputeReflection(*unpacked_compute->metal_desktop);
  ExpectComputeReflection(*unpacked_compute->vulkan);
}

}  // namespace testing
}  // namespace compiler
}  // namespace impeller
