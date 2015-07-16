// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/android/base_jni_onload.h"

#include "base/android/jni_android.h"
#include "base/android/jni_utils.h"
#include "base/android/library_loader/library_loader_hooks.h"
#include "base/bind.h"

namespace base {
namespace android {

namespace {

bool RegisterJNI(JNIEnv* env) {
  return RegisterLibraryLoaderEntryHook(env);
}

bool Init() {
  InitAtExitManager();
  JNIEnv* env = base::android::AttachCurrentThread();
  base::android::InitReplacementClassLoader(env,
                                            base::android::GetClassLoader(env));
  return true;
}

}  // namespace


bool OnJNIOnLoadRegisterJNI(JavaVM* vm,
                            std::vector<RegisterCallback> callbacks) {
  base::android::InitVM(vm);
  JNIEnv* env = base::android::AttachCurrentThread();

  callbacks.push_back(base::Bind(&RegisterJNI));
  for (std::vector<RegisterCallback>::reverse_iterator i =
           callbacks.rbegin(); i != callbacks.rend(); ++i) {
    if (!i->Run(env))
      return false;
  }
  return true;
}

bool OnJNIOnLoadInit(std::vector<InitCallback> callbacks) {
  callbacks.push_back(base::Bind(&Init));
  for (std::vector<InitCallback>::reverse_iterator i =
           callbacks.rbegin(); i != callbacks.rend(); ++i) {
    if (!i->Run())
      return false;
  }
  return true;
}

}  // namespace android
}  // namespace base
