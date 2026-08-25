// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FILESYSTEM_WINDOWS_UTILS_H_
#define FILESYSTEM_WINDOWS_UTILS_H_

#include "tonic/common/build_config.h"

#if defined(OS_WIN)
#include <filesystem>
#include <string>
#include <string_view>

namespace filesystem {

inline std::wstring Utf8PathToWide(std::string_view utf8_path) {
  if (utf8_path.empty()) {
    return std::wstring();
  }
  const char8_t* u8_data = reinterpret_cast<const char8_t*>(utf8_path.data());
  std::u8string_view u8_view(u8_data, utf8_path.size());
  return std::filesystem::path(u8_view).wstring();
}

inline std::string WidePathToUtf8(std::wstring_view wide_path) {
  if (wide_path.empty()) {
    return std::string();
  }
  std::u8string u8_str = std::filesystem::path(wide_path).u8string();
  return std::string(reinterpret_cast<const char*>(u8_str.data()),
                     u8_str.size());
}

}  // namespace filesystem

#endif  // defined(OS_WIN)

#endif  // FILESYSTEM_WINDOWS_UTILS_H_
