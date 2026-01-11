// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/shader_archive/shader_archive_writer.h"

#include <array>
#include <filesystem>
#include <optional>

#include "flutter/fml/build_config.h"
#include "impeller/shader_archive/shader_archive_flatbuffers.h"

namespace impeller {

ShaderArchiveWriter::ShaderArchiveWriter() = default;

ShaderArchiveWriter::~ShaderArchiveWriter() = default;

void ShaderArchiveWriter::SetEntryPointPrefix(std::string prefix) {
  prefix_ = std::move(prefix);
}

std::optional<ArchiveShaderType> InferShaderTypefromFileExtension(
    const std::filesystem::path& path) {
#if FML_OS_QNX
  return std::nullopt;
#else   // FML_OS_QNX
  if (path == ".vert") {
    return ArchiveShaderType::kVertex;
  } else if (path == ".frag") {
    return ArchiveShaderType::kFragment;
  } else if (path == ".comp") {
    return ArchiveShaderType::kCompute;
  }
  return std::nullopt;
#endif  // FML_OS_QNX
}

bool ShaderArchiveWriter::AddShaderAtPath(const std::string& std_path) {
#if FML_OS_QNX
  return false;
#else   // FML_OS_QNX
  std::filesystem::path path(std_path);

  if (path.stem().empty()) {
    FML_LOG(ERROR) << "File path stem was empty for " << path;
    return false;
  }

  if (path.extension() != ".gles" && path.extension() != ".vkspv") {
    FML_LOG(ERROR) << "File path doesn't have a known shader extension "
                   << path;
    return false;
  }

  // Get rid of .gles
  path = path.replace_extension();

  auto shader_type = InferShaderTypefromFileExtension(path.extension());

  if (!shader_type.has_value()) {
    FML_LOG(ERROR) << "Could not infer shader type from file extension: "
                   << path.extension().string();
    return false;
  }

  // Get rid of the shader type extension (.vert, .frag, etc..).
  path = path.replace_extension();

  const auto shader_name = prefix_ + path.stem().string();
  if (shader_name.empty()) {
    FML_LOG(ERROR) << "Shader name was empty.";
    return false;
  }

  auto file_mapping = fml::FileMapping::CreateReadOnly(std_path);
  if (!file_mapping) {
    FML_LOG(ERROR) << "File doesn't exist at path: " << path;
    return false;
  }

  return AddShader(shader_type.value(), shader_name, std::move(file_mapping));
#endif  // FML_OS_QNX
}

bool ShaderArchiveWriter::AddShader(ArchiveShaderType type,
                                    std::string name,
                                    std::shared_ptr<fml::Mapping> mapping) {
  if (name.empty() || !mapping || mapping->GetMapping() == nullptr) {
    return false;
  }

  shader_descriptions_.emplace_back(
      ShaderDescription{type, std::move(name), std::move(mapping)});
  return true;
}

constexpr fb::Stage ToStage(ArchiveShaderType type) {
  switch (type) {
    case ArchiveShaderType::kVertex:
      return fb::Stage::kVertex;
    case ArchiveShaderType::kFragment:
      return fb::Stage::kFragment;
    case ArchiveShaderType::kCompute:
      return fb::Stage::kCompute;
  }
  FML_UNREACHABLE();
}

std::shared_ptr<fml::Mapping> ShaderArchiveWriter::CreateMapping() const {
  fb::ShaderArchiveT shader_archive;
  shader_archive.format_version =
      static_cast<uint32_t>(fb::ShaderArchiveFormatVersion::kVersion);
  for (const auto& shader_description : shader_descriptions_) {
    auto mapping = shader_description.mapping;
    if (!mapping) {
      return nullptr;
    }
    auto desc = std::make_unique<fb::ShaderBlobT>();
    desc->name = shader_description.name;
    desc->stage = ToStage(shader_description.type);
    desc->mapping = {mapping->GetMapping(),
                     mapping->GetMapping() + mapping->GetSize()};
    shader_archive.items.emplace_back(std::move(desc));
  }
  auto builder = std::make_shared<flatbuffers::FlatBufferBuilder>();
  builder->Finish(fb::ShaderArchive::Pack(*builder.get(), &shader_archive),
                  fb::ShaderArchiveIdentifier());
  return std::make_shared<fml::NonOwnedMapping>(builder->GetBufferPointer(),
                                                builder->GetSize(),
                                                [builder](auto, auto) {});
}

}  // namespace impeller
