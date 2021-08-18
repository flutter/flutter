// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/macros.h"
#include "impeller/entity/entity.h"

namespace impeller {

class Surface;
class RenderPass;
class Context;
class EntityRendererImpl;

class EntityRenderer {
 public:
  EntityRenderer(std::shared_ptr<Context> context);

  ~EntityRenderer();

  bool IsValid() const;

  [[nodiscard]] bool RenderEntities(const Surface& surface,
                                    const RenderPass& onscreen_pass,
                                    const std::vector<Entity>& entities) const;

 private:
  std::unique_ptr<EntityRendererImpl> renderer_;
  bool is_valid_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(EntityRenderer);
};

}  // namespace impeller
