// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/tools/compositor_model_bench/forward_render_model.h"

#include <cstdlib>
#include <vector>

#include "gpu/tools/compositor_model_bench/render_model_utils.h"

using std::vector;

class ForwardRenderNodeVisitor : public RenderNodeVisitor {
 public:
  ForwardRenderNodeVisitor() {}

  void BeginVisitRenderNode(RenderNode* v) override { NOTREACHED(); }

  void BeginVisitCCNode(CCNode* v) override {
    if (!v->drawsContent())
      return;
    ConfigAndActivateShaderForNode(v);
    DrawQuad(v->width(), v->height());
  }

  void BeginVisitContentLayerNode(ContentLayerNode* l) override {
    if (!l->drawsContent())
      return;
    ConfigAndActivateShaderForTiling(l);
    // Now that we capture root layer tiles, a layer without tiles
    // should not get drawn.
    for (size_t n = 0; n < l->num_tiles(); ++n) {
      const Tile* i = l->tile(n);
      DrawTileQuad(i->texID, i->x, i->y);
    }
  }
};

ForwardRenderSimulator::ForwardRenderSimulator(RenderNode* root,
                                               int window_width,
                                               int window_height)
    : RenderModelSimulator(root) {
  textures_.reset(new TextureGenerator(root));
  visitor_.reset(new ForwardRenderNodeVisitor());
  glViewport(0, 0, window_width, window_height);
  glDisable(GL_DEPTH_TEST);
  glDisable(GL_CULL_FACE);
  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
}

ForwardRenderSimulator::~ForwardRenderSimulator() {
}

void ForwardRenderSimulator::Update() {
  glClearColor(0, 0, 1, 1);
  glColorMask(true, true, true, true);
  glClear(GL_COLOR_BUFFER_BIT);
  glColorMask(true, true, true, false);
  BeginFrame();
  root_->Accept(visitor_.get());
}

void ForwardRenderSimulator::Resize(int width, int height) {
  glViewport(0, 0, width, height);
}

