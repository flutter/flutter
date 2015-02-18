// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/platform_view.h"

#include <android/input.h>
#include <android/native_window_jni.h>

#include "base/android/jni_android.h"
#include "base/bind.h"
#include "base/location.h"
#include "jni/PlatformView_jni.h"
#include "sky/shell/shell.h"

namespace sky {
namespace shell {

static jlong Attach(JNIEnv* env, jclass clazz) {
  return reinterpret_cast<jlong>(Shell::Shared().view());
}

// static
bool PlatformView::Register(JNIEnv* env) {
  return RegisterNativesImpl(env);
}

PlatformView::PlatformView(const Config& config)
    : config_(config), window_(nullptr) {
}

PlatformView::~PlatformView() {
  if (window_)
    ReleaseWindow();
}

void PlatformView::Detach(JNIEnv* env, jobject obj) {
  DCHECK(!window_);
}

void PlatformView::SurfaceCreated(JNIEnv* env, jobject obj, jobject jsurface) {
  base::android::ScopedJavaLocalRef<jobject> protector(env, jsurface);
  // Note: This ensures that any local references used by
  // ANativeWindow_fromSurface are released immediately. This is needed as a
  // workaround for https://code.google.com/p/android/issues/detail?id=68174
  {
    base::android::ScopedJavaLocalFrame scoped_local_reference_frame(env);
    window_ = ANativeWindow_fromSurface(env, jsurface);
  }
  config_.gpu_task_runner->PostTask(
      FROM_HERE, base::Bind(&GPUDelegate::OnAcceleratedWidgetAvailable,
                            config_.gpu_delegate, window_));
}

void PlatformView::SurfaceDestroyed(JNIEnv* env, jobject obj) {
  DCHECK(window_);
  config_.gpu_task_runner->PostTask(
      FROM_HERE,
      base::Bind(&GPUDelegate::OnOutputSurfaceDestroyed, config_.gpu_delegate));
  ReleaseWindow();
}

void PlatformView::SurfaceSetSize(JNIEnv* env,
                                  jobject obj,
                                  jint width,
                                  jint height,
                                  jfloat density) {
  config_.ui_task_runner->PostTask(
      FROM_HERE,
      base::Bind(&UIDelegate::OnViewportMetricsChanged, config_.ui_delegate,
                 gfx::Size(width, height), density));
}

void PlatformView::ReleaseWindow() {
  ANativeWindow_release(window_);
  window_ = nullptr;
}

}  // namespace shell
}  // namespace sky
