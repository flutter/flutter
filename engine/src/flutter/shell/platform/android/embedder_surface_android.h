// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_EMBEDDER_SURFACE_ANDROID_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_EMBEDDER_SURFACE_ANDROID_H_

#include "flutter/fml/macros.h"
#include "flutter/shell/common/platform_view.h"
#include "flutter/shell/platform/android/context/android_context.h"
#include "flutter/shell/platform/android/surface/android_native_window.h"
#include "flutter/shell/platform/android/surface/android_surface.h"
#include "flutter/shell/platform/embedder/embedder_surface.h"

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

class EmbedderSurfaceAndroid final : public EmbedderSurface {
 public:
  EmbedderSurfaceAndroid(
      const std::shared_ptr<flutter::AndroidContext>& android_context,
      PlatformView::Delegate& delegate);

  ~EmbedderSurfaceAndroid() override;

  // |EmbedderSurface|
  bool IsValid() const override;

  // |EmbedderSurface|
  std::unique_ptr<Surface> CreateGPUSurface() override;

  // |EmbedderSurface|
  sk_sp<GrDirectContext> CreateResourceContext() const override;

  void ReleaseResourceContext() const;

  // |EmbedderSurface|
  std::shared_ptr<impeller::Context> CreateImpellerContext() const override;

  void NotifyCreated(fml::RefPtr<AndroidNativeWindow> native_window,
                     const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade);

  void NotifySurfaceWindowChanged(
      fml::RefPtr<AndroidNativeWindow> native_window,
      const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade);

  void NotifyChanged(const DlISize& size);

  void NotifyDestroyed();

  void TeardownOnScreenContext();

  void SetupImpellerContext();

  AndroidSurface* GetAndroidSurface() const;

  std::shared_ptr<AndroidSurfaceFactory> GetAndroidSurfaceFactory() const {
    return surface_factory_;
  }

 private:
  std::shared_ptr<flutter::AndroidContext> android_context_;
  std::shared_ptr<AndroidSurfaceFactoryImpl> surface_factory_;
  std::unique_ptr<AndroidSurface> android_surface_;

  FML_DISALLOW_COPY_AND_ASSIGN(EmbedderSurfaceAndroid);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_EMBEDDER_SURFACE_ANDROID_H_
