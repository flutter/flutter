// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/platform_view_android.h"

#include <android/api-level.h>
#include <sys/system_properties.h>
#include <memory>
#include <utility>

#include "common/settings.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/shell/platform/android/android_context_dynamic_impeller.h"
#include "flutter/shell/platform/android/android_context_gl_impeller.h"
#include "flutter/shell/platform/android/android_context_vk_impeller.h"
#include "flutter/shell/platform/android/android_rendering_selector.h"
#include "flutter/shell/platform/android/android_surface_dynamic_impeller.h"
#include "flutter/shell/platform/android/android_surface_gl_impeller.h"
#include "flutter/shell/platform/android/image_external_texture_gl_impeller.h"
#include "flutter/shell/platform/android/surface_texture_external_texture_gl_impeller.h"
#include "flutter/shell/platform/android/surface_texture_external_texture_vk_impeller.h"

#if !SLIMPELLER
#include "flutter/shell/platform/android/android_context_gl_skia.h"
#include "flutter/shell/platform/android/android_surface_gl_skia.h"
#include "flutter/shell/platform/android/android_surface_software.h"
#include "flutter/shell/platform/android/image_external_texture_gl_skia.h"
#include "flutter/shell/platform/android/surface_texture_external_texture_gl_skia.h"
#endif  // !SLIMPELLER

#include "fml/logging.h"
#if IMPELLER_ENABLE_VULKAN  // b/258506856 for why this is behind an if
#include "flutter/shell/platform/android/android_surface_vk_impeller.h"
#include "flutter/shell/platform/android/image_external_texture_vk_impeller.h"
#endif
#include "flutter/shell/platform/android/context/android_context.h"
#include "flutter/shell/platform/android/external_view_embedder/external_view_embedder_wrapper.h"
#include "flutter/shell/platform/android/jni/platform_view_android_jni.h"
#include "flutter/shell/platform/android/surface/android_surface.h"
#include "flutter/shell/platform/android/surface/snapshot_surface_producer.h"

namespace flutter {

namespace {

static constexpr int kMinAPILevelHCPP = 34;

AndroidContext::ContextSettings CreateContextSettings(
    const Settings& p_settings) {
  AndroidContext::ContextSettings settings;
  settings.enable_gpu_tracing = p_settings.enable_vulkan_gpu_tracing;
  settings.enable_validation = p_settings.enable_vulkan_validation;
  settings.enable_surface_control = p_settings.enable_surface_control;
  return settings;
}
}  // namespace

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

static std::shared_ptr<flutter::AndroidContext> CreateAndroidContext(
    const flutter::TaskRunners& task_runners,
    AndroidRenderingAPI android_rendering_api,
    bool enable_opengl_gpu_tracing,
    const AndroidContext::ContextSettings& settings,
    std::shared_ptr<fml::BasicTaskRunner> io_task_runner) {
  switch (android_rendering_api) {
#if !SLIMPELLER
    case AndroidRenderingAPI::kSoftware:
      return std::make_shared<AndroidContext>(AndroidRenderingAPI::kSoftware);
    case AndroidRenderingAPI::kSkiaOpenGLES:
      return std::make_unique<AndroidContextGLSkia>(
          fml::MakeRefCounted<AndroidEnvironmentGL>(),  //
          task_runners                                  //
      );
#endif  // !SLIMPELLER
    case AndroidRenderingAPI::kImpellerVulkan:
      return std::make_unique<AndroidContextVKImpeller>(settings);
    case AndroidRenderingAPI::kImpellerOpenGLES:
      return std::make_unique<AndroidContextGLImpeller>(
          std::make_unique<impeller::egl::Display>(), enable_opengl_gpu_tracing,
          std::move(io_task_runner));
    case AndroidRenderingAPI::kImpellerAutoselect:
      // Determine if we're using GL or Vulkan.
      return std::make_unique<AndroidContextDynamicImpeller>(
          settings, std::move(io_task_runner));
  }
  FML_UNREACHABLE();
}

PlatformViewAndroid::PlatformViewAndroid(
    PlatformView::Delegate& delegate,
    const flutter::TaskRunners& task_runners,
    const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade,
    AndroidRenderingAPI rendering_api,
    PlatformDispatchTable platform_dispatch_table)
    : PlatformViewAndroid(
          delegate,
          task_runners,
          jni_facade,
          CreateAndroidContext(
              task_runners,
              rendering_api,
              delegate.OnPlatformViewGetSettings().enable_opengl_gpu_tracing,
              CreateContextSettings(delegate.OnPlatformViewGetSettings()),
              delegate.OnPlatformViewGetShutdownSafeIOTaskRunner()),
          std::move(platform_dispatch_table)) {}

PlatformViewEmbedder::PlatformDispatchTable
PlatformViewAndroid::WithAndroidCallbacks(
    PlatformViewAndroid* self,
    PlatformViewEmbedder::PlatformDispatchTable platform_dispatch_table) {
  if (!platform_dispatch_table.create_rendering_surface_callback) {
    platform_dispatch_table.create_rendering_surface_callback = [self]() {
      return self->CreateAndroidRenderingSurface();
    };
  }
  if (!platform_dispatch_table.create_external_view_embedder_callback) {
    platform_dispatch_table.create_external_view_embedder_callback = [self]() {
      return self->CreateAndroidExternalViewEmbedder();
    };
  }
  if (!platform_dispatch_table.create_snapshot_surface_producer_callback) {
    platform_dispatch_table.create_snapshot_surface_producer_callback =
        [self]() { return self->CreateAndroidSnapshotSurfaceProducer(); };
  }
  if (!platform_dispatch_table.create_resource_context_callback &&
      !platform_dispatch_table.make_resource_current_callback) {
    platform_dispatch_table.make_resource_current_callback = [self]() {
      return self->MakeAndroidResourceContextCurrent();
    };
  }
  if (!platform_dispatch_table.release_resource_context_callback) {
    platform_dispatch_table.release_resource_context_callback = [self]() {
      self->ReleaseAndroidResourceContext();
    };
  }
  if (!platform_dispatch_table.get_impeller_context_callback) {
    platform_dispatch_table.get_impeller_context_callback = [self]() {
      return self->GetAndroidImpellerContext();
    };
  }
  if (!platform_dispatch_table.setup_impeller_context_callback) {
    platform_dispatch_table.setup_impeller_context_callback = [self]() {
      self->SetupAndroidImpellerContext();
    };
  }
  return platform_dispatch_table;
}

PlatformViewAndroid::PlatformViewAndroid(
    PlatformView::Delegate& delegate,
    const flutter::TaskRunners& task_runners,
    const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade,
    const std::shared_ptr<flutter::AndroidContext>& android_context,
    PlatformDispatchTable platform_dispatch_table)
    : PlatformViewEmbedder(
          delegate,
          task_runners,
          WithAndroidCallbacks(this, std::move(platform_dispatch_table))),
      jni_facade_(jni_facade),
      android_context_(android_context) {
  if (android_context_) {
    FML_CHECK(android_context_->IsValid())
        << "Could not create surface from invalid Android context.";
    surface_factory_ = std::make_shared<AndroidSurfaceFactoryImpl>(
        android_context_,                                      //
        delegate.OnPlatformViewGetSettings().enable_impeller,  //
        delegate.OnPlatformViewGetSettings()
            .impeller_enable_lazy_shader_mode  //
    );
    android_surface_ = surface_factory_->CreateSurface();
    android_meets_hcpp_criteria_ =
        delegate.OnPlatformViewGetSettings().enable_surface_control &&
        android_get_device_api_level() >= kMinAPILevelHCPP &&
        delegate.OnPlatformViewGetSettings().enable_impeller;
    FML_CHECK(android_surface_ && android_surface_->IsValid())
        << "Could not create an OpenGL, Vulkan or Software surface to set "
           "up "
           "rendering.";
  }
}

PlatformViewAndroid::~PlatformViewAndroid() = default;

bool PlatformViewAndroid::SetNativeWindow(
    fml::RefPtr<AndroidNativeWindow> native_window) {
  if (!android_surface_) {
    return false;
  }
  fml::AutoResetWaitableEvent latch;
  fml::TaskRunner::RunNowOrPostTask(
      task_runners_.GetRasterTaskRunner(),
      [&latch, surface = android_surface_.get(),
       native_window = std::move(native_window), jni_facade = jni_facade_]() {
        surface->SetNativeWindow(native_window, jni_facade);
        latch.Signal();
      });
  latch.Wait();
  return true;
}

void PlatformViewAndroid::SwapNativeWindow(
    fml::RefPtr<AndroidNativeWindow> native_window) {
  if (!android_surface_) {
    return;
  }
  fml::AutoResetWaitableEvent latch;
  fml::TaskRunner::RunNowOrPostTask(
      task_runners_.GetRasterTaskRunner(),
      [&latch, surface = android_surface_.get(),
       native_window = std::move(native_window), jni_facade = jni_facade_]() {
        surface->TeardownOnScreenContext();
        surface->SetNativeWindow(native_window, jni_facade);
        latch.Signal();
      });
  latch.Wait();
}

void PlatformViewAndroid::TeardownSurface() {
  if (!android_surface_) {
    return;
  }
  fml::AutoResetWaitableEvent latch;
  fml::TaskRunner::RunNowOrPostTask(
      task_runners_.GetRasterTaskRunner(),
      [&latch, surface = android_surface_.get()]() {
        surface->TeardownOnScreenContext();
        latch.Signal();
      });
  latch.Wait();
}

void PlatformViewAndroid::ResizeSurface(const DlISize& size) {
  if (!android_surface_) {
    return;
  }
  fml::AutoResetWaitableEvent latch;
  fml::TaskRunner::RunNowOrPostTask(
      task_runners_.GetRasterTaskRunner(),  //
      [&latch, surface = android_surface_.get(), size]() {
        surface->OnScreenSurfaceResize(size);
        latch.Signal();
      });
  latch.Wait();
}

std::unique_ptr<Texture> PlatformViewAndroid::CreateSurfaceTexture(
    int64_t texture_id,
    const fml::jni::ScopedJavaGlobalRef<jobject>& surface_texture) {
  switch (android_context_->RenderingApi()) {
    case AndroidRenderingAPI::kImpellerOpenGLES:
      // Impeller GLES.
      return std::make_unique<SurfaceTextureExternalTextureGLImpeller>(
          std::static_pointer_cast<impeller::ContextGLES>(
              android_context_->GetImpellerContext()),  //
          texture_id,                                   //
          surface_texture,                              //
          jni_facade_                                   //
      );
#if !SLIMPELLER
    case AndroidRenderingAPI::kSkiaOpenGLES:
      // Legacy GL.
      return std::make_unique<SurfaceTextureExternalTextureGLSkia>(
          texture_id,       //
          surface_texture,  //
          jni_facade_       //
      );
    case AndroidRenderingAPI::kSoftware:
      FML_LOG(INFO) << "Software rendering does not support external textures.";
      return nullptr;
#endif  // !SLIMPELLER
    case AndroidRenderingAPI::kImpellerVulkan:
      FML_LOG(IMPORTANT)
          << "Flutter recommends migrating plugins that create and "
             "register surface textures to the new surface producer "
             "API. See https://docs.flutter.dev/release/breaking-changes/"
             "android-surface-plugins";
      return std::make_unique<SurfaceTextureExternalTextureVKImpeller>(
          std::static_pointer_cast<impeller::ContextVK>(
              android_context_->GetImpellerContext()),  //
          texture_id,                                   //
          surface_texture,                              //
          jni_facade_                                   //
      );
    case AndroidRenderingAPI::kImpellerAutoselect:
    default:
      FML_CHECK(false);
      return nullptr;
  }
}

std::unique_ptr<Texture> PlatformViewAndroid::CreateImageTexture(
    int64_t texture_id,
    const fml::jni::ScopedJavaGlobalRef<jobject>& image_texture_entry,
    ImageExternalTexture::ImageLifecycle lifecycle) {
  switch (android_context_->RenderingApi()) {
#if !SLIMPELLER
    case AndroidRenderingAPI::kSkiaOpenGLES:
      // Legacy GL.
      return std::make_unique<ImageExternalTextureGLSkia>(
          std::static_pointer_cast<AndroidContextGLSkia>(android_context_),
          texture_id, image_texture_entry, jni_facade_, lifecycle);
    case AndroidRenderingAPI::kSoftware:
      FML_LOG(INFO) << "Software rendering does not support external textures.";
      return nullptr;
#endif  // !SLIMPELLER
    case AndroidRenderingAPI::kImpellerOpenGLES:
      // Impeller GLES.
      return std::make_unique<ImageExternalTextureGLImpeller>(
          std::static_pointer_cast<impeller::ContextGLES>(
              android_context_->GetImpellerContext()),
          texture_id, image_texture_entry, jni_facade_, lifecycle);
    case AndroidRenderingAPI::kImpellerVulkan:
      return std::make_unique<ImageExternalTextureVKImpeller>(
          std::static_pointer_cast<impeller::ContextVK>(
              android_context_->GetImpellerContext()),
          texture_id, image_texture_entry, jni_facade_, lifecycle);
    case AndroidRenderingAPI::kImpellerAutoselect:
      FML_CHECK(false);
      return nullptr;
  }
  return nullptr;
}

std::unique_ptr<Surface> PlatformViewAndroid::CreateAndroidRenderingSurface() {
  if (!android_surface_) {
    return nullptr;
  }
  return android_surface_->CreateGPUSurface(
      android_context_->GetMainSkiaContext().get());
}

std::shared_ptr<ExternalViewEmbedder>
PlatformViewAndroid::CreateAndroidExternalViewEmbedder() {
  return std::make_shared<AndroidExternalViewEmbedderWrapper>(
      android_meets_hcpp_criteria_, *android_context_, jni_facade_,
      surface_factory_, task_runners_);
}

std::unique_ptr<SnapshotSurfaceProducer>
PlatformViewAndroid::CreateAndroidSnapshotSurfaceProducer() {
  if (!android_surface_) {
    return nullptr;
  }
  return std::make_unique<AndroidSnapshotSurfaceProducer>(*android_surface_);
}

bool PlatformViewAndroid::MakeAndroidResourceContextCurrent() const {
  if (!android_surface_) {
    return false;
  }
  return android_surface_->ResourceContextMakeCurrent();
}

void PlatformViewAndroid::ReleaseAndroidResourceContext() const {
  if (android_surface_) {
    android_surface_->ResourceContextClearCurrent();
  }
}

std::shared_ptr<impeller::Context>
PlatformViewAndroid::GetAndroidImpellerContext() const {
  if (android_surface_) {
    return android_surface_->GetImpellerContext();
  }
  return android_context_->GetImpellerContext();
}

bool PlatformViewAndroid::IsSurfaceControlEnabled() const {
  // This needs to know if we're actually using HCPP.
  return android_meets_hcpp_criteria_ &&
         android_context_->RenderingApi() ==
             AndroidRenderingAPI::kImpellerVulkan &&
         impeller::ContextVK::Cast(*android_context_->GetImpellerContext())
             .GetShouldEnableSurfaceControlSwapchain();
}

void PlatformViewAndroid::SetupAndroidImpellerContext() {
  android_context_->SetupImpellerContext();
  android_surface_->SetupImpellerSurface();
}

}  // namespace flutter
