// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_ANDROID_BASE_JNI_ONLOAD_H_
#define BASE_ANDROID_BASE_JNI_ONLOAD_H_

#include <jni.h>
#include <vector>

#include "base/base_export.h"
#include "base/callback.h"

namespace base {
namespace android {

// Returns whether JNI registration succeeded. Caller shall put the
// RegisterCallback into |callbacks| in reverse order.
typedef base::Callback<bool(JNIEnv*)> RegisterCallback;
BASE_EXPORT bool OnJNIOnLoadRegisterJNI(
    JavaVM* vm,
    std::vector<RegisterCallback> callbacks);

// Returns whether initialization succeeded. Caller shall put the
// InitCallback into |callbacks| in reverse order.
typedef base::Callback<bool(void)> InitCallback;
BASE_EXPORT bool OnJNIOnLoadInit(std::vector<InitCallback> callbacks);

}  // namespace android
}  // namespace base

#endif  // BASE_ANDROID_BASE_JNI_ONLOAD_H_
