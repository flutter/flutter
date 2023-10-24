// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <string>

#include "flutter/fml/mapping.h"
#include "flutter/testing/testing.h"
#include "impeller/base/validation.h"
#include "impeller/shader_archive/multi_arch_shader_archive.h"
#include "impeller/shader_archive/multi_arch_shader_archive_flatbuffers.h"
#include "impeller/shader_archive/multi_arch_shader_archive_writer.h"
#include "impeller/shader_archive/shader_archive.h"
#include "impeller/shader_archive/shader_archive_flatbuffers.h"
#include "impeller/shader_archive/shader_archive_writer.h"

namespace impeller {
namespace testing {

static std::shared_ptr<fml::Mapping> CreateMappingFromString(
    std::string p_string) {
  auto string = std::make_shared<std::string>(std::move(p_string));
  return std::make_shared<fml::NonOwnedMapping>(
      reinterpret_cast<const uint8_t*>(string->data()), string->size(),
      [string](auto, auto) {});
}

const std::string CreateStringFromMapping(const fml::Mapping& mapping) {
  return std::string{reinterpret_cast<const char*>(mapping.GetMapping()),
                     mapping.GetSize()};
}

TEST(ShaderArchiveTest, CanReadAndWriteBlobs) {
  ShaderArchiveWriter writer;
  ASSERT_TRUE(writer.AddShader(ArchiveShaderType::kVertex, "Hello",
                               CreateMappingFromString("World")));
  ASSERT_TRUE(writer.AddShader(ArchiveShaderType::kFragment, "Foo",
                               CreateMappingFromString("Bar")));
  ASSERT_TRUE(writer.AddShader(ArchiveShaderType::kVertex, "Baz",
                               CreateMappingFromString("Bang")));
  ASSERT_TRUE(writer.AddShader(ArchiveShaderType::kVertex, "Ping",
                               CreateMappingFromString("Pong")));
  ASSERT_TRUE(writer.AddShader(ArchiveShaderType::kFragment, "Pang",
                               CreateMappingFromString("World")));

  auto mapping = writer.CreateMapping();
  ASSERT_NE(mapping, nullptr);

  MultiArchShaderArchiveWriter multi_writer;

  ASSERT_TRUE(multi_writer.RegisterShaderArchive(
      ArchiveRenderingBackend::kOpenGLES, mapping));

  {
    ScopedValidationDisable no_val;
    // Can't add the same backend again.
    ASSERT_FALSE(multi_writer.RegisterShaderArchive(
        ArchiveRenderingBackend::kOpenGLES, mapping));
  }

  auto multi_mapping = multi_writer.CreateMapping();
  ASSERT_TRUE(multi_mapping);

  {
    ScopedValidationDisable no_val;
    auto no_library = MultiArchShaderArchive::CreateArchiveFromMapping(
        multi_mapping, ArchiveRenderingBackend::kVulkan);
    ASSERT_EQ(no_library, nullptr);
  }

  auto library = MultiArchShaderArchive::CreateArchiveFromMapping(
      multi_mapping, ArchiveRenderingBackend::kOpenGLES);
  ASSERT_EQ(library->GetShaderCount(), 5u);

  // Wrong type.
  ASSERT_EQ(library->GetMapping(ArchiveShaderType::kFragment, "Hello"),
            nullptr);

  auto hello_vtx = library->GetMapping(ArchiveShaderType::kVertex, "Hello");
  ASSERT_NE(hello_vtx, nullptr);
  ASSERT_EQ(CreateStringFromMapping(*hello_vtx), "World");
}

TEST(ShaderArchiveTest, ArchiveAndMultiArchiveHaveDifferentIdentifiers) {
  // The unarchiving process depends on these identifiers to check to see if its
  // a standalone archive or a multi-archive. Things will get nutty if these are
  // ever the same.
  auto archive_id = fb::ShaderArchiveIdentifier();
  auto multi_archive_id = fb::MultiArchShaderArchiveIdentifier();
  ASSERT_EQ(std::strlen(archive_id), std::strlen(multi_archive_id));
  ASSERT_NE(std::strncmp(archive_id, multi_archive_id, std::strlen(archive_id)),
            0);
}

}  // namespace testing
}  // namespace impeller
