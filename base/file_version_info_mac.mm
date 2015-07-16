// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/file_version_info_mac.h"

#import <Foundation/Foundation.h>

#include "base/files/file_path.h"
#include "base/logging.h"
#include "base/mac/bundle_locations.h"
#include "base/mac/foundation_util.h"
#include "base/strings/sys_string_conversions.h"

FileVersionInfoMac::FileVersionInfoMac(NSBundle *bundle)
    : bundle_([bundle retain]) {
}

FileVersionInfoMac::~FileVersionInfoMac() {}

// static
FileVersionInfo* FileVersionInfo::CreateFileVersionInfoForCurrentModule() {
  return CreateFileVersionInfo(base::mac::FrameworkBundlePath());
}

// static
FileVersionInfo* FileVersionInfo::CreateFileVersionInfo(
    const base::FilePath& file_path) {
  NSString* path = base::SysUTF8ToNSString(file_path.value());
  NSBundle* bundle = [NSBundle bundleWithPath:path];
  return new FileVersionInfoMac(bundle);
}

base::string16 FileVersionInfoMac::company_name() {
  return base::string16();
}

base::string16 FileVersionInfoMac::company_short_name() {
  return base::string16();
}

base::string16 FileVersionInfoMac::internal_name() {
  return base::string16();
}

base::string16 FileVersionInfoMac::product_name() {
  return GetString16Value(kCFBundleNameKey);
}

base::string16 FileVersionInfoMac::product_short_name() {
  return GetString16Value(kCFBundleNameKey);
}

base::string16 FileVersionInfoMac::comments() {
  return base::string16();
}

base::string16 FileVersionInfoMac::legal_copyright() {
  return GetString16Value(CFSTR("CFBundleGetInfoString"));
}

base::string16 FileVersionInfoMac::product_version() {
  // On OS X, CFBundleVersion is used by LaunchServices, and must follow
  // specific formatting rules, so the four-part Chrome version is in
  // CFBundleShortVersionString. On iOS, both have a policy-enfoced limit
  // of three version components, so the full version is stored in a custom
  // key (CrBundleVersion) falling back to CFBundleVersion if not present.
#if defined(OS_IOS)
  base::string16 version(GetString16Value(CFSTR("CrBundleVersion")));
  if (version.length() > 0)
    return version;
  return GetString16Value(CFSTR("CFBundleVersion"));
#else
  return GetString16Value(CFSTR("CFBundleShortVersionString"));
#endif  // defined(OS_IOS)
}

base::string16 FileVersionInfoMac::file_description() {
  return base::string16();
}

base::string16 FileVersionInfoMac::legal_trademarks() {
  return base::string16();
}

base::string16 FileVersionInfoMac::private_build() {
  return base::string16();
}

base::string16 FileVersionInfoMac::file_version() {
  return product_version();
}

base::string16 FileVersionInfoMac::original_filename() {
  return GetString16Value(kCFBundleNameKey);
}

base::string16 FileVersionInfoMac::special_build() {
  return base::string16();
}

base::string16 FileVersionInfoMac::last_change() {
  return GetString16Value(CFSTR("SCMRevision"));
}

bool FileVersionInfoMac::is_official_build() {
#if defined (GOOGLE_CHROME_BUILD)
  return true;
#else
  return false;
#endif
}

base::string16 FileVersionInfoMac::GetString16Value(CFStringRef name) {
  if (bundle_) {
    NSString *ns_name = base::mac::CFToNSCast(name);
    NSString* value = [bundle_ objectForInfoDictionaryKey:ns_name];
    if (value) {
      return base::SysNSStringToUTF16(value);
    }
  }
  return base::string16();
}
