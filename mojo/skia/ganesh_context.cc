// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/skia/ganesh_context.h"

#include "mojo/public/c/gpu/MGL/mgl.h"
#include "mojo/skia/gl_bindings_skia.h"
#include "third_party/skia/include/gpu/gl/GrGLInterface.h"

namespace mojo {
namespace {

// The limit of the number of GPU resources we hold in the GrContext's
// GPU cache.
const int kMaxGaneshResourceCacheCount = 2048;

// The limit of the bytes allocated toward GPU resources in the GrContext's
// GPU cache.
const size_t kMaxGaneshResourceCacheBytes = 96 * 1024 * 1024;

}

GaneshContext::Scope::Scope(GaneshContext* context)
    : previous_(MGLGetCurrentContext()) {
  context->gl_context_->MakeCurrent();
}

GaneshContext::Scope::~Scope() {
  MGLMakeCurrent(previous_);
}

GaneshContext::GaneshContext(base::WeakPtr<GLContext> gl_context)
    : gl_context_(gl_context) {
  DCHECK(gl_context_);
  gl_context_->AddObserver(this);
  Scope scope(this);

  skia::RefPtr<GrGLInterface> interface =
      skia::AdoptRef(skia_bindings::CreateMojoSkiaGLBinding());
  DCHECK(interface);

  context_ = skia::AdoptRef(GrContext::Create(
      kOpenGL_GrBackend, reinterpret_cast<GrBackendContext>(interface.get())));
  DCHECK(context_);
  context_->setResourceCacheLimits(kMaxGaneshResourceCacheCount,
                                   kMaxGaneshResourceCacheBytes);
}

GaneshContext::~GaneshContext() {
  if (context_) {
    Scope scope(this);
    context_.clear();
  }
  if (gl_context_.get())
    gl_context_->RemoveObserver(this);
}

bool GaneshContext::InScope() const {
  return gl_context_->IsCurrent();
}

void GaneshContext::OnContextLost() {
  context_->abandonContext();
  context_.clear();
  gl_context_.reset();
}

}  // namespace mojo
