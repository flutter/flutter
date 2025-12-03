// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/embedder_surface_android.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/shell/gpu/gpu_surface_gl_delegate.h"

namespace flutter {

EmbedderSurfaceAndroid::EmbedderSurfaceAndroid(
    const std::shared_ptr<flutter::AndroidContext>& android_context,
    std::unique_ptr<AndroidSurface> android_surface)
    : android_context_(android_context),
      android_surface_(std::move(android_surface)) {}

EmbedderSurfaceAndroid::~EmbedderSurfaceAndroid() = default;

bool EmbedderSurfaceAndroid::IsValid() const {
  return android_context_ && android_context_->IsValid() && android_surface_ &&
         android_surface_->IsValid();
}

std::unique_ptr<Surface> EmbedderSurfaceAndroid::CreateGPUSurface() {
  if (!IsValid()) {
    return nullptr;
  }
  return android_surface_->CreateGPUSurface(
      android_context_->GetMainSkiaContext().get());
}

sk_sp<GrDirectContext> EmbedderSurfaceAndroid::CreateResourceContext() const {
  if (!IsValid()) {
    return nullptr;
  }
#if !SLIMPELLER
  sk_sp<GrDirectContext> resource_context;
  if (android_surface_->ResourceContextMakeCurrent()) {
    resource_context = ShellIOManager::CreateCompatibleResourceLoadingContext(
        GrBackendApi::kOpenGL,
        GPUSurfaceGLDelegate::GetDefaultPlatformGLInterface());
  } else {
    FML_DLOG(ERROR) << "Could not make the resource context current.";
  }
  return resource_context;
#else
  android_surface_->ResourceContextMakeCurrent();
  return nullptr;
#endif  //  !SLIMPELLER
}

std::shared_ptr<impeller::Context>
EmbedderSurfaceAndroid::CreateImpellerContext() const {
  if (android_surface_) {
    return android_surface_->GetImpellerContext();
  }
  return android_context_->GetImpellerContext();
}

void EmbedderSurfaceAndroid::NotifyCreated(
    fml::RefPtr<AndroidNativeWindow> native_window,
    const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade) {
  if (android_surface_) {
    android_surface_->SetNativeWindow(native_window, jni_facade);
  }
}

void EmbedderSurfaceAndroid::NotifySurfaceWindowChanged(
    fml::RefPtr<AndroidNativeWindow> native_window,
    const std::shared_p<PlatformViewAndroidJNI>& jni_facade) {
  if (android_surface_) {
    android_surface_->TeardownOnScreenContext();
    android_surface_->SetNativeWindow(native_window, jni_facade);
  }
}

void EmbedderSurfaceAndroid::NotifyChanged(const DlISize& size) {
  if (android_surface_) {
    android_surface_->OnScreenSurfaceResize(size);
  }
}

void EmbedderSurfaceAndroid::NotifyDestroyed() {
  if (android_surface_) {
    android_surface_->TeardownOnScreenContext();
  }
}

void EmbedderSurfaceAndroid::TeardownOnScreenContext() {
  if (android_surface_) {
    android_surface_->TeardownOnScreenContext();
  }
}

AndroidSurface* EmbedderSurfaceAndroid::GetAndroidSurface() const {
  return android_surface_.get();
}

}  // namespace flutter
