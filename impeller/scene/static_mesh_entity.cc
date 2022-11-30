// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/scene/static_mesh_entity.h"

#include <memory>

#include "impeller/scene/material.h"
#include "impeller/scene/scene_encoder.h"

namespace impeller {
namespace scene {

StaticMeshEntity::StaticMeshEntity() = default;
StaticMeshEntity::~StaticMeshEntity() = default;

void StaticMeshEntity::SetGeometry(std::shared_ptr<Geometry> geometry) {
  geometry_ = std::move(geometry);
}

void StaticMeshEntity::SetMaterial(std::shared_ptr<Material> material) {
  material_ = std::move(material);
}

// |SceneEntity|
bool StaticMeshEntity::OnRender(SceneEncoder& encoder,
                                const Camera& camera) const {
  SceneCommand command = {
      .label = "Static Mesh",
      .transform = GetGlobalTransform(),
      .geometry = geometry_.get(),
      .material = material_.get(),
  };
  encoder.Add(command);
  return true;
}

}  // namespace scene
}  // namespace impeller
