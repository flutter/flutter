// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <utility>
#include "flutter/shell/platform/android/android_surface_gl.h"
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

AndroidSurfaceGL::AndroidSurfaceGL(AndroidNativeWindow window,
                                   PlatformView::SurfaceConfig onscreen_config,
                                   PlatformView::SurfaceConfig offscreen_config)
    : valid_(false) {
  // Acquire the offscreen context.
  offscreen_context_ = GlobalResourceLoadingContext(offscreen_config);

  if (!offscreen_context_ || !offscreen_context_->IsValid()) {
    return;
  }

  // Create the onscreen context.
  onscreen_context_ = ftl::MakeRefCounted<AndroidContextGL>(
      offscreen_context_->Environment(), std::move(window), onscreen_config,
      offscreen_context_.get() /* sharegroup */);

  if (!onscreen_context_->IsValid()) {
    return;
  }

  // All done.
  valid_ = true;
}

AndroidSurfaceGL::~AndroidSurfaceGL() = default;

bool AndroidSurfaceGL::IsValid() const {
  return valid_;
}

SkISize AndroidSurfaceGL::OnScreenSurfaceSize() const {
  FTL_DCHECK(valid_);
  return onscreen_context_->GetSize();
}

bool AndroidSurfaceGL::OnScreenSurfaceResize(const SkISize& size) const {
  FTL_DCHECK(valid_);
  return onscreen_context_->Resize(size);
}

bool AndroidSurfaceGL::GLOffscreenContextMakeCurrent() {
  FTL_DCHECK(valid_);
  return offscreen_context_->MakeCurrent();
}

bool AndroidSurfaceGL::GLContextMakeCurrent() {
  FTL_DCHECK(valid_);
  return onscreen_context_->MakeCurrent();
}

bool AndroidSurfaceGL::GLContextClearCurrent() {
  FTL_DCHECK(valid_);
  return onscreen_context_->ClearCurrent();
}

bool AndroidSurfaceGL::GLContextPresent() {
  FTL_DCHECK(valid_);
  return onscreen_context_->SwapBuffers();
}

intptr_t AndroidSurfaceGL::GLContextFBO() const {
  FTL_DCHECK(valid_);
  // The default window bound framebuffer on Android.
  return 0;
}

}  // namespace shell
