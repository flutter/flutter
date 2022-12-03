// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>
#include <type_traits>

#include "flutter/fml/macros.h"
#include "impeller/scene/geometry.h"
#include "impeller/scene/material.h"
#include "impeller/scene/scene_entity.h"

namespace impeller {
namespace scene {

class StaticMeshEntity final : public SceneEntity {
 public:
  StaticMeshEntity();
  ~StaticMeshEntity();

  void SetGeometry(std::shared_ptr<Geometry> material);
  void SetMaterial(std::shared_ptr<Material> material);

 private:
  // |SceneEntity|
  bool OnRender(SceneEncoder& encoder) const override;

  std::shared_ptr<Material> material_;
  std::shared_ptr<Geometry> geometry_;

  FML_DISALLOW_COPY_AND_ASSIGN(StaticMeshEntity);
};

}  // namespace scene
}  // namespace impeller
