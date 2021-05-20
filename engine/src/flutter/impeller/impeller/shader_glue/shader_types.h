// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <cstddef>
#include <string_view>

namespace impeller {

enum class ShaderStage {
  kUnknown,
  kVertex,
  kFragment,
};

struct ShaderStageInput {
  const char* name;
  std::size_t location;
};

}  // namespace impeller
