// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_surface_gl_impeller.h"

#if defined(__ANDROID__)
#include <sys/system_properties.h>
#endif

#include "flutter/common/graphics/gl_context_switch.h"
#include "flutter/fml/logging.h"
#include "flutter/impeller/toolkit/egl/surface.h"
#include "flutter/shell/gpu/gpu_surface_gl_impeller.h"

namespace flutter {

namespace {

bool ShouldClearContextBetweenFrames() {
#if defined(__ANDROID__)
  auto is_bad_platform = [](const char* name) -> bool {
    char value[PROP_VALUE_MAX];
    if (__system_property_get(name, value) > 0) {
      std::string_view platform(value);
      if (platform.starts_with("mt6762") || platform.starts_with("mt6765") ||
          platform.starts_with("MT6762") || platform.starts_with("MT6765")) {
        return true;
      }
    }
    return false;
  };

  return is_bad_platform("ro.board.platform") ||
         is_bad_platform("ro.vendor.mediatek.platform");
#else
  return false;
#endif
}

class AndroidSwitchableGLContextImpeller : public SwitchableGLContext {
 public:
  explicit AndroidSwitchableGLContextImpeller(
      std::shared_ptr<AndroidContextGLImpeller> android_context)
      : android_context_(std::move(android_context)) {}

  bool SetCurrent() override { return true; }

  bool RemoveCurrent() override {
    if (auto context = android_context_.lock()) {
      return context->OnscreenContextClearCurrent();
    }
    return false;
  }

 private:
  std::weak_ptr<AndroidContextGLImpeller> android_context_;
};

}  // namespace

AndroidSurfaceGLImpeller::AndroidSurfaceGLImpeller(
    const std::shared_ptr<AndroidContextGLImpeller>& android_context)
    : android_context_(android_context) {
  offscreen_surface_ = android_context_->CreateOffscreenSurface();

  if (!offscreen_surface_) {
    FML_DLOG(ERROR) << "Could not create offscreen surface.";
    return;
  }

  // The onscreen surface will be acquired once the native window is set.

  is_valid_ = true;
}

AndroidSurfaceGLImpeller::~AndroidSurfaceGLImpeller() = default;

// |AndroidSurface|
bool AndroidSurfaceGLImpeller::IsValid() const {
  return is_valid_;
}

// |AndroidSurface|
std::unique_ptr<Surface> AndroidSurfaceGLImpeller::CreateGPUSurface(
    GrDirectContext* gr_context) {
  auto surface = std::make_unique<GPUSurfaceGLImpeller>(
      this,                                    // delegate
      android_context_->GetImpellerContext(),  // context
      true                                     // render to surface
  );
  if (!surface->IsValid()) {
    return nullptr;
  }
  return surface;
}

// |AndroidSurface|
void AndroidSurfaceGLImpeller::TeardownOnScreenContext() {
  GLContextClearCurrent();
  onscreen_surface_.reset();
}

// |AndroidSurface|
bool AndroidSurfaceGLImpeller::OnScreenSurfaceResize(const DlISize& size) {
  // The size is unused. It was added only for iOS where the sizes were
  // necessary to re-create auxiliary buffers (stencil, depth, etc.).
  return RecreateOnscreenSurfaceAndMakeOnscreenContextCurrent();
}

// |AndroidSurface|
bool AndroidSurfaceGLImpeller::ResourceContextMakeCurrent() {
  if (!offscreen_surface_) {
    return false;
  }
  return android_context_->ResourceContextMakeCurrent(offscreen_surface_.get());
}

// |AndroidSurface|
bool AndroidSurfaceGLImpeller::ResourceContextClearCurrent() {
  return android_context_->ResourceContextClearCurrent();
}

// |AndroidSurface|
bool AndroidSurfaceGLImpeller::SetNativeWindow(
    fml::RefPtr<AndroidNativeWindow> window,
    const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade) {
  native_window_ = std::move(window);
  return RecreateOnscreenSurfaceAndMakeOnscreenContextCurrent();
}

// |AndroidSurface|
std::unique_ptr<Surface> AndroidSurfaceGLImpeller::CreateSnapshotSurface() {
  if (!onscreen_surface_ || !onscreen_surface_->IsValid()) {
    onscreen_surface_ = android_context_->CreateOffscreenSurface();
    if (!onscreen_surface_) {
      FML_DLOG(ERROR) << "Could not create offscreen surface for snapshot.";
      return nullptr;
    }
  }
  // Make the snapshot surface current because constucting a
  // GPUSurfaceGLImpeller and its AiksContext may invoke graphics APIs.
  if (!android_context_->OnscreenContextMakeCurrent(onscreen_surface_.get())) {
    FML_DLOG(ERROR) << "Could not make snapshot surface current.";
    return nullptr;
  }
  return std::make_unique<GPUSurfaceGLImpeller>(
      this,                                    // delegate
      android_context_->GetImpellerContext(),  // context
      true                                     // render to surface
  );
}

// |AndroidSurface|
std::shared_ptr<impeller::Context>
AndroidSurfaceGLImpeller::GetImpellerContext() {
  return android_context_->GetImpellerContext();
}

// |GPUSurfaceGLDelegate|
std::unique_ptr<GLContextResult>
AndroidSurfaceGLImpeller::GLContextMakeCurrent() {
  bool success = OnGLContextMakeCurrent();
  if (!success) {
    return std::make_unique<GLContextDefaultResult>(false);
  }
  if (ShouldClearContextBetweenFrames()) {
    return std::make_unique<GLContextSwitch>(
        std::make_unique<AndroidSwitchableGLContextImpeller>(android_context_));
  }
  return std::make_unique<GLContextDefaultResult>(true);
}

bool AndroidSurfaceGLImpeller::OnGLContextMakeCurrent() {
  if (!onscreen_surface_) {
    return false;
  }

  return android_context_->OnscreenContextMakeCurrent(onscreen_surface_.get());
}

// |GPUSurfaceGLDelegate|
bool AndroidSurfaceGLImpeller::GLContextClearCurrent() {
  if (!onscreen_surface_) {
    return false;
  }

  return android_context_->OnscreenContextClearCurrent();
}

// |GPUSurfaceGLDelegate|
SurfaceFrame::FramebufferInfo
AndroidSurfaceGLImpeller::GLContextFramebufferInfo() const {
  auto info = SurfaceFrame::FramebufferInfo{};
  info.supports_readback = true;
  info.supports_partial_repaint = false;
  return info;
}

// |GPUSurfaceGLDelegate|
void AndroidSurfaceGLImpeller::GLContextSetDamageRegion(
    const std::optional<DlIRect>& region) {
  // Not supported.
}

// |GPUSurfaceGLDelegate|
bool AndroidSurfaceGLImpeller::GLContextPresent(
    const GLPresentInfo& present_info) {
  // The FBO ID is superfluous and was introduced for iOS where the default
  // framebuffer was not FBO0.
  if (!onscreen_surface_) {
    return false;
  }
  return onscreen_surface_->Present();
}

// |GPUSurfaceGLDelegate|
GLFBOInfo AndroidSurfaceGLImpeller::GLContextFBO(GLFrameInfo frame_info) const {
  // FBO0 is the default window bound framebuffer in EGL environments.
  return GLFBOInfo{
      .fbo_id = 0,
  };
}

// |GPUSurfaceGLDelegate|
sk_sp<const GrGLInterface> AndroidSurfaceGLImpeller::GetGLInterface() const {
  return nullptr;
}

bool AndroidSurfaceGLImpeller::
    RecreateOnscreenSurfaceAndMakeOnscreenContextCurrent() {
  GLContextClearCurrent();
  if (!native_window_) {
    return false;
  }
  onscreen_surface_.reset();
  auto onscreen_surface =
      android_context_->CreateOnscreenSurface(native_window_->handle());
  if (!onscreen_surface) {
    FML_DLOG(ERROR) << "Could not create onscreen surface.";
    return false;
  }
  onscreen_surface_ = std::move(onscreen_surface);
  return OnGLContextMakeCurrent();
}

}  // namespace flutter
