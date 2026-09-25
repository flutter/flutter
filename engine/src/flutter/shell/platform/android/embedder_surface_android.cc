// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/embedder_surface_android.h"

#include <utility>

#include "flutter/fml/logging.h"
#include "flutter/shell/common/shell_io_manager.h"
#include "flutter/shell/gpu/gpu_surface_gl_delegate.h"
#include "flutter/shell/platform/android/android_context_dynamic_impeller.h"
#include "flutter/shell/platform/android/android_context_gl_impeller.h"
#include "flutter/shell/platform/android/android_context_vk_impeller.h"
#include "flutter/shell/platform/android/android_surface_dynamic_impeller.h"
#include "flutter/shell/platform/android/android_surface_gl_impeller.h"
#include "flutter/shell/platform/android/external_view_embedder/external_view_embedder_wrapper.h"
#include "flutter/shell/platform/android/surface/snapshot_surface_producer.h"

#if !SLIMPELLER
#include "flutter/shell/platform/android/android_context_gl_skia.h"
#include "flutter/shell/platform/android/android_surface_gl_skia.h"
#include "flutter/shell/platform/android/android_surface_software.h"
#endif  // !SLIMPELLER

#if IMPELLER_ENABLE_VULKAN
#include "flutter/shell/platform/android/android_surface_vk_impeller.h"
#endif  // IMPELLER_ENABLE_VULKAN

namespace flutter {

AndroidSurfaceFactoryImpl::AndroidSurfaceFactoryImpl(
    std::shared_ptr<AndroidContext> context,
    bool enable_impeller,
    bool lazy_shader_mode)
    : android_context_(std::move(context)),
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
    std::shared_ptr<flutter::AndroidContext> android_context,
    bool enable_impeller,
    bool lazy_shader_mode,
    std::shared_ptr<PlatformViewAndroidJNI> jni_facade,
    const flutter::TaskRunners& task_runners,
    bool android_meets_hcpp_criteria)
    : android_context_(std::move(android_context)),
      jni_facade_(std::move(jni_facade)),
      task_runners_(task_runners),
      android_meets_hcpp_criteria_(android_meets_hcpp_criteria) {
  if (android_context_ && android_context_->IsValid()) {
    surface_factory_ = std::make_shared<AndroidSurfaceFactoryImpl>(
        android_context_, enable_impeller, lazy_shader_mode);
    android_surface_ = surface_factory_->CreateSurface();
  }
}

EmbedderSurfaceAndroid::EmbedderSurfaceAndroid(
    const std::shared_ptr<flutter::AndroidContext>& android_context,
    PlatformView::Delegate& delegate,
    const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade,
    const flutter::TaskRunners& task_runners,
    bool android_meets_hcpp_criteria)
    : EmbedderSurfaceAndroid(
          android_context,
          delegate.OnPlatformViewGetSettings().enable_impeller,
          delegate.OnPlatformViewGetSettings().impeller_enable_lazy_shader_mode,
          jni_facade,
          task_runners,
          android_meets_hcpp_criteria) {}

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
    // TODO(chinmaygarde): Currently, this code depends on the fact that only
    // the OpenGL surface will be able to make a resource context current. If
    // this changes, this assumption breaks. Handle the same.
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
#endif  // !SLIMPELLER
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
  if (android_context_) {
    return android_context_->GetImpellerContext();
  }
  return nullptr;
}

void EmbedderSurfaceAndroid::SetupImpellerContext() {
  if (android_context_) {
    android_context_->SetupImpellerContext();
  }
  if (android_surface_) {
    android_surface_->SetupImpellerSurface();
  }
}

std::shared_ptr<ExternalViewEmbedder>
EmbedderSurfaceAndroid::CreateExternalViewEmbedder() {
  if (!IsValid()) {
    return nullptr;
  }
  return std::make_shared<AndroidExternalViewEmbedderWrapper>(
      android_meets_hcpp_criteria_, *android_context_, jni_facade_,
      surface_factory_, task_runners_);
}

std::unique_ptr<SnapshotSurfaceProducer>
EmbedderSurfaceAndroid::CreateSnapshotSurfaceProducer() {
  if (!android_surface_) {
    return nullptr;
  }
  return std::make_unique<AndroidSnapshotSurfaceProducer>(*android_surface_);
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

void EmbedderSurfaceAndroid::TeardownOnScreenContext() {
  if (android_surface_) {
    android_surface_->TeardownOnScreenContext();
  }
}

AndroidSurface* EmbedderSurfaceAndroid::GetAndroidSurface() const {
  return android_surface_.get();
}

}  // namespace flutter
