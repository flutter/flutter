// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/skia/ganesh_context.h"

#include "gpu/command_buffer/client/gles2_lib.h"
#include "gpu/skia_bindings/gl_bindings_skia_cmd_buffer.h"
#include "third_party/skia/include/gpu/gl/GrGLInterface.h"

namespace mojo {
namespace {

// The limit of the number of GPU resources we hold in the GrContext's
// GPU cache.
const int kMaxGaneshResourceCacheCount = 2048;

// The limit of the bytes allocated toward GPU resources in the GrContext's
// GPU cache.
const size_t kMaxGaneshResourceCacheBytes = 96 * 1024 * 1024;

void EnsureInitialized() {
  static bool initialized;
  if (initialized)
    return;
  gles2::Initialize();
  initialized = true;
}
}

GaneshContext::Scope::Scope(GaneshContext* context)
    : previous_(gles2::GetGLContext()) {
  auto gl = context->gl_context_->gl();
  DCHECK(gl);
  gles2::SetGLContext(gl);
  DCHECK(gles2::GetGLContext());
}

GaneshContext::Scope::~Scope() {
  gles2::SetGLContext(previous_);
}

GaneshContext::GaneshContext(base::WeakPtr<GLContext> gl_context)
    : gl_context_(gl_context) {
  EnsureInitialized();

  DCHECK(gl_context_);
  gl_context_->AddObserver(this);
  Scope scope(this);

  skia::RefPtr<GrGLInterface> interface =
      skia::AdoptRef(skia_bindings::CreateCommandBufferSkiaGLBinding());
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
  return gles2::GetGLContext() == gl_context_->gl();
}

void GaneshContext::OnContextLost() {
  context_->abandonContext();
  context_.clear();
  gl_context_.reset();
}

}  // namespace mojo
