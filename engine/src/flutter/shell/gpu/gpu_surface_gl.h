// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_GPU_GPU_SURFACE_GL_H_
#define SHELL_GPU_GPU_SURFACE_GL_H_

#include <functional>
#include <memory>

#include "flutter/flow/embedded_views.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/shell/common/surface.h"
#include "third_party/skia/include/gpu/GrContext.h"

namespace shell {

class GPUSurfaceGLDelegate {
 public:
  virtual bool GLContextMakeCurrent() = 0;

  virtual bool GLContextClearCurrent() = 0;

  virtual bool GLContextPresent() = 0;

  virtual intptr_t GLContextFBO() const = 0;

  virtual bool GLContextFBOResetAfterPresent() const;

  virtual bool UseOffscreenSurface() const;

  virtual SkMatrix GLContextSurfaceTransformation() const;

  virtual flow::ExternalViewEmbedder* GetExternalViewEmbedder();

  using GLProcResolver =
      std::function<void* /* proc name */ (const char* /* proc address */)>;
  virtual GLProcResolver GetGLProcResolver() const;
};

class GPUSurfaceGL : public Surface {
 public:
  GPUSurfaceGL(GPUSurfaceGLDelegate* delegate);

  // Creates a new GL surface reusing an existing GrContext.
  GPUSurfaceGL(sk_sp<GrContext> gr_context, GPUSurfaceGLDelegate* delegate);

  ~GPUSurfaceGL() override;

  // |shell::Surface|
  bool IsValid() override;

  // |shell::Surface|
  std::unique_ptr<SurfaceFrame> AcquireFrame(const SkISize& size) override;

  // |shell::Surface|
  SkMatrix GetRootTransformation() const override;

  // |shell::Surface|
  GrContext* GetContext() override;

  // |shell::Surface|
  flow::ExternalViewEmbedder* GetExternalViewEmbedder() override;

  // |shell::Surface|
  bool MakeRenderContextCurrent() override;

 private:
  GPUSurfaceGLDelegate* delegate_;
  GPUSurfaceGLDelegate::GLProcResolver proc_resolver_;
  sk_sp<GrContext> context_;
  sk_sp<SkSurface> onscreen_surface_;
  sk_sp<SkSurface> offscreen_surface_;
  bool valid_ = false;
  fml::WeakPtrFactory<GPUSurfaceGL> weak_factory_;
  bool context_owner_;

  bool CreateOrUpdateSurfaces(const SkISize& size);

  sk_sp<SkSurface> AcquireRenderSurface(
      const SkISize& untransformed_size,
      const SkMatrix& root_surface_transformation);

  bool PresentSurface(SkCanvas* canvas);

  bool IsProcResolverOpenGLES();

  FML_DISALLOW_COPY_AND_ASSIGN(GPUSurfaceGL);
};

}  // namespace shell

#endif  // SHELL_GPU_GPU_SURFACE_GL_H_
