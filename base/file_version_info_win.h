// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_FILE_VERSION_INFO_WIN_H_
#define BASE_FILE_VERSION_INFO_WIN_H_

#include <string>

#include "base/base_export.h"
#include "base/basictypes.h"
#include "base/file_version_info.h"
#include "base/memory/scoped_ptr.h"

struct tagVS_FIXEDFILEINFO;
typedef tagVS_FIXEDFILEINFO VS_FIXEDFILEINFO;

class BASE_EXPORT FileVersionInfoWin : public FileVersionInfo {
 public:
  FileVersionInfoWin(void* data, WORD language, WORD code_page);
  ~FileVersionInfoWin() override;

  // Accessors to the different version properties.
  // Returns an empty string if the property is not found.
  base::string16 company_name() override;
  base::string16 company_short_name() override;
  base::string16 product_name() override;
  base::string16 product_short_name() override;
  base::string16 internal_name() override;
  base::string16 product_version() override;
  base::string16 private_build() override;
  base::string16 special_build() override;
  base::string16 comments() override;
  base::string16 original_filename() override;
  base::string16 file_description() override;
  base::string16 file_version() override;
  base::string16 legal_copyright() override;
  base::string16 legal_trademarks() override;
  base::string16 last_change() override;
  bool is_official_build() override;

  // Lets you access other properties not covered above.
  bool GetValue(const wchar_t* name, std::wstring* value);

  // Similar to GetValue but returns a wstring (empty string if the property
  // does not exist).
  std::wstring GetStringValue(const wchar_t* name);

  // Get the fixed file info if it exists. Otherwise NULL
  VS_FIXEDFILEINFO* fixed_file_info() { return fixed_file_info_; }

 private:
  scoped_ptr<char, base::FreeDeleter> data_;
  WORD language_;
  WORD code_page_;
  // This is a pointer into the data_ if it exists. Otherwise NULL.
  VS_FIXEDFILEINFO* fixed_file_info_;

  DISALLOW_COPY_AND_ASSIGN(FileVersionInfoWin);
};

#endif  // BASE_FILE_VERSION_INFO_WIN_H_
