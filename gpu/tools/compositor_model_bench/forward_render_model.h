// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// A render model simulator for the original model used in Chromium.

#ifndef GPU_TOOLS_COMPOSITOR_MODEL_BENCH_FORWARD_RENDER_MODEL_H_
#define GPU_TOOLS_COMPOSITOR_MODEL_BENCH_FORWARD_RENDER_MODEL_H_

#include "base/basictypes.h"
#include "base/memory/scoped_ptr.h"
#include "gpu/tools/compositor_model_bench/render_model_utils.h"
#include "gpu/tools/compositor_model_bench/render_models.h"

class ForwardRenderNodeVisitor;

class ForwardRenderSimulator : public RenderModelSimulator {
 public:
  explicit ForwardRenderSimulator(RenderNode* root,
                                  int window_width,
                                  int window_height);
  ~ForwardRenderSimulator() override;
  void Update() override;
  void Resize(int width, int height) override;

 private:
  scoped_ptr<ForwardRenderNodeVisitor> visitor_;
  scoped_ptr<TextureGenerator> textures_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(ForwardRenderSimulator);
};

#endif  // GPU_TOOLS_COMPOSITOR_MODEL_BENCH_FORWARD_RENDER_MODEL_H_

