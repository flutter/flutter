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
#include "flutter/shell/platform/android/context/android_context.h"
#include "flutter/shell/platform/android/jni/platform_view_android_jni.h"
#include "flutter/shell/platform/android/platform_message_handler_android.h"
#include "flutter/shell/platform/android/surface/android_native_window.h"
#include "flutter/shell/platform/android/surface/android_surface.h"
#include "flutter/shell/platform/embedder/platform_view_embedder.h"
#include "shell/platform/android/image_external_texture.h"

namespace flutter {

class AndroidSurfaceFactoryImpl : public AndroidSurfaceFactory {
 public:
  AndroidSurfaceFactoryImpl(const std::shared_ptr<AndroidContext>& context,
                            bool enable_impeller,
                            bool lazy_shader_mode);

  ~AndroidSurfaceFactoryImpl() override;

  std::unique_ptr<AndroidSurface> CreateSurface() override;

 private:
  const std::shared_ptr<AndroidContext>& android_context_;
  const bool enable_impeller_;
  const bool lazy_shader_mode_;
};

// Renders on its own (Android surfaces and contexts) and takes the remaining
// platform callbacks from the PlatformViewEmbedder dispatch table. An override
// that is deleted falls back to the embedder API callback for it, which the
// holder puts in the table.
class PlatformViewAndroid final : public PlatformViewEmbedder {
 public:
  static bool Register(JNIEnv* env);

  PlatformViewAndroid(PlatformView::Delegate& delegate,
                      const flutter::TaskRunners& task_runners,
                      const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade,
                      AndroidRenderingAPI rendering_api,
                      PlatformDispatchTable platform_dispatch_table);

  //----------------------------------------------------------------------------
  /// @brief      Creates a new PlatformViewAndroid but using an existing
  ///             Android GPU context to create new surfaces. This maximizes
  ///             resource sharing between 2 PlatformViewAndroids of 2 Shells.
  ///
  PlatformViewAndroid(
      PlatformView::Delegate& delegate,
      const flutter::TaskRunners& task_runners,
      const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade,
      const std::shared_ptr<flutter::AndroidContext>& android_context,
      PlatformDispatchTable platform_dispatch_table);

  ~PlatformViewAndroid() override;

  bool SetNativeWindow(fml::RefPtr<AndroidNativeWindow> native_window);

  void SwapNativeWindow(fml::RefPtr<AndroidNativeWindow> native_window);

  void ResizeSurface(const DlISize& size);

  void TeardownSurface();

  std::unique_ptr<Texture> CreateSurfaceTexture(
      int64_t texture_id,
      const fml::jni::ScopedJavaGlobalRef<jobject>& surface_texture);

  std::unique_ptr<Texture> CreateImageTexture(
      int64_t texture_id,
      const fml::jni::ScopedJavaGlobalRef<jobject>& image_texture_entry,
      ImageExternalTexture::ImageLifecycle lifecycle);

  const std::shared_ptr<AndroidContext>& GetAndroidContext() {
    return android_context_;
  }

  /// @brief Whether the SurfaceControl based swapchain is enabled and active.
  bool IsSurfaceControlEnabled() const;

 private:
  PlatformViewAndroid(
      PlatformView::Delegate& delegate,
      const flutter::TaskRunners& task_runners,
      const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade,
      const std::shared_ptr<flutter::AndroidContext>& android_context,
      std::shared_ptr<PlatformMessageHandlerAndroid> platform_message_handler,
      PlatformDispatchTable platform_dispatch_table);

  static PlatformDispatchTable WithAndroidCallbacks(
      PlatformViewAndroid* self,
      PlatformDispatchTable platform_dispatch_table,
      const std::shared_ptr<PlatformMessageHandlerAndroid>&
          platform_message_handler);

  const std::shared_ptr<PlatformViewAndroidJNI> jni_facade_;
  std::shared_ptr<AndroidContext> android_context_;
  std::shared_ptr<AndroidSurfaceFactoryImpl> surface_factory_;

  std::unique_ptr<AndroidSurface> android_surface_;
  bool android_meets_hcpp_criteria_ = false;

  std::unique_ptr<Surface> CreateAndroidRenderingSurface();

  std::shared_ptr<ExternalViewEmbedder> CreateAndroidExternalViewEmbedder();

  std::unique_ptr<SnapshotSurfaceProducer>
  CreateAndroidSnapshotSurfaceProducer();

  sk_sp<GrDirectContext> CreateAndroidResourceContext() const;

  void ReleaseAndroidResourceContext() const;

  std::shared_ptr<impeller::Context> GetAndroidImpellerContext() const;

  void SetupAndroidImpellerContext();

  FML_DISALLOW_COPY_AND_ASSIGN(PlatformViewAndroid);
};
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_PLATFORM_VIEW_ANDROID_H_
