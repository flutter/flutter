// Copyright 2018 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/embedder_surface_gl.h"

#include "flutter/shell/common/io_manager.h"

namespace shell {

EmbedderSurfaceGL::EmbedderSurfaceGL(GLDispatchTable gl_dispatch_table,
                                     bool fbo_reset_after_present)
    : gl_dispatch_table_(gl_dispatch_table),
      fbo_reset_after_present_(fbo_reset_after_present) {
  // Make sure all required members of the dispatch table are checked.
  if (!gl_dispatch_table_.gl_make_current_callback ||
      !gl_dispatch_table_.gl_clear_current_callback ||
      !gl_dispatch_table_.gl_present_callback ||
      !gl_dispatch_table_.gl_fbo_callback) {
    return;
  }

  valid_ = true;
}

EmbedderSurfaceGL::~EmbedderSurfaceGL() = default;

// |shell::EmbedderSurface|
bool EmbedderSurfaceGL::IsValid() const {
  return valid_;
}

// |shell::GPUSurfaceGLDelegate|
bool EmbedderSurfaceGL::GLContextMakeCurrent() {
  return gl_dispatch_table_.gl_make_current_callback();
}

// |shell::GPUSurfaceGLDelegate|
bool EmbedderSurfaceGL::GLContextClearCurrent() {
  return gl_dispatch_table_.gl_clear_current_callback();
}

// |shell::GPUSurfaceGLDelegate|
bool EmbedderSurfaceGL::GLContextPresent() {
  return gl_dispatch_table_.gl_present_callback();
}

// |shell::GPUSurfaceGLDelegate|
intptr_t EmbedderSurfaceGL::GLContextFBO() const {
  return gl_dispatch_table_.gl_fbo_callback();
}

// |shell::GPUSurfaceGLDelegate|
bool EmbedderSurfaceGL::GLContextFBOResetAfterPresent() const {
  return fbo_reset_after_present_;
}

// |shell::GPUSurfaceGLDelegate|
SkMatrix EmbedderSurfaceGL::GLContextSurfaceTransformation() const {
  auto callback = gl_dispatch_table_.gl_surface_transformation_callback;
  if (!callback) {
    SkMatrix matrix;
    matrix.setIdentity();
    return matrix;
  }
  return callback();
}

// |shell::GPUSurfaceGLDelegate|
EmbedderSurfaceGL::GLProcResolver EmbedderSurfaceGL::GetGLProcResolver() const {
  return gl_dispatch_table_.gl_proc_resolver;
}

// |shell::EmbedderSurface|
std::unique_ptr<Surface> EmbedderSurfaceGL::CreateGPUSurface() {
  return std::make_unique<GPUSurfaceGL>(this);
}

// |shell::EmbedderSurface|
sk_sp<GrContext> EmbedderSurfaceGL::CreateResourceContext() const {
  auto callback = gl_dispatch_table_.gl_make_resource_current_callback;
  if (callback && callback()) {
    return IOManager::CreateCompatibleResourceLoadingContext(
        GrBackend::kOpenGL_GrBackend);
  }
  return nullptr;
}

}  // namespace shell
