// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/jni/platform_view_android_jni.h"

#if FML_OS_ANDROID
#include "flutter/fml/platform/android/jni_util.h"
#endif

namespace flutter {

#if FML_OS_ANDROID
HybridJavaGlobalRef::HybridJavaGlobalRef(JNIEnv* env,
                                         jobject local_or_global_obj) {
  if (local_or_global_obj == nullptr) {
    return;
  }
  if (env == nullptr) {
    env = fml::jni::AttachCurrentThread();
  }
  if (env != nullptr) {
    global_ref_ = env->NewGlobalRef(local_or_global_obj);
    if (!fml::jni::CheckException(env)) {
      global_ref_ = nullptr;
    }
  }
}
#endif

void HybridJavaGlobalRef::Reset() noexcept {
#if FML_OS_ANDROID
  if (global_ref_ != nullptr) {
    JNIEnv* env = fml::jni::AttachCurrentThread();
    if (env != nullptr) {
      env->DeleteGlobalRef(global_ref_);
    }
    global_ref_ = nullptr;
  }
#endif
  token_ = 0;
}

PlatformViewAndroidJNI::~PlatformViewAndroidJNI() = default;

}  // namespace flutter
