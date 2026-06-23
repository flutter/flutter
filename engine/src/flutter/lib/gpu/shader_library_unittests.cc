// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/shader_library.h"

#include <cstdint>
#include <memory>
#include <vector>

#include "fml/mapping.h"
#include "gtest/gtest.h"
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
      impeller::Context::BackendType::kMetal,
      CreateMappingFromVector(std::move(data)), "test_bundle");
  EXPECT_FALSE(library);
}

// A buffer without the "IPSB" identifier is rejected at the identifier check
// (pre-existing behavior, guarded here against regression).
TEST(FlutterGpuShaderLibraryTest, MakeFromFlatbufferRejectsMissingIdentifier) {
  auto data = std::make_shared<std::vector<uint8_t>>(32, 0);
  // No identifier bytes set.
  auto library = ShaderLibrary::MakeFromFlatbuffer(
      impeller::Context::BackendType::kMetal,
      CreateMappingFromVector(std::move(data)), "test_bundle");
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
      impeller::Context::BackendType::kMetal,
      CreateMappingFromVector(std::move(valid)), "test_bundle");
  EXPECT_FALSE(library);
}

}  // namespace testing
}  // namespace gpu
}  // namespace flutter
