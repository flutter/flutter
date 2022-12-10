// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/scene/mesh.h"

#include <memory>

#include "impeller/base/validation.h"
#include "impeller/scene/material.h"
#include "impeller/scene/scene_encoder.h"

namespace impeller {
namespace scene {

Mesh::Mesh() = default;
Mesh::~Mesh() = default;

void Mesh::AddPrimitive(Primitive mesh) {
  if (mesh.geometry_ == nullptr) {
    VALIDATION_LOG << "Mesh geometry cannot be null.";
  }
  if (mesh.material_ == nullptr) {
    VALIDATION_LOG << "Mesh material cannot be null.";
  }

  meshes_.push_back(std::move(mesh));
}

bool Mesh::Render(SceneEncoder& encoder, const Matrix& transform) const {
  for (const auto& mesh : meshes_) {
    SceneCommand command = {
        .label = "Mesh Primitive",
        .transform = transform,
        .geometry = mesh.geometry_.get(),
        .material = mesh.material_.get(),
    };
    encoder.Add(command);
  }
  return true;
}

}  // namespace scene
}  // namespace impeller
