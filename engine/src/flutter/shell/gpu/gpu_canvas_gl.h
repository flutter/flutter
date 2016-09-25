// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_GPU_GPU_CANVAS_GL_H_
#define SHELL_GPU_GPU_CANVAS_GL_H_

#include "lib/ftl/macros.h"
#include "gpu_canvas.h"

namespace shell {

class GPUCanvasGL : public GPUCanvas {
 public:
  GPUCanvasGL(intptr_t fbo);

  ~GPUCanvasGL() override;

  bool Setup() override;

  bool IsValid() override;

  SkCanvas* AcquireCanvas(const SkISize& size) override;

  GrContext* GetContext() override;

 private:
  intptr_t fbo_;
  sk_sp<GrContext> context_;
  sk_sp<SkSurface> cached_surface_;

  sk_sp<SkSurface> CreateSurface(const SkISize& size);

  sk_sp<SkSurface> AcquireSurface(const SkISize& size);

  bool SelectPixelConfig(GrPixelConfig* config);

  FTL_DISALLOW_COPY_AND_ASSIGN(GPUCanvasGL);
};

}  // namespace shell

#endif  // SHELL_GPU_GPU_CANVAS_GL_H_
