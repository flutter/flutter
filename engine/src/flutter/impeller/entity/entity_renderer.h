// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/macros.h"
#include "impeller/entity/entity.h"
#include "impeller/renderer/context.h"
#include "impeller/renderer/surface.h"

namespace impeller {

class ContentRenderer;

class EntityRenderer {
 public:
  EntityRenderer(std::shared_ptr<Context> context);

  ~EntityRenderer();

  bool IsValid() const;

  [[nodiscard]] bool RenderEntities(RenderPass& parent_pass,
                                    const std::vector<Entity>& entities);

 private:
  std::shared_ptr<Context> context_;
  std::unique_ptr<ContentRenderer> content_renderer_;
  bool is_valid_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(EntityRenderer);
};

}  // namespace impeller
