// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_GPU_MOJO_RASTERIZER_MOJO_H_
#define SKY_SHELL_GPU_MOJO_RASTERIZER_MOJO_H_

#include "base/memory/weak_ptr.h"
#include "mojo/public/c/gpu/MGL/mgl.h"
#include "mojo/services/native_viewport/interfaces/native_viewport.mojom.h"
#include "skia/ext/refptr.h"
#include "sky/compositor/paint_context.h"
#include "sky/shell/gpu/ganesh_canvas.h"
#include "sky/shell/rasterizer.h"

namespace sky {
namespace shell {

class RasterizerMojo : public Rasterizer {
 public:
  explicit RasterizerMojo();
  ~RasterizerMojo() override;

  base::WeakPtr<RasterizerMojo> GetWeakPtr();

  RasterCallback GetRasterCallback() override;

  void OnContextProviderAvailable(
      mojo::InterfacePtrInfo<mojo::ContextProvider> context_provder);

  void OnContextLost();

 private:
  void OnContextCreated(mojo::CommandBufferPtr command_buffer);
  void Draw(scoped_ptr<compositor::LayerTree> layer_tree);

  mojo::ContextProviderPtr context_provider_;
  skia::RefPtr<GrGLInterface> gr_gl_interface_;
  MGLContext context_;
  GaneshCanvas ganesh_canvas_;

  compositor::PaintContext paint_context_;

  base::WeakPtrFactory<RasterizerMojo> weak_factory_;

  DISALLOW_COPY_AND_ASSIGN(RasterizerMojo);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_GPU_MOJO_RASTERIZER_MOJO_H_
