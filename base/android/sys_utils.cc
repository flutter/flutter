// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/android/sys_utils.h"

#include "base/android/build_info.h"
#include "base/sys_info.h"
#include "jni/SysUtils_jni.h"

namespace base {
namespace android {

bool SysUtils::Register(JNIEnv* env) {
  return RegisterNativesImpl(env);
}

bool SysUtils::IsLowEndDeviceFromJni() {
  JNIEnv* env = AttachCurrentThread();
  return Java_SysUtils_isLowEndDevice(env);
}

}  // namespace android

}  // namespace base