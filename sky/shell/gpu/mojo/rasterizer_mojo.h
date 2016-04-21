// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_GPU_MOJO_RASTERIZER_MOJO_H_
#define SKY_SHELL_GPU_MOJO_RASTERIZER_MOJO_H_

#include "base/memory/weak_ptr.h"
#include "flow/paint_context.h"
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
  explicit RasterizerMojo();
  ~RasterizerMojo() override;

  base::WeakPtr<RasterizerMojo> GetWeakPtr();

  base::WeakPtr<Rasterizer> GetWeakRasterizerPtr() override;

  void ConnectToRasterizer(
       mojo::InterfaceRequest<rasterizer::Rasterizer> request) override;

  void Init(mojo::ApplicationConnectorPtr connector,
            mojo::gfx::composition::ScenePtr scene);

  flow::LayerTree* GetLastLayerTree() override;

 private:
  void Draw(uint64_t layer_tree_ptr, const DrawCallback& callback) override;

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
  flow::PaintContext paint_context_;
  std::unique_ptr<flow::LayerTree> last_layer_tree_;

  base::WeakPtrFactory<RasterizerMojo> weak_factory_;

  DISALLOW_COPY_AND_ASSIGN(RasterizerMojo);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_GPU_MOJO_RASTERIZER_MOJO_H_
