// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_GPU_MOJO_RASTERIZER_MOJO_H_
#define SKY_SHELL_GPU_MOJO_RASTERIZER_MOJO_H_

#include "flow/compositor_context.h"
#include "lib/ftl/memory/weak_ptr.h"
#include "mojo/gpu/gl_context.h"
#include "mojo/public/interfaces/application/application_connector.mojom.h"
#include "mojo/services/gfx/composition/interfaces/scenes.mojom.h"
#include "mojo/skia/ganesh_context.h"
#include "sky/shell/gpu/mojo/gl_texture_recycler.h"
#include "sky/shell/rasterizer.h"

namespace sky {
namespace shell {

class RasterizerMojo : public Rasterizer {
 public:
  RasterizerMojo();

  ~RasterizerMojo() override;

  void Init(mojo::ApplicationConnectorPtr connector,
            mojo::gfx::composition::ScenePtr scene);

  // sky::shell::rasterizer::Rasterizer override
  void ConnectToRasterizer(
      mojo::InterfaceRequest<rasterizer::Rasterizer> request) override;

  // sky::shell::rasterizer::Rasterizer override
  void Setup(PlatformView* platform_view,
             ftl::Closure rasterizer_continuation,
             ftl::AutoResetWaitableEvent* setup_completion_event) override;

  // sky::shell::rasterizer::Rasterizer override
  void Teardown(
      ftl::AutoResetWaitableEvent* teardown_completion_event) override;

  // sky::shell::rasterizer::Rasterizer override
  ftl::WeakPtr<Rasterizer> GetWeakRasterizerPtr() override;

  // sky::shell::rasterizer::Rasterizer override
  flow::LayerTree* GetLastLayerTree() override;

 private:
  struct GLState {
    explicit GLState(mojo::ApplicationConnector* connector);

    ~GLState();

    scoped_refptr<mojo::GLContext> gl_context;
    GLTextureRecycler gl_texture_recycler;
    scoped_refptr<mojo::skia::GaneshContext> ganesh_context;
  };

  mojo::Binding<rasterizer::Rasterizer> binding_;
  mojo::gfx::composition::ScenePtr scene_;
  std::unique_ptr<GLState> gl_state_;
  flow::CompositorContext compositor_context_;
  std::unique_ptr<flow::LayerTree> last_layer_tree_;
  ftl::WeakPtrFactory<RasterizerMojo> weak_factory_;

  void Draw(uint64_t layer_tree_ptr, const DrawCallback& callback) override;

  FTL_DISALLOW_COPY_AND_ASSIGN(RasterizerMojo);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_GPU_MOJO_RASTERIZER_MOJO_H_
