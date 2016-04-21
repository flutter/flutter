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

GaneshContext::GaneshContext(const scoped_refptr<GLContext>& gl_context)
    : gl_context_(gl_context) {
  DCHECK(gl_context_);
  if (is_lost())
    return;

  gl_context_->AddObserver(this);

  GLContext::Scope gl_scope(gl_context_);
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
  DCHECK(!scope_entered_);
  if (!gr_context_)
    return;

  gl_context_->RemoveObserver(this);
  if (is_lost()) {
    gr_context_->abandonContext();
  } else {
    // TODO(jeffbrown): Current versions of Skia offer a function to release
    // and abandon the context.  Enable this after rolling Skia.
    // GLContext::Scope gl_scope(gl_context_);
    // gr_context_->releaseResourcesAndAbandonContext();
    gr_context_->abandonContext();
  }
}

void GaneshContext::OnContextLost() {
  DCHECK(gr_context_);
  DCHECK(is_lost());

  gl_context_->RemoveObserver(this);
  if (!scope_entered_) {
    gr_context_->abandonContext();
    gr_context_.clear();
  }
}

GaneshContext::Scope::Scope(const scoped_refptr<GaneshContext>& ganesh_context)
    : ganesh_context_(ganesh_context), gl_scope_(ganesh_context->gl_context_) {
  DCHECK(!ganesh_context_->scope_entered_);
  DCHECK(ganesh_context_->gr_context_);
  DCHECK(!ganesh_context_->is_lost());

  // Do this first to avoid potential reentrance if the context is lost.
  ganesh_context_->scope_entered_ = true;

  // Reset the Ganesh context when entering its scope in case the caller
  // performed GL operations which might interfere with Ganesh's cached state.
  ganesh_context_->gr_context_->resetContext();
}

GaneshContext::Scope::~Scope() {
  DCHECK(ganesh_context_->scope_entered_);
  DCHECK(ganesh_context_->gr_context_);

  // Flush the Ganesh context when exiting its scope to ensure all pending
  // operations have been applied to the GL context.
  if (!ganesh_context_->is_lost()) {
    ganesh_context_->gr_context_->flush();
  }

  // Abandon the Ganesh context if lost while inside the scope or while
  // flushing it above.
  if (ganesh_context_->is_lost()) {
    ganesh_context_->gr_context_->abandonContext();
    ganesh_context_->gr_context_.clear();
  }

  // Do this last to avoid potential reentrance if the context is lost.
  ganesh_context_->scope_entered_ = false;
}

}  // namespace skia
}  // namespace mojo
