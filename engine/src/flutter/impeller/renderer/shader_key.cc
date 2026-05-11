// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/shader_key.h"

namespace impeller {

std::string ShaderKey::MakeUserScopedName(std::string_view scope,
                                          std::string_view library_id,
                                          std::string_view entrypoint) {
  std::string out;
  out.reserve(scope.size() + 1 + library_id.size() + 1 + entrypoint.size());
  out.append(scope.data(), scope.size());
  out.push_back(':');
  out.append(library_id.data(), library_id.size());
  out.push_back(':');
  out.append(entrypoint.data(), entrypoint.size());
  return out;
}

}  // namespace impeller
