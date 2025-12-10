// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_GPU_GPU_SURFACE_MULTI_VIEW_H_
#define FLUTTER_SHELL_GPU_GPU_SURFACE_MULTI_VIEW_H_

#include "flutter/common/graphics/gl_context_switch.h"
#include "flutter/flow/surface.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/impeller/display_list/aiks_context.h"
#include "flutter/impeller/renderer/context.h"
#include "flutter/shell/gpu/gpu_surface_gl_delegate.h"

namespace flutter {

class GPUSurfaceMultiView final : public Surface {
 public:
  using MakeRenderContextCurrentCallback = std::function<std::unique_ptr<GLContextResult>()>;
  using ClearRenderContextCallback = std::function<bool()>;
  using EnableRasterCacheCallback = std::function<bool()>;
  using GetGrContextCallback = std::function<GrDirectContext*()>;
  //GetGrContext
  explicit GPUSurfaceMultiView(
    std::shared_ptr<impeller::Context> context,
    std::shared_ptr<impeller::AiksContext> aiks_context,
    const MakeRenderContextCurrentCallback& make_render_context_current_callback,
    const ClearRenderContextCallback& clear_render_context_callback,
    const EnableRasterCacheCallback& enable_raster_cache_callback,
    const GetGrContextCallback& get_gr_context_callback);

  // |Surface|
  ~GPUSurfaceMultiView() override;

  // |Surface|
  bool IsValid() override;

 private:
    // |Surface|
  std::unique_ptr<SurfaceFrame> AcquireFrame(const DlISize& size) override;

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

  MakeRenderContextCurrentCallback make_render_context_current_callback_;
  ClearRenderContextCallback clear_render_context_callback_;
  EnableRasterCacheCallback enable_raster_cache_callback_;
  GetGrContextCallback get_gr_context_callback_;

  std::shared_ptr<impeller::Context> impeller_context_;
  bool render_to_surface_ = true;
  std::shared_ptr<impeller::AiksContext> aiks_context_;
  bool is_valid_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(GPUSurfaceMultiView);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_GPU_GPU_SURFACE_MULTI_VIEW_H_
