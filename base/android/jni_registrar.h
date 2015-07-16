// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_ANDROID_JNI_REGISTRAR_H_
#define BASE_ANDROID_JNI_REGISTRAR_H_

#include <jni.h>
#include "base/base_export.h"
#include "base/basictypes.h"

namespace base {
namespace android {

struct RegistrationMethod;

// Registers the JNI bindings for the specified |method| definition containing
// |count| elements.  Returns whether the registration of the given methods
// succeeded.
BASE_EXPORT bool RegisterNativeMethods(JNIEnv* env,
                                       const RegistrationMethod* method,
                                       size_t count);

}  // namespace android
}  // namespace base

#endif  // BASE_ANDROID_JNI_REGISTRAR_H_
