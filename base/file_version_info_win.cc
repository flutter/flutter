// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/file_version_info_win.h"

#include <windows.h>

#include "base/file_version_info.h"
#include "base/files/file_path.h"
#include "base/logging.h"
#include "base/threading/thread_restrictions.h"

using base::FilePath;

FileVersionInfoWin::FileVersionInfoWin(void* data,
                                       WORD language,
                                       WORD code_page)
    : language_(language), code_page_(code_page) {
  base::ThreadRestrictions::AssertIOAllowed();
  data_.reset((char*) data);
  fixed_file_info_ = NULL;
  UINT size;
  ::VerQueryValue(data_.get(), L"\\", (LPVOID*)&fixed_file_info_, &size);
}

FileVersionInfoWin::~FileVersionInfoWin() {
  DCHECK(data_.get());
}

typedef struct {
  WORD language;
  WORD code_page;
} LanguageAndCodePage;

// static
FileVersionInfo* FileVersionInfo::CreateFileVersionInfoForModule(
    HMODULE module) {
  // Note that the use of MAX_PATH is basically in line with what we do for
  // all registered paths (PathProviderWin).
  wchar_t system_buffer[MAX_PATH];
  system_buffer[0] = 0;
  if (!GetModuleFileName(module, system_buffer, MAX_PATH))
    return NULL;

  FilePath app_path(system_buffer);
  return CreateFileVersionInfo(app_path);
}

// static
FileVersionInfo* FileVersionInfo::CreateFileVersionInfo(
    const FilePath& file_path) {
  base::ThreadRestrictions::AssertIOAllowed();

  DWORD dummy;
  const wchar_t* path = file_path.value().c_str();
  DWORD length = ::GetFileVersionInfoSize(path, &dummy);
  if (length == 0)
    return NULL;

  void* data = calloc(length, 1);
  if (!data)
    return NULL;

  if (!::GetFileVersionInfo(path, dummy, length, data)) {
    free(data);
    return NULL;
  }

  LanguageAndCodePage* translate = NULL;
  uint32 page_count;
  BOOL query_result = VerQueryValue(data, L"\\VarFileInfo\\Translation",
                                   (void**) &translate, &page_count);

  if (query_result && translate) {
    return new FileVersionInfoWin(data, translate->language,
                                  translate->code_page);

  } else {
    free(data);
    return NULL;
  }
}

base::string16 FileVersionInfoWin::company_name() {
  return GetStringValue(L"CompanyName");
}

base::string16 FileVersionInfoWin::company_short_name() {
  return GetStringValue(L"CompanyShortName");
}

base::string16 FileVersionInfoWin::internal_name() {
  return GetStringValue(L"InternalName");
}

base::string16 FileVersionInfoWin::product_name() {
  return GetStringValue(L"ProductName");
}

base::string16 FileVersionInfoWin::product_short_name() {
  return GetStringValue(L"ProductShortName");
}

base::string16 FileVersionInfoWin::comments() {
  return GetStringValue(L"Comments");
}

base::string16 FileVersionInfoWin::legal_copyright() {
  return GetStringValue(L"LegalCopyright");
}

base::string16 FileVersionInfoWin::product_version() {
  return GetStringValue(L"ProductVersion");
}

base::string16 FileVersionInfoWin::file_description() {
  return GetStringValue(L"FileDescription");
}

base::string16 FileVersionInfoWin::legal_trademarks() {
  return GetStringValue(L"LegalTrademarks");
}

base::string16 FileVersionInfoWin::private_build() {
  return GetStringValue(L"PrivateBuild");
}

base::string16 FileVersionInfoWin::file_version() {
  return GetStringValue(L"FileVersion");
}

base::string16 FileVersionInfoWin::original_filename() {
  return GetStringValue(L"OriginalFilename");
}

base::string16 FileVersionInfoWin::special_build() {
  return GetStringValue(L"SpecialBuild");
}

base::string16 FileVersionInfoWin::last_change() {
  return GetStringValue(L"LastChange");
}

bool FileVersionInfoWin::is_official_build() {
  return (GetStringValue(L"Official Build").compare(L"1") == 0);
}

bool FileVersionInfoWin::GetValue(const wchar_t* name,
                                  std::wstring* value_str) {
  WORD lang_codepage[8];
  int i = 0;
  // Use the language and codepage from the DLL.
  lang_codepage[i++] = language_;
  lang_codepage[i++] = code_page_;
  // Use the default language and codepage from the DLL.
  lang_codepage[i++] = ::GetUserDefaultLangID();
  lang_codepage[i++] = code_page_;
  // Use the language from the DLL and Latin codepage (most common).
  lang_codepage[i++] = language_;
  lang_codepage[i++] = 1252;
  // Use the default language and Latin codepage (most common).
  lang_codepage[i++] = ::GetUserDefaultLangID();
  lang_codepage[i++] = 1252;

  i = 0;
  while (i < arraysize(lang_codepage)) {
    wchar_t sub_block[MAX_PATH];
    WORD language = lang_codepage[i++];
    WORD code_page = lang_codepage[i++];
    _snwprintf_s(sub_block, MAX_PATH, MAX_PATH,
                 L"\\StringFileInfo\\%04x%04x\\%ls", language, code_page, name);
    LPVOID value = NULL;
    uint32 size;
    BOOL r = ::VerQueryValue(data_.get(), sub_block, &value, &size);
    if (r && value) {
      value_str->assign(static_cast<wchar_t*>(value));
      return true;
    }
  }
  return false;
}

std::wstring FileVersionInfoWin::GetStringValue(const wchar_t* name) {
  std::wstring str;
  if (GetValue(name, &str))
    return str;
  else
    return L"";
}
