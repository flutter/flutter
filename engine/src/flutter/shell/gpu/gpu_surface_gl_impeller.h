// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_GPU_GPU_SURFACE_GL_IMPELLER_H_
#define FLUTTER_SHELL_GPU_GPU_SURFACE_GL_IMPELLER_H_

#include "flutter/common/graphics/gl_context_switch.h"
#include "flutter/flow/surface.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/impeller/display_list/aiks_context.h"
#include "flutter/impeller/renderer/context.h"
#include "flutter/shell/gpu/gpu_surface_gl_delegate.h"

namespace flutter {

class GPUSurfaceGLImpeller final : public Surface {
 public:
 using GetGPUSurfaceGLDelegateCallback = std::function<GPUSurfaceGLDelegate*(int64_t view_id)>;
  explicit GPUSurfaceGLImpeller(GPUSurfaceGLDelegate* delegate,
                                std::shared_ptr<impeller::Context> context,
                                bool render_to_surface,
                              const GetGPUSurfaceGLDelegateCallback& get_gpu_surface_delegate = {});

  // |Surface|
  ~GPUSurfaceGLImpeller() override;

  // |Surface|
  bool IsValid() override;

 private:
  GPUSurfaceGLDelegate* delegate_ = nullptr;
  std::shared_ptr<impeller::Context> impeller_context_;
  bool render_to_surface_ = true;
  std::shared_ptr<impeller::AiksContext> aiks_context_;
  bool is_valid_ = false;
  fml::TaskRunnerAffineWeakPtrFactory<GPUSurfaceGLImpeller> weak_factory_;

  const GetGPUSurfaceGLDelegateCallback get_gpu_surface_delegate_;

  // |Surface|
  std::unique_ptr<SurfaceFrame> AcquireFrame(const DlISize& size) override;

   std::unique_ptr<SurfaceFrame> AcquireFrame(int64_t view_id, const DlISize& size) override;

  // |Surface|
  DlMatrix GetRootTransformation() const override;

  // |Surface|
  GrDirectContext* GetContext() override;

  // |Surface|
  std::unique_ptr<GLContextResult> MakeRenderContextCurrent() override;

  // |Surface|
  bool ClearRenderContext() override;

  // |Surface|
  bool AllowsDrawingWhenGpuDisabled() const override;

  // |Surface|
  bool EnableRasterCache() const override;

  // |Surface|
  std::shared_ptr<impeller::AiksContext> GetAiksContext() const override;

  FML_DISALLOW_COPY_AND_ASSIGN(GPUSurfaceGLImpeller);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_GPU_GPU_SURFACE_GL_IMPELLER_H_
