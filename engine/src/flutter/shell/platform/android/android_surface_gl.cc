// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_surface_gl.h"
#include <utility>
#include "lib/ftl/logging.h"
#include "lib/ftl/memory/ref_ptr.h"

namespace shell {

static ftl::RefPtr<AndroidContextGL> GlobalResourceLoadingContext(
    PlatformView::SurfaceConfig offscreen_config) {
  // AndroidSurfaceGL instances are only ever created on the platform thread. So
  // there is no need to lock here.

  static ftl::RefPtr<AndroidContextGL> global_context;

  if (global_context) {
    return global_context;
  }

  auto environment = ftl::MakeRefCounted<AndroidEnvironmentGL>();

  if (!environment->IsValid()) {
    return nullptr;
  }

  // TODO(chinmaygarde): We should check that the configurations are stable
  // across multiple invocations.

  auto context =
      ftl::MakeRefCounted<AndroidContextGL>(environment, offscreen_config);

  if (!context->IsValid()) {
    return nullptr;
  }

  global_context = context;
  return global_context;
}

AndroidSurfaceGL::AndroidSurfaceGL(
    PlatformView::SurfaceConfig offscreen_config) {
  // Acquire the offscreen context.
  offscreen_context_ = GlobalResourceLoadingContext(offscreen_config);

  if (!offscreen_context_ || !offscreen_context_->IsValid()) {
    offscreen_context_ = nullptr;
  }
}

AndroidSurfaceGL::~AndroidSurfaceGL() = default;

bool AndroidSurfaceGL::SetNativeWindowForOnScreenContext(
    AndroidNativeWindow window,
    PlatformView::SurfaceConfig onscreen_config) {
  // In any case, we want to get rid of our current onscreen context.
  onscreen_context_ = nullptr;

  // If the offscreen context has not been setup, we dont have the sharegroup.
  // So bail.
  if (!offscreen_context_ || !offscreen_context_->IsValid()) {
    return false;
  }

  // Create the onscreen context.
  onscreen_context_ = ftl::MakeRefCounted<AndroidContextGL>(
      offscreen_context_->Environment(), std::move(window), onscreen_config,
      offscreen_context_.get() /* sharegroup */);

  if (!onscreen_context_->IsValid()) {
    onscreen_context_ = nullptr;
    return false;
  }

  return true;
}

bool AndroidSurfaceGL::IsValid() const {
  if (!onscreen_context_ || !offscreen_context_) {
    return false;
  }

  return onscreen_context_->IsValid() && offscreen_context_->IsValid();
}

SkISize AndroidSurfaceGL::OnScreenSurfaceSize() const {
  FTL_DCHECK(onscreen_context_ && onscreen_context_->IsValid());
  return onscreen_context_->GetSize();
}

bool AndroidSurfaceGL::OnScreenSurfaceResize(const SkISize& size) const {
  FTL_DCHECK(onscreen_context_ && onscreen_context_->IsValid());
  return onscreen_context_->Resize(size);
}

bool AndroidSurfaceGL::GLOffscreenContextMakeCurrent() {
  FTL_DCHECK(offscreen_context_ && offscreen_context_->IsValid());
  return offscreen_context_->MakeCurrent();
}

bool AndroidSurfaceGL::GLContextMakeCurrent() {
  FTL_DCHECK(onscreen_context_ && onscreen_context_->IsValid());
  return onscreen_context_->MakeCurrent();
}

bool AndroidSurfaceGL::GLContextClearCurrent() {
  FTL_DCHECK(onscreen_context_ && onscreen_context_->IsValid());
  return onscreen_context_->ClearCurrent();
}

bool AndroidSurfaceGL::GLContextPresent() {
  FTL_DCHECK(onscreen_context_ && onscreen_context_->IsValid());
  return onscreen_context_->SwapBuffers();
}

intptr_t AndroidSurfaceGL::GLContextFBO() const {
  FTL_DCHECK(onscreen_context_ && onscreen_context_->IsValid());
  // The default window bound framebuffer on Android.
  return 0;
}

}  // namespace shell
