// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_GPU_DIRECT_RASTERIZER_DIRECT_H_
#define SKY_SHELL_GPU_DIRECT_RASTERIZER_DIRECT_H_

#include "base/memory/weak_ptr.h"
#include "base/synchronization/waitable_event.h"
#include "flow/compositor_context.h"
#include "skia/ext/refptr.h"
#include "sky/shell/gpu/direct/ganesh_canvas.h"
#include "sky/shell/rasterizer.h"

namespace sky {
namespace shell {

class RasterizerDirect : public Rasterizer {
 public:
  RasterizerDirect();

  ~RasterizerDirect() override;

  // sky::shell::Rasterizer override.
  void ConnectToRasterizer(
      mojo::InterfaceRequest<rasterizer::Rasterizer> request) override;

  // sky::shell::Rasterizer override.
  void Setup(PlatformView* platform_view,
             base::Closure continuation,
             base::WaitableEvent* setup_completion_event) override;

  // sky::shell::Rasterizer override.
  void Teardown(base::WaitableEvent* teardown_completion_event) override;

  // sky::shell::Rasterizer override.
  base::WeakPtr<sky::shell::Rasterizer> GetWeakRasterizerPtr() override;

  // sky::shell::Rasterizer override.
  flow::LayerTree* GetLastLayerTree() override;

 private:
  skia::RefPtr<const GrGLInterface> gr_gl_interface_;
  GaneshCanvas ganesh_canvas_;
  flow::CompositorContext compositor_context_;
  mojo::Binding<rasterizer::Rasterizer> binding_;
  std::unique_ptr<flow::LayerTree> last_layer_tree_;
  PlatformView* platform_view_;
  base::WeakPtrFactory<RasterizerDirect> weak_factory_;

  // sky::services::rasterizer::Rasterizer (from rasterizer.mojom) override.
  void Draw(uint64_t layer_tree_ptr, const DrawCallback& callback) override;

  DISALLOW_COPY_AND_ASSIGN(RasterizerDirect);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_GPU_DIRECT_RASTERIZER_DIRECT_H_
