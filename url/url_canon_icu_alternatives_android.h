// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef URL_URL_CANON_ICU_ALTERNATIVES_ANDROID_H_
#define URL_URL_CANON_ICU_ALTERNATIVES_ANDROID_H_

#include <jni.h>

namespace url {

// Explicitly register static JNI functions needed when not using ICU.
bool RegisterIcuAlternativesJni(JNIEnv* env);

}  // namespace url

#endif  // URL_URL_CANON_ICU_ALTERNATIVES_ANDROID_H_

