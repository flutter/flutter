// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_ANDROID_SURFACE_ANDROID_SURFACE_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_ANDROID_SURFACE_ANDROID_SURFACE_H_

#include <functional>
#include <memory>
#include "flutter/flow/surface.h"
#include "flutter/fml/macros.h"
#include "flutter/shell/platform/embedder/android/context/android_context.h"
#include "flutter/shell/platform/embedder/android/surface/android_native_window.h"

namespace impeller {
class Context;
}  // namespace impeller

// From <android/surface_control.h>.
struct ASurfaceTransaction;

namespace flutter {

//------------------------------------------------------------------------------
/// @brief      Returns a transaction that the Vulkan swapchain adds its frames
///             to, or null if the swapchain should create and apply its own.
///             The embedder owns and applies a transaction it returns; with
///             HCPP, that is how a frame lands together with the platform
///             view changes of the same frame. Called on the raster thread.
///
using CreateSurfaceTransaction = std::function<ASurfaceTransaction*()>;

class AndroidExternalViewEmbedder;

class AndroidSurface {
 public:
  virtual ~AndroidSurface();

  virtual bool IsValid() const = 0;

  virtual void TeardownOnScreenContext() = 0;

  virtual std::unique_ptr<Surface> CreateGPUSurface(
      GrDirectContext* gr_context = nullptr) = 0;

  virtual bool OnScreenSurfaceResize(const DlISize& size) = 0;

  virtual bool ResourceContextMakeCurrent() = 0;

  virtual bool ResourceContextClearCurrent() = 0;

  virtual bool SetNativeWindow(fml::RefPtr<AndroidNativeWindow> window) = 0;

  virtual std::unique_ptr<Surface> CreateSnapshotSurface();

  virtual std::shared_ptr<impeller::Context> GetImpellerContext();

  virtual void SetupImpellerSurface();

 protected:
  AndroidSurface();
};

class AndroidSurfaceFactory {
 public:
  AndroidSurfaceFactory() = default;

  virtual ~AndroidSurfaceFactory() = default;

  virtual std::unique_ptr<AndroidSurface> CreateSurface() = 0;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_ANDROID_SURFACE_ANDROID_SURFACE_H_
