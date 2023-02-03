// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <optional>

#include "impeller/compiler/compiler_backend.h"

#include "spirv_msl.hpp"
#include "spirv_parser.hpp"

namespace impeller {

/// @brief Sorts uniform declarations in an IR according to decoration order.
std::vector<spirv_cross::ID> SortUniforms(
    const spirv_cross::ParsedIR* ir,
    const spirv_cross::Compiler* compiler,
    std::optional<spirv_cross::SPIRType::BaseType> type_filter = std::nullopt);

}  // namespace impeller
