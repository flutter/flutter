// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_ANDROID_BUILD_INFO_H_
#define BASE_ANDROID_BUILD_INFO_H_

#include <jni.h>

#include <string>

#include "base/base_export.h"
#include "base/memory/singleton.h"

namespace base {
namespace android {

// This enumeration maps to the values returned by BuildInfo::sdk_int(),
// indicating the Android release associated with a given SDK version.
enum SdkVersion {
  SDK_VERSION_JELLY_BEAN = 16,
  SDK_VERSION_JELLY_BEAN_MR1 = 17,
  SDK_VERSION_JELLY_BEAN_MR2 = 18,
  SDK_VERSION_KITKAT = 19,
  SDK_VERSION_KITKAT_WEAR = 20,
  SDK_VERSION_LOLLIPOP = 21,
  SDK_VERSION_LOLLIPOP_MR1 = 22
};

// BuildInfo is a singleton class that stores android build and device
// information. It will be called from Android specific code and gets used
// primarily in crash reporting.

// It is also used to store the last java exception seen during JNI.
// TODO(nileshagrawal): Find a better place to store this info.
class BASE_EXPORT BuildInfo {
 public:

  ~BuildInfo() {}

  // Static factory method for getting the singleton BuildInfo instance.
  // Note that ownership is not conferred on the caller and the BuildInfo in
  // question isn't actually freed until shutdown. This is ok because there
  // should only be one instance of BuildInfo ever created.
  static BuildInfo* GetInstance();

  // Const char* is used instead of std::strings because these values must be
  // available even if the process is in a crash state. Sadly
  // std::string.c_str() doesn't guarantee that memory won't be allocated when
  // it is called.
  const char* device() const {
    return device_;
  }

  const char* manufacturer() const {
    return manufacturer_;
  }

  const char* model() const {
    return model_;
  }

  const char* brand() const {
    return brand_;
  }

  const char* android_build_id() const {
    return android_build_id_;
  }

  const char* android_build_fp() const {
    return android_build_fp_;
  }

  const char* package_version_code() const {
    return package_version_code_;
  }

  const char* package_version_name() const {
    return package_version_name_;
  }

  const char* package_label() const {
    return package_label_;
  }

  const char* package_name() const {
    return package_name_;
  }

  const char* build_type() const {
    return build_type_;
  }

  int sdk_int() const {
    return sdk_int_;
  }

  int has_language_apk_splits() const {
    return has_language_apk_splits_;
  }

  const char* java_exception_info() const {
    return java_exception_info_;
  }

  void SetJavaExceptionInfo(const std::string& info);

  void ClearJavaExceptionInfo();

  static bool RegisterBindings(JNIEnv* env);

 private:
  friend struct BuildInfoSingletonTraits;

  explicit BuildInfo(JNIEnv* env);

  // Const char* is used instead of std::strings because these values must be
  // available even if the process is in a crash state. Sadly
  // std::string.c_str() doesn't guarantee that memory won't be allocated when
  // it is called.
  const char* const device_;
  const char* const manufacturer_;
  const char* const model_;
  const char* const brand_;
  const char* const android_build_id_;
  const char* const android_build_fp_;
  const char* const package_version_code_;
  const char* const package_version_name_;
  const char* const package_label_;
  const char* const package_name_;
  const char* const build_type_;
  const int sdk_int_;
  const bool has_language_apk_splits_;
  // This is set via set_java_exception_info, not at constructor time.
  const char* java_exception_info_;

  DISALLOW_COPY_AND_ASSIGN(BuildInfo);
};

}  // namespace android
}  // namespace base

#endif  // BASE_ANDROID_BUILD_INFO_H_
