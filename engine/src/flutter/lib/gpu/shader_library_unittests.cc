// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/shader_library.h"

#include <cstdint>
#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "flutter/lib/gpu/shader.h"
#include "fml/mapping.h"
#include "gtest/gtest.h"
#include "impeller/core/shader_types.h"
#include "impeller/renderer/context.h"
// Pulls in flatbuffers/flatbuffers.h (FlatBufferBuilder, Verifier) and the
// generated impeller::fb::shaderbundle:: symbols.
#include "impeller/shader_bundle/shader_bundle_flatbuffers.h"

namespace flutter {
namespace gpu {
namespace testing {

// Wraps an owning byte vector in an fml::Mapping that keeps the vector alive
// for the lifetime of the mapping. Mirrors the helper pattern used by the
// impeller runtime_stage / shader_archive verifier tests.
static std::shared_ptr<fml::Mapping> CreateMappingFromVector(
    const std::shared_ptr<std::vector<uint8_t>>& data) {
  const uint8_t* ptr = data->data();
  const size_t size = data->size();
  return std::make_shared<fml::NonOwnedMapping>(ptr, size,
                                                [data](auto, auto) {});
}

// Builds a structurally-valid, minimal shader bundle FlatBuffer with the
// correct "IPSB" identifier and an empty (but present) shaders vector. This is
// used as a positive control: the verifier added by this change must ACCEPT a
// well-formed buffer, so that the rejection tests below prove the verifier is
// catching genuinely corrupt input rather than rejecting everything.
static std::shared_ptr<std::vector<uint8_t>> BuildValidEmptyBundle() {
  flatbuffers::FlatBufferBuilder builder;
  std::vector<flatbuffers::Offset<impeller::fb::shaderbundle::Shader>> shaders;
  auto shaders_vec = builder.CreateVector(shaders);
  impeller::fb::shaderbundle::ShaderBundleBuilder bundle_builder(builder);
  bundle_builder.add_format_version(static_cast<uint32_t>(
      impeller::fb::shaderbundle::ShaderBundleFormatVersion::kVersion));
  bundle_builder.add_shaders(shaders_vec);
  auto bundle = bundle_builder.Finish();
  // Finish with the "IPSB" file identifier (mirrors the runtime_stage test's
  // builder.Finish(stages, fb::RuntimeStagesIdentifier()) idiom).
  builder.Finish(bundle, impeller::fb::shaderbundle::ShaderBundleIdentifier());
  return std::make_shared<std::vector<uint8_t>>(
      builder.GetBufferPointer(),
      builder.GetBufferPointer() + builder.GetSize());
}

// A corrupt buffer with a valid "IPSB" file identifier at bytes 4-7 but a root
// table offset that points beyond the buffer. This passes the identifier check
// (ShaderBundleBufferHasIdentifier) but must fail FlatBuffer structural
// verification (VerifyShaderBundleBuffer). Mirrors the impeller
// RejectsCorruptBufferWithValidIdentifier tests for runtime_stage / shader
// archive.
static std::shared_ptr<std::vector<uint8_t>> BuildCorruptBundle() {
  auto data = std::make_shared<std::vector<uint8_t>>(32, 0);
  // "IPSB" file identifier at bytes 4-7.
  (*data)[4] = 'I';
  (*data)[5] = 'P';
  (*data)[6] = 'S';
  (*data)[7] = 'B';
  // Root offset (little-endian uint32 at offset 0) pointing out of bounds.
  (*data)[0] = 0xFF;
  (*data)[1] = 0xFF;
  return data;
}

// Sanity check on the test fixtures themselves: the corrupt buffer carries the
// expected identifier (so it reaches the new verification) while failing
// structural verification, and the valid buffer passes both.
TEST(FlutterGpuShaderLibraryTest, VerifierAcceptsValidBundleRejectsCorrupt) {
  auto valid = BuildValidEmptyBundle();
  EXPECT_TRUE(impeller::fb::shaderbundle::ShaderBundleBufferHasIdentifier(
      valid->data()));
  {
    flatbuffers::Verifier verifier(valid->data(), valid->size());
    EXPECT_TRUE(impeller::fb::shaderbundle::VerifyShaderBundleBuffer(verifier));
  }

  auto corrupt = BuildCorruptBundle();
  EXPECT_TRUE(impeller::fb::shaderbundle::ShaderBundleBufferHasIdentifier(
      corrupt->data()));
  {
    flatbuffers::Verifier verifier(corrupt->data(), corrupt->size());
    EXPECT_FALSE(
        impeller::fb::shaderbundle::VerifyShaderBundleBuffer(verifier));
  }
}

// Core regression: a buffer with a valid "IPSB" identifier but corrupt internal
// offsets must be rejected (null library) rather than read out of bounds. Prior
// to the structural verification this exercised GetShaderBundle() on unverified
// data.
TEST(FlutterGpuShaderLibraryTest,
     MakeFromFlatbufferRejectsCorruptBufferWithValidIdentifier) {
  auto mapping = CreateMappingFromVector(BuildCorruptBundle());
  auto library =
      ShaderLibrary::MakeFromFlatbuffer(impeller::Context::BackendType::kMetal,
                                        std::move(mapping), "test_bundle");
  EXPECT_FALSE(library);
}

// A truncated buffer (shorter than a FlatBuffer header) with the identifier
// bytes must also be rejected without reading out of bounds.
TEST(FlutterGpuShaderLibraryTest, MakeFromFlatbufferRejectsTruncatedBuffer) {
  // 8 bytes: just enough to hold a (bogus) root offset + "IPSB" identifier.
  auto data = std::make_shared<std::vector<uint8_t>>(8, 0);
  (*data)[4] = 'I';
  (*data)[5] = 'P';
  (*data)[6] = 'S';
  (*data)[7] = 'B';
  // Root offset points past the 8-byte buffer.
  (*data)[0] = 0x10;
  auto library = ShaderLibrary::MakeFromFlatbuffer(
      impeller::Context::BackendType::kMetal, CreateMappingFromVector(data),
      "test_bundle");
  EXPECT_FALSE(library);
}

// A buffer without the "IPSB" identifier is rejected at the identifier check
// (pre-existing behavior, guarded here against regression).
TEST(FlutterGpuShaderLibraryTest, MakeFromFlatbufferRejectsMissingIdentifier) {
  auto data = std::make_shared<std::vector<uint8_t>>(32, 0);
  // No identifier bytes set.
  auto library = ShaderLibrary::MakeFromFlatbuffer(
      impeller::Context::BackendType::kMetal, CreateMappingFromVector(data),
      "test_bundle");
  EXPECT_FALSE(library);
}

// A null payload must be handled gracefully.
TEST(FlutterGpuShaderLibraryTest, MakeFromFlatbufferRejectsNullPayload) {
  auto library = ShaderLibrary::MakeFromFlatbuffer(
      impeller::Context::BackendType::kMetal, nullptr, "test_bundle");
  EXPECT_FALSE(library);
}

// A structurally-valid bundle that simply contains no shaders parses to an
// empty shader map, which MakeFromFlatbuffer reports as a null library. This
// confirms the verifier does NOT reject a well-formed buffer (the failure in
// the corrupt case above comes from structural verification, not from the
// buffer being non-empty).
TEST(FlutterGpuShaderLibraryTest,
     MakeFromFlatbufferValidEmptyBundleIsNotRejectedByVerifier) {
  auto valid = BuildValidEmptyBundle();
  // The verifier accepts it (asserted directly here so this test stands alone).
  flatbuffers::Verifier verifier(valid->data(), valid->size());
  ASSERT_TRUE(impeller::fb::shaderbundle::VerifyShaderBundleBuffer(verifier));

  // Driven through the public entry, an empty bundle yields a null library
  // because there are no shaders to register (empty ShaderMap), NOT because the
  // verifier rejected it.
  auto library = ShaderLibrary::MakeFromFlatbuffer(
      impeller::Context::BackendType::kMetal, CreateMappingFromVector(valid),
      "test_bundle");
  EXPECT_FALSE(library);
}

// Serializes a single-fragment-shader bundle (Metal desktop variant) carrying
// the given reflected textures and uniform structs, each as a
// (name, ext_res_0) pair. A texture/struct whose ext_res_0 is the optimized-out
// sentinel stands in for a resource the shader compiler dead-code-eliminated.
static std::shared_ptr<std::vector<uint8_t>> BuildFragmentBundle(
    const std::vector<std::pair<std::string, uint64_t>>& textures,
    const std::vector<std::pair<std::string, uint64_t>>& structs) {
  namespace fbs = impeller::fb::shaderbundle;

  auto metal = std::make_unique<fbs::BackendShaderT>();
  metal->stage = fbs::ShaderStage::kFragment;
  metal->entrypoint = "main";
  // The bytes are ignored at parse time (no GPU compile), but the field must be
  // present and non-empty for the loader to build a code mapping.
  metal->shader = {0};
  for (const auto& [name, ext_res_0] : textures) {
    auto texture = std::make_unique<fbs::ShaderUniformTextureT>();
    texture->name = name;
    texture->ext_res_0 = ext_res_0;
    metal->uniform_textures.push_back(std::move(texture));
  }
  for (const auto& [name, ext_res_0] : structs) {
    auto uniform = std::make_unique<fbs::ShaderUniformStructT>();
    uniform->name = name;
    uniform->ext_res_0 = ext_res_0;
    uniform->size_in_bytes = 16;
    metal->uniform_structs.push_back(std::move(uniform));
  }

  auto shader = std::make_unique<fbs::ShaderT>();
  shader->name = "test";
  shader->metal_desktop = std::move(metal);

  fbs::ShaderBundleT bundle;
  bundle.format_version =
      static_cast<uint32_t>(fbs::ShaderBundleFormatVersion::kVersion);
  bundle.shaders.push_back(std::move(shader));

  flatbuffers::FlatBufferBuilder builder;
  builder.Finish(fbs::ShaderBundle::Pack(builder, &bundle),
                 fbs::ShaderBundleIdentifier());
  return std::make_shared<std::vector<uint8_t>>(
      builder.GetBufferPointer(),
      builder.GetBufferPointer() + builder.GetSize());
}

// A sampler the shader compiler dead-code-eliminated is still listed in
// reflection but carries the out-of-range binding sentinel. It must not be
// registered as a bindable uniform texture (binding an out-of-range index
// crashes the Metal backend), while a live sampler alongside it survives.
TEST(FlutterGpuShaderLibraryTest, MakeFromFlatbufferSkipsOptimizedOutTexture) {
  const uint64_t sentinel = impeller::kOptimizedOutBinding;
  auto bundle = BuildFragmentBundle(
      /*textures=*/{{"u_live", 0}, {"u_dced", sentinel}}, /*structs=*/{});
  auto library = ShaderLibrary::MakeFromFlatbuffer(
      impeller::Context::BackendType::kMetal, CreateMappingFromVector(bundle),
      "test_bundle");
  ASSERT_TRUE(library);
  auto shader = library->FindShaderForTesting("test");
  ASSERT_TRUE(shader);
  EXPECT_NE(shader->GetUniformTexture("u_live"), nullptr);
  EXPECT_EQ(shader->GetUniformTexture("u_dced"), nullptr);
}

// The same skip applies to a dead-code-eliminated uniform block.
TEST(FlutterGpuShaderLibraryTest, MakeFromFlatbufferSkipsOptimizedOutStruct) {
  const uint64_t sentinel = impeller::kOptimizedOutBinding;
  auto bundle = BuildFragmentBundle(
      /*textures=*/{}, /*structs=*/{{"Live", 0}, {"Dced", sentinel}});
  auto library = ShaderLibrary::MakeFromFlatbuffer(
      impeller::Context::BackendType::kMetal, CreateMappingFromVector(bundle),
      "test_bundle");
  ASSERT_TRUE(library);
  auto shader = library->FindShaderForTesting("test");
  ASSERT_TRUE(shader);
  EXPECT_NE(shader->GetUniformStruct("Live"), nullptr);
  EXPECT_EQ(shader->GetUniformStruct("Dced"), nullptr);
}

}  // namespace testing
}  // namespace gpu
}  // namespace flutter
