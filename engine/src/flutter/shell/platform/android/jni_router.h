// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_JNI_ROUTER_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_JNI_ROUTER_H_

#include <jni.h>
#include <vector>

#include "flutter/fml/macros.h"

namespace flutter {

class JniRouter {
 public:
  static bool RegisterJniMethods(JNIEnv* env);
  static const std::vector<JNINativeMethod>& GetFlutterJniMethods();
  static const JNINativeMethod* GetNativeMethods(size_t* count_out);

 private:
  FML_DISALLOW_IMPLICIT_CONSTRUCTORS(JniRouter);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_JNI_ROUTER_H_
