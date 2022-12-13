// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>
#include <type_traits>

#include "flutter/fml/macros.h"
#include "impeller/scene/geometry.h"
#include "impeller/scene/material.h"
#include "impeller/scene/scene_encoder.h"

namespace impeller {
namespace scene {

class Mesh final {
 public:
  struct Primitive {
    std::shared_ptr<Geometry> geometry;
    std::shared_ptr<Material> material;
  };

  Mesh();
  ~Mesh();

  Mesh(Mesh&& mesh);
  Mesh& operator=(Mesh&& mesh);

  void AddPrimitive(Primitive mesh_);
  std::vector<Primitive>& GetPrimitives();

  bool Render(SceneEncoder& encoder, const Matrix& transform) const;

 private:
  std::vector<Primitive> primitives_;

  FML_DISALLOW_COPY_AND_ASSIGN(Mesh);
};

}  // namespace scene
}  // namespace impeller
