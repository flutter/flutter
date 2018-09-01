// Copyright 2018 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_SURFACE_GL_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_SURFACE_GL_H_

#include "flutter/fml/macros.h"
#include "flutter/shell/gpu/gpu_surface_gl.h"
#include "flutter/shell/platform/embedder/embedder_surface.h"

namespace shell {

class EmbedderSurfaceGL final : public EmbedderSurface,
                                public GPUSurfaceGLDelegate {
 public:
  struct GLDispatchTable {
    std::function<bool(void)> gl_make_current_callback;           // required
    std::function<bool(void)> gl_clear_current_callback;          // required
    std::function<bool(void)> gl_present_callback;                // required
    std::function<intptr_t(void)> gl_fbo_callback;                // required
    std::function<bool(void)> gl_make_resource_current_callback;  // optional
    std::function<SkMatrix(void)>
        gl_surface_transformation_callback;  // optional
  };

  EmbedderSurfaceGL(GLDispatchTable gl_dispatch_table,
                    bool fbo_reset_after_present);

  ~EmbedderSurfaceGL() override;

 private:
  bool valid_ = false;
  GLDispatchTable gl_dispatch_table_;
  bool fbo_reset_after_present_;

  // |shell::EmbedderSurface|
  bool IsValid() const override;

  // |shell::EmbedderSurface|
  std::unique_ptr<Surface> CreateGPUSurface() override;

  // |shell::EmbedderSurface|
  sk_sp<GrContext> CreateResourceContext() const override;

  // |shell::GPUSurfaceGLDelegate|
  bool GLContextMakeCurrent() override;

  // |shell::GPUSurfaceGLDelegate|
  bool GLContextClearCurrent() override;

  // |shell::GPUSurfaceGLDelegate|
  bool GLContextPresent() override;

  // |shell::GPUSurfaceGLDelegate|
  intptr_t GLContextFBO() const override;

  // |shell::GPUSurfaceGLDelegate|
  bool GLContextFBOResetAfterPresent() const override;

  // |shell::GPUSurfaceGLDelegate|
  SkMatrix GLContextSurfaceTransformation() const override;

  FML_DISALLOW_COPY_AND_ASSIGN(EmbedderSurfaceGL);
};

}  // namespace shell

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_SURFACE_GL_H_
