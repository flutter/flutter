// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_FLUTTER_MAIN_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_FLUTTER_MAIN_H_

#include <jni.h>

#include "flutter/common/settings.h"
#include "flutter/fml/macros.h"
#include "flutter/shell/platform/android/android_rendering_selector.h"
#include "flutter/shell/platform/android/android_vm_init.h"

namespace flutter {

class FlutterMain {
 public:
  ~FlutterMain();

  static bool Register(JNIEnv* env);

  static FlutterMain& Get();

  const flutter::Settings& GetSettings() const;
  flutter::AndroidRenderingAPI GetAndroidRenderingAPI() const;
  const android::AndroidVMArgs& GetVMArgs() const;
  std::shared_ptr<android::AndroidVMInit> GetVMInit() const;

  static AndroidRenderingAPI SelectedRenderingAPI(
      const flutter::Settings& settings,
      int api_level);

 private:
  const flutter::Settings settings_;
  const flutter::AndroidRenderingAPI android_rendering_api_;
  const android::AndroidVMArgs vm_args_;
  std::shared_ptr<android::AndroidVMInit> vm_init_;

  explicit FlutterMain(const flutter::Settings& settings,
                       flutter::AndroidRenderingAPI android_rendering_api,
                       const android::AndroidVMArgs& vm_args,
                       std::shared_ptr<android::AndroidVMInit> vm_init);

  static void Init(JNIEnv* env,
                   jclass clazz,
                   jobject context,
                   jobjectArray jargs,
                   jstring kernelPath,
                   jstring appStoragePath,
                   jstring engineCachesPath,
                   jlong initTimeMillis,
                   jint api_level);

  FML_DISALLOW_COPY_AND_ASSIGN(FlutterMain);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_FLUTTER_MAIN_H_
