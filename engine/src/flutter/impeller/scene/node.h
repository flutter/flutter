// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>
#include <vector>

#include "flutter/fml/macros.h"

#include "impeller/geometry/matrix.h"
#include "impeller/renderer/render_target.h"
#include "impeller/scene/camera.h"
#include "impeller/scene/mesh.h"
#include "impeller/scene/scene_encoder.h"

namespace impeller {
namespace scene {

class Node final {
 public:
  Node();
  ~Node();

  void SetLocalTransform(Matrix transform);
  Matrix GetLocalTransform() const;

  void SetGlobalTransform(Matrix transform);
  Matrix GetGlobalTransform() const;

  void AddChild(Node child);

  void SetMesh(const Mesh& mesh);

  bool Render(SceneEncoder& encoder, const Matrix& parent_transform) const;

 protected:
  Matrix local_transform_;

 private:
  Node* parent_ = nullptr;
  std::vector<Node> children_;
  Mesh mesh_;
};

}  // namespace scene
}  // namespace impeller
