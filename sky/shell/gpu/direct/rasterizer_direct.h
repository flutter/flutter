// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_GPU_DIRECT_RASTERIZER_H_
#define SKY_SHELL_GPU_DIRECT_RASTERIZER_H_

#include "base/memory/weak_ptr.h"
#include "flow/paint_context.h"
#include "skia/ext/refptr.h"
#include "sky/shell/gpu/direct/ganesh_canvas.h"
#include "sky/shell/rasterizer.h"
#include "ui/gfx/native_widget_types.h"

namespace gfx {
class GLContext;
class GLShareGroup;
class GLSurface;
}

namespace sky {
namespace shell {
class GaneshContext;
class GaneshSurface;

class RasterizerDirect : public Rasterizer {
 public:
  explicit RasterizerDirect();
  ~RasterizerDirect() override;

  base::WeakPtr<RasterizerDirect> GetWeakPtr();

  base::WeakPtr<::sky::shell::Rasterizer> GetWeakRasterizerPtr() override;

  void ConnectToRasterizer(
      mojo::InterfaceRequest<rasterizer::Rasterizer> request) override;

  void OnAcceleratedWidgetAvailable(gfx::AcceleratedWidget widget);
  void OnOutputSurfaceDestroyed();

 private:
  void Draw(uint64_t layer_tree_ptr, const DrawCallback& callback) override;

  void EnsureGLContext();

  scoped_refptr<gfx::GLShareGroup> share_group_;
  scoped_refptr<gfx::GLSurface> surface_;
  scoped_refptr<gfx::GLContext> context_;

  skia::RefPtr<const GrGLInterface> gr_gl_interface_;
  GaneshCanvas ganesh_canvas_;

  flow::PaintContext paint_context_;

  mojo::Binding<rasterizer::Rasterizer> binding_;

  base::WeakPtrFactory<RasterizerDirect> weak_factory_;

  DISALLOW_COPY_AND_ASSIGN(RasterizerDirect);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_GPU_DIRECT_RASTERIZER_H_
