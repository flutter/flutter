// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/java_service_provider.h"

#include "jni/JavaServiceProvider_jni.h"

namespace sky {
namespace shell {

bool RegisterJavaServiceProvider(JNIEnv* env) {
  return RegisterNativesImpl(env);
}

mojo::ScopedMessagePipeHandle CreateJavaServiceProvider() {
  JNIEnv* env = base::android::AttachCurrentThread();
  return mojo::ScopedMessagePipeHandle(
      mojo::MessagePipeHandle(Java_JavaServiceProvider_create(env)));
}

}  // namespace shell
}  // namespace sky
