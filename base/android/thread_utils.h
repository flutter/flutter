// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_ANDROID_THREAD_UTILS_H_
#define BASE_ANDROID_THREAD_UTILS_H_

#include "base/android/jni_android.h"

namespace base {

bool RegisterThreadUtils(JNIEnv* env);

}  // namespace base

#endif  // BASE_ANDROID_THREAD_UTILS_H_
