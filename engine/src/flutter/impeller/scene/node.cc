// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/scene/node.h"

#include <memory>

#include "impeller/base/validation.h"
#include "impeller/geometry/matrix.h"
#include "impeller/scene/importer/scene_flatbuffers.h"
#include "impeller/scene/mesh.h"
#include "impeller/scene/node.h"
#include "impeller/scene/scene_encoder.h"

namespace impeller {
namespace scene {

std::shared_ptr<Node> Node::MakeFromFlatbuffer(fml::Mapping& mapping,
                                               Allocator& allocator) {
  flatbuffers::Verifier verifier(mapping.GetMapping(), mapping.GetSize());
  if (!fb::VerifySceneBuffer(verifier)) {
    VALIDATION_LOG << "Failed to unpack scene: Scene flatbuffer is invalid.";
    return nullptr;
  }

  return Node::MakeFromFlatbuffer(*fb::GetScene(mapping.GetMapping()),
                                  allocator);
}

std::shared_ptr<Node> Node::MakeFromFlatbuffer(const fb::Scene& scene,
                                               Allocator& allocator) {
  auto result = std::make_shared<Node>();
  if (!scene.nodes() || !scene.children()) {
    return result;  // The scene is empty.
  }

  // Initialize nodes for unpacking the entire scene.
  std::vector<std::shared_ptr<Node>> scene_nodes;
  scene_nodes.reserve(scene.nodes()->size());
  for (size_t node_i = 0; node_i < scene.nodes()->size(); node_i++) {
    scene_nodes.push_back(std::make_shared<Node>());
  }

  // Connect children to the root node.
  for (int child : *scene.children()) {
    if (child < 0 || static_cast<size_t>(child) >= scene_nodes.size()) {
      VALIDATION_LOG << "Scene child index out of range.";
      continue;
    }
    result->AddChild(scene_nodes[child]);
  }
  // TODO(bdero): Unpack animations.

  // Unpack each node.
  for (size_t node_i = 0; node_i < scene.nodes()->size(); node_i++) {
    scene_nodes[node_i]->UnpackFromFlatbuffer(*scene.nodes()->Get(node_i),
                                              scene_nodes, allocator);
  }

  return result;
}

void Node::UnpackFromFlatbuffer(
    const fb::Node& source_node,
    const std::vector<std::shared_ptr<Node>>& scene_nodes,
    Allocator& allocator) {
  if (source_node.mesh_primitives()) {
    Mesh mesh;
    for (const auto* primitives : *source_node.mesh_primitives()) {
      auto geometry = Geometry::MakeFromFlatbuffer(*primitives, allocator);
      mesh.AddPrimitive({geometry, Material::MakeUnlit()});
    }
    SetMesh(std::move(mesh));
  }

  if (!source_node.children()) {
    return;
  }

  // Wire up graph connections.
  for (int child : *source_node.children()) {
    if (child < 0 || static_cast<size_t>(child) >= scene_nodes.size()) {
      VALIDATION_LOG << "Node child index out of range.";
      continue;
    }
    AddChild(scene_nodes[child]);
  }
}

Node::Node() = default;

Node::~Node() = default;

Mesh::Mesh(Mesh&& mesh) = default;

Mesh& Mesh::operator=(Mesh&& mesh) = default;

Node::Node(Node&& node) = default;

Node& Node::operator=(Node&& node) = default;

void Node::SetLocalTransform(Matrix transform) {
  local_transform_ = transform;
}

Matrix Node::GetLocalTransform() const {
  return local_transform_;
}

void Node::SetGlobalTransform(Matrix transform) {
  Matrix inverse_global_transform =
      parent_ ? parent_->GetGlobalTransform().Invert() : Matrix();

  local_transform_ = inverse_global_transform * transform;
}

Matrix Node::GetGlobalTransform() const {
  if (parent_) {
    return parent_->GetGlobalTransform() * local_transform_;
  }
  return local_transform_;
}

bool Node::AddChild(std::shared_ptr<Node> node) {
  // This ensures that cycles are impossible.
  if (node->parent_ != nullptr) {
    VALIDATION_LOG
        << "Cannot add a node as a child which already has a parent.";
    return false;
  }
  node->parent_ = this;
  children_.push_back(std::move(node));

  return true;
}

std::vector<std::shared_ptr<Node>>& Node::GetChildren() {
  return children_;
}

void Node::SetMesh(Mesh mesh) {
  mesh_ = std::move(mesh);
}

Mesh& Node::GetMesh() {
  return mesh_;
}

bool Node::Render(SceneEncoder& encoder, const Matrix& parent_transform) const {
  Matrix transform = parent_transform * local_transform_;

  mesh_.Render(encoder, transform);

  for (auto& child : children_) {
    if (!child->Render(encoder, transform)) {
      return false;
    }
  }
  return true;
}

}  // namespace scene
}  // namespace impeller
