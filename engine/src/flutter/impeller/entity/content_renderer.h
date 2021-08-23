// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/macros.h"
#include "impeller/compositor/pipeline.h"
#include "impeller/entity/gradient_fill.frag.h"
#include "impeller/entity/gradient_fill.vert.h"

namespace impeller {

using GradientFillPipeline =
    PipelineT<GradientFillVertexShader, GradientFillFragmentShader>;

class ContentRenderer {
 public:
  ContentRenderer(std::shared_ptr<Context> context);

  ~ContentRenderer();

  bool IsValid() const;

  std::shared_ptr<Pipeline> GetGradientFillPipeline() const;

  std::shared_ptr<Context> GetContext() const;

 private:
  std::shared_ptr<Context> context_;
  std::unique_ptr<GradientFillPipeline> gradient_fill_pipeline_;
  bool is_valid_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(ContentRenderer);
};

}  // namespace impeller
