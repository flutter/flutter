// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/platform/android/platform_view_android.h"

#include <android/input.h>
#include <android/native_window_jni.h>

#include "base/android/jni_android.h"
#include "base/bind.h"
#include "base/location.h"
#include "jni/FlutterView_jni.h"
#include "sky/engine/core/script/dart_service_isolate.h"
#include "sky/shell/gpu/direct/surface_notifications_direct.h"
#include "sky/shell/shell.h"
#include "sky/shell/shell_view.h"

namespace sky {
namespace shell {

static jlong Attach(JNIEnv* env, jclass clazz, jint skyEngineHandle) {
  ShellView* shell_view = new ShellView(Shell::Shared());
  auto view = static_cast<PlatformViewAndroid*>(shell_view->view());
  view->SetShellView(std::unique_ptr<ShellView>(shell_view));
  view->ConnectToEngine(
      mojo::InterfaceRequest<SkyEngine>(mojo::ScopedMessagePipeHandle(
          mojo::MessagePipeHandle(skyEngineHandle))));
  return reinterpret_cast<jlong>(shell_view->view());
}

jint GetObservatoryPort(JNIEnv* env, jclass clazz) {
  return blink::DartServiceIsolate::GetObservatoryPort();
}

// static
bool PlatformViewAndroid::Register(JNIEnv* env) {
  return RegisterNativesImpl(env);
}

PlatformView* PlatformView::Create(const Config& config) {
  return new PlatformViewAndroid(config);
}

PlatformViewAndroid::PlatformViewAndroid(const Config& config)
  : PlatformView(config), window_(nullptr) {
}

PlatformViewAndroid::~PlatformViewAndroid() {
  if (window_)
    ReleaseWindow();
}

void PlatformViewAndroid::Detach(JNIEnv* env, jobject obj) {
  shell_view_.reset();
  // Note: |this| has been destroyed at this point.
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
  SurfaceNotificationsDirect::NotifyCreated(config_, window_);
}

void PlatformViewAndroid::SurfaceDestroyed(JNIEnv* env, jobject obj) {
  DCHECK(window_);
  SurfaceNotificationsDirect::NotifyDestroyed(config_);
  ReleaseWindow();
}

void PlatformViewAndroid::SetShellView(std::unique_ptr<ShellView> shell_view) {
  DCHECK(!shell_view_);
  shell_view_ = std::move(shell_view);
}

void PlatformViewAndroid::ReleaseWindow() {
  ANativeWindow_release(window_);
  window_ = nullptr;
}

}  // namespace shell
}  // namespace sky
