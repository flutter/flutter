// Copyright (c) 2010 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/win/i18n.h"

#include <windows.h>

#include "base/logging.h"

namespace {

// Keep this enum in sync with kLanguageFunctionNames.
enum LanguageFunction {
  SYSTEM_LANGUAGES,
  USER_LANGUAGES,
  PROCESS_LANGUAGES,
  THREAD_LANGUAGES,
  NUM_FUNCTIONS
};

const char kSystemLanguagesFunctionName[] = "GetSystemPreferredUILanguages";
const char kUserLanguagesFunctionName[] = "GetUserPreferredUILanguages";
const char kProcessLanguagesFunctionName[] = "GetProcessPreferredUILanguages";
const char kThreadLanguagesFunctionName[] = "GetThreadPreferredUILanguages";

// Keep this array in sync with enum LanguageFunction.
const char *const kLanguageFunctionNames[] = {
  &kSystemLanguagesFunctionName[0],
  &kUserLanguagesFunctionName[0],
  &kProcessLanguagesFunctionName[0],
  &kThreadLanguagesFunctionName[0]
};

COMPILE_ASSERT(NUM_FUNCTIONS == arraysize(kLanguageFunctionNames),
               language_function_enum_and_names_out_of_sync);

// Calls one of the MUI Get*PreferredUILanguages functions, placing the result
// in |languages|.  |function| identifies the function to call and |flags| is
// the function-specific flags (callers must not specify MUI_LANGUAGE_ID or
// MUI_LANGUAGE_NAME).  Returns true if at least one language is placed in
// |languages|.
bool GetMUIPreferredUILanguageList(LanguageFunction function, ULONG flags,
                                   std::vector<wchar_t>* languages) {
  DCHECK(0 <= function && NUM_FUNCTIONS > function);
  DCHECK_EQ(0U, (flags & (MUI_LANGUAGE_ID | MUI_LANGUAGE_NAME)));
  DCHECK(languages);

  HMODULE kernel32 = GetModuleHandle(L"kernel32.dll");
  if (NULL != kernel32) {
    typedef BOOL (WINAPI* GetPreferredUILanguages_Fn)(
        DWORD, PULONG, PZZWSTR, PULONG);
    GetPreferredUILanguages_Fn get_preferred_ui_languages =
        reinterpret_cast<GetPreferredUILanguages_Fn>(
            GetProcAddress(kernel32, kLanguageFunctionNames[function]));
    if (NULL != get_preferred_ui_languages) {
      const ULONG call_flags = flags | MUI_LANGUAGE_NAME;
      ULONG language_count = 0;
      ULONG buffer_length = 0;
      if (get_preferred_ui_languages(call_flags, &language_count, NULL,
                                     &buffer_length) &&
          0 != buffer_length) {
        languages->resize(buffer_length);
        if (get_preferred_ui_languages(call_flags, &language_count,
                                       &(*languages)[0], &buffer_length) &&
            0 != language_count) {
          DCHECK(languages->size() == buffer_length);
          return true;
        } else {
          DPCHECK(0 == language_count)
              << "Failed getting preferred UI languages.";
        }
      } else {
        DPCHECK(0 == buffer_length)
            << "Failed getting size of preferred UI languages.";
      }
    } else {
      DVLOG(2) << "MUI not available.";
    }
  } else {
    NOTREACHED() << "kernel32.dll not found.";
  }

  return false;
}

bool GetUserDefaultUILanguage(std::wstring* language, std::wstring* region) {
  DCHECK(language);

  LANGID lang_id = ::GetUserDefaultUILanguage();
  if (LOCALE_CUSTOM_UI_DEFAULT != lang_id) {
    const LCID locale_id = MAKELCID(lang_id, SORT_DEFAULT);
    // max size for LOCALE_SISO639LANGNAME and LOCALE_SISO3166CTRYNAME is 9
    wchar_t result_buffer[9];
    int result_length =
        GetLocaleInfo(locale_id, LOCALE_SISO639LANGNAME, &result_buffer[0],
                      arraysize(result_buffer));
    DPCHECK(0 != result_length) << "Failed getting language id";
    if (1 < result_length) {
      language->assign(&result_buffer[0], result_length - 1);
      region->clear();
      if (SUBLANG_NEUTRAL != SUBLANGID(lang_id)) {
        result_length =
            GetLocaleInfo(locale_id, LOCALE_SISO3166CTRYNAME, &result_buffer[0],
                          arraysize(result_buffer));
        DPCHECK(0 != result_length) << "Failed getting region id";
        if (1 < result_length)
          region->assign(&result_buffer[0], result_length - 1);
      }
      return true;
    }
  } else {
    // This is entirely unexpected on pre-Vista, which is the only time we
    // should try GetUserDefaultUILanguage anyway.
    NOTREACHED() << "Cannot determine language for a supplemental locale.";
  }
  return false;
}

bool GetPreferredUILanguageList(LanguageFunction function, ULONG flags,
                                std::vector<std::wstring>* languages) {
  std::vector<wchar_t> buffer;
  std::wstring language;
  std::wstring region;

  if (GetMUIPreferredUILanguageList(function, flags, &buffer)) {
    std::vector<wchar_t>::const_iterator scan = buffer.begin();
    language.assign(&*scan);
    while (!language.empty()) {
      languages->push_back(language);
      scan += language.size() + 1;
      language.assign(&*scan);
    }
  } else if (GetUserDefaultUILanguage(&language, &region)) {
    // Mimic the MUI behavior of putting the neutral version of the lang after
    // the regional one (e.g., "fr-CA, fr").
    if (!region.empty())
      languages->push_back(std::wstring(language)
                               .append(1, L'-')
                               .append(region));
    languages->push_back(language);
  } else {
    return false;
  }

  return true;
}

}  // namespace

namespace base {
namespace win {
namespace i18n {

bool GetUserPreferredUILanguageList(std::vector<std::wstring>* languages) {
  DCHECK(languages);
  return GetPreferredUILanguageList(USER_LANGUAGES, 0, languages);
}

bool GetThreadPreferredUILanguageList(std::vector<std::wstring>* languages) {
  DCHECK(languages);
  return GetPreferredUILanguageList(
      THREAD_LANGUAGES, MUI_MERGE_SYSTEM_FALLBACK | MUI_MERGE_USER_FALLBACK,
      languages);
}

}  // namespace i18n
}  // namespace win
}  // namespace base
