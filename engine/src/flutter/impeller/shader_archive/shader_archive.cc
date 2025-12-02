// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/shader_archive/shader_archive.h"

#include <array>
#include <sstream>
#include <string>
#include <utility>

#include "impeller/base/validation.h"
#include "impeller/shader_archive/shader_archive_flatbuffers.h"

namespace impeller {

constexpr ArchiveShaderType ToShaderType(fb::Stage stage) {
  switch (stage) {
    case fb::Stage::kVertex:
      return ArchiveShaderType::kVertex;
    case fb::Stage::kFragment:
      return ArchiveShaderType::kFragment;
    case fb::Stage::kCompute:
      return ArchiveShaderType::kCompute;
  }
  FML_UNREACHABLE();
}

absl::StatusOr<ShaderArchive> ShaderArchive::Create(
    std::shared_ptr<fml::Mapping> payload) {
  if (!payload || payload->GetMapping() == nullptr) {
    return absl::InvalidArgumentError("Shader mapping was absent.");
  }

  if (!fb::ShaderArchiveBufferHasIdentifier(payload->GetMapping())) {
    return absl::InvalidArgumentError("Invalid shader magic.");
  }

  auto shader_archive = fb::GetShaderArchive(payload->GetMapping());
  if (!shader_archive) {
    return absl::InvalidArgumentError("Could not read shader archive.");
  }

  const auto version = shader_archive->format_version();
  const auto expected =
      static_cast<uint32_t>(fb::ShaderArchiveFormatVersion::kVersion);
  if (version != expected) {
    std::stringstream stream;
    stream << "Unsupported shader archive format version. Expected: "
           << expected << ", Got: " << version;
    return absl::InvalidArgumentError(stream.str());
  }

  Shaders shaders;
  if (auto items = shader_archive->items()) {
    for (auto i = items->begin(), end = items->end(); i != end; i++) {
      ShaderKey key;
      key.name = i->name()->str();
      key.type = ToShaderType(i->stage());
      shaders[key] = std::make_shared<fml::NonOwnedMapping>(
          i->mapping()->Data(), i->mapping()->size(), [payload](auto, auto) {
            // The pointers are into the base payload. Instead of copying the
            // data, just hold onto the payload.
          });
    }
  }

  return ShaderArchive(std::move(payload), std::move(shaders));
}

ShaderArchive::ShaderArchive(std::shared_ptr<fml::Mapping> payload,
                             Shaders shaders)
    : payload_(std::move(payload)), shaders_(std::move(shaders)) {}

ShaderArchive::ShaderArchive(ShaderArchive&&) = default;

ShaderArchive::~ShaderArchive() = default;

size_t ShaderArchive::GetShaderCount() const {
  return shaders_.size();
}

std::shared_ptr<fml::Mapping> ShaderArchive::GetMapping(
    ArchiveShaderType type,
    std::string name) const {
  ShaderKey key;
  key.type = type;
  key.name = std::move(name);
  auto found = shaders_.find(key);
  return found == shaders_.end() ? nullptr : found->second;
}

size_t ShaderArchive::IterateAllShaders(
    const std::function<bool(ArchiveShaderType type,
                             const std::string& name,
                             const std::shared_ptr<fml::Mapping>& mapping)>&
        callback) const {
  if (!callback) {
    return 0u;
  }
  size_t count = 0u;
  for (const auto& shader : shaders_) {
    count++;
    if (!callback(shader.first.type, shader.first.name, shader.second)) {
      break;
    }
  }
  return count;
}

}  // namespace impeller
