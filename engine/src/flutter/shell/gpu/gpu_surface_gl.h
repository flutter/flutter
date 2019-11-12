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
#include "flutter/shell/gpu/gpu_surface_gl_delegate.h"
#include "third_party/skia/include/gpu/GrContext.h"

namespace flutter {

class GPUSurfaceGL : public Surface {
 public:
  GPUSurfaceGL(GPUSurfaceGLDelegate* delegate, bool render_to_surface);

  // Creates a new GL surface reusing an existing GrContext.
  GPUSurfaceGL(sk_sp<GrContext> gr_context,
               GPUSurfaceGLDelegate* delegate,
               bool render_to_surface);

  ~GPUSurfaceGL() override;

  // |Surface|
  bool IsValid() override;

  // |Surface|
  std::unique_ptr<SurfaceFrame> AcquireFrame(const SkISize& size) override;

  // |Surface|
  SkMatrix GetRootTransformation() const override;

  // |Surface|
  GrContext* GetContext() override;

  // |Surface|
  flutter::ExternalViewEmbedder* GetExternalViewEmbedder() override;

  // |Surface|
  bool MakeRenderContextCurrent() override;

 private:
  GPUSurfaceGLDelegate* delegate_;
  sk_sp<GrContext> context_;
  sk_sp<SkSurface> onscreen_surface_;
  sk_sp<SkSurface> offscreen_surface_;
  bool context_owner_;
  // TODO(38466): Refactor GPU surface APIs take into account the fact that an
  // external view embedder may want to render to the root surface. This is a
  // hack to make avoid allocating resources for the root surface when an
  // external view embedder is present.
  const bool render_to_surface_;
  bool valid_ = false;
  fml::WeakPtrFactory<GPUSurfaceGL> weak_factory_;

  bool CreateOrUpdateSurfaces(const SkISize& size);

  sk_sp<SkSurface> AcquireRenderSurface(
      const SkISize& untransformed_size,
      const SkMatrix& root_surface_transformation);

  bool PresentSurface(SkCanvas* canvas);

  FML_DISALLOW_COPY_AND_ASSIGN(GPUSurfaceGL);
};

}  // namespace flutter

#endif  // SHELL_GPU_GPU_SURFACE_GL_H_
