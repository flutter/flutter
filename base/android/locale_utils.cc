// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/android/locale_utils.h"

#include "base/android/jni_android.h"
#include "base/android/jni_string.h"
#include "jni/LocaleUtils_jni.h"

namespace base {
namespace android {

std::string GetDefaultCountryCode() {
  JNIEnv* env = base::android::AttachCurrentThread();
  return ConvertJavaStringToUTF8(Java_LocaleUtils_getDefaultCountryCode(env));
}

std::string GetDefaultLocale() {
  JNIEnv* env = base::android::AttachCurrentThread();
  ScopedJavaLocalRef<jstring> locale = Java_LocaleUtils_getDefaultLocale(
      env);
  return ConvertJavaStringToUTF8(locale);
}

bool RegisterLocaleUtils(JNIEnv* env) {
  return RegisterNativesImpl(env);
}

}  // namespace android
}  // namespace base
