// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/shader_key.h"

#include <atomic>
#include <cstdint>

namespace impeller {

std::string ShaderKey::MakeFallbackLibraryId() {
  static std::atomic<uint64_t> counter{0};
  return "auto:" +
         std::to_string(counter.fetch_add(1, std::memory_order_relaxed));
}

std::string ShaderKey::MakeUserScopedName(std::string_view scope,
                                          std::string_view library_id,
                                          std::string_view entrypoint) {
  std::string out;
  out.reserve(scope.size() + 1 + library_id.size() + 1 + entrypoint.size());
  out.append(scope);
  out.push_back(':');
  out.append(library_id);
  out.push_back(':');
  out.append(entrypoint);
  return out;
}

}  // namespace impeller
