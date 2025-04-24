// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/compiler/filesystem.h"

namespace impeller {

static bool MappingsAreSame(const fml::Mapping* lhs, const fml::Mapping* rhs) {
  if (lhs == rhs) {
    return true;
  }
  if (lhs == nullptr || rhs == nullptr) {
    return false;
  }
  if (lhs->GetSize() != rhs->GetSize()) {
    return false;
  }
  return std::memcmp(lhs->GetMapping(), rhs->GetMapping(), lhs->GetSize()) == 0;
}

bool WriteAtomicallyIfChanged(const fml::UniqueFD& base_directory,
                              const char* file_name,
                              const fml::Mapping& data) {
  if (auto existing = fml::FileMapping::CreateReadOnly(file_name)) {
    if (MappingsAreSame(&data, existing.get())) {
      return true;
    }
  }
  return fml::WriteAtomically(base_directory, file_name, data);
}

}  // namespace impeller
