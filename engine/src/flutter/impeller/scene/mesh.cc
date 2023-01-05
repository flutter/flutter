// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/scene/mesh.h"

#include <memory>
#include <optional>

#include "impeller/base/validation.h"
#include "impeller/scene/material.h"
#include "impeller/scene/pipeline_key.h"
#include "impeller/scene/scene_encoder.h"

namespace impeller {
namespace scene {

Mesh::Mesh() = default;
Mesh::~Mesh() = default;

void Mesh::AddPrimitive(Primitive mesh) {
  if (mesh.geometry == nullptr) {
    VALIDATION_LOG << "Mesh geometry cannot be null.";
  }
  if (mesh.material == nullptr) {
    VALIDATION_LOG << "Mesh material cannot be null.";
  }

  primitives_.push_back(std::move(mesh));
}

std::vector<Mesh::Primitive>& Mesh::GetPrimitives() {
  return primitives_;
}

bool Mesh::Render(SceneEncoder& encoder,
                  const Matrix& transform,
                  const std::shared_ptr<Texture>& joints) const {
  for (const auto& mesh : primitives_) {
    mesh.geometry->SetJointsTexture(joints);
    SceneCommand command = {
        .label = "Mesh Primitive",
        .transform = transform,
        .geometry = mesh.geometry.get(),
        .material = mesh.material.get(),
    };
    encoder.Add(command);
  }
  return true;
}

}  // namespace scene
}  // namespace impeller
