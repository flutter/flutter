// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/tools/compositor_model_bench/render_models.h"

#include <string>

#include "gpu/tools/compositor_model_bench/forward_render_model.h"

const char* ModelToString(RenderModel m) {
  switch (m) {
    case ForwardRenderModel:
      return "Forward Rendering";
    default:
      return "(unknown render model name)";
  }
}

RenderModelSimulator::RenderModelSimulator(RenderNode* root) : root_(root) {
}

RenderModelSimulator::~RenderModelSimulator() {
}

RenderModelSimulator* ConstructSimulationModel(RenderModel model,
                                               RenderNode* render_tree_root,
                                               int window_width,
                                               int window_height) {
  switch (model) {
    case ForwardRenderModel:
      return new ForwardRenderSimulator(render_tree_root,
                                        window_width,
                                        window_height);
    default:
      LOG(ERROR) << "Unrecognized render model. "
        "If we know its name, then it's..." << ModelToString(model);
      return 0;
  }
}

