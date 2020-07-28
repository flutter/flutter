// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_surface_gl.h"

#include <utility>

#include "flutter/fml/logging.h"
#include "flutter/fml/memory/ref_ptr.h"
#include "flutter/shell/platform/android/android_shell_holder.h"

namespace flutter {

AndroidSurfaceGL::AndroidSurfaceGL(
    std::shared_ptr<AndroidContext> android_context,
    std::shared_ptr<PlatformViewAndroidJNI> jni_facade,
    const AndroidSurface::Factory& surface_factory)
    : external_view_embedder_(
          std::make_unique<AndroidExternalViewEmbedder>(android_context,
                                                        jni_facade,
                                                        surface_factory)),
      android_context_(
          std::static_pointer_cast<AndroidContextGL>(android_context)),
      native_window_(nullptr),
      onscreen_surface_(nullptr),
      offscreen_surface_(nullptr) {
  // Acquire the offscreen surface.
  offscreen_surface_ = android_context_->CreateOffscreenSurface();
  if (!offscreen_surface_->IsValid()) {
    offscreen_surface_ = nullptr;
  }
}

AndroidSurfaceGL::~AndroidSurfaceGL() = default;

void AndroidSurfaceGL::TeardownOnScreenContext() {
  android_context_->ClearCurrent();
}

bool AndroidSurfaceGL::IsValid() const {
  return offscreen_surface_ && android_context_->IsValid();
}

std::unique_ptr<Surface> AndroidSurfaceGL::CreateGPUSurface(
    GrDirectContext* gr_context) {
  if (gr_context) {
    return std::make_unique<GPUSurfaceGL>(sk_ref_sp(gr_context), this, true);
  }
  return std::make_unique<GPUSurfaceGL>(this, true);
}

bool AndroidSurfaceGL::OnScreenSurfaceResize(const SkISize& size) {
  FML_DCHECK(IsValid());
  FML_DCHECK(onscreen_surface_);
  FML_DCHECK(native_window_);

  if (size == onscreen_surface_->GetSize()) {
    return true;
  }

  android_context_->ClearCurrent();

  // Ensure the destructor is called since it destroys the `EGLSurface` before
  // creating a new onscreen surface.
  onscreen_surface_ = nullptr;
  onscreen_surface_ = android_context_->CreateOnscreenSurface(native_window_);
  if (!onscreen_surface_->IsValid()) {
    FML_LOG(ERROR) << "Unable to create EGL window surface on resize.";
    return false;
  }
  onscreen_surface_->MakeCurrent();
  return true;
}

bool AndroidSurfaceGL::ResourceContextMakeCurrent() {
  FML_DCHECK(IsValid());
  return offscreen_surface_->MakeCurrent();
}

bool AndroidSurfaceGL::ResourceContextClearCurrent() {
  FML_DCHECK(IsValid());
  return android_context_->ClearCurrent();
}

bool AndroidSurfaceGL::SetNativeWindow(
    fml::RefPtr<AndroidNativeWindow> window) {
  FML_DCHECK(IsValid());
  FML_DCHECK(window);
  native_window_ = window;
  // Create the onscreen surface.
  onscreen_surface_ = android_context_->CreateOnscreenSurface(window);
  if (!onscreen_surface_->IsValid()) {
    return false;
  }
  return true;
}

std::unique_ptr<GLContextResult> AndroidSurfaceGL::GLContextMakeCurrent() {
  FML_DCHECK(IsValid());
  FML_DCHECK(onscreen_surface_);
  auto default_context_result = std::make_unique<GLContextDefaultResult>(
      onscreen_surface_->MakeCurrent());
  return std::move(default_context_result);
}

bool AndroidSurfaceGL::GLContextClearCurrent() {
  FML_DCHECK(IsValid());
  return android_context_->ClearCurrent();
}

bool AndroidSurfaceGL::GLContextPresent() {
  FML_DCHECK(IsValid());
  FML_DCHECK(onscreen_surface_);
  return onscreen_surface_->SwapBuffers();
}

intptr_t AndroidSurfaceGL::GLContextFBO() const {
  FML_DCHECK(IsValid());
  // The default window bound framebuffer on Android.
  return 0;
}

// |GPUSurfaceGLDelegate|
ExternalViewEmbedder* AndroidSurfaceGL::GetExternalViewEmbedder() {
  if (!AndroidShellHolder::use_embedded_view) {
    return nullptr;
  }
  return external_view_embedder_.get();
}

}  // namespace flutter
