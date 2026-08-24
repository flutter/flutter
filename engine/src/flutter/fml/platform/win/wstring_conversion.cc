// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/platform/win/wstring_conversion.h"

#include <windows.h>
#include <string>

namespace fml {

std::string WideStringToUtf8(const std::wstring_view str) {
  if (str.empty()) {
    return {};
  }
  int size_needed = ::WideCharToMultiByte(CP_UTF8, 0, str.data(),
                                          static_cast<int>(str.size()), nullptr,
                                          0, nullptr, nullptr);
  if (size_needed <= 0) {
    return {};
  }
  std::string result(size_needed, 0);
  ::WideCharToMultiByte(CP_UTF8, 0, str.data(), static_cast<int>(str.size()),
                        &result[0], size_needed, nullptr, nullptr);
  return result;
}

std::wstring Utf8ToWideString(const std::string_view str) {
  if (str.empty()) {
    return {};
  }
  int size_needed = ::MultiByteToWideChar(
      CP_UTF8, 0, str.data(), static_cast<int>(str.size()), nullptr, 0);
  if (size_needed <= 0) {
    return {};
  }
  std::wstring result(size_needed, 0);
  ::MultiByteToWideChar(CP_UTF8, 0, str.data(), static_cast<int>(str.size()),
                        &result[0], size_needed);
  return result;
}

std::u16string WideStringToUtf16(const std::wstring_view str) {
  static_assert(sizeof(std::wstring::value_type) ==
                sizeof(std::u16string::value_type));
  return {begin(str), end(str)};
}

std::wstring Utf16ToWideString(const std::u16string_view str) {
  static_assert(sizeof(std::wstring::value_type) ==
                sizeof(std::u16string::value_type));
  return {begin(str), end(str)};
}

}  // namespace fml
