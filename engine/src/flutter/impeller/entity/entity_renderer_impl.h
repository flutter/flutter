// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/macros.h"
#include "impeller/compositor/context.h"
#include "impeller/compositor/pipeline.h"
#include "impeller/compositor/pipeline_builder.h"
#include "impeller/compositor/render_pass.h"
#include "impeller/compositor/surface.h"
#include "impeller/entity/entity.h"
#include "impeller/entity/path.vert.h"
#include "impeller/entity/solid_fill.frag.h"

namespace impeller {

// TODO(csg): Only present to hide Objective-C++ interface in the headers. Once
// the backend is separated into its own TU, this can be merged with
// EntityRenderer.
class EntityRendererImpl {
 public:
  EntityRendererImpl(std::shared_ptr<Context> context);

  ~EntityRendererImpl();

  bool IsValid() const;

  [[nodiscard]] bool RenderEntity(const Surface& surface,
                                  const RenderPass& onscreen_pass,
                                  const Entity& entities);

 private:
  using SolidFillPipeline =
      PipelineT<PathVertexShader, SolidFillFragmentShader>;

  std::shared_ptr<Context> context_;
  std::unique_ptr<SolidFillPipeline> solid_fill_pipeline_;

  bool is_valid_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(EntityRendererImpl);
};

}  // namespace impeller
