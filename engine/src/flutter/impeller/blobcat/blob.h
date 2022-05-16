// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <cstddef>
#include <cstdint>
#include <memory>
#include <string>

#include "flutter/fml/macros.h"
#include "flutter/fml/mapping.h"

namespace impeller {

constexpr const uint32_t kBlobCatMagic = 0x0B10BCA7;
struct BlobHeader {
  uint32_t magic = kBlobCatMagic;
  uint32_t blob_count = 0u;
};

struct Blob {
  enum class ShaderType : uint8_t {
    kVertex,
    kFragment,
  };

  static constexpr size_t kMaxNameLength = 32u;

  ShaderType type = ShaderType::kVertex;
  uint64_t offset = 0;
  uint64_t length = 0;
  uint8_t name[kMaxNameLength] = {};
};

struct BlobDescription {
  Blob::ShaderType type;
  std::string name;
  std::shared_ptr<fml::Mapping> mapping;
};

}  // namespace impeller
