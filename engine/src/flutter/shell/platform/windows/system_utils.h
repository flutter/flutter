// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file contains utilities for system-level information/settings.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_SYSTEM_UTILS_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_SYSTEM_UTILS_H_

#include <string>
#include <vector>

namespace flutter {

// Components of a system language/locale.
struct LanguageInfo {
  std::string language;
  std::string region;
  std::string script;
};

// Returns the list of user-preferred languages, in preference order,
// parsed into LanguageInfo structures.
std::vector<LanguageInfo> GetPreferredLanguageInfo();

// Returns the list of user-preferred languages, in preference order.
// The language names are as described at:
// https://docs.microsoft.com/en-us/windows/win32/intl/language-names
std::vector<std::wstring> GetPreferredLanguages();

// Parses a Windows language name into its components.
LanguageInfo ParseLanguageName(std::wstring language_name);

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_SYSTEM_UTILS_H_
