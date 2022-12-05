// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/scene/importer/importer.h"

#include <array>
#include <cstring>
#include <functional>
#include <iostream>
#include <memory>
#include <vector>

#include "flutter/fml/mapping.h"
#include "impeller/geometry/matrix.h"
#include "impeller/scene/importer/conversions.h"
#include "impeller/scene/importer/scene_flatbuffers.h"
#include "impeller/scene/importer/vertices_builder.h"
#include "third_party/tinygltf/tiny_gltf.h"

namespace impeller {
namespace scene {
namespace importer {

static const std::map<std::string, VerticesBuilder::Attribute> kAttributes = {
    {"POSITION", VerticesBuilder::Attribute::kPosition},
    {"NORMAL", VerticesBuilder::Attribute::kNormal},
    {"TANGENT", VerticesBuilder::Attribute::kTangent},
    {"TEXCOORD_0", VerticesBuilder::Attribute::kTextureCoords},
    {"COLOR_0", VerticesBuilder::Attribute::kColor},
};

static bool WithinRange(int index, size_t size) {
  return index >= 0 && static_cast<size_t>(index) < size;
}

static bool ProcessStaticMesh(const tinygltf::Model& gltf,
                              const tinygltf::Primitive& primitive,
                              fb::StaticMeshT& static_mesh) {
  //---------------------------------------------------------------------------
  /// Vertices.
  ///

  {
    VerticesBuilder builder;

    for (const auto& attribute : primitive.attributes) {
      auto attribute_type = kAttributes.find(attribute.first);
      if (attribute_type == kAttributes.end()) {
        std::cerr << "Vertex attribute \"" << attribute.first
                  << "\" not supported." << std::endl;
        continue;
      }

      const auto accessor = gltf.accessors[attribute.second];
      const auto view = gltf.bufferViews[accessor.bufferView];

      const auto buffer = gltf.buffers[view.buffer];
      const unsigned char* source_start = &buffer.data[view.byteOffset];

      VerticesBuilder::ComponentType type;
      switch (accessor.componentType) {
        case TINYGLTF_COMPONENT_TYPE_BYTE:
          type = VerticesBuilder::ComponentType::kSignedByte;
          break;
        case TINYGLTF_COMPONENT_TYPE_UNSIGNED_BYTE:
          type = VerticesBuilder::ComponentType::kUnsignedByte;
          break;
        case TINYGLTF_COMPONENT_TYPE_SHORT:
          type = VerticesBuilder::ComponentType::kSignedShort;
          break;
        case TINYGLTF_COMPONENT_TYPE_UNSIGNED_SHORT:
          type = VerticesBuilder::ComponentType::kUnsignedShort;
          break;
        case TINYGLTF_COMPONENT_TYPE_INT:
          type = VerticesBuilder::ComponentType::kSignedInt;
          break;
        case TINYGLTF_COMPONENT_TYPE_UNSIGNED_INT:
          type = VerticesBuilder::ComponentType::kUnsignedInt;
          break;
        case TINYGLTF_COMPONENT_TYPE_FLOAT:
          type = VerticesBuilder::ComponentType::kFloat;
          break;
        default:
          std::cerr << "Skipping attribute \"" << attribute.first
                    << "\" due to invalid component type." << std::endl;
          continue;
      }

      builder.SetAttributeFromBuffer(attribute_type->second,  // attribute
                                     type,                    // component_type
                                     source_start,            // buffer_start
                                     accessor.ByteStride(view),  // stride_bytes
                                     accessor.count);            // count
    }

    builder.WriteFBVertices(static_mesh.vertices);
  }

  //---------------------------------------------------------------------------
  /// Indices.
  ///

  if (!WithinRange(primitive.indices, gltf.accessors.size())) {
    std::cerr << "Mesh primitive has no index buffer. Skipping." << std::endl;
    return false;
  }

  auto index_accessor = gltf.accessors[primitive.indices];
  auto index_view = gltf.bufferViews[index_accessor.bufferView];
  static_mesh.indices.resize(index_accessor.count);
  const auto* index_buffer =
      &gltf.buffers[index_view.buffer].data[index_view.byteOffset];
  std::memcpy(static_mesh.indices.data(), index_buffer, index_view.byteLength);

  return true;
}

static void ProcessNode(const tinygltf::Model& gltf,
                        const tinygltf::Node& in_node,
                        fb::NodeT& out_node) {
  //---------------------------------------------------------------------------
  /// Transform.
  ///

  Matrix transform;
  if (in_node.translation.size() == 3) {
    transform = transform * Matrix::MakeTranslation(
                                {static_cast<Scalar>(in_node.translation[0]),
                                 static_cast<Scalar>(in_node.translation[0]),
                                 static_cast<Scalar>(in_node.translation[0])});
  }
  if (in_node.rotation.size() == 4) {
    transform = transform * Matrix::MakeRotation(Quaternion(
                                in_node.rotation[0], in_node.rotation[1],
                                in_node.rotation[2], in_node.rotation[3]));
  }
  if (in_node.scale.size() == 3) {
    transform =
        transform * Matrix::MakeScale({static_cast<Scalar>(in_node.scale[0]),
                                       static_cast<Scalar>(in_node.scale[1]),
                                       static_cast<Scalar>(in_node.scale[2])});
  }
  if (in_node.matrix.size() == 16) {
    if (!transform.IsIdentity()) {
      std::cerr << "The `matrix` attribute of node (name: " << in_node.name
                << ") is set in addition to one or more of the "
                   "`translation/rotation/scale` attributes. Using only the "
                   "`matrix` "
                   "attribute.";
    }
    transform = ToMatrix(in_node.matrix);
  }
  out_node.transform = ToFBMatrix(transform);

  //---------------------------------------------------------------------------
  /// Static meshes.
  ///

  if (WithinRange(in_node.mesh, gltf.meshes.size())) {
    auto& mesh = gltf.meshes[in_node.mesh];
    for (const auto& primitive : mesh.primitives) {
      auto static_mesh = std::make_unique<fb::StaticMeshT>();
      if (!ProcessStaticMesh(gltf, primitive, *static_mesh)) {
        continue;
      }
      out_node.meshes.push_back(std::move(static_mesh));
    }
  }

  //---------------------------------------------------------------------------
  /// Children.
  ///

  for (size_t node_i = 0; node_i < out_node.children.size(); node_i++) {
    auto child = std::make_unique<fb::NodeT>();
    ProcessNode(gltf, gltf.nodes[in_node.children[node_i]], *child);
    out_node.children.push_back(std::move(child));
  }
}

bool ParseGLTF(const fml::Mapping& source_mapping, fb::SceneT& out_scene) {
  tinygltf::Model gltf;

  {
    tinygltf::TinyGLTF loader;
    std::string error;
    std::string warning;
    bool success = loader.LoadBinaryFromMemory(&gltf, &error, &warning,
                                               source_mapping.GetMapping(),
                                               source_mapping.GetSize());
    if (!warning.empty()) {
      std::cerr << "Warning while loading GLTF: " << warning << std::endl;
    }
    if (!error.empty()) {
      std::cerr << "Error while loading GLTF: " << error << std::endl;
    }
    if (!success) {
      return false;
    }
  }

  const tinygltf::Scene& scene = gltf.scenes[gltf.defaultScene];
  for (size_t node_i = 0; node_i < scene.nodes.size(); node_i++) {
    auto node = std::make_unique<fb::NodeT>();
    ProcessNode(gltf, gltf.nodes[scene.nodes[node_i]], *node);
    out_scene.children.push_back(std::move(node));
  }

  return true;
}

}  // namespace importer
}  // namespace scene
}  // namespace impeller
