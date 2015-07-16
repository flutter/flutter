// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/android/jni_registrar.h"

#include "base/logging.h"
#include "base/android/jni_android.h"
#include "base/trace_event/trace_event.h"

namespace base {
namespace android {

bool RegisterNativeMethods(JNIEnv* env,
                           const RegistrationMethod* method,
                           size_t count) {
  TRACE_EVENT0("startup", "base_android::RegisterNativeMethods")
  const RegistrationMethod* end = method + count;
  while (method != end) {
    if (!method->func(env)) {
      DLOG(ERROR) << method->name << " failed registration!";
      return false;
    }
    method++;
  }
  return true;
}

}  // namespace android
}  // namespace base
