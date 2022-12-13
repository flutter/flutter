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
  static std::optional<Node> MakeFromFlatbuffer(fml::Mapping& mapping,
                                                Allocator& allocator);
  static Node MakeFromFlatbuffer(const fb::Scene& scene, Allocator& allocator);
  static Node MakeFromFlatbuffer(const fb::Node& node, Allocator& allocator);

  Node();
  ~Node();

  Node(Node&& node);
  Node& operator=(Node&& node);

  void SetLocalTransform(Matrix transform);
  Matrix GetLocalTransform() const;

  void SetGlobalTransform(Matrix transform);
  Matrix GetGlobalTransform() const;

  bool AddChild(Node child);
  std::vector<Node>& GetChildren();

  void SetMesh(Mesh mesh);
  Mesh& GetMesh();

  bool Render(SceneEncoder& encoder, const Matrix& parent_transform) const;

 protected:
  Matrix local_transform_;

 private:
  Node* parent_ = nullptr;
  std::vector<Node> children_;
  Mesh mesh_;

  FML_DISALLOW_COPY_AND_ASSIGN(Node);
};

}  // namespace scene
}  // namespace impeller
