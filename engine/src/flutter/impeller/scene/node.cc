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

std::optional<Node> Node::MakeFromFlatbuffer(fml::Mapping& mapping,
                                             Allocator& allocator) {
  flatbuffers::Verifier verifier(mapping.GetMapping(), mapping.GetSize());
  if (!fb::VerifySceneBuffer(verifier)) {
    return std::nullopt;
  }

  return Node::MakeFromFlatbuffer(*fb::GetScene(mapping.GetMapping()),
                                  allocator);
}

Node Node::MakeFromFlatbuffer(const fb::Scene& scene, Allocator& allocator) {
  Node result;

  if (!scene.children()) {
    return result;
  }
  for (const auto* child : *scene.children()) {
    result.AddChild(Node::MakeFromFlatbuffer(*child, allocator));
  }

  return result;
}

Node Node::MakeFromFlatbuffer(const fb::Node& node, Allocator& allocator) {
  Node result;

  if (node.mesh_primitives()) {
    Mesh mesh;
    for (const auto* primitives : *node.mesh_primitives()) {
      auto geometry = Geometry::MakeFromFlatbuffer(*primitives, allocator);
      mesh.AddPrimitive({geometry, Material::MakeUnlit()});
    }
    result.SetMesh(std::move(mesh));
  }

  if (!node.children()) {
    return result;
  }
  for (const auto* child : *node.children()) {
    result.AddChild(Node::MakeFromFlatbuffer(*child, allocator));
  }

  return result;
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

bool Node::AddChild(Node node) {
  if (node.parent_ != nullptr) {
    VALIDATION_LOG
        << "Cannot add a node as a child which already has a parent.";
    return false;
  }
  node.parent_ = this;
  children_.push_back(std::move(node));

  Node& ref = children_.back();
  for (Node& child : ref.children_) {
    child.parent_ = &ref;
  }

  return true;
}

std::vector<Node>& Node::GetChildren() {
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
    if (!child.Render(encoder, transform)) {
      return false;
    }
  }
  return true;
}

}  // namespace scene
}  // namespace impeller
