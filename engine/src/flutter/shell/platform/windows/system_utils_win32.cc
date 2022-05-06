// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/system_utils.h"

#include <Windows.h>

#include <sstream>

#include "flutter/fml/platform/win/wstring_conversion.h"

namespace flutter {

std::vector<LanguageInfo> GetPreferredLanguageInfo() {
  std::vector<std::wstring> languages = GetPreferredLanguages();
  std::vector<LanguageInfo> language_info;
  language_info.reserve(languages.size());

  for (auto language : languages) {
    language_info.push_back(ParseLanguageName(language));
  }
  return language_info;
}

std::vector<std::wstring> GetPreferredLanguages() {
  std::vector<std::wstring> languages;
  DWORD flags = MUI_LANGUAGE_NAME | MUI_UI_FALLBACK;

  // Get buffer length.
  ULONG count = 0;
  ULONG buffer_size = 0;
  if (!::GetThreadPreferredUILanguages(flags, &count, nullptr, &buffer_size)) {
    return languages;
  }

  // Get the list of null-separated languages.
  std::wstring buffer(buffer_size, '\0');
  if (!::GetThreadPreferredUILanguages(flags, &count, buffer.data(),
                                       &buffer_size)) {
    return languages;
  }

  // Extract the individual languages from the buffer.
  size_t start = 0;
  while (true) {
    // The buffer is terminated by an empty string (i.e., a double null).
    if (buffer[start] == L'\0') {
      break;
    }
    // Read the next null-terminated language.
    std::wstring language(buffer.c_str() + start);
    if (language.empty()) {
      break;
    }
    languages.push_back(language);
    // Skip past that language and its terminating null in the buffer.
    start += language.size() + 1;
  }
  return languages;
}

LanguageInfo ParseLanguageName(std::wstring language_name) {
  LanguageInfo info;

  // Split by '-', discarding any suplemental language info (-x-foo).
  std::vector<std::string> components;
  std::istringstream stream(fml::WideStringToUtf8(language_name));
  std::string component;
  while (getline(stream, component, '-')) {
    if (component == "x") {
      break;
    }
    components.push_back(component);
  }

  // Determine which components are which.
  info.language = components[0];
  if (components.size() == 3) {
    info.script = components[1];
    info.region = components[2];
  } else if (components.size() == 2) {
    // A script code will always be four characters long.
    if (components[1].size() == 4) {
      info.script = components[1];
    } else {
      info.region = components[1];
    }
  }
  return info;
}

std::wstring GetUserTimeFormat() {
  // Rather than do the call-allocate-call-free dance, just use a sufficiently
  // large buffer to handle any reasonable time format string.
  const int kBufferSize = 100;
  wchar_t buffer[kBufferSize];
  if (::GetLocaleInfoEx(LOCALE_NAME_USER_DEFAULT, LOCALE_STIMEFORMAT, buffer,
                        kBufferSize) == 0) {
    return std::wstring();
  }
  return std::wstring(buffer, kBufferSize);
}

bool Prefer24HourTime(std::wstring time_format) {
  return time_format.find(L"H") != std::wstring::npos;
}

}  // namespace flutter
