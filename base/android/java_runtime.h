// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_ANDROID_JAVA_RUNTIME_H_
#define BASE_ANDROID_JAVA_RUNTIME_H_

#include "base/android/scoped_java_ref.h"
#include "base/base_export.h"

namespace base {
namespace android {

// Wrapper class for using the java.lang.Runtime object from jni.
class BASE_EXPORT JavaRuntime {
 public:
  // Registers the jni class (once per process).
  static bool Register(JNIEnv* env);

  // Fills the total memory used and memory allocated for objects by the java
  // heap in the current process. Returns true on success.
  static void GetMemoryUsage(long* total_memory, long* free_memory);
};

}  // namespace android
}  // namespace base

#endif  // BASE_ANDROID_JAVA_RUNTIME_H_
