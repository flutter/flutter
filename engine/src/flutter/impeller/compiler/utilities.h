// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_COMPILER_UTILITIES_H_
#define FLUTTER_IMPELLER_COMPILER_UTILITIES_H_

#include <filesystem>
#include <string>
#include <string_view>

namespace impeller {
namespace compiler {

/// @brief  Sets the file access mode of the file at path 'p' to 0644.
bool SetPermissiveAccess(const std::filesystem::path& p);

/// @brief  Converts a native format path to a utf8 string.
///
///         This utility uses `path::u8string()` to convert native paths to
///         utf8. If the given path doesn't match the underlying native path
///         format, and the native path format isn't utf8 (i.e. Windows, which
///         has utf16 paths), the path will get mangled.
std::string Utf8FromPath(const std::filesystem::path& path);

/// @brief  Escapes a path so it survives a depfile's space separated list.
///
///         A space is written as `\ `, and any run of backslashes immediately
///         before it is doubled, since a parser reads 2N+1 backslashes followed
///         by a space as N backslashes followed by a space. Backslashes
///         elsewhere in the path are left alone so that Windows paths, which
///         Ninja copies through verbatim, keep working.
std::string EscapeDepfilePath(const std::string& path);

std::string InferShaderNameFromPath(const std::filesystem::path& path);

std::string ToCamelCase(std::string_view string);

std::string ToLowerCase(std::string_view string);

/// @brief  Ensure that the entrypoint name is a valid identifier in the target
///         language.
std::string ConvertToEntrypointName(std::string_view string);

bool StringStartsWith(const std::string& target, const std::string& prefix);

}  // namespace compiler
}  // namespace impeller

#endif  // FLUTTER_IMPELLER_COMPILER_UTILITIES_H_
