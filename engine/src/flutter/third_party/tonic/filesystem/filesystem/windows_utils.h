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

inline std::wstring Utf8ToWide(std::string_view utf8_string) {
  if (utf8_string.empty()) {
    return std::wstring();
  }
  const char8_t* u8_data =
      reinterpret_cast<const char8_t*>(utf8_string.data());
  std::u8string_view u8_view(u8_data, utf8_string.size());
  return std::filesystem::path(u8_view).wstring();
}

inline std::string WideToUtf8(std::wstring_view wide_string) {
  if (wide_string.empty()) {
    return std::string();
  }
  std::u8string u8_str = std::filesystem::path(wide_string).u8string();
  return std::string(reinterpret_cast<const char*>(u8_str.data()),
                     u8_str.size());
}

}  // namespace filesystem

#endif  // defined(OS_WIN)

#endif  // FILESYSTEM_WINDOWS_UTILS_H_
