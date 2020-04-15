// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_STRING_CONVERSION_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_STRING_CONVERSION_H_

#include <string>

namespace flutter {

// Converts a string from UTF-16 to UTF-8. Returns an empty string if the
// input is not valid UTF-16.
std::string Utf8FromUtf16(const std::wstring& utf16_string);

// Converts a string from UTF-8 to UTF-16. Returns an empty string if the
// input is not valid UTF-8.
std::wstring Utf16FromUtf8(const std::string& utf8_string);

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_STRING_CONVERSION_H_
