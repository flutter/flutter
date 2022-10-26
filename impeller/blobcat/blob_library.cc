// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/blobcat/blob_library.h"

#include <array>
#include <string>
#include <utility>

#include "impeller/base/validation.h"
#include "impeller/blobcat/blob_flatbuffers.h"

namespace impeller {

constexpr BlobShaderType ToShaderType(fb::Stage stage) {
  switch (stage) {
    case fb::Stage::kVertex:
      return BlobShaderType::kVertex;
    case fb::Stage::kFragment:
      return BlobShaderType::kFragment;
    case fb::Stage::kCompute:
      return BlobShaderType::kCompute;
  }
  FML_UNREACHABLE();
}

BlobLibrary::BlobLibrary(std::shared_ptr<fml::Mapping> payload)
    : payload_(std::move(payload)) {
  if (!payload_ || payload_->GetMapping() == nullptr) {
    VALIDATION_LOG << "Blob mapping was absent.";
    return;
  }

  if (!fb::BlobLibraryBufferHasIdentifier(payload_->GetMapping())) {
    VALIDATION_LOG << "Invalid blob magic.";
    return;
  }

  auto blob_library = fb::GetBlobLibrary(payload_->GetMapping());
  if (!blob_library) {
    return;
  }

  if (auto items = blob_library->items()) {
    for (auto i = items->begin(), end = items->end(); i != end; i++) {
      BlobKey key;
      key.name = i->name()->str();
      key.type = ToShaderType(i->stage());
      blobs_[key] = std::make_shared<fml::NonOwnedMapping>(
          i->mapping()->Data(), i->mapping()->size(),
          [payload = payload_](auto, auto) {
            // The pointers are into the base payload. Instead of copying the
            // data, just hold onto the payload.
          });
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

std::shared_ptr<fml::Mapping> BlobLibrary::GetMapping(BlobShaderType type,
                                                      std::string name) const {
  BlobKey key;
  key.type = type;
  key.name = std::move(name);
  auto found = blobs_.find(key);
  return found == blobs_.end() ? nullptr : found->second;
}

size_t BlobLibrary::IterateAllBlobs(
    const std::function<bool(BlobShaderType type,
                             const std::string& name,
                             const std::shared_ptr<fml::Mapping>& mapping)>&
        callback) const {
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
