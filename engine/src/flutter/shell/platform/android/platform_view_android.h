// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_PLATFORM_VIEW_ANDROID_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_PLATFORM_VIEW_ANDROID_H_

#include <jni.h>

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/android/jni/platform_view_android_jni.h"
#include "flutter/shell/platform/embedder/embedder.h"

namespace flutter {

class PlatformViewAndroid final {
 public:
  static bool Register(JNIEnv* env);

  static FlutterNativeWindowCompositor MakeNativeWindowCompositor(
      PlatformViewAndroidJNI* jni_facade);

 private:
  FML_DISALLOW_IMPLICIT_CONSTRUCTORS(PlatformViewAndroid);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_PLATFORM_VIEW_ANDROID_H_
