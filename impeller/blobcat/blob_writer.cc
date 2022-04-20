// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/blobcat/blob_writer.h"

#include <filesystem>
#include <optional>

namespace impeller {

BlobWriter::BlobWriter() = default;

BlobWriter::~BlobWriter() = default;

std::optional<Blob::ShaderType> InferShaderTypefromFileExtension(
    const std::filesystem::path& path) {
  if (path == ".vert") {
    return Blob::ShaderType::kVertex;
  } else if (path == ".frag") {
    return Blob::ShaderType::kFragment;
  }
  return std::nullopt;
}

bool BlobWriter::AddBlobAtPath(const std::string& std_path) {
  std::filesystem::path path(std_path);

  if (path.stem().empty()) {
    FML_LOG(ERROR) << "File path stem was empty for " << path;
    return false;
  }

  if (path.extension() != ".gles") {
    FML_LOG(ERROR) << "File path doesn't have a known shader extension "
                   << path;
    return false;
  }

  // Get rid of .gles
  path = path.replace_extension();

  auto shader_type = InferShaderTypefromFileExtension(path.extension());

  if (!shader_type.has_value()) {
    FML_LOG(ERROR) << "Could not infer shader type from file extension.";
    return false;
  }

  // Get rid of the shader type extension (.vert, .frag, etc..).
  path = path.replace_extension();

  const auto shader_name = path.stem().string();
  if (shader_name.empty()) {
    FML_LOG(ERROR) << "Shader name was empty.";
    return false;
  }

  auto file_mapping = fml::FileMapping::CreateReadOnly(std_path);
  if (!file_mapping) {
    FML_LOG(ERROR) << "File doesn't exist at path: " << path;
    return false;
  }

  return AddBlob(shader_type.value(), std::move(shader_name),
                 std::move(file_mapping));
}

bool BlobWriter::AddBlob(Blob::ShaderType type,
                         std::string name,
                         std::shared_ptr<fml::Mapping> mapping) {
  if (name.empty() || !mapping || mapping->GetMapping() == nullptr) {
    return false;
  }

  if (name.length() >= Blob::kMaxNameLength) {
    FML_LOG(ERROR) << "Blob name length was too long.";
    return false;
  }

  blob_descriptions_.emplace_back(
      BlobDescription{type, std::move(name), std::move(mapping)});
  return true;
}

std::shared_ptr<fml::Mapping> BlobWriter::CreateMapping() const {
  BlobHeader header;
  header.blob_count = blob_descriptions_.size();

  uint64_t offset = sizeof(BlobHeader) + (sizeof(Blob) * header.blob_count);

  std::vector<Blob> blobs;
  {
    blobs.resize(header.blob_count);
    for (size_t i = 0; i < header.blob_count; i++) {
      const auto& desc = blob_descriptions_[i];
      blobs[i].type = desc.type;
      blobs[i].offset = offset;
      blobs[i].length = desc.mapping->GetSize();
      std::memcpy(reinterpret_cast<void*>(blobs[i].name), desc.name.data(),
                  desc.name.size());
      offset += blobs[i].length;
    }
  }

  {
    auto buffer = std::make_shared<std::vector<uint8_t>>();
    buffer->resize(offset, 0);

    size_t write_offset = 0u;

    // Write the header.
    {
      const size_t write_length = sizeof(header);
      std::memcpy(buffer->data() + write_offset, &header, write_length);
      write_offset += write_length;
    }

    // Write the blob descriptions.
    {
      const size_t write_length = blobs.size() * sizeof(Blob);
      std::memcpy(buffer->data() + write_offset, blobs.data(), write_length);
      write_offset += write_length;
    }

    // Write the blobs themselves.
    {
      for (size_t i = 0; i < header.blob_count; i++) {
        const auto& desc = blob_descriptions_[i];
        const size_t write_length = desc.mapping->GetSize();
        std::memcpy(buffer->data() + write_offset, desc.mapping->GetMapping(),
                    write_length);
        write_offset += write_length;
      }
    }
    FML_CHECK(write_offset == offset);
    return std::make_shared<fml::NonOwnedMapping>(
        buffer->data(), buffer->size(),
        [buffer](const uint8_t* data, size_t size) {});
  }
  return nullptr;
}

}  // namespace impeller
