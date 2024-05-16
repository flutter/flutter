// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/scene/node.h"

#include <inttypes.h>
#include <atomic>
#include <memory>
#include <vector>

#include "flutter/fml/logging.h"
#include "impeller/base/strings.h"
#include "impeller/base/thread.h"
#include "impeller/base/validation.h"
#include "impeller/geometry/matrix.h"
#include "impeller/scene/animation/animation_player.h"
#include "impeller/scene/importer/conversions.h"
#include "impeller/scene/importer/scene_flatbuffers.h"
#include "impeller/scene/mesh.h"
#include "impeller/scene/node.h"
#include "impeller/scene/scene_encoder.h"

namespace impeller {
namespace scene {

static std::atomic_uint64_t kNextNodeID = 0;

void Node::MutationLog::Append(const Entry& entry) {
  WriterLock lock(write_mutex_);
  dirty_ = true;
  entries_.push_back(entry);
}

std::optional<std::vector<Node::MutationLog::Entry>>
Node::MutationLog::Flush() {
  WriterLock lock(write_mutex_);
  if (!dirty_) {
    return std::nullopt;
  }
  dirty_ = false;
  auto result = entries_;
  entries_ = {};
  return result;
}

std::shared_ptr<Node> Node::MakeFromFlatbuffer(
    const fml::Mapping& ipscene_mapping,
    Allocator& allocator) {
  flatbuffers::Verifier verifier(ipscene_mapping.GetMapping(),
                                 ipscene_mapping.GetSize());
  if (!fb::VerifySceneBuffer(verifier)) {
    VALIDATION_LOG << "Failed to unpack scene: Scene flatbuffer is invalid.";
    return nullptr;
  }

  return Node::MakeFromFlatbuffer(*fb::GetScene(ipscene_mapping.GetMapping()),
                                  allocator);
}

static std::shared_ptr<Texture> UnpackTextureFromFlatbuffer(
    const fb::Texture* iptexture,
    Allocator& allocator) {
  if (iptexture == nullptr || iptexture->embedded_image() == nullptr ||
      iptexture->embedded_image()->bytes() == nullptr) {
    return nullptr;
  }

  auto embedded = iptexture->embedded_image();

  uint8_t bytes_per_component = 0;
  switch (embedded->component_type()) {
    case fb::ComponentType::k8Bit:
      bytes_per_component = 1;
      break;
    case fb::ComponentType::k16Bit:
      // bytes_per_component = 2;
      FML_LOG(WARNING) << "16 bit textures not yet supported.";
      return nullptr;
  }

  switch (embedded->component_count()) {
    case 4:
      // RGBA.
      break;
    case 1:
    case 3:
    default:
      FML_LOG(WARNING) << "Textures with " << embedded->component_count()
                       << " components are not supported." << std::endl;
      return nullptr;
  }
  if (embedded->bytes()->size() != bytes_per_component *
                                       embedded->component_count() *
                                       embedded->width() * embedded->height()) {
    FML_LOG(WARNING) << "Embedded texture has an unexpected size. Skipping."
                     << std::endl;
    return nullptr;
  }

  auto image_mapping = std::make_shared<fml::NonOwnedMapping>(
      embedded->bytes()->Data(), embedded->bytes()->size());

  auto texture_descriptor = TextureDescriptor{};
  texture_descriptor.storage_mode = StorageMode::kHostVisible;
  texture_descriptor.format = PixelFormat::kR8G8B8A8UNormInt;
  texture_descriptor.size = ISize(embedded->width(), embedded->height());
  // TODO(bdero): Generate mipmaps for embedded textures.
  texture_descriptor.mip_count = 1u;

  auto texture = allocator.CreateTexture(texture_descriptor);
  if (!texture) {
    FML_LOG(ERROR) << "Could not allocate texture.";
    return nullptr;
  }

  auto uploaded = texture->SetContents(image_mapping);
  if (!uploaded) {
    FML_LOG(ERROR) << "Could not upload texture to device memory.";
    return nullptr;
  }

  return texture;
}

std::shared_ptr<Node> Node::MakeFromFlatbuffer(const fb::Scene& scene,
                                               Allocator& allocator) {
  // Unpack textures.
  std::vector<std::shared_ptr<Texture>> textures;
  if (scene.textures()) {
    for (const auto iptexture : *scene.textures()) {
      // The elements of the unpacked texture array must correspond exactly with
      // the ipscene texture array. So if a texture is empty or invalid, a
      // nullptr is inserted as a placeholder.
      textures.push_back(UnpackTextureFromFlatbuffer(iptexture, allocator));
    }
  }

  auto result = std::make_shared<Node>();
  result->SetLocalTransform(importer::ToMatrix(*scene.transform()));

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

  // Unpack each node.
  for (size_t node_i = 0; node_i < scene.nodes()->size(); node_i++) {
    scene_nodes[node_i]->UnpackFromFlatbuffer(*scene.nodes()->Get(node_i),
                                              scene_nodes, textures, allocator);
  }

  // Unpack animations.
  if (scene.animations()) {
    for (const auto animation : *scene.animations()) {
      if (auto out_animation =
              Animation::MakeFromFlatbuffer(*animation, scene_nodes)) {
        result->animations_.push_back(out_animation);
      }
    }
  }

  return result;
}

void Node::UnpackFromFlatbuffer(
    const fb::Node& source_node,
    const std::vector<std::shared_ptr<Node>>& scene_nodes,
    const std::vector<std::shared_ptr<Texture>>& textures,
    Allocator& allocator) {
  name_ = source_node.name()->str();
  SetLocalTransform(importer::ToMatrix(*source_node.transform()));

  /// Meshes.

  if (source_node.mesh_primitives()) {
    Mesh mesh;
    for (const auto* primitives : *source_node.mesh_primitives()) {
      auto geometry = Geometry::MakeFromFlatbuffer(*primitives, allocator);
      auto material =
          primitives->material()
              ? Material::MakeFromFlatbuffer(*primitives->material(), textures)
              : Material::MakeUnlit();
      mesh.AddPrimitive({std::move(geometry), std::move(material)});
    }
    SetMesh(std::move(mesh));
  }

  /// Child nodes.

  if (source_node.children()) {
    // Wire up graph connections.
    for (int child : *source_node.children()) {
      if (child < 0 || static_cast<size_t>(child) >= scene_nodes.size()) {
        VALIDATION_LOG << "Node child index out of range.";
        continue;
      }
      AddChild(scene_nodes[child]);
    }
  }

  /// Skin.

  if (source_node.skin()) {
    skin_ = Skin::MakeFromFlatbuffer(*source_node.skin(), scene_nodes);
  }
}

Node::Node() : name_(SPrintF("__node%" PRIu64, kNextNodeID++)){};

Node::~Node() = default;

Mesh::Mesh(Mesh&& mesh) = default;

Mesh& Mesh::operator=(Mesh&& mesh) = default;

const std::string& Node::GetName() const {
  return name_;
}

void Node::SetName(const std::string& new_name) {
  name_ = new_name;
}

Node* Node::GetParent() const {
  return parent_;
}

std::shared_ptr<Node> Node::FindChildByName(
    const std::string& name,
    bool exclude_animation_players) const {
  for (auto& child : children_) {
    if (exclude_animation_players && child->animation_player_.has_value()) {
      continue;
    }
    if (child->GetName() == name) {
      return child;
    }
    if (auto found = child->FindChildByName(name)) {
      return found;
    }
  }
  return nullptr;
}

std::shared_ptr<Animation> Node::FindAnimationByName(
    const std::string& name) const {
  for (const auto& animation : animations_) {
    if (animation->GetName() == name) {
      return animation;
    }
  }
  return nullptr;
}

AnimationClip* Node::AddAnimation(const std::shared_ptr<Animation>& animation) {
  if (!animation_player_.has_value()) {
    animation_player_ = AnimationPlayer();
  }
  return animation_player_->AddAnimation(animation, this);
}

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
  if (!node) {
    VALIDATION_LOG << "Cannot add null child to node.";
    return false;
  }

  // TODO(bdero): Figure out a better paradigm/rules for nodes with multiple
  //              parents. We should probably disallow this, make deep
  //              copying of nodes cheap and easy, add mesh instancing, etc.
  //              Today, the parent link is only used for skin posing, and so
  //              it's reasonable to not have a check and allow multi-parenting.
  //              Even still, there should still be some kind of cycle
  //              prevention/detection, ideally at the protocol level.
  //
  // if (node->parent_ != nullptr) {
  //   VALIDATION_LOG
  //       << "Cannot add a node as a child which already has a parent.";
  //   return false;
  // }
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

void Node::SetIsJoint(bool is_joint) {
  is_joint_ = is_joint;
}

bool Node::IsJoint() const {
  return is_joint_;
}

bool Node::Render(SceneEncoder& encoder,
                  Allocator& allocator,
                  const Matrix& parent_transform) {
  std::optional<std::vector<MutationLog::Entry>> log = mutation_log_.Flush();
  if (log.has_value()) {
    for (const auto& entry : log.value()) {
      if (auto e = std::get_if<MutationLog::SetTransformEntry>(&entry)) {
        local_transform_ = e->transform;
      } else if (auto e =
                     std::get_if<MutationLog::SetAnimationStateEntry>(&entry)) {
        AnimationClip* clip =
            animation_player_.has_value()
                ? animation_player_->GetClip(e->animation_name)
                : nullptr;
        if (!clip) {
          auto animation = FindAnimationByName(e->animation_name);
          if (!animation) {
            continue;
          }
          clip = AddAnimation(animation);
          if (!clip) {
            continue;
          }
        }

        clip->SetPlaying(e->playing);
        clip->SetLoop(e->loop);
        clip->SetWeight(e->weight);
        clip->SetPlaybackTimeScale(e->time_scale);
      } else if (auto e =
                     std::get_if<MutationLog::SeekAnimationEntry>(&entry)) {
        AnimationClip* clip =
            animation_player_.has_value()
                ? animation_player_->GetClip(e->animation_name)
                : nullptr;
        if (!clip) {
          auto animation = FindAnimationByName(e->animation_name);
          if (!animation) {
            continue;
          }
          clip = AddAnimation(animation);
          if (!clip) {
            continue;
          }
        }

        clip->Seek(SecondsF(e->time));
      }
    }
  }

  if (animation_player_.has_value()) {
    animation_player_->Update();
  }

  Matrix transform = parent_transform * local_transform_;
  mesh_.Render(encoder, transform,
               skin_ ? skin_->GetJointsTexture(allocator) : nullptr);

  for (auto& child : children_) {
    if (!child->Render(encoder, allocator, transform)) {
      return false;
    }
  }
  return true;
}

void Node::AddMutation(const MutationLog::Entry& entry) {
  mutation_log_.Append(entry);
}

}  // namespace scene
}  // namespace impeller
