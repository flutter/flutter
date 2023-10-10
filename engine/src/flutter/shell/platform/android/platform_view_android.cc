// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/platform_view_android.h"

#include <memory>
#include <utility>

#include "flutter/common/graphics/texture.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/shell/common/shell_io_manager.h"
#include "flutter/shell/gpu/gpu_surface_gl_delegate.h"
#include "flutter/shell/platform/android/android_context_gl_impeller.h"
#include "flutter/shell/platform/android/android_context_gl_skia.h"
#include "flutter/shell/platform/android/android_context_vulkan_impeller.h"
#include "flutter/shell/platform/android/android_surface_gl_impeller.h"
#include "flutter/shell/platform/android/android_surface_gl_skia.h"
#include "flutter/shell/platform/android/android_surface_software.h"
#include "flutter/shell/platform/android/hardware_buffer_external_texture_gl.h"
#include "flutter/shell/platform/android/surface_texture_external_texture_gl.h"
#if IMPELLER_ENABLE_VULKAN  // b/258506856 for why this is behind an if
#include "flutter/shell/platform/android/android_surface_vulkan_impeller.h"
#include "flutter/shell/platform/android/hardware_buffer_external_texture_vk.h"
#endif
#include "flutter/shell/platform/android/context/android_context.h"
#include "flutter/shell/platform/android/external_view_embedder/external_view_embedder.h"
#include "flutter/shell/platform/android/jni/platform_view_android_jni.h"
#include "flutter/shell/platform/android/platform_message_response_android.h"
#include "flutter/shell/platform/android/surface/android_surface.h"
#include "flutter/shell/platform/android/surface/snapshot_surface_producer.h"
#include "flutter/shell/platform/android/vsync_waiter_android.h"

namespace flutter {

AndroidSurfaceFactoryImpl::AndroidSurfaceFactoryImpl(
    const std::shared_ptr<AndroidContext>& context,
    bool enable_impeller)
    : android_context_(context), enable_impeller_(enable_impeller) {}

AndroidSurfaceFactoryImpl::~AndroidSurfaceFactoryImpl() = default;

std::unique_ptr<AndroidSurface> AndroidSurfaceFactoryImpl::CreateSurface() {
  switch (android_context_->RenderingApi()) {
    case AndroidRenderingAPI::kSoftware:
      return std::make_unique<AndroidSurfaceSoftware>();
    case AndroidRenderingAPI::kOpenGLES:
      if (enable_impeller_) {
        return std::make_unique<AndroidSurfaceGLImpeller>(
            std::static_pointer_cast<AndroidContextGLImpeller>(
                android_context_));
      } else {
        return std::make_unique<AndroidSurfaceGLSkia>(
            std::static_pointer_cast<AndroidContextGLSkia>(android_context_));
      }
    case AndroidRenderingAPI::kVulkan:
      FML_DCHECK(enable_impeller_);
      return std::make_unique<AndroidSurfaceVulkanImpeller>(
          std::static_pointer_cast<AndroidContextVulkanImpeller>(
              android_context_));
    default:
      FML_DCHECK(false);
      return nullptr;
  }
}

static std::shared_ptr<flutter::AndroidContext> CreateAndroidContext(
    bool use_software_rendering,
    const flutter::TaskRunners& task_runners,
    uint8_t msaa_samples,
    bool enable_impeller,
    const std::optional<std::string>& impeller_backend,
    bool enable_vulkan_validation) {
  if (use_software_rendering) {
    return std::make_shared<AndroidContext>(AndroidRenderingAPI::kSoftware);
  }
  if (enable_impeller) {
    // Default value is Vulkan with GLES fallback.
    AndroidRenderingAPI backend = AndroidRenderingAPI::kAutoselect;
    if (impeller_backend.has_value()) {
      if (impeller_backend.value() == "opengles") {
        backend = AndroidRenderingAPI::kOpenGLES;
      } else if (impeller_backend.value() == "vulkan") {
        backend = AndroidRenderingAPI::kVulkan;
      } else {
        FML_CHECK(impeller_backend.value() == "vulkan" ||
                  impeller_backend.value() == "opengles");
      }
    }
    switch (backend) {
      case AndroidRenderingAPI::kOpenGLES:
        return std::make_unique<AndroidContextGLImpeller>(
            std::make_unique<impeller::egl::Display>());
      case AndroidRenderingAPI::kVulkan:
        return std::make_unique<AndroidContextVulkanImpeller>(
            enable_vulkan_validation);
      case AndroidRenderingAPI::kAutoselect: {
        auto vulkan_backend = std::make_unique<AndroidContextVulkanImpeller>(
            enable_vulkan_validation);
        if (!vulkan_backend->IsValid()) {
          return std::make_unique<AndroidContextGLImpeller>(
              std::make_unique<impeller::egl::Display>());
        }
        return vulkan_backend;
      }
      default:
        FML_UNREACHABLE();
    }
  }
  return std::make_unique<AndroidContextGLSkia>(
      AndroidRenderingAPI::kOpenGLES,               //
      fml::MakeRefCounted<AndroidEnvironmentGL>(),  //
      task_runners,                                 //
      msaa_samples                                  //
  );
}

PlatformViewAndroid::PlatformViewAndroid(
    PlatformView::Delegate& delegate,
    const flutter::TaskRunners& task_runners,
    const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade,
    bool use_software_rendering,
    uint8_t msaa_samples)
    : PlatformViewAndroid(
          delegate,
          task_runners,
          jni_facade,
          CreateAndroidContext(
              use_software_rendering,
              task_runners,
              msaa_samples,
              delegate.OnPlatformViewGetSettings().enable_impeller,
              delegate.OnPlatformViewGetSettings().impeller_backend,
              delegate.OnPlatformViewGetSettings().enable_vulkan_validation)) {}

PlatformViewAndroid::PlatformViewAndroid(
    PlatformView::Delegate& delegate,
    const flutter::TaskRunners& task_runners,
    const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade,
    const std::shared_ptr<flutter::AndroidContext>& android_context)
    : PlatformView(delegate, task_runners),
      jni_facade_(jni_facade),
      android_context_(android_context),
      platform_view_android_delegate_(jni_facade),
      platform_message_handler_(new PlatformMessageHandlerAndroid(jni_facade)) {
  if (android_context_) {
    FML_CHECK(android_context_->IsValid())
        << "Could not create surface from invalid Android context.";
    surface_factory_ = std::make_shared<AndroidSurfaceFactoryImpl>(
        android_context_,                                     //
        delegate.OnPlatformViewGetSettings().enable_impeller  //
    );
    android_surface_ = surface_factory_->CreateSurface();
    FML_CHECK(android_surface_ && android_surface_->IsValid())
        << "Could not create an OpenGL, Vulkan or Software surface to set up "
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
         native_window = std::move(native_window)]() {
          surface->SetNativeWindow(native_window);
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
         native_window = std::move(native_window)]() {
          surface->TeardownOnScreenContext();
          surface->SetNativeWindow(native_window);
          latch.Signal();
        });
    latch.Wait();
  }
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

void PlatformViewAndroid::NotifyChanged(const SkISize& size) {
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

// |PlatformView|
void PlatformViewAndroid::OnPreEngineRestart() const {
  jni_facade_->FlutterViewOnPreEngineRestart();
}

void PlatformViewAndroid::DispatchSemanticsAction(JNIEnv* env,
                                                  jint id,
                                                  jint action,
                                                  jobject args,
                                                  jint args_position) {
  if (env->IsSameObject(args, NULL)) {
    PlatformView::DispatchSemanticsAction(
        id, static_cast<flutter::SemanticsAction>(action),
        fml::MallocMapping());
    return;
  }

  uint8_t* args_data = static_cast<uint8_t*>(env->GetDirectBufferAddress(args));
  auto args_vector = fml::MallocMapping::Copy(args_data, args_position);

  PlatformView::DispatchSemanticsAction(
      id, static_cast<flutter::SemanticsAction>(action),
      std::move(args_vector));
}

// |PlatformView|
void PlatformViewAndroid::UpdateSemantics(
    flutter::SemanticsNodeUpdates update,
    flutter::CustomAccessibilityActionUpdates actions) {
  platform_view_android_delegate_.UpdateSemantics(update, actions);
}

void PlatformViewAndroid::RegisterExternalTexture(
    int64_t texture_id,
    const fml::jni::ScopedJavaGlobalRef<jobject>& surface_texture) {
  if (android_context_->RenderingApi() == AndroidRenderingAPI::kOpenGLES) {
    if (android_context_->GetImpellerContext()) {
      // Impeller GLES.
      RegisterTexture(std::make_shared<SurfaceTextureExternalTextureImpellerGL>(
          std::static_pointer_cast<impeller::ContextGLES>(
              android_context_->GetImpellerContext()),
          texture_id, surface_texture, jni_facade_));
    } else {
      // Legacy GL.
      RegisterTexture(std::make_shared<SurfaceTextureExternalTextureGL>(
          texture_id, surface_texture, jni_facade_));
    }
  } else {
    FML_LOG(INFO) << "Attempted to use a SurfaceTextureExternalTexture with an "
                     "unsupported rendering API.";
  }
}

void PlatformViewAndroid::RegisterImageTexture(
    int64_t texture_id,
    const fml::jni::ScopedJavaGlobalRef<jobject>& image_texture_entry) {
  if (android_context_->RenderingApi() == AndroidRenderingAPI::kOpenGLES) {
    if (android_context_->GetImpellerContext()) {
      // Impeller GLES.
      RegisterTexture(std::make_shared<HardwareBufferExternalTextureGLImpeller>(
          std::static_pointer_cast<impeller::ContextGLES>(
              android_context_->GetImpellerContext()),
          texture_id, image_texture_entry, jni_facade_));
    } else {
      // Legacy GL.
      RegisterTexture(std::make_shared<HardwareBufferExternalTextureGLSkia>(
          std::static_pointer_cast<AndroidContextGLSkia>(android_context_),
          texture_id, image_texture_entry, jni_facade_));
    }
  } else if (android_context_->RenderingApi() == AndroidRenderingAPI::kVulkan) {
    RegisterTexture(std::make_shared<HardwareBufferExternalTextureVK>(
        std::static_pointer_cast<impeller::ContextVK>(
            android_context_->GetImpellerContext()),
        texture_id, image_texture_entry, jni_facade_));
  } else {
    FML_LOG(INFO) << "Attempted to use a HardwareBuffer texture with an "
                     "unsupported rendering API.";
  }
}

// |PlatformView|
std::unique_ptr<VsyncWaiter> PlatformViewAndroid::CreateVSyncWaiter() {
  return std::make_unique<VsyncWaiterAndroid>(task_runners_);
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
  return std::make_shared<AndroidExternalViewEmbedder>(
      *android_context_, jni_facade_, surface_factory_, task_runners_);
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
  sk_sp<GrDirectContext> resource_context;
  if (android_surface_->ResourceContextMakeCurrent()) {
    // TODO(chinmaygarde): Currently, this code depends on the fact that only
    // the OpenGL surface will be able to make a resource context current. If
    // this changes, this assumption breaks. Handle the same.
    resource_context = ShellIOManager::CreateCompatibleResourceLoadingContext(
        GrBackend::kOpenGL_GrBackend,
        GPUSurfaceGLDelegate::GetDefaultPlatformGLInterface());
  } else {
    FML_DLOG(ERROR) << "Could not make the resource context current.";
  }

  return resource_context;
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
  return nullptr;
}

// |PlatformView|
std::unique_ptr<std::vector<std::string>>
PlatformViewAndroid::ComputePlatformResolvedLocales(
    const std::vector<std::string>& supported_locale_data) {
  return jni_facade_->FlutterViewComputePlatformResolvedLocale(
      supported_locale_data);
}

// |PlatformView|
void PlatformViewAndroid::RequestDartDeferredLibrary(intptr_t loading_unit_id) {
  if (jni_facade_->RequestDartDeferredLibrary(loading_unit_id)) {
    return;
  }
  return;  // TODO(garyq): Call LoadDartDeferredLibraryFailure()
}

// |PlatformView|
void PlatformViewAndroid::LoadDartDeferredLibrary(
    intptr_t loading_unit_id,
    std::unique_ptr<const fml::Mapping> snapshot_data,
    std::unique_ptr<const fml::Mapping> snapshot_instructions) {
  delegate_.LoadDartDeferredLibrary(loading_unit_id, std::move(snapshot_data),
                                    std::move(snapshot_instructions));
}

// |PlatformView|
void PlatformViewAndroid::LoadDartDeferredLibraryError(
    intptr_t loading_unit_id,
    const std::string error_message,
    bool transient) {
  delegate_.LoadDartDeferredLibraryError(loading_unit_id, error_message,
                                         transient);
}

// |PlatformView|
void PlatformViewAndroid::UpdateAssetResolverByType(
    std::unique_ptr<AssetResolver> updated_asset_resolver,
    AssetResolver::AssetResolverType type) {
  delegate_.UpdateAssetResolverByType(std::move(updated_asset_resolver), type);
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

double PlatformViewAndroid::GetScaledFontSize(double unscaled_font_size,
                                              int configuration_id) const {
  return jni_facade_->FlutterViewGetScaledFontSize(unscaled_font_size,
                                                   configuration_id);
}
}  // namespace flutter
