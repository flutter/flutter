// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>
#include <optional>
#include <vector>

#include "flutter/fml/macros.h"
#include "impeller/entity/contents.h"
#include "impeller/entity/entity.h"

namespace impeller {

class ContentRenderer;

class CanvasPass {
 public:
  using Subpasses = std::vector<CanvasPass>;

  CanvasPass();

  ~CanvasPass();

  void PushEntity(Entity entity);

  Rect GetCoverageRect() const;

  const std::vector<Entity>& GetEntities() const;

  const Subpasses& GetSubpasses() const;

  bool AddSubpass(CanvasPass pass);

  bool Render(ContentRenderer& renderer, RenderPass& parent_pass) const;

 private:
  std::vector<Entity> entities_;
  Subpasses subpasses_;
};

struct CanvasStackEntry {
  Matrix xformation;
  size_t stencil_depth = 0u;
  std::optional<CanvasPass> pass;
};

}  // namespace impeller
