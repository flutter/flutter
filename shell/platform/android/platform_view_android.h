// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_PLATFORM_ANDROID_PLATFORM_VIEW_ANDROID_H_
#define SHELL_PLATFORM_ANDROID_PLATFORM_VIEW_ANDROID_H_

#include <memory>
#include <string>
#include <unordered_map>
#include <vector>

#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/fml/platform/android/jni_weak_ref.h"
#include "flutter/fml/platform/android/scoped_java_ref.h"
#include "flutter/lib/ui/window/platform_message.h"
#include "flutter/shell/common/platform_view.h"
#include "flutter/shell/platform/android/jni/platform_view_android_jni.h"
#include "flutter/shell/platform/android/platform_view_android_delegate/platform_view_android_delegate.h"
#include "flutter/shell/platform/android/surface/android_native_window.h"
#include "flutter/shell/platform/android/surface/android_surface.h"

namespace flutter {

class PlatformViewAndroid final : public PlatformView {
 public:
  static bool Register(JNIEnv* env);

  // Creates a PlatformViewAndroid with no rendering surface for use with
  // background execution.
  PlatformViewAndroid(PlatformView::Delegate& delegate,
                      flutter::TaskRunners task_runners,
                      std::shared_ptr<PlatformViewAndroidJNI> jni_facade);

  // Creates a PlatformViewAndroid with a rendering surface.
  PlatformViewAndroid(PlatformView::Delegate& delegate,
                      flutter::TaskRunners task_runners,
                      std::shared_ptr<PlatformViewAndroidJNI> jni_facade,
                      bool use_software_rendering);

  ~PlatformViewAndroid() override;

  void NotifyCreated(fml::RefPtr<AndroidNativeWindow> native_window);

  void NotifySurfaceWindowChanged(
      fml::RefPtr<AndroidNativeWindow> native_window);

  void NotifyChanged(const SkISize& size);

  // |PlatformView|
  void NotifyDestroyed() override;

  void DispatchPlatformMessage(JNIEnv* env,
                               std::string name,
                               jobject message_data,
                               jint message_position,
                               jint response_id);

  void DispatchEmptyPlatformMessage(JNIEnv* env,
                                    std::string name,
                                    jint response_id);

  void InvokePlatformMessageResponseCallback(JNIEnv* env,
                                             jint response_id,
                                             jobject java_response_data,
                                             jint java_response_position);

  void InvokePlatformMessageEmptyResponseCallback(JNIEnv* env,
                                                  jint response_id);

  void DispatchSemanticsAction(JNIEnv* env,
                               jint id,
                               jint action,
                               jobject args,
                               jint args_position);

  void RegisterExternalTexture(
      int64_t texture_id,
      const fml::jni::JavaObjectWeakGlobalRef& surface_texture);

 private:
  const std::shared_ptr<PlatformViewAndroidJNI> jni_facade_;

  PlatformViewAndroidDelegate platform_view_android_delegate_;

  std::unique_ptr<AndroidSurface> android_surface_;
  // We use id 0 to mean that no response is expected.
  int next_response_id_ = 1;
  std::unordered_map<int, fml::RefPtr<flutter::PlatformMessageResponse>>
      pending_responses_;

  // |PlatformView|
  void UpdateSemantics(
      flutter::SemanticsNodeUpdates update,
      flutter::CustomAccessibilityActionUpdates actions) override;

  // |PlatformView|
  void HandlePlatformMessage(
      fml::RefPtr<flutter::PlatformMessage> message) override;

  // |PlatformView|
  void OnPreEngineRestart() const override;

  // |PlatformView|
  std::unique_ptr<VsyncWaiter> CreateVSyncWaiter() override;

  // |PlatformView|
  std::unique_ptr<Surface> CreateRenderingSurface() override;

  // |PlatformView|
  sk_sp<GrDirectContext> CreateResourceContext() const override;

  // |PlatformView|
  void ReleaseResourceContext() const override;

  // |PlatformView|
  std::unique_ptr<std::vector<std::string>> ComputePlatformResolvedLocales(
      const std::vector<std::string>& supported_locale_data) override;

  void InstallFirstFrameCallback();

  void FireFirstFrameCallback();

  FML_DISALLOW_COPY_AND_ASSIGN(PlatformViewAndroid);
};
}  // namespace flutter

#endif  // SHELL_PLATFORM_ANDROID_PLATFORM_VIEW_ANDROID_H_
