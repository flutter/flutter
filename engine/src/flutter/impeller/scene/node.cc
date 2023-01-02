// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/scene/node.h"

#include <inttypes.h>
#include <atomic>
#include <memory>

#include "flutter/fml/logging.h"
#include "impeller/base/strings.h"
#include "impeller/base/validation.h"
#include "impeller/geometry/matrix.h"
#include "impeller/scene/importer/conversions.h"
#include "impeller/scene/importer/scene_flatbuffers.h"
#include "impeller/scene/mesh.h"
#include "impeller/scene/node.h"
#include "impeller/scene/scene_encoder.h"

namespace impeller {
namespace scene {

static std::atomic_uint64_t kNextNodeID = 0;

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

  DecompressedImage::Format format;
  switch (embedded->component_count()) {
    case 1:
      format = DecompressedImage::Format::kGrey;
      break;
    case 3:
      format = DecompressedImage::Format::kRGB;
      break;
    case 4:
      format = DecompressedImage::Format::kRGBA;
      break;
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
  auto decompressed_image =
      DecompressedImage(ISize(embedded->width(), embedded->height()), format,
                        image_mapping)
          .ConvertToRGBA();

  auto texture_descriptor = TextureDescriptor{};
  texture_descriptor.storage_mode = StorageMode::kHostVisible;
  texture_descriptor.format = PixelFormat::kR8G8B8A8UNormInt;
  texture_descriptor.size = decompressed_image.GetSize();
  // TODO(bdero): Generate mipmaps for embedded textures.
  texture_descriptor.mip_count = 1u;

  auto texture = allocator.CreateTexture(texture_descriptor);
  if (!texture) {
    FML_LOG(ERROR) << "Could not allocate texture.";
    return nullptr;
  }

  auto uploaded = texture->SetContents(decompressed_image.GetAllocation());
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
                                              scene_nodes, textures, allocator);
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

Node::Node() : name_(SPrintF("__node%" PRIu64, kNextNodeID++)){};

Node::~Node() = default;

Mesh::Mesh(Mesh&& mesh) = default;

Mesh& Mesh::operator=(Mesh&& mesh) = default;

Node::Node(Node&& node) = default;

Node& Node::operator=(Node&& node) = default;

const std::string& Node::GetName() const {
  return name_;
}

void Node::SetName(const std::string& new_name) {
  name_ = new_name;
}

std::shared_ptr<Node> Node::FindNodeByName(const std::string& name) const {
  for (auto& child : children_) {
    if (child->GetName() == name) {
      return child;
    }
    if (auto found = child->FindNodeByName(name)) {
      return found;
    }
  }
  return nullptr;
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
