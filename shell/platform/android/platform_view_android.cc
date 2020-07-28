// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/platform_view_android.h"

#include <memory>
#include <utility>

#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/shell/common/shell_io_manager.h"
#include "flutter/shell/gpu/gpu_surface_gl_delegate.h"
#include "flutter/shell/platform/android/android_context_gl.h"
#include "flutter/shell/platform/android/android_external_texture_gl.h"
#include "flutter/shell/platform/android/android_surface_gl.h"
#include "flutter/shell/platform/android/android_surface_software.h"

#if SHELL_ENABLE_VULKAN
#include "flutter/shell/platform/android/android_surface_vulkan.h"
#endif  // SHELL_ENABLE_VULKAN

#include "flutter/shell/platform/android/context/android_context.h"
#include "flutter/shell/platform/android/jni/platform_view_android_jni.h"
#include "flutter/shell/platform/android/platform_message_response_android.h"
#include "flutter/shell/platform/android/vsync_waiter_android.h"

namespace flutter {

std::unique_ptr<AndroidSurface> SurfaceFactory(
    std::shared_ptr<AndroidContext> android_context,
    std::shared_ptr<PlatformViewAndroidJNI> jni_facade) {
  FML_CHECK(SurfaceFactory);
  switch (android_context->RenderingApi()) {
    case AndroidRenderingAPI::kSoftware:
      return std::make_unique<AndroidSurfaceSoftware>(
          android_context, jni_facade, SurfaceFactory);
    case AndroidRenderingAPI::kOpenGLES:
      return std::make_unique<AndroidSurfaceGL>(android_context, jni_facade,
                                                SurfaceFactory);
    case AndroidRenderingAPI::kVulkan:
#if SHELL_ENABLE_VULKAN
      return std::make_unique<AndroidSurfaceVulkan>(android_context, jni_facade,
                                                    SurfaceFactory);
#endif  // SHELL_ENABLE_VULKAN
      return nullptr;
  }
  return nullptr;
}

PlatformViewAndroid::PlatformViewAndroid(
    PlatformView::Delegate& delegate,
    flutter::TaskRunners task_runners,
    std::shared_ptr<PlatformViewAndroidJNI> jni_facade,
    bool use_software_rendering)
    : PlatformView(delegate, std::move(task_runners)),
      jni_facade_(jni_facade),
      platform_view_android_delegate_(jni_facade) {
  std::shared_ptr<AndroidContext> android_context;
  if (use_software_rendering) {
    android_context =
        std::make_shared<AndroidContext>(AndroidRenderingAPI::kSoftware);
  } else {
#if SHELL_ENABLE_VULKAN
    android_context =
        std::make_shared<AndroidContext>(AndroidRenderingAPI::kVulkan);
#else   // SHELL_ENABLE_VULKAN
    android_context = std::make_shared<AndroidContextGL>(
        AndroidRenderingAPI::kOpenGLES,
        fml::MakeRefCounted<AndroidEnvironmentGL>());
#endif  // SHELL_ENABLE_VULKAN
  }
  FML_CHECK(android_context && android_context->IsValid())
      << "Could not create an Android context.";

  android_surface_ = SurfaceFactory(std::move(android_context), jni_facade);
  FML_CHECK(android_surface_ && android_surface_->IsValid())
      << "Could not create an OpenGL, Vulkan or Software surface to setup "
         "rendering.";
}

PlatformViewAndroid::PlatformViewAndroid(
    PlatformView::Delegate& delegate,
    flutter::TaskRunners task_runners,
    std::shared_ptr<PlatformViewAndroidJNI> jni_facade)
    : PlatformView(delegate, std::move(task_runners)),
      jni_facade_(jni_facade),
      platform_view_android_delegate_(jni_facade) {}

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
  std::vector<uint8_t> message =
      std::vector<uint8_t>(message_data, message_data + java_message_position);

  fml::RefPtr<flutter::PlatformMessageResponse> response;
  if (response_id) {
    response = fml::MakeRefCounted<PlatformMessageResponseAndroid>(
        response_id, jni_facade_, task_runners_.GetPlatformTaskRunner());
  }

  PlatformView::DispatchPlatformMessage(
      fml::MakeRefCounted<flutter::PlatformMessage>(
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
      fml::MakeRefCounted<flutter::PlatformMessage>(std::move(name),
                                                    std::move(response)));
}

void PlatformViewAndroid::InvokePlatformMessageResponseCallback(
    JNIEnv* env,
    jint response_id,
    jobject java_response_data,
    jint java_response_position) {
  if (!response_id)
    return;
  auto it = pending_responses_.find(response_id);
  if (it == pending_responses_.end())
    return;
  uint8_t* response_data =
      static_cast<uint8_t*>(env->GetDirectBufferAddress(java_response_data));
  std::vector<uint8_t> response = std::vector<uint8_t>(
      response_data, response_data + java_response_position);
  auto message_response = std::move(it->second);
  pending_responses_.erase(it);
  message_response->Complete(
      std::make_unique<fml::DataMapping>(std::move(response)));
}

void PlatformViewAndroid::InvokePlatformMessageEmptyResponseCallback(
    JNIEnv* env,
    jint response_id) {
  if (!response_id)
    return;
  auto it = pending_responses_.find(response_id);
  if (it == pending_responses_.end())
    return;
  auto message_response = std::move(it->second);
  pending_responses_.erase(it);
  message_response->CompleteEmpty();
}

// |PlatformView|
void PlatformViewAndroid::HandlePlatformMessage(
    fml::RefPtr<flutter::PlatformMessage> message) {
  int response_id = 0;
  if (auto response = message->response()) {
    response_id = next_response_id_++;
    pending_responses_[response_id] = response;
  }
  // This call can re-enter in InvokePlatformMessageXxxResponseCallback.
  jni_facade_->FlutterViewHandlePlatformMessage(message, response_id);
  message = nullptr;
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
    std::vector<uint8_t> args_vector;
    PlatformView::DispatchSemanticsAction(
        id, static_cast<flutter::SemanticsAction>(action), args_vector);
    return;
  }

  uint8_t* args_data = static_cast<uint8_t*>(env->GetDirectBufferAddress(args));
  std::vector<uint8_t> args_vector =
      std::vector<uint8_t>(args_data, args_data + args_position);

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
    const fml::jni::JavaObjectWeakGlobalRef& surface_texture) {
  RegisterTexture(std::make_shared<AndroidExternalTextureGL>(
      texture_id, surface_texture, std::move(jni_facade_)));
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
  return android_surface_->CreateGPUSurface();
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
std::unique_ptr<std::vector<std::string>>
PlatformViewAndroid::ComputePlatformResolvedLocales(
    const std::vector<std::string>& supported_locale_data) {
  return jni_facade_->FlutterViewComputePlatformResolvedLocale(
      supported_locale_data);
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

}  // namespace flutter
