// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/platform_view_android.h"

#include <android/api-level.h>
#include <sys/system_properties.h>
#include <memory>
#include <utility>

#include "common/settings.h"
#include "flutter/common/graphics/texture.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/shell/common/shell_io_manager.h"
#include "flutter/shell/gpu/gpu_surface_gl_delegate.h"
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
#include "impeller/display_list/aiks_context.h"
#if IMPELLER_ENABLE_VULKAN  // b/258506856 for why this is behind an if
#include "flutter/shell/platform/android/android_surface_vk_impeller.h"
#include "flutter/shell/platform/android/image_external_texture_vk_impeller.h"
#endif
#include "flutter/shell/platform/android/context/android_context.h"
#include "flutter/shell/platform/android/external_view_embedder/external_view_embedder_wrapper.h"
#include "flutter/shell/platform/android/jni/platform_view_android_jni.h"
#include "flutter/shell/platform/android/platform_message_response_android.h"
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

PlatformViewAndroid::PlatformViewAndroid(
    PlatformView::Delegate& delegate,
    const flutter::TaskRunners& task_runners,
    const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade,
    const std::shared_ptr<flutter::AndroidContext>& android_context,
    PlatformDispatchTable platform_dispatch_table)
    : PlatformViewEmbedder(delegate,
                           task_runners,
                           std::move(platform_dispatch_table)),
      jni_facade_(jni_facade),
      android_context_(android_context),
      platform_message_handler_(new PlatformMessageHandlerAndroid(jni_facade)) {
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

void PlatformViewAndroid::NotifyCreated(
    fml::RefPtr<AndroidNativeWindow> native_window) {
  if (android_surface_) {
    InstallFirstFrameCallback();

    fml::AutoResetWaitableEvent latch;
    fml::TaskRunner::RunNowOrPostTask(
        task_runners_.GetRasterTaskRunner(),
        [&latch, surface = android_surface_.get(),
         native_window = std::move(native_window), jni_facade = jni_facade_]() {
          surface->SetNativeWindow(native_window, jni_facade);
          latch.Signal();
        });
    latch.Wait();
  }

  PlatformView::NotifyCreated();
}

void PlatformViewAndroid::NotifySurfaceWindowChanged(
    fml::RefPtr<AndroidNativeWindow> native_window) {
  if (android_surface_) {
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

  PlatformView::ScheduleFrame();
}

void PlatformViewAndroid::NotifyDestroyed() {
  PlatformView::NotifyDestroyed();

  if (android_surface_) {
    fml::AutoResetWaitableEvent latch;
    fml::TaskRunner::RunNowOrPostTask(
        task_runners_.GetRasterTaskRunner(),
        [&latch, surface = android_surface_.get()]() {
          surface->TeardownOnScreenContext();
          latch.Signal();
        });
    latch.Wait();
  }
}

void PlatformViewAndroid::NotifyChanged(const DlISize& size) {
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

void PlatformViewAndroid::DispatchPlatformMessage(JNIEnv* env,
                                                  std::string name,
                                                  jobject java_message_data,
                                                  jint java_message_position,
                                                  jint response_id) {
  uint8_t* message_data =
      static_cast<uint8_t*>(env->GetDirectBufferAddress(java_message_data));
  fml::MallocMapping message =
      fml::MallocMapping::Copy(message_data, java_message_position);

  fml::RefPtr<flutter::PlatformMessageResponse> response;
  if (response_id) {
    response = fml::MakeRefCounted<PlatformMessageResponseAndroid>(
        response_id, jni_facade_, task_runners_.GetPlatformTaskRunner());
  }

  PlatformView::DispatchPlatformMessage(
      std::make_unique<flutter::PlatformMessage>(
          std::move(name), std::move(message), std::move(response)));
}

void PlatformViewAndroid::DispatchEmptyPlatformMessage(JNIEnv* env,
                                                       std::string name,
                                                       jint response_id) {
  fml::RefPtr<flutter::PlatformMessageResponse> response;
  if (response_id) {
    response = fml::MakeRefCounted<PlatformMessageResponseAndroid>(
        response_id, jni_facade_, task_runners_.GetPlatformTaskRunner());
  }

  PlatformView::DispatchPlatformMessage(
      std::make_unique<flutter::PlatformMessage>(std::move(name),
                                                 std::move(response)));
}

// |PlatformView|
void PlatformViewAndroid::HandlePlatformMessage(
    std::unique_ptr<flutter::PlatformMessage> message) {
  // Called from the ui thread.
  platform_message_handler_->HandlePlatformMessage(std::move(message));
}

void PlatformViewAndroid::RegisterExternalTexture(
    int64_t texture_id,
    const fml::jni::ScopedJavaGlobalRef<jobject>& surface_texture) {
  switch (android_context_->RenderingApi()) {
    case AndroidRenderingAPI::kImpellerOpenGLES:
      // Impeller GLES.
      RegisterTexture(std::make_shared<SurfaceTextureExternalTextureGLImpeller>(
          std::static_pointer_cast<impeller::ContextGLES>(
              android_context_->GetImpellerContext()),  //
          texture_id,                                   //
          surface_texture,                              //
          jni_facade_                                   //
          ));
      break;
#if !SLIMPELLER
    case AndroidRenderingAPI::kSkiaOpenGLES:
      // Legacy GL.
      RegisterTexture(std::make_shared<SurfaceTextureExternalTextureGLSkia>(
          texture_id,       //
          surface_texture,  //
          jni_facade_       //
          ));
      break;
    case AndroidRenderingAPI::kSoftware:
      FML_LOG(INFO) << "Software rendering does not support external textures.";
      break;
#endif  // !SLIMPELLER
    case AndroidRenderingAPI::kImpellerVulkan:
      FML_LOG(IMPORTANT)
          << "Flutter recommends migrating plugins that create and "
             "register surface textures to the new surface producer "
             "API. See https://docs.flutter.dev/release/breaking-changes/"
             "android-surface-plugins";
      RegisterTexture(std::make_shared<SurfaceTextureExternalTextureVKImpeller>(
          std::static_pointer_cast<impeller::ContextVK>(
              android_context_->GetImpellerContext()),  //
          texture_id,                                   //
          surface_texture,                              //
          jni_facade_                                   //
          ));
      break;
    case AndroidRenderingAPI::kImpellerAutoselect:
    default:
      FML_CHECK(false);
      break;
  }
}

void PlatformViewAndroid::RegisterImageTexture(
    int64_t texture_id,
    const fml::jni::ScopedJavaGlobalRef<jobject>& image_texture_entry,
    ImageExternalTexture::ImageLifecycle lifecycle) {
  switch (android_context_->RenderingApi()) {
#if !SLIMPELLER
    case AndroidRenderingAPI::kSkiaOpenGLES:
      // Legacy GL.
      RegisterTexture(std::make_shared<ImageExternalTextureGLSkia>(
          std::static_pointer_cast<AndroidContextGLSkia>(android_context_),
          texture_id, image_texture_entry, jni_facade_, lifecycle));
      break;
    case AndroidRenderingAPI::kSoftware:
      FML_LOG(INFO) << "Software rendering does not support external textures.";
      break;
#endif  // !SLIMPELLER
    case AndroidRenderingAPI::kImpellerOpenGLES:
      // Impeller GLES.
      RegisterTexture(std::make_shared<ImageExternalTextureGLImpeller>(
          std::static_pointer_cast<impeller::ContextGLES>(
              android_context_->GetImpellerContext()),
          texture_id, image_texture_entry, jni_facade_, lifecycle));
      break;
    case AndroidRenderingAPI::kImpellerVulkan:
      RegisterTexture(std::make_shared<ImageExternalTextureVKImpeller>(
          std::static_pointer_cast<impeller::ContextVK>(
              android_context_->GetImpellerContext()),
          texture_id, image_texture_entry, jni_facade_, lifecycle));
      break;
    case AndroidRenderingAPI::kImpellerAutoselect:
      FML_CHECK(false);
      break;
  }
}

// |PlatformView|
std::unique_ptr<Surface> PlatformViewAndroid::CreateRenderingSurface() {
  if (!android_surface_) {
    return nullptr;
  }
  return android_surface_->CreateGPUSurface(
      android_context_->GetMainSkiaContext().get());
}

// |PlatformView|
std::shared_ptr<ExternalViewEmbedder>
PlatformViewAndroid::CreateExternalViewEmbedder() {
  return std::make_shared<AndroidExternalViewEmbedderWrapper>(
      android_meets_hcpp_criteria_, *android_context_, jni_facade_,
      surface_factory_, task_runners_);
}

// |PlatformView|
std::unique_ptr<SnapshotSurfaceProducer>
PlatformViewAndroid::CreateSnapshotSurfaceProducer() {
  if (!android_surface_) {
    return nullptr;
  }
  return std::make_unique<AndroidSnapshotSurfaceProducer>(*android_surface_);
}

// |PlatformView|
sk_sp<GrDirectContext> PlatformViewAndroid::CreateResourceContext() const {
  if (!android_surface_) {
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
#endif  //  !SLIMPELLER
}

// |PlatformView|
void PlatformViewAndroid::ReleaseResourceContext() const {
  if (android_surface_) {
    android_surface_->ResourceContextClearCurrent();
  }
}

// |PlatformView|
std::shared_ptr<impeller::Context> PlatformViewAndroid::GetImpellerContext()
    const {
  if (android_surface_) {
    return android_surface_->GetImpellerContext();
  }
  return android_context_->GetImpellerContext();
}

void PlatformViewAndroid::InstallFirstFrameCallback() {
  // On Platform Task Runner.
  SetNextFrameCallback(
      [platform_view = GetWeakPtr(),
       platform_task_runner = task_runners_.GetPlatformTaskRunner()]() {
        // On GPU Task Runner.
        platform_task_runner->PostTask([platform_view]() {
          // Back on Platform Task Runner.
          if (platform_view) {
            reinterpret_cast<PlatformViewAndroid*>(platform_view.get())
                ->FireFirstFrameCallback();
          }
        });
      });
}

void PlatformViewAndroid::FireFirstFrameCallback() {
  jni_facade_->FlutterViewOnFirstFrame();
}

bool PlatformViewAndroid::IsSurfaceControlEnabled() const {
  // This needs to know if we're actually using HCPP.
  return android_meets_hcpp_criteria_ &&
         android_context_->RenderingApi() ==
             AndroidRenderingAPI::kImpellerVulkan &&
         impeller::ContextVK::Cast(*android_context_->GetImpellerContext())
             .GetShouldEnableSurfaceControlSwapchain();
}

void PlatformViewAndroid::SetupImpellerContext() {
  android_context_->SetupImpellerContext();
  android_surface_->SetupImpellerSurface();
}

}  // namespace flutter
