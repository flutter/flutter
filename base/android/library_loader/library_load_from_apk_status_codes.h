// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_ANDROID_LIBRARY_LOADER_LIBRARY_LOAD_FROM_APK_STATUS_CODES_H_
#define BASE_ANDROID_LIBRARY_LOADER_LIBRARY_LOAD_FROM_APK_STATUS_CODES_H_

namespace base {
namespace android {

namespace {

// This enum must be kept in sync with the LibraryLoadFromApkStatus enum in
// tools/metrics/histograms/histograms.xml.
// GENERATED_JAVA_ENUM_PACKAGE: org.chromium.base.library_loader
enum LibraryLoadFromApkStatusCodes {
  // The loader was unable to determine whether the functionality is supported.
  LIBRARY_LOAD_FROM_APK_STATUS_CODES_UNKNOWN = 0,

  // The device does not support loading a library directly from the APK file
  // (obsolete).
  LIBRARY_LOAD_FROM_APK_STATUS_CODES_NOT_SUPPORTED_OBSOLETE = 1,

  // The device supports loading a library directly from the APK file.
  // (obsolete).
  LIBRARY_LOAD_FROM_APK_STATUS_CODES_SUPPORTED_OBSOLETE = 2,

  // The Chromium library was successfully loaded directly from the APK file.
  LIBRARY_LOAD_FROM_APK_STATUS_CODES_SUCCESSFUL = 3,

  // The Chromium library was successfully loaded using the unpack library
  // fallback because it was compressed or not page aligned in the APK file.
  LIBRARY_LOAD_FROM_APK_STATUS_CODES_USED_UNPACK_LIBRARY_FALLBACK = 4,

  // The Chromium library was successfully loaded using the no map executable
  // support fallback (obsolete).
  LIBRARY_LOAD_FROM_APK_STATUS_CODES_USED_NO_MAP_EXEC_SUPPORT_FALLBACK_OBSOLETE
      = 5,

  // End sentinel.
  LIBRARY_LOAD_FROM_APK_STATUS_CODES_MAX = 6,
};

}  // namespace

}  // namespace android
}  // namespace base

#endif  // BASE_ANDROID_LIBRARY_LOADER_LIBRARY_LOAD_FROM_APK_STATUS_CODES_H_
