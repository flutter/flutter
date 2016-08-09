// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/android/base_jni_onload.h"
#include "base/android/base_jni_registrar.h"
#include "base/android/jni_android.h"
#include "base/android/jni_registrar.h"
#include "base/bind.h"
#include "mojo/android/javatests/mojo_test_case.h"
#include "mojo/android/javatests/validation_test_util.h"
#include "mojo/android/system/core_impl.h"
#include "mojo/edk/embedder/embedder.h"
#include "mojo/edk/embedder/simple_platform_support.h"

namespace {

base::android::RegistrationMethod kMojoRegisteredMethods[] = {
  { "CoreImpl", mojo::android::RegisterCoreImpl },
  { "MojoTestCase", mojo::android::RegisterMojoTestCase },
  { "ValidationTestUtil", mojo::android::RegisterValidationTestUtil },
};

bool RegisterJNI(JNIEnv* env) {
  return base::android::RegisterJni(env) &&
      RegisterNativeMethods(env, kMojoRegisteredMethods,
                            arraysize(kMojoRegisteredMethods));
}

bool Init() {
  mojo::embedder::Init(mojo::embedder::CreateSimplePlatformSupport());
  return true;
}

}  // namespace

JNI_EXPORT jint JNI_OnLoad(JavaVM* vm, void* reserved) {
  std::vector<base::android::RegisterCallback> register_callbacks;
  register_callbacks.push_back(base::Bind(&RegisterJNI));
  std::vector<base::android::InitCallback> init_callbacks;
  init_callbacks.push_back(base::Bind(&Init));
  if (!base::android::OnJNIOnLoadRegisterJNI(vm, register_callbacks) ||
      !base::android::OnJNIOnLoadInit(init_callbacks))
    return -1;

  return JNI_VERSION_1_4;
}
