// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>
#include <type_traits>
#include <unordered_map>

#include "flutter/fml/hash_combine.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/mapping.h"
#include "impeller/blobcat/blob.h"

namespace impeller {

class BlobLibrary {
 public:
  BlobLibrary(std::shared_ptr<fml::Mapping> mapping);

  BlobLibrary(BlobLibrary&&);

  ~BlobLibrary();

  bool IsValid() const;

  size_t GetShaderCount() const;

  std::shared_ptr<fml::Mapping> GetMapping(Blob::ShaderType type,
                                           std::string name) const;

  size_t IterateAllBlobs(
      std::function<bool(Blob::ShaderType type,
                         const std::string& name,
                         const std::shared_ptr<fml::Mapping>& mapping)>) const;

 private:
  struct BlobKey {
    Blob::ShaderType type = Blob::ShaderType::kFragment;
    std::string name;

    struct Hash {
      size_t operator()(const BlobKey& key) const {
        return fml::HashCombine(
            static_cast<std::underlying_type_t<decltype(key.type)>>(key.type),
            key.name);
      }
    };

    struct Equal {
      bool operator()(const BlobKey& lhs, const BlobKey& rhs) const {
        return lhs.type == rhs.type && lhs.name == rhs.name;
      }
    };
  };

  using Blobs = std::unordered_map<BlobKey,
                                   std::shared_ptr<fml::Mapping>,
                                   BlobKey::Hash,
                                   BlobKey::Equal>;

  std::shared_ptr<fml::Mapping> mapping_;
  Blobs blobs_;
  bool is_valid_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(BlobLibrary);
};

}  // namespace impeller
