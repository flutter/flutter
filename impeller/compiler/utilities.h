// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <string>
#include <string_view>

#include "flutter/fml/macros.h"

namespace impeller {
namespace compiler {

std::string InferShaderNameFromPath(std::string_view path);

std::string ConvertToCamelCase(std::string_view string);

}  // namespace compiler
}  // namespace impeller
