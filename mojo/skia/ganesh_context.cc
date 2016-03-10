// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/skia/ganesh_context.h"

#include "mojo/public/c/gpu/MGL/mgl.h"
#include "mojo/skia/gl_bindings_skia.h"
#include "third_party/skia/include/gpu/gl/GrGLInterface.h"

namespace mojo {
namespace skia {

// The limit of the number of GPU resources we hold in the GrContext's
// GPU cache.
constexpr int kMaxGaneshResourceCacheCount = 2048;

// The limit of the bytes allocated toward GPU resources in the GrContext's
// GPU cache.
constexpr size_t kMaxGaneshResourceCacheBytes = 96 * 1024 * 1024;

GaneshContext::GaneshContext(base::WeakPtr<GLContext> gl_context)
    : gl_context_(gl_context) {
  DCHECK(gl_context_);
  gl_context_->AddObserver(this);

  Scope scope(this);

  ::skia::RefPtr<GrGLInterface> interface =
      ::skia::AdoptRef(CreateMojoSkiaGLBinding());
  DCHECK(interface);

  gr_context_ = ::skia::AdoptRef(GrContext::Create(
      kOpenGL_GrBackend, reinterpret_cast<GrBackendContext>(interface.get())));
  DCHECK(gr_context_);

  gr_context_->setResourceCacheLimits(kMaxGaneshResourceCacheCount,
                                      kMaxGaneshResourceCacheBytes);
}

GaneshContext::~GaneshContext() {
  if (gl_context_)
    gl_context_->RemoveObserver(this);

  ReleaseContext();
}

void GaneshContext::OnContextLost() {
  context_lost_ = true;
  if (!scope_entered_)
    ReleaseContext();
}

void GaneshContext::ReleaseContext() {
  Scope(this);
  gr_context_->abandonContext();
  gr_context_.clear();
  gl_context_.reset();
}

void GaneshContext::EnterScope() {
  CHECK(!scope_entered_);
  scope_entered_ = true;

  if (gl_context_) {
    previous_mgl_context_ = MGLGetCurrentContext();
    gl_context_->MakeCurrent();

    // Reset the Ganesh context when entering its scope in case the caller
    // performed low-level GL operations which might interfere with Ganesh's
    // state expectations.
    if (gr_context_)
      gr_context_->resetContext();
  }
}

void GaneshContext::ExitScope() {
  CHECK(scope_entered_);
  scope_entered_ = false;

  if (gl_context_) {
    // Flush the Ganesh context when exiting its scope.
    if (gr_context_)
      gr_context_->flush();

    MGLMakeCurrent(previous_mgl_context_);
    previous_mgl_context_ = MGL_NO_CONTEXT;

    if (context_lost_)
      ReleaseContext();
  }
}

}  // namespace skia
}  // namespace mojo
