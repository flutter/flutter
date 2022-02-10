// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/platform/win/wstring_conversion.h"

#include <codecvt>
#include <locale>
#include <string>

namespace fml {

using WideStringConverter =
    std::wstring_convert<std::codecvt_utf8_utf16<wchar_t>, wchar_t>;

std::string WideStringToUtf8(const std::wstring_view str) {
  WideStringConverter converter;
  return converter.to_bytes(str.data());
}

std::wstring Utf8ToWideString(const std::string_view str) {
  WideStringConverter converter;
  return converter.from_bytes(str.data());
}

}  // namespace fml
