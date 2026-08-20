// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/platform/win/wstring_conversion.h"

#include <filesystem>
#include <string>

namespace fml {

std::string WideStringToUtf8(const std::wstring_view str) {
  if (str.empty()) {
    return {};
  }
  std::filesystem::path path(str);
  std::u8string u8str = path.u8string();
  return std::string(u8str.begin(), u8str.end());
}

std::wstring Utf8ToWideString(const std::string_view str) {
  if (str.empty()) {
    return {};
  }
  const char8_t* start = reinterpret_cast<const char8_t*>(str.data());
  const char8_t* end = start + str.size();
  std::filesystem::path path(start, end);
  return path.wstring();
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
