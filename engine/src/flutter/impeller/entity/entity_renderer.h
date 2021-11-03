// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/macros.h"
#include "flutter/impeller/entity/solid_fill.frag.h"
#include "flutter/impeller/entity/solid_fill.vert.h"
#include "impeller/entity/content_renderer.h"
#include "impeller/entity/entity.h"
#include "impeller/renderer/context.h"
#include "impeller/renderer/pipeline.h"
#include "impeller/renderer/pipeline_builder.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/surface.h"

namespace impeller {

class EntityRenderer {
 public:
  EntityRenderer(std::shared_ptr<Context> context);

  ~EntityRenderer();

  bool IsValid() const;

  [[nodiscard]] bool RenderEntities(const Surface& surface,
                                    RenderPass& onscreen_pass,
                                    const std::vector<Entity>& entities);

  enum class RenderResult {
    kSkipped,
    kSuccess,
    kFailure,
  };

  [[nodiscard]] RenderResult RenderEntity(const Surface& surface,
                                          RenderPass& onscreen_pass,
                                          const Entity& entities);

 private:
  using SolidFillPipeline =
      PipelineT<SolidFillVertexShader, SolidFillFragmentShader>;

  std::shared_ptr<Context> context_;
  std::unique_ptr<SolidFillPipeline> solid_fill_pipeline_;
  std::unique_ptr<ContentRenderer> content_renderer_;
  bool is_valid_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(EntityRenderer);
};

}  // namespace impeller
