// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/shader_key.h"

#include <atomic>
#include <cstdint>

#include "third_party/abseil-cpp/absl/strings/str_cat.h"

namespace impeller {

std::string ShaderKey::MakeFallbackLibraryId() {
  static std::atomic<uint64_t> counter{0};
  return absl::StrCat("auto:", counter.fetch_add(1, std::memory_order_relaxed));
}

std::string ShaderKey::MakeUserScopedName(std::string_view scope,
                                          std::string_view library_id,
                                          std::string_view entrypoint) {
  return absl::StrCat(scope, ":", library_id, ":", entrypoint);
}

}  // namespace impeller
