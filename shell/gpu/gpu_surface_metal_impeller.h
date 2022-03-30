// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_GPU_GPU_SURFACE_METAL_IMPELLER_H_
#define FLUTTER_SHELL_GPU_GPU_SURFACE_METAL_IMPELLER_H_

#include "flutter/flow/surface.h"
#include "flutter/fml/macros.h"
#include "flutter/impeller/aiks/aiks_context.h"
#include "flutter/impeller/renderer/renderer.h"
#include "flutter/shell/gpu/gpu_surface_metal_delegate.h"

namespace flutter {

class SK_API_AVAILABLE_CA_METAL_LAYER GPUSurfaceMetalImpeller : public Surface {
 public:
  GPUSurfaceMetalImpeller(GPUSurfaceMetalDelegate* delegate,
                          std::shared_ptr<impeller::Context> context);

  // |Surface|
  ~GPUSurfaceMetalImpeller();

  // |Surface|
  bool IsValid() override;

 private:
  const GPUSurfaceMetalDelegate* delegate_;
  std::shared_ptr<impeller::Renderer> impeller_renderer_;
  std::shared_ptr<impeller::AiksContext> aiks_context_;

  // |Surface|
  std::unique_ptr<SurfaceFrame> AcquireFrame(const SkISize& size) override;

  // |Surface|
  SkMatrix GetRootTransformation() const override;

  // |Surface|
  GrDirectContext* GetContext() override;

  // |Surface|
  std::unique_ptr<GLContextResult> MakeRenderContextCurrent() override;

  // |Surface|
  bool AllowsDrawingWhenGpuDisabled() const override;

  // |Surface|
  bool EnableRasterCache() const override;

  FML_DISALLOW_COPY_AND_ASSIGN(GPUSurfaceMetalImpeller);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_GPU_GPU_SURFACE_METAL_IMPELLER_H_
