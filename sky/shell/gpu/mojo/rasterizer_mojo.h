// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_GPU_MOJO_RASTERIZER_MOJO_H_
#define SKY_SHELL_GPU_MOJO_RASTERIZER_MOJO_H_

#include "mojo/public/c/gpu/MGL/mgl.h"
#include "mojo/services/native_viewport/interfaces/native_viewport.mojom.h"
#include "skia/ext/refptr.h"
#include "sky/compositor/paint_context.h"
#include "sky/shell/gpu/ganesh_canvas.h"
#include "sky/shell/gpu_delegate.h"
#include "ui/gfx/native_widget_types.h"

namespace sky {
namespace shell {

class RasterizerMojo : public GPUDelegate {
 public:
  explicit RasterizerMojo();
  ~RasterizerMojo() override;

  void OnAcceleratedWidgetAvailable(gfx::AcceleratedWidget widget) override;
  void OnOutputSurfaceDestroyed() override;
  void Draw(scoped_ptr<compositor::LayerTree> layer_tree) override;

  void OnContextProviderAvailable(
      mojo::InterfacePtrInfo<mojo::ContextProvider> context_provder);

  void OnContextLost();

 private:
  SkCanvas* GetCanvas(const SkISize& size);
  void OnContextCreated(mojo::CommandBufferPtr command_buffer);

  mojo::ContextProviderPtr context_provider_;
  skia::RefPtr<GrGLInterface> gr_gl_interface_;
  MGLContext context_;
  GaneshCanvas ganesh_canvas_;

  DISALLOW_COPY_AND_ASSIGN(RasterizerMojo);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_GPU_MOJO_RASTERIZER_MOJO_H_
