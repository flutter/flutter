// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/compiler/compiler_test.h"

#include <algorithm>

namespace impeller {
namespace compiler {
namespace testing {

static fml::UniqueFD CreateIntermediatesDirectory() {
  auto test_name = flutter::testing::GetCurrentTestName();
  std::replace(test_name.begin(), test_name.end(), '/', '_');
  std::replace(test_name.begin(), test_name.end(), '.', '_');
  return fml::OpenDirectory(flutter::testing::OpenFixturesDirectory(),
                            test_name.c_str(),
                            true,  // create if necessary
                            fml::FilePermission::kReadWrite);
}

CompilerTest::CompilerTest()
    : intermediates_directory_(CreateIntermediatesDirectory()) {
  FML_CHECK(intermediates_directory_.is_valid());
}

CompilerTest::~CompilerTest() = default;

static std::string ReflectionHeaderName(const char* fixture_name) {
  std::stringstream stream;
  stream << fixture_name << ".h";
  return stream.str();
}

static std::string ReflectionCCName(const char* fixture_name) {
  std::stringstream stream;
  stream << fixture_name << ".cc";
  return stream.str();
}

static std::string ReflectionJSONName(const char* fixture_name) {
  std::stringstream stream;
  stream << fixture_name << ".json";
  return stream.str();
}

static std::string SPIRVFileName(const char* fixture_name) {
  std::stringstream stream;
  stream << fixture_name << ".spv";
  return stream.str();
}

static std::string SLFileName(const char* fixture_name,
                              TargetPlatform platform) {
  std::stringstream stream;
  stream << fixture_name << "." << TargetPlatformSLExtension(platform);
  return stream.str();
}

bool CompilerTest::CanCompileAndReflect(const char* fixture_name,
                                        SourceType source_type) const {
  auto fixture = flutter::testing::OpenFixtureAsMapping(fixture_name);
  if (!fixture->GetMapping()) {
    VALIDATION_LOG << "Could not find shader in fixtures: " << fixture_name;
    return false;
  }

  SourceOptions source_options(fixture_name, source_type);
  source_options.target_platform = GetParam();
  source_options.working_directory = std::make_shared<fml::UniqueFD>(
      flutter::testing::OpenFixturesDirectory());
  source_options.entry_point_name = EntryPointFunctionNameFromSourceName(
      fixture_name, SourceTypeFromFileName(fixture_name));

  Reflector::Options reflector_options;
  reflector_options.header_file_name = ReflectionHeaderName(fixture_name);
  reflector_options.shader_name = "shader_name";

  Compiler compiler(*fixture.get(), source_options, reflector_options);
  if (!compiler.IsValid()) {
    VALIDATION_LOG << "Compilation failed: " << compiler.GetErrorMessages();
    return false;
  }

  auto spirv_assembly = compiler.GetSPIRVAssembly();
  if (!spirv_assembly) {
    VALIDATION_LOG << "No spirv was generated.";
    return false;
  }

  if (!fml::WriteAtomically(intermediates_directory_,
                            SPIRVFileName(fixture_name).c_str(),
                            *spirv_assembly)) {
    VALIDATION_LOG << "Could not write SPIRV intermediates.";
    return false;
  }

  if (TargetPlatformNeedsSL(GetParam())) {
    auto sl_source = compiler.GetSLShaderSource();
    if (!sl_source) {
      VALIDATION_LOG << "No SL source was generated.";
      return false;
    }

    if (!fml::WriteAtomically(intermediates_directory_,
                              SLFileName(fixture_name, GetParam()).c_str(),
                              *sl_source)) {
      VALIDATION_LOG << "Could not write SL intermediates.";
      return false;
    }
  }

  if (TargetPlatformNeedsReflection(GetParam())) {
    auto reflector = compiler.GetReflector();
    if (!reflector) {
      VALIDATION_LOG
          << "No reflector was found for target platform SL compiler.";
      return false;
    }

    auto reflection_json = reflector->GetReflectionJSON();
    auto reflection_header = reflector->GetReflectionHeader();
    auto reflection_source = reflector->GetReflectionCC();

    if (!reflection_json) {
      VALIDATION_LOG << "Reflection JSON was not found.";
      return false;
    }

    if (!reflection_header) {
      VALIDATION_LOG << "Reflection header was not found.";
      return false;
    }

    if (!reflection_source) {
      VALIDATION_LOG << "Reflection source was not found.";
      return false;
    }

    if (!fml::WriteAtomically(intermediates_directory_,
                              ReflectionHeaderName(fixture_name).c_str(),
                              *reflection_header)) {
      VALIDATION_LOG << "Could not write reflection header intermediates.";
      return false;
    }

    if (!fml::WriteAtomically(intermediates_directory_,
                              ReflectionCCName(fixture_name).c_str(),
                              *reflection_source)) {
      VALIDATION_LOG << "Could not write reflection CC intermediates.";
      return false;
    }

    if (!fml::WriteAtomically(intermediates_directory_,
                              ReflectionJSONName(fixture_name).c_str(),
                              *reflection_json)) {
      VALIDATION_LOG << "Could not write reflection json intermediates.";
      return false;
    }
  }

  return true;
}

}  // namespace testing
}  // namespace compiler
}  // namespace impeller
