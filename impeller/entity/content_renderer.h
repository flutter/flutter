// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/macros.h"
#include "flutter/impeller/entity/gradient_fill.frag.h"
#include "flutter/impeller/entity/gradient_fill.vert.h"
#include "flutter/impeller/entity/solid_fill.frag.h"
#include "flutter/impeller/entity/solid_fill.vert.h"
#include "flutter/impeller/entity/solid_stroke.frag.h"
#include "flutter/impeller/entity/solid_stroke.vert.h"
#include "flutter/impeller/entity/texture_fill.frag.h"
#include "flutter/impeller/entity/texture_fill.vert.h"
#include "impeller/renderer/pipeline.h"

namespace impeller {

using GradientFillPipeline =
    PipelineT<GradientFillVertexShader, GradientFillFragmentShader>;
using SolidFillPipeline =
    PipelineT<SolidFillVertexShader, SolidFillFragmentShader>;
using TexturePipeline =
    PipelineT<TextureFillVertexShader, TextureFillFragmentShader>;
using SolidStrokePipeline =
    PipelineT<SolidStrokeVertexShader, SolidStrokeFragmentShader>;
// Instead of requiring new shaders for clips,  the solid fill stages are used
// to redirect writing to the stencil instead of color attachments.
using ClipPipeline = PipelineT<SolidFillVertexShader, SolidFillFragmentShader>;

class ContentRenderer {
 public:
  ContentRenderer(std::shared_ptr<Context> context);

  ~ContentRenderer();

  bool IsValid() const;

  std::shared_ptr<Pipeline> GetGradientFillPipeline() const;

  std::shared_ptr<Pipeline> GetSolidFillPipeline() const;

  std::shared_ptr<Pipeline> GetTexturePipeline() const;

  std::shared_ptr<Pipeline> GetSolidStrokePipeline() const;

  std::shared_ptr<Pipeline> GetClipPipeline() const;

  std::shared_ptr<Context> GetContext() const;

 private:
  std::shared_ptr<Context> context_;
  std::unique_ptr<GradientFillPipeline> gradient_fill_pipeline_;
  std::unique_ptr<SolidFillPipeline> solid_fill_pipeline_;
  std::unique_ptr<TexturePipeline> texture_pipeline_;
  std::unique_ptr<SolidStrokePipeline> solid_stroke_pipeline_;
  std::unique_ptr<ClipPipeline> clip_pipeline_;
  bool is_valid_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(ContentRenderer);
};

}  // namespace impeller
