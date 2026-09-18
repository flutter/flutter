// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_EMBEDDER_SURFACE_ANDROID_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_EMBEDDER_SURFACE_ANDROID_H_

#include <memory>

#include "flutter/fml/macros.h"
#include "flutter/shell/common/platform_view.h"
#include "flutter/shell/platform/android/context/android_context.h"
#include "flutter/shell/platform/android/jni/platform_view_android_jni.h"
#include "flutter/shell/platform/android/surface/android_native_window.h"
#include "flutter/shell/platform/android/surface/android_surface.h"
#include "flutter/shell/platform/embedder/embedder_surface.h"

namespace flutter {

class AndroidSurfaceFactoryImpl : public AndroidSurfaceFactory {
 public:
  AndroidSurfaceFactoryImpl(std::shared_ptr<AndroidContext> context,
                            bool enable_impeller,
                            bool lazy_shader_mode);

  ~AndroidSurfaceFactoryImpl() override;

  std::unique_ptr<AndroidSurface> CreateSurface() override;

 private:
  std::shared_ptr<AndroidContext> android_context_;
  const bool enable_impeller_;
  const bool lazy_shader_mode_;
};

class EmbedderSurfaceAndroid final : public EmbedderSurface {
 public:
  EmbedderSurfaceAndroid(
      std::shared_ptr<flutter::AndroidContext> android_context,
      bool enable_impeller,
      bool lazy_shader_mode,
      std::shared_ptr<PlatformViewAndroidJNI> jni_facade,
      const flutter::TaskRunners& task_runners,
      bool android_meets_hcpp_criteria);

  EmbedderSurfaceAndroid(
      const std::shared_ptr<flutter::AndroidContext>& android_context,
      PlatformView::Delegate& delegate,
      const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade,
      const flutter::TaskRunners& task_runners,
      bool android_meets_hcpp_criteria);

  ~EmbedderSurfaceAndroid() override;

  // |EmbedderSurface|
  bool IsValid() const override;

  // |EmbedderSurface|
  std::unique_ptr<Surface> CreateGPUSurface() override;

  // |EmbedderSurface|
  sk_sp<GrDirectContext> CreateResourceContext() const override;

  // |EmbedderSurface|
  void ReleaseResourceContext() const override;

  // |EmbedderSurface|
  std::shared_ptr<impeller::Context> CreateImpellerContext() const override;

  // |EmbedderSurface|
  void SetupImpellerContext() override;

  // |EmbedderSurface|
  std::shared_ptr<ExternalViewEmbedder> CreateExternalViewEmbedder() override;

  // |EmbedderSurface|
  std::unique_ptr<SnapshotSurfaceProducer> CreateSnapshotSurfaceProducer()
      override;

  void NotifyCreated(fml::RefPtr<AndroidNativeWindow> native_window,
                     const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade);

  void NotifySurfaceWindowChanged(
      fml::RefPtr<AndroidNativeWindow> native_window,
      const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade);

  void NotifyChanged(const DlISize& size);

  void TeardownOnScreenContext();

  AndroidSurface* GetAndroidSurface() const;

  std::shared_ptr<AndroidSurfaceFactory> GetAndroidSurfaceFactory() const {
    return surface_factory_;
  }

 private:
  std::shared_ptr<flutter::AndroidContext> android_context_;
  std::shared_ptr<PlatformViewAndroidJNI> jni_facade_;
  std::shared_ptr<AndroidSurfaceFactoryImpl> surface_factory_;
  std::unique_ptr<AndroidSurface> android_surface_;
  flutter::TaskRunners task_runners_;
  bool android_meets_hcpp_criteria_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(EmbedderSurfaceAndroid);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_EMBEDDER_SURFACE_ANDROID_H_
