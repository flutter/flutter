// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "url/android/url_jni_registrar.h"

#ifdef USE_ICU_ALTERNATIVES_ON_ANDROID
#include "url/url_canon_icu_alternatives_android.h"
#endif

namespace url {
namespace android {

bool RegisterJni(JNIEnv* env) {
#ifdef USE_ICU_ALTERNATIVES_ON_ANDROID
  return RegisterIcuAlternativesJni(env);
#endif

  // Do nothing if USE_ICU_ALTERNATIVES_ON_ANDROID is not defined.
  return true;
}

}  // namespace android
}  // namespace url
