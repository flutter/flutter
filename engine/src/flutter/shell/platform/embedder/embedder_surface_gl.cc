// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/embedder_surface_gl.h"

#include "flutter/shell/common/shell_io_manager.h"

namespace flutter {

EmbedderSurfaceGL::EmbedderSurfaceGL(
    GLDispatchTable gl_dispatch_table,
    bool fbo_reset_after_present,
    std::unique_ptr<EmbedderExternalViewEmbedder> external_view_embedder)
    : gl_dispatch_table_(gl_dispatch_table),
      fbo_reset_after_present_(fbo_reset_after_present),
      external_view_embedder_(std::move(external_view_embedder)) {
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

// |EmbedderSurface|
bool EmbedderSurfaceGL::IsValid() const {
  return valid_;
}

// |GPUSurfaceGLDelegate|
std::unique_ptr<GLContextResult> EmbedderSurfaceGL::GLContextMakeCurrent() {
  return std::make_unique<GLContextDefaultResult>(
      gl_dispatch_table_.gl_make_current_callback());
}

// |GPUSurfaceGLDelegate|
bool EmbedderSurfaceGL::GLContextClearCurrent() {
  return gl_dispatch_table_.gl_clear_current_callback();
}

// |GPUSurfaceGLDelegate|
bool EmbedderSurfaceGL::GLContextPresent() {
  return gl_dispatch_table_.gl_present_callback();
}

// |GPUSurfaceGLDelegate|
intptr_t EmbedderSurfaceGL::GLContextFBO() const {
  return gl_dispatch_table_.gl_fbo_callback();
}

// |GPUSurfaceGLDelegate|
bool EmbedderSurfaceGL::GLContextFBOResetAfterPresent() const {
  return fbo_reset_after_present_;
}

// |GPUSurfaceGLDelegate|
SkMatrix EmbedderSurfaceGL::GLContextSurfaceTransformation() const {
  auto callback = gl_dispatch_table_.gl_surface_transformation_callback;
  if (!callback) {
    SkMatrix matrix;
    matrix.setIdentity();
    return matrix;
  }
  return callback();
}

// |GPUSurfaceGLDelegate|
ExternalViewEmbedder* EmbedderSurfaceGL::GetExternalViewEmbedder() {
  return external_view_embedder_.get();
}

// |GPUSurfaceGLDelegate|
EmbedderSurfaceGL::GLProcResolver EmbedderSurfaceGL::GetGLProcResolver() const {
  return gl_dispatch_table_.gl_proc_resolver;
}

// |EmbedderSurface|
std::unique_ptr<Surface> EmbedderSurfaceGL::CreateGPUSurface() {
  const bool render_to_surface = !external_view_embedder_;
  return std::make_unique<GPUSurfaceGL>(this,  // GPU surface GL delegate
                                        render_to_surface  // render to surface

  );
}

// |EmbedderSurface|
sk_sp<GrDirectContext> EmbedderSurfaceGL::CreateResourceContext() const {
  auto callback = gl_dispatch_table_.gl_make_resource_current_callback;
  if (callback && callback()) {
    if (auto context = ShellIOManager::CreateCompatibleResourceLoadingContext(
            GrBackend::kOpenGL_GrBackend, GetGLInterface())) {
      return context;
    } else {
      FML_LOG(ERROR)
          << "Internal error: Resource context available but could not create "
             "a compatible Skia context.";
      return nullptr;
    }
  }

  // The callback was not available or failed.
  FML_LOG(ERROR)
      << "Could not create a resource context for async texture uploads. "
         "Expect degraded performance. Set a valid make_resource_current "
         "callback on FlutterOpenGLRendererConfig.";
  return nullptr;
}

}  // namespace flutter
