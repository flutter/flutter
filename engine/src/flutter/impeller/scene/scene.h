// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>
#include <vector>

#include "flutter/fml/macros.h"

#include "impeller/renderer/render_target.h"
#include "impeller/scene/camera.h"
#include "impeller/scene/scene_context.h"
#include "impeller/scene/scene_entity.h"

namespace impeller {
namespace scene {

class Scene {
 public:
  Scene() = delete;
  explicit Scene(std::shared_ptr<Context> context);

  void Add(const std::shared_ptr<SceneEntity>& child);
  bool Render(const RenderTarget& render_target, const Camera& camera) const;

 private:
  std::unique_ptr<SceneContext> scene_context_;
  SceneEntity root_;

  FML_DISALLOW_COPY_AND_ASSIGN(Scene);
};

}  // namespace scene
}  // namespace impeller
