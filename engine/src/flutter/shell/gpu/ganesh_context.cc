// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/gpu/ganesh_context.h"

#include "base/logging.h"
#include "third_party/skia/include/gpu/gl/GrGLInterface.h"
#include "ui/gl/gl_bindings_skia_in_process.h"

namespace sky {
namespace shell {
namespace {

// The limit of the number of GPU resources we hold in the GrContext's
// GPU cache.
const int kMaxGaneshResourceCacheCount = 2048;

// The limit of the bytes allocated toward GPU resources in the GrContext's
// GPU cache.
const size_t kMaxGaneshResourceCacheBytes = 96 * 1024 * 1024;

}  // namespace

GaneshContext::GaneshContext(scoped_refptr<gfx::GLContext> gl_context)
    : gl_context_(gl_context) {
  skia::RefPtr<GrGLInterface> interface =
      skia::AdoptRef(gfx::CreateInProcessSkiaGLBinding());
  DCHECK(interface);

  gr_context_ = skia::AdoptRef(GrContext::Create(
      kOpenGL_GrBackend, reinterpret_cast<GrBackendContext>(interface.get())));
  DCHECK(gr_context_) << "Failed to create GrContext.";
  gr_context_->setResourceCacheLimits(kMaxGaneshResourceCacheCount,
                                      kMaxGaneshResourceCacheBytes);
}

GaneshContext::~GaneshContext() {
}

}  // namespace shell
}  // namespace sky
