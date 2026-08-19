// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FILESYSTEM_WINDOWS_UTILS_H_
#define FILESYSTEM_WINDOWS_UTILS_H_

#include "tonic/common/build_config.h"

#if defined(OS_WIN)
#include <windows.h>
#include <string>
#include <string_view>

namespace filesystem {

inline std::wstring Utf8ToWide(std::string_view utf8_string) {
  if (utf8_string.empty()) {
    return std::wstring();
  }
  int target_len = MultiByteToWideChar(CP_UTF8, 0, utf8_string.data(),
                                       static_cast<int>(utf8_string.length()),
                                       nullptr, 0);
  if (target_len == 0) {
    return std::wstring();
  }
  std::wstring wide_string(target_len, L'\0');
  MultiByteToWideChar(CP_UTF8, 0, utf8_string.data(),
                      static_cast<int>(utf8_string.length()),
                      &wide_string[0], target_len);
  return wide_string;
}

inline std::string WideToUtf8(std::wstring_view wide_string) {
  if (wide_string.empty()) {
    return std::string();
  }
  int target_len = WideCharToMultiByte(
      CP_UTF8, 0, wide_string.data(), static_cast<int>(wide_string.length()),
      nullptr, 0, nullptr, nullptr);
  if (target_len == 0) {
    return std::string();
  }
  std::string utf8_string(target_len, '\0');
  WideCharToMultiByte(
      CP_UTF8, 0, wide_string.data(), static_cast<int>(wide_string.length()),
      &utf8_string[0], target_len, nullptr, nullptr);
  return utf8_string;
}

}  // namespace filesystem

#endif  // defined(OS_WIN)

#endif  // FILESYSTEM_WINDOWS_UTILS_H_
