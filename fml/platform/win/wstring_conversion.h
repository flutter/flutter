// Copyright 2018 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_PLATFORM_WIN_WSTRING_CONVERSION_H_
#define FLUTTER_FML_PLATFORM_WIN_WSTRING_CONVERSION_H_

#include <codecvt>
#include <locale>
#include <string>

namespace fml {

using WideStringConvertor =
    std::wstring_convert<std::codecvt_utf8<wchar_t>, wchar_t>;

inline std::wstring ConvertToWString(const char* path) {
  if (path == nullptr) {
    return {};
  }
  std::string path8(path);
  std::wstring_convert<std::codecvt_utf8_utf16<wchar_t>, wchar_t> wchar_conv;
  return wchar_conv.from_bytes(path8);
}

inline std::wstring StringToWideString(const std::string& str) {
  WideStringConvertor converter;
  return converter.from_bytes(str);
}

inline std::string WideStringToString(const std::wstring& wstr) {
  WideStringConvertor converter;
  return converter.to_bytes(wstr);
}

}  // namespace fml

#endif  // FLUTTER_FML_PLATFORM_WIN_WSTRING_CONVERSION_H_
