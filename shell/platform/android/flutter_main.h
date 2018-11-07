// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_PLATFORM_ANDROID_FLUTTER_MAIN_H_
#define SHELL_PLATFORM_ANDROID_FLUTTER_MAIN_H_

#include <jni.h>

#include "flutter/common/settings.h"
#include "flutter/fml/macros.h"

namespace shell {

class FlutterMain {
 public:
  ~FlutterMain();

  static bool Register(JNIEnv* env);

  static FlutterMain& Get();

  const blink::Settings& GetSettings() const;

 private:
  const blink::Settings settings_;

  FlutterMain(blink::Settings settings);

  static void Init(JNIEnv* env,
                   jclass clazz,
                   jobject context,
                   jobjectArray jargs,
                   jstring bundlePath,
                   jstring appRootPath,
                   jstring engineCachesPath);

  FML_DISALLOW_COPY_AND_ASSIGN(FlutterMain);
};

}  // namespace shell

#endif  // SHELL_PLATFORM_ANDROID_FLUTTER_MAIN_H_
