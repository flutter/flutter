// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_PLATFORM_VIEW_ANDROID_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_PLATFORM_VIEW_ANDROID_H_

#include <memory>
#include <string>
#include <vector>

#include <android/hardware_buffer_jni.h>
#include "flutter/fml/platform/android/scoped_java_ref.h"
#include "flutter/lib/ui/window/platform_message.h"
#include "flutter/shell/platform/android/android_engine.h"
#include "flutter/shell/platform/android/context/android_context.h"
#include "flutter/shell/platform/android/jni/platform_view_android_jni.h"
#include "flutter/shell/platform/android/platform_message_handler_android.h"
#include "flutter/shell/platform/android/platform_view_android_delegate/platform_view_android_delegate.h"
#include "flutter/shell/platform/android/surface/android_native_window.h"
#include "flutter/shell/platform/android/surface/android_surface.h"

namespace flutter {

class PlatformViewAndroid final {
 public:
  static bool Register(JNIEnv* env);

  static std::shared_ptr<AndroidContext> CreateAndroidContext(
      const flutter::TaskRunners& task_runners,
      AndroidRenderingAPI android_rendering_api,
      bool enable_opengl_gpu_tracing,
      const AndroidContext::ContextSettings& settings,
      std::shared_ptr<fml::BasicTaskRunner> io_task_runner);

  static AndroidContext::ContextSettings CreateContextSettings(
      const Settings& settings);

  static bool MeetsHCPPCriteria(const Settings& settings);

  PlatformViewAndroid(
      const flutter::TaskRunners& task_runners,
      const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade,
      const std::shared_ptr<flutter::AndroidContext>& android_context);

  ~PlatformViewAndroid();

  void NotifyCreated(const fml::RefPtr<AndroidNativeWindow>& native_window);

  void NotifySurfaceWindowChanged(
      const fml::RefPtr<AndroidNativeWindow>& native_window);

  void NotifyChanged(const DlISize& size);

  void NotifyDestroyed();

  void DispatchPlatformMessage(JNIEnv* env,
                               std::string name,
                               jobject message_data,
                               jint message_position,
                               jint response_id);

  void DispatchEmptyPlatformMessage(JNIEnv* env,
                                    std::string name,
                                    jint response_id);

  void DispatchSemanticsAction(JNIEnv* env,
                               jint id,
                               jint action,
                               jobject args,
                               jint args_position);

  void RegisterExternalTexture(
      int64_t texture_id,
      const fml::jni::ScopedJavaGlobalRef<jobject>& surface_texture);

  void RegisterImageTexture(
      int64_t texture_id,
      const fml::jni::ScopedJavaGlobalRef<jobject>& image_texture_entry,
      bool reset_on_background);

  void LoadDartDeferredLibrary(
      intptr_t loading_unit_id,
      std::unique_ptr<const fml::Mapping> snapshot_data,
      std::unique_ptr<const fml::Mapping> snapshot_instructions);

  void LoadDartDeferredLibraryError(intptr_t loading_unit_id,
                                    const std::string& error_message,
                                    bool transient);

  void UpdateAssetResolverByType(
      std::unique_ptr<AssetResolver> updated_asset_resolver,
      AssetResolver::AssetResolverType type);

  const std::shared_ptr<AndroidContext>& GetAndroidContext() {
    return android_context_;
  }

  std::shared_ptr<PlatformViewAndroidJNI> GetJniFacade() const {
    return jni_facade_;
  }

  std::shared_ptr<PlatformMessageHandler> GetPlatformMessageHandler() const {
    return platform_message_handler_;
  }

  /// @brief Whether the SurfaceControl based swapchain is enabled and active.
  bool IsSurfaceControlEnabled() const;

  void UpdateSemantics(
      int64_t view_id,
      const flutter::SemanticsNodeUpdates& update,
      const flutter::CustomAccessibilityActionUpdates& actions);

  void HandlePlatformMessage(std::unique_ptr<flutter::PlatformMessage> message);

  void OnPreEngineRestart() const;

  std::unique_ptr<std::vector<std::string>> ComputePlatformResolvedLocales(
      const std::vector<std::string>& supported_locale_data);

  void RequestDartDeferredLibrary(intptr_t loading_unit_id);

  double GetScaledFontSize(double unscaled_font_size,
                           int configuration_id) const;

  void SendChannelUpdate(const std::string& name, bool listening);

  void RequestViewFocusChange(const ViewFocusChangeRequest& request);

  void OnVsyncCallback(intptr_t baton);

  void SetApplicationLocale(std::string locale);

  void SetSemanticsTreeEnabled(bool enabled);

  void SetEngine(AndroidEngine* engine);

  void SetSemanticsEnabled(bool enabled);

  void SetAccessibilityFeatures(int32_t flags);

  void SetViewportMetrics(int64_t view_id, const ViewportMetrics& metrics);

  void DispatchPointerDataPacket(std::unique_ptr<PointerDataPacket> packet);

  void UnregisterTexture(int64_t texture_id);

  void MarkTextureFrameAvailable(int64_t texture_id);

  void ScheduleFrame();

  fml::WeakPtr<PlatformViewAndroid> GetWeakPtr() const;

 private:
  const flutter::TaskRunners task_runners_;
  const std::shared_ptr<PlatformViewAndroidJNI> jni_facade_;
  std::shared_ptr<AndroidContext> android_context_;
  AndroidEngine* engine_ = nullptr;

  PlatformViewAndroidDelegate platform_view_android_delegate_;

  std::shared_ptr<PlatformMessageHandlerAndroid> platform_message_handler_;

  void InstallFirstFrameCallback();

  void FireFirstFrameCallback();

  fml::WeakPtrFactory<PlatformViewAndroid> weak_factory_;

  FML_DISALLOW_COPY_AND_ASSIGN(PlatformViewAndroid);
};
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_PLATFORM_VIEW_ANDROID_H_
