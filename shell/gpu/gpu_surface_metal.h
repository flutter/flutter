// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_GPU_GPU_SURFACE_METAL_H_
#define FLUTTER_SHELL_GPU_GPU_SURFACE_METAL_H_

#include "flutter/flow/surface.h"
#include "flutter/fml/macros.h"
#include "flutter/shell/gpu/gpu_surface_metal_delegate.h"
#include "third_party/skia/include/gpu/GrDirectContext.h"
#include "third_party/skia/include/gpu/mtl/GrMtlTypes.h"

namespace flutter {

class SK_API_AVAILABLE_CA_METAL_LAYER GPUSurfaceMetal : public Surface {
 public:
  GPUSurfaceMetal(GPUSurfaceMetalDelegate* delegate,
                  sk_sp<GrDirectContext> context,
                  bool render_to_surface = true);

  // |Surface|
  ~GPUSurfaceMetal();

  // |Surface|
  bool IsValid() override;

 private:
  const GPUSurfaceMetalDelegate* delegate_;
  const MTLRenderTargetType render_target_type_;
  GrMTLHandle next_drawable_ = nullptr;
  sk_sp<GrDirectContext> context_;
  GrDirectContext* precompiled_sksl_context_ = nullptr;
  // TODO(38466): Refactor GPU surface APIs take into account the fact that an
  // external view embedder may want to render to the root surface. This is a
  // hack to make avoid allocating resources for the root surface when an
  // external view embedder is present.
  bool render_to_surface_;

  // |Surface|
  std::unique_ptr<SurfaceFrame> AcquireFrame(const SkISize& size) override;

  // |Surface|
  SkMatrix GetRootTransformation() const override;

  // |Surface|
  GrDirectContext* GetContext() override;

  // |Surface|
  std::unique_ptr<GLContextResult> MakeRenderContextCurrent() override;

  std::unique_ptr<SurfaceFrame> AcquireFrameFromCAMetalLayer(
      const SkISize& frame_info);

  std::unique_ptr<SurfaceFrame> AcquireFrameFromMTLTexture(
      const SkISize& frame_info);

  void ReleaseUnusedDrawableIfNecessary();

  void PrecompileKnownSkSLsIfNecessary();

  FML_DISALLOW_COPY_AND_ASSIGN(GPUSurfaceMetal);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_GPU_GPU_SURFACE_METAL_H_
