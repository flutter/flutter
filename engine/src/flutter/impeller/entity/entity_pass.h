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
#include "impeller/entity/entity_pass_delegate.h"
#include "impeller/renderer/render_target.h"

namespace impeller {

class ContentRenderer;

class EntityPass {
 public:
  using Entities = std::vector<Entity>;
  using Subpasses = std::vector<std::unique_ptr<EntityPass>>;

  EntityPass(std::unique_ptr<EntityPassDelegate> delegate = nullptr);

  ~EntityPass();

  size_t GetSubpassesDepth() const;

  std::unique_ptr<EntityPass> Clone() const;

  Rect GetCoverageRect() const;

  // TODO(csg): This prevents an optimization where the coverage can be
  // calculated once in SetEntities an memoized.
  void AddEntity(Entity entity);

  void SetEntities(Entities entities);

  const std::vector<Entity>& GetEntities() const;

  const Subpasses& GetSubpasses() const;

  EntityPass* AddSubpass(std::unique_ptr<EntityPass> pass);

  EntityPass* GetSuperpass() const;

  bool Render(ContentRenderer& renderer, RenderPass& parent_pass) const;

  void IterateAllEntities(std::function<bool(Entity&)> iterator);

  void SetTransformation(Matrix xformation);

  void SetStencilDepth(size_t stencil_depth);

 private:
  Entities entities_;
  Subpasses subpasses_;
  EntityPass* superpass_ = nullptr;
  Matrix xformation_;
  size_t stencil_depth_ = 0u;
  std::unique_ptr<EntityPassDelegate> delegate_;

  FML_DISALLOW_COPY_AND_ASSIGN(EntityPass);
};

struct CanvasStackEntry {
  Matrix xformation;
  size_t stencil_depth = 0u;
  bool is_subpass = false;
};

}  // namespace impeller
