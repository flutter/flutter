// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/blobcat/blob_library.h"

#include <string>

namespace impeller {

BlobLibrary::BlobLibrary(std::shared_ptr<fml::Mapping> mapping)
    : mapping_(std::move(mapping)) {
  if (!mapping_ || mapping_->GetMapping() == nullptr) {
    FML_LOG(ERROR) << "Invalid mapping.";
    return;
  }

  BlobHeader header;
  std::vector<Blob> blobs;

  size_t offset = 0u;

  // Read the header.
  {
    const size_t read_size = sizeof(BlobHeader);
    if (mapping_->GetSize() < offset + read_size) {
      return;
    }
    std::memcpy(&header, mapping_->GetMapping() + offset, read_size);
    offset += read_size;

    // Validate the header.
    if (header.magic != kBlobCatMagic) {
      FML_LOG(ERROR) << "Invalid blob magic.";
      return;
    }

    blobs.resize(header.blob_count);
  }

  // Read the blob descriptions.
  {
    const size_t read_size = sizeof(Blob) * header.blob_count;
    ::memcpy(blobs.data(), mapping_->GetMapping() + offset, read_size);
    offset += read_size;  // NOLINT(clang-analyzer-deadcode.DeadStores)
  }

  // Read the blobs.
  {
    for (size_t i = 0; i < header.blob_count; i++) {
      const auto& blob = blobs[i];

      BlobKey key;
      key.type = blob.type;
      key.name = std::string{reinterpret_cast<const char*>(blob.name)};
      auto mapping = std::make_shared<fml::NonOwnedMapping>(
          mapping_->GetMapping() + blob.offset,  // offset
          blob.length,                           // length
          [mapping = mapping_](const uint8_t* data, size_t size) {}
          // release proc
      );

      auto inserted = blobs_.insert({key, mapping});
      if (!inserted.second) {
        FML_LOG(ERROR) << "Shader library had duplicate shader named "
                       << key.name;
        return;
      }
    }
  }

  is_valid_ = true;
}

BlobLibrary::BlobLibrary(BlobLibrary&&) = default;

BlobLibrary::~BlobLibrary() = default;

bool BlobLibrary::IsValid() const {
  return is_valid_;
}

size_t BlobLibrary::GetShaderCount() const {
  return blobs_.size();
}

std::shared_ptr<fml::Mapping> BlobLibrary::GetMapping(Blob::ShaderType type,
                                                      std::string name) const {
  BlobKey key;
  key.type = type;
  key.name = name;
  auto found = blobs_.find(key);
  return found == blobs_.end() ? nullptr : found->second;
}

size_t BlobLibrary::IterateAllBlobs(
    std::function<bool(Blob::ShaderType type,
                       const std::string& name,
                       const std::shared_ptr<fml::Mapping>& mapping)> callback)
    const {
  if (!IsValid() || !callback) {
    return 0u;
  }
  size_t count = 0u;
  for (const auto& blob : blobs_) {
    count++;
    if (!callback(blob.first.type, blob.first.name, blob.second)) {
      break;
    }
  }
  return count;
}

}  // namespace impeller
