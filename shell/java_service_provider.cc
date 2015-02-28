// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/java_service_provider.h"

#include "base/android/jni_android.h"
#include "jni/JavaServiceProvider_jni.h"
#include "mojo/public/cpp/bindings/interface_request.h"

namespace sky {
namespace shell {

bool RegisterJavaServiceProvider(JNIEnv* env) {
  return RegisterNativesImpl(env);
}

void CreateJavaServiceProvider(
    mojo::InterfaceRequest<mojo::ServiceProvider> request) {
  Java_JavaServiceProvider_create(
      base::android::AttachCurrentThread(),
      base::android::GetApplicationContext(),
      request.PassMessagePipe().release().value());
}

}  // namespace shell
}  // namespace sky
