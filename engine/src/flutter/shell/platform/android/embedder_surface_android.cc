// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_context_dynamic_impeller.h"
#include "flutter/shell/platform/android/android_surface_dynamic_impeller.h"

#if !SLIMPELLER
#include "flutter/shell/platform/android/android_context_gl_skia.h"
#include "flutter/shell/platform/android/android_surface_gl_skia.h"
#include "flutter/shell/platform/android/android_surface_software.h"
#include "flutter/shell/platform/android/image_external_texture_gl_skia.h"
#include "flutter/shell/platform/android/surface_texture_external_texture_gl_skia.h"
#endif  // !SLIMPELLER
        //
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/shell/common/shell_io_manager.h"
#include "flutter/shell/gpu/gpu_surface_gl_delegate.h"
#include "flutter/shell/platform/android/embedder_surface_android.h"

namespace flutter {

AndroidSurfaceFactoryImpl::AndroidSurfaceFactoryImpl(
    const std::shared_ptr<AndroidContext>& context,
    bool enable_impeller,
    bool lazy_shader_mode)
    : android_context_(context),
      enable_impeller_(enable_impeller),
      lazy_shader_mode_(lazy_shader_mode) {}

AndroidSurfaceFactoryImpl::~AndroidSurfaceFactoryImpl() = default;

std::unique_ptr<AndroidSurface> AndroidSurfaceFactoryImpl::CreateSurface() {
  if (android_context_->IsDynamicSelection()) {
    auto cast_ptr = std::static_pointer_cast<AndroidContextDynamicImpeller>(
        android_context_);
    return std::make_unique<AndroidSurfaceDynamicImpeller>(cast_ptr);
  }
  switch (android_context_->RenderingApi()) {
#if !SLIMPELLER
    case AndroidRenderingAPI::kSoftware:
      return std::make_unique<AndroidSurfaceSoftware>();
    case AndroidRenderingAPI::kSkiaOpenGLES:
      return std::make_unique<AndroidSurfaceGLSkia>(
          std::static_pointer_cast<AndroidContextGLSkia>(android_context_));
#endif  // !SLIMPELLER
    case AndroidRenderingAPI::kImpellerOpenGLES:
      return std::make_unique<AndroidSurfaceGLImpeller>(
          std::static_pointer_cast<AndroidContextGLImpeller>(android_context_));
    case AndroidRenderingAPI::kImpellerVulkan:
      return std::make_unique<AndroidSurfaceVKImpeller>(
          std::static_pointer_cast<AndroidContextVKImpeller>(android_context_));
    case AndroidRenderingAPI::kImpellerAutoselect: {
      auto cast_ptr = std::static_pointer_cast<AndroidContextDynamicImpeller>(
          android_context_);
      return std::make_unique<AndroidSurfaceDynamicImpeller>(cast_ptr);
    }
  }
  FML_UNREACHABLE();
}

EmbedderSurfaceAndroid::EmbedderSurfaceAndroid(
    const std::shared_ptr<flutter::AndroidContext>& android_context,
    PlatformView::Delegate& delegate)
    : android_context_(android_context) {
  surface_factory_ = std::make_shared<AndroidSurfaceFactoryImpl>(
      android_context_,                                                      //
      delegate.OnPlatformViewGetSettings().enable_impeller,                  //
      delegate.OnPlatformViewGetSettings().impeller_enable_lazy_shader_mode  //
  );
  android_surface_ = surface_factory_->CreateSurface();
}

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

void EmbedderSurfaceAndroid::ReleaseResourceContext() const {
  if (android_surface_) {
    android_surface_->ResourceContextClearCurrent();
  }
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
    android_surface_->SetNativeWindow(std::move(native_window), jni_facade);
  }
}

void EmbedderSurfaceAndroid::NotifySurfaceWindowChanged(
    fml::RefPtr<AndroidNativeWindow> native_window,
    const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade) {
  if (android_surface_) {
    android_surface_->TeardownOnScreenContext();
    android_surface_->SetNativeWindow(std::move(native_window), jni_facade);
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

void EmbedderSurfaceAndroid::SetupImpellerContext() {
  android_context_->SetupImpellerContext();
  android_surface_->SetupImpellerSurface();
}

}  // namespace flutter
