// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/android/platform_view_android.h"

#include <android/input.h>
#include <android/native_window_jni.h>

#include "base/android/jni_android.h"
#include "base/bind.h"
#include "base/location.h"
#include "jni/PlatformViewAndroid_jni.h"
#include "sky/shell/shell.h"

namespace sky {
namespace shell {

static jlong Attach(JNIEnv* env, jclass clazz, jint viewportObserverHandle) {
  PlatformView* view = Shell::Shared().view();
  view->ConnectToViewportObserver(
      mojo::MakeRequest<ViewportObserver>(mojo::ScopedMessagePipeHandle(
          mojo::MessagePipeHandle(viewportObserverHandle))));
  return reinterpret_cast<jlong>(view);
}

// static
bool PlatformViewAndroid::Register(JNIEnv* env) {
  return RegisterNativesImpl(env);
}

PlatformViewAndroid::~PlatformViewAndroid() {
  if (window_)
    ReleaseWindow();
}

void PlatformViewAndroid::Detach(JNIEnv* env, jobject obj) {
  DCHECK(!window_);
}

void PlatformViewAndroid::SurfaceCreated(JNIEnv* env, jobject obj, jobject jsurface) {
  base::android::ScopedJavaLocalRef<jobject> protector(env, jsurface);
  // Note: This ensures that any local references used by
  // ANativeWindow_fromSurface are released immediately. This is needed as a
  // workaround for https://code.google.com/p/android/issues/detail?id=68174
  {
    base::android::ScopedJavaLocalFrame scoped_local_reference_frame(env);
    window_ = ANativeWindow_fromSurface(env, jsurface);
  }
  SurfaceWasCreated();
}

void PlatformViewAndroid::SurfaceDestroyed(JNIEnv* env, jobject obj) {
  DCHECK(window_);
  SurfaceWasDestroyed();
  ReleaseWindow();
}

void PlatformViewAndroid::ReleaseWindow() {
  ANativeWindow_release(window_);
  window_ = nullptr;
}

}  // namespace shell
}  // namespace sky
