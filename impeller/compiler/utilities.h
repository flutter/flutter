// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <filesystem>
#include <string>
#include <string_view>

#include "flutter/fml/macros.h"

namespace impeller {
namespace compiler {

/// @brief  Converts a native format path to a utf8 string.
///
///         This utility uses `path::u8string()` to convert native paths to
///         utf8. If the given path doesn't match the underlying native path
///         format, and the native path format isn't utf8 (i.e. Windows, which
///         has utf16 paths), the path will get mangled.
std::string Utf8FromPath(const std::filesystem::path& path);

std::string InferShaderNameFromPath(std::string_view path);

std::string ConvertToCamelCase(std::string_view string);

/// @brief  Ensure that the entrypoint name is a valid identifier in the target
///         language.
std::string ConvertToEntrypointName(std::string_view string);

bool StringStartsWith(const std::string& target, const std::string& prefix);

}  // namespace compiler
}  // namespace impeller
