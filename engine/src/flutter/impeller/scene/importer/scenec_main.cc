// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <filesystem>
#include <memory>

#include "flutter/fml/backtrace.h"
#include "flutter/fml/command_line.h"
#include "flutter/fml/file.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/mapping.h"
#include "impeller/base/strings.h"
#include "impeller/compiler/utilities.h"
#include "impeller/scene/importer/importer.h"
#include "impeller/scene/importer/scene_flatbuffers.h"
#include "impeller/scene/importer/switches.h"
#include "impeller/scene/importer/types.h"

#include "third_party/flatbuffers/include/flatbuffers/flatbuffer_builder.h"

namespace impeller {
namespace scene {
namespace importer {

// Sets the file access mode of the file at path 'p' to 0644.
static bool SetPermissiveAccess(const std::filesystem::path& p) {
  auto permissions =
      std::filesystem::perms::owner_read | std::filesystem::perms::owner_write |
      std::filesystem::perms::group_read | std::filesystem::perms::others_read;
  std::error_code error;
  std::filesystem::permissions(p, permissions, error);
  if (error) {
    std::cerr << "Failed to set access on file '" << p
              << "': " << error.message() << std::endl;
    return false;
  }
  return true;
}

bool Main(const fml::CommandLine& command_line) {
  fml::InstallCrashHandler();
  if (command_line.HasOption("help")) {
    Switches::PrintHelp(std::cout);
    return true;
  }

  Switches switches(command_line);
  if (!switches.AreValid(std::cerr)) {
    std::cerr << "Invalid flags specified." << std::endl;
    Switches::PrintHelp(std::cerr);
    return false;
  }

  auto source_file_mapping =
      fml::FileMapping::CreateReadOnly(switches.source_file_name);
  if (!source_file_mapping) {
    std::cerr << "Could not open input file." << std::endl;
    return false;
  }

  fb::SceneT scene;
  bool success = false;
  switch (switches.input_type) {
    case SourceType::kGLTF:
      success = ParseGLTF(*source_file_mapping, scene);
      break;
    case SourceType::kUnknown:
      std::cerr << "Unknown input type." << std::endl;
      return false;
  }
  if (!success) {
    std::cerr << "Failed to parse input file." << std::endl;
    return false;
  }

  flatbuffers::FlatBufferBuilder builder;
  builder.Finish(fb::Scene::Pack(builder, &scene), fb::SceneIdentifier());

  auto output_file_name = std::filesystem::absolute(
      std::filesystem::current_path() / switches.output_file_name);
  fml::NonOwnedMapping mapping(builder.GetCurrentBufferPointer(),
                               builder.GetSize());
  if (!fml::WriteAtomically(*switches.working_directory,
                            compiler::Utf8FromPath(output_file_name).c_str(),
                            mapping)) {
    std::cerr << "Could not write file to " << switches.output_file_name
              << std::endl;
    return false;
  }

  // Tools that consume the geometry data expect the access mode to be 0644.
  if (!SetPermissiveAccess(output_file_name)) {
    return false;
  }

  return true;
}

}  // namespace importer
}  // namespace scene
}  // namespace impeller

int main(int argc, char const* argv[]) {
  return impeller::scene::importer::Main(
             fml::CommandLineFromPlatformOrArgcArgv(argc, argv))
             ? EXIT_SUCCESS
             : EXIT_FAILURE;
}
