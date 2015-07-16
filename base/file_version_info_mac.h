// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_FILE_VERSION_INFO_MAC_H_
#define BASE_FILE_VERSION_INFO_MAC_H_

#include <CoreFoundation/CoreFoundation.h>
#include <string>

#include "base/file_version_info.h"
#include "base/mac/scoped_nsobject.h"

@class NSBundle;

class FileVersionInfoMac : public FileVersionInfo {
 public:
  explicit FileVersionInfoMac(NSBundle *bundle);
  ~FileVersionInfoMac() override;

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

 private:
  // Returns a base::string16 value for a property name.
  // Returns the empty string if the property does not exist.
  base::string16 GetString16Value(CFStringRef name);

  base::scoped_nsobject<NSBundle> bundle_;

  DISALLOW_COPY_AND_ASSIGN(FileVersionInfoMac);
};

#endif  // BASE_FILE_VERSION_INFO_MAC_H_
