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
#include "flutter/shell/platform/android/jni/platform_view_android_jni.h"
#include "flutter/shell/platform/android/platform_message_response_android.h"
#include "flutter/shell/platform/android/surface/android_surface.h"
#include "flutter/shell/platform/android/surface/snapshot_surface_producer.h"
#include "flutter/shell/platform/android/vsync_waiter_android.h"

namespace flutter {

namespace {

static constexpr int kMinAPILevelHCPP = 34;
static constexpr int64_t kImplicitViewId = 0;

}  // namespace

AndroidContext::ContextSettings PlatformViewAndroid::CreateContextSettings(
    const Settings& p_settings) {
  AndroidContext::ContextSettings settings;
  settings.enable_gpu_tracing = p_settings.enable_vulkan_gpu_tracing;
  settings.enable_validation = p_settings.enable_vulkan_validation;
  settings.enable_surface_control = p_settings.enable_surface_control;
  return settings;
}

bool PlatformViewAndroid::MeetsHCPPCriteria(const Settings& settings) {
  return settings.enable_surface_control &&
         android_get_device_api_level() >= kMinAPILevelHCPP &&
         settings.enable_impeller;
}

std::shared_ptr<flutter::AndroidContext>
PlatformViewAndroid::CreateAndroidContext(
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
    const flutter::TaskRunners& task_runners,
    const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade,
    const std::shared_ptr<flutter::AndroidContext>& android_context)
    : task_runners_(task_runners),
      jni_facade_(jni_facade),
      android_context_(android_context),
      platform_view_android_delegate_(jni_facade),
      platform_message_handler_(new PlatformMessageHandlerAndroid(jni_facade)),
      weak_factory_(this) {}

PlatformViewAndroid::~PlatformViewAndroid() = default;

void PlatformViewAndroid::NotifyCreated(
    const fml::RefPtr<AndroidNativeWindow>& native_window) {
  if (engine_ && native_window) {
    engine_->NotifySurfaceCreated(native_window->handle(),
                                  native_window->IsFakeWindow());
  } else if (engine_) {
    engine_->NotifyCreated();
  }
}

void PlatformViewAndroid::NotifySurfaceWindowChanged(
    const fml::RefPtr<AndroidNativeWindow>& native_window) {
  if (engine_ && native_window) {
    engine_->NotifySurfaceWindowChanged(native_window->handle(),
                                        native_window->IsFakeWindow());
  } else {
    ScheduleFrame();
  }
}

void PlatformViewAndroid::NotifyDestroyed() {
  if (engine_) {
    engine_->NotifySurfaceDestroyed();
  }
}

void PlatformViewAndroid::NotifyChanged(const DlISize& size) {
  if (engine_) {
    engine_->NotifySurfaceChanged(size.width, size.height);
  }
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

  auto platform_message = std::make_unique<flutter::PlatformMessage>(
      std::move(name), std::move(message), std::move(response));
  if (engine_) {
    engine_->DispatchPlatformMessage(std::move(platform_message));
  }
}

void PlatformViewAndroid::DispatchEmptyPlatformMessage(JNIEnv* env,
                                                       std::string name,
                                                       jint response_id) {
  fml::RefPtr<flutter::PlatformMessageResponse> response;
  if (response_id) {
    response = fml::MakeRefCounted<PlatformMessageResponseAndroid>(
        response_id, jni_facade_, task_runners_.GetPlatformTaskRunner());
  }

  auto platform_message = std::make_unique<flutter::PlatformMessage>(
      std::move(name), std::move(response));
  if (engine_) {
    engine_->DispatchPlatformMessage(std::move(platform_message));
  }
}

void PlatformViewAndroid::HandlePlatformMessage(
    std::unique_ptr<flutter::PlatformMessage> message) {
  // Called from the ui thread.
  platform_message_handler_->HandlePlatformMessage(std::move(message));
}

void PlatformViewAndroid::OnPreEngineRestart() const {
  jni_facade_->FlutterViewOnPreEngineRestart();
}

void PlatformViewAndroid::DispatchSemanticsAction(JNIEnv* env,
                                                  jint node_id,
                                                  jint action,
                                                  jobject args,
                                                  jint args_position) {
  // TODO(team-android): Remove implicit view assumption.
  // https://github.com/flutter/flutter/issues/142845
  if (env->IsSameObject(args, NULL)) {
    if (engine_) {
      engine_->DispatchSemanticsAction(
          kImplicitViewId, node_id,
          static_cast<flutter::SemanticsAction>(action), fml::MallocMapping());
    }
    return;
  }

  uint8_t* args_data = static_cast<uint8_t*>(env->GetDirectBufferAddress(args));
  auto args_vector = fml::MallocMapping::Copy(args_data, args_position);

  if (engine_) {
    engine_->DispatchSemanticsAction(
        kImplicitViewId, node_id, static_cast<flutter::SemanticsAction>(action),
        std::move(args_vector));
  }
}

// |PlatformView|
void PlatformViewAndroid::UpdateSemantics(
    int64_t view_id,
    const flutter::SemanticsNodeUpdates& update,
    const flutter::CustomAccessibilityActionUpdates& actions) {
  if (engine_ && engine_->UpdateSemantics(view_id, update, actions)) {
    return;
  }
  platform_view_android_delegate_.UpdateSemantics(update, actions);
}

// |PlatformView|
void PlatformViewAndroid::SetApplicationLocale(std::string locale) {
  jni_facade_->FlutterViewSetApplicationLocale(std::move(locale));
}

// |PlatformView|
void PlatformViewAndroid::SetSemanticsTreeEnabled(bool enabled) {
  jni_facade_->FlutterViewSetSemanticsTreeEnabled(enabled);
}

void PlatformViewAndroid::RegisterExternalTexture(
    int64_t texture_id,
    const fml::jni::ScopedJavaGlobalRef<jobject>& surface_texture) {
  std::shared_ptr<impeller::Context> impeller_context;
  if (engine_) {
    impeller_context = engine_->GetImpellerContext();
  }
  if (!impeller_context && android_context_) {
    impeller_context = android_context_->GetImpellerContext();
  }
  switch (android_context_->RenderingApi()) {
    case AndroidRenderingAPI::kImpellerOpenGLES:
      // Impeller GLES.
      RegisterTexture(std::make_shared<SurfaceTextureExternalTextureGLImpeller>(
          std::static_pointer_cast<impeller::ContextGLES>(impeller_context),
          texture_id,       //
          surface_texture,  //
          jni_facade_       //
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
          std::static_pointer_cast<impeller::ContextVK>(impeller_context),
          texture_id,       //
          surface_texture,  //
          jni_facade_       //
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
  std::shared_ptr<impeller::Context> impeller_context;
  if (engine_) {
    impeller_context = engine_->GetImpellerContext();
  }
  if (!impeller_context && android_context_) {
    impeller_context = android_context_->GetImpellerContext();
  }
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
          std::static_pointer_cast<impeller::ContextGLES>(impeller_context),
          texture_id, image_texture_entry, jni_facade_, lifecycle));
      break;
    case AndroidRenderingAPI::kImpellerVulkan:
      RegisterTexture(std::make_shared<ImageExternalTextureVKImpeller>(
          std::static_pointer_cast<impeller::ContextVK>(impeller_context),
          texture_id, image_texture_entry, jni_facade_, lifecycle));
      break;
    case AndroidRenderingAPI::kImpellerAutoselect:
      FML_CHECK(false);
      break;
  }
}

std::unique_ptr<std::vector<std::string>>
PlatformViewAndroid::ComputePlatformResolvedLocales(
    const std::vector<std::string>& supported_locale_data) {
  return jni_facade_->FlutterViewComputePlatformResolvedLocale(
      supported_locale_data);
}

void PlatformViewAndroid::RequestDartDeferredLibrary(intptr_t loading_unit_id) {
  if (jni_facade_->RequestDartDeferredLibrary(loading_unit_id)) {
    return;
  }
  return;  // TODO(garyq): Call LoadDartDeferredLibraryFailure()
}

void PlatformViewAndroid::LoadDartDeferredLibrary(
    intptr_t loading_unit_id,
    std::unique_ptr<const fml::Mapping> snapshot_data,
    std::unique_ptr<const fml::Mapping> snapshot_instructions) {
  if (engine_) {
    engine_->LoadDartDeferredLibrary(loading_unit_id, std::move(snapshot_data),
                                     std::move(snapshot_instructions));
  }
}

void PlatformViewAndroid::LoadDartDeferredLibraryError(
    intptr_t loading_unit_id,
    const std::string& error_message,
    bool transient) {
  if (engine_) {
    engine_->LoadDartDeferredLibraryError(loading_unit_id, error_message,
                                          transient);
  }
}

void PlatformViewAndroid::UpdateAssetResolverByType(
    std::unique_ptr<AssetResolver> updated_asset_resolver,
    AssetResolver::AssetResolverType type) {
  if (engine_) {
    engine_->UpdateAssetResolverByType(std::move(updated_asset_resolver), type);
  }
}

void PlatformViewAndroid::InstallFirstFrameCallback() {
  // On Platform Task Runner.
  auto callback = [platform_view = GetWeakPtr(),
                   platform_task_runner =
                       task_runners_.GetPlatformTaskRunner()]() {
    // On GPU Task Runner.
    platform_task_runner->PostTask([platform_view]() {
      // Back on Platform Task Runner.
      if (platform_view) {
        platform_view->FireFirstFrameCallback();
      }
    });
  };
  if (engine_) {
    engine_->SetNextFrameCallback(callback);
  }
}

void PlatformViewAndroid::FireFirstFrameCallback() {
  jni_facade_->FlutterViewOnFirstFrame();
}

double PlatformViewAndroid::GetScaledFontSize(double unscaled_font_size,
                                              int configuration_id) const {
  return jni_facade_->FlutterViewGetScaledFontSize(unscaled_font_size,
                                                   configuration_id);
}

void PlatformViewAndroid::SendChannelUpdate(const std::string& name,
                                            bool listening) {}

void PlatformViewAndroid::RequestViewFocusChange(
    const ViewFocusChangeRequest& request) {}

void PlatformViewAndroid::OnVsyncCallback(intptr_t baton) {
  if (engine_) {
    engine_->OnVsyncCallback(baton);
  }
}

void PlatformViewAndroid::SetEngine(AndroidEngine* engine) {
  engine_ = engine;
}

void PlatformViewAndroid::SetSemanticsEnabled(bool enabled) {
  if (engine_) {
    engine_->SetSemanticsEnabled(enabled);
  }
}

void PlatformViewAndroid::SetAccessibilityFeatures(int32_t flags) {
  if (engine_) {
    engine_->SetAccessibilityFeatures(flags);
  }
}

void PlatformViewAndroid::SetViewportMetrics(int64_t view_id,
                                             const ViewportMetrics& metrics) {
  if (engine_) {
    engine_->SetViewportMetrics(view_id, metrics);
  }
}

void PlatformViewAndroid::DispatchPointerDataPacket(
    std::unique_ptr<PointerDataPacket> packet) {
  if (engine_) {
    engine_->DispatchPointerDataPacket(std::move(packet));
  }
}

void PlatformViewAndroid::RegisterTexture(
    std::shared_ptr<flutter::Texture> texture) {
  if (engine_) {
    engine_->RegisterTexture(std::move(texture));
  }
}

void PlatformViewAndroid::UnregisterTexture(int64_t texture_id) {
  if (engine_) {
    engine_->UnregisterTexture(texture_id);
  }
}

void PlatformViewAndroid::MarkTextureFrameAvailable(int64_t texture_id) {
  if (engine_) {
    engine_->MarkTextureFrameAvailable(texture_id);
  }
}

void PlatformViewAndroid::ScheduleFrame() {
  if (engine_) {
    engine_->ScheduleFrame();
  }
}

fml::WeakPtr<PlatformViewAndroid> PlatformViewAndroid::GetWeakPtr() const {
  return weak_factory_.GetWeakPtr();
}

bool PlatformViewAndroid::IsSurfaceControlEnabled() const {
  return engine_ ? engine_->IsSurfaceControlEnabled() : false;
}

}  // namespace flutter
