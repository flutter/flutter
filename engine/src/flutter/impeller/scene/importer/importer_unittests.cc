// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"
#include "impeller/geometry/geometry_asserts.h"
#include "impeller/geometry/matrix.h"
#include "impeller/scene/importer/conversions.h"
#include "impeller/scene/importer/importer.h"
#include "impeller/scene/importer/scene_flatbuffers.h"

namespace impeller {
namespace scene {
namespace importer {
namespace testing {

TEST(ImporterTest, CanParseUnskinnedGLTF) {
  auto mapping =
      flutter::testing::OpenFixtureAsMapping("flutter_logo_baked.glb");

  fb::SceneT scene;
  ASSERT_TRUE(ParseGLTF(*mapping, scene));

  ASSERT_EQ(scene.children.size(), 1u);
  auto& node = scene.nodes[scene.children[0]];

  Matrix node_transform = ToMatrix(*node->transform);
  ASSERT_MATRIX_NEAR(node_transform, Matrix());

  ASSERT_EQ(node->mesh_primitives.size(), 1u);
  auto& mesh = *node->mesh_primitives[0];
  ASSERT_EQ(mesh.indices->count, 918u);

  uint16_t first_index =
      *reinterpret_cast<uint16_t*>(mesh.indices->data.data());
  ASSERT_EQ(first_index, 45u);

  ASSERT_EQ(mesh.vertices.type, fb::VertexBuffer::UnskinnedVertexBuffer);
  auto& vertices = mesh.vertices.AsUnskinnedVertexBuffer()->vertices;
  ASSERT_EQ(vertices.size(), 260u);
  auto& vertex = vertices[0];

  Vector3 position = ToVector3(vertex.position());
  ASSERT_VECTOR3_NEAR(position, Vector3(-0.0100185, -0.522907, 0.133178));

  Vector3 normal = ToVector3(vertex.normal());
  ASSERT_VECTOR3_NEAR(normal, Vector3(0.556997, -0.810833, 0.179733));

  Vector4 tangent = ToVector4(vertex.tangent());
  ASSERT_VECTOR4_NEAR(tangent, Vector4(0.155901, -0.110485, -0.981574, 1));

  Vector2 texture_coords = ToVector2(vertex.texture_coords());
  ASSERT_POINT_NEAR(texture_coords, Vector2(0.727937, 0.713817));

  Color color = ToColor(vertex.color());
  ASSERT_COLOR_NEAR(color, Color(0.0221714, 0.467781, 0.921584, 1));
}

TEST(ImporterTest, CanParseSkinnedGLTF) {
  auto mapping = flutter::testing::OpenFixtureAsMapping("two_triangles.glb");

  fb::SceneT scene;
  ASSERT_TRUE(ParseGLTF(*mapping, scene));

  ASSERT_EQ(scene.children.size(), 1u);
  auto& node = scene.nodes[scene.children[0]];

  Matrix node_transform = ToMatrix(*node->transform);
  ASSERT_MATRIX_NEAR(node_transform, Matrix());

  ASSERT_EQ(node->mesh_primitives.size(), 0u);
  ASSERT_EQ(node->children.size(), 2u);

  // The skinned node contains both a skeleton and skinned mesh primitives that
  // reference bones in the skeleton.
  auto& skinned_node = scene.nodes[node->children[0]];
  ASSERT_NE(skinned_node->skin, nullptr);

  ASSERT_EQ(skinned_node->mesh_primitives.size(), 2u);
  auto& bottom_triangle = *skinned_node->mesh_primitives[0];
  ASSERT_EQ(bottom_triangle.indices->count, 3u);

  ASSERT_EQ(bottom_triangle.vertices.type,
            fb::VertexBuffer::SkinnedVertexBuffer);
  auto& vertices = bottom_triangle.vertices.AsSkinnedVertexBuffer()->vertices;
  ASSERT_EQ(vertices.size(), 3u);
  auto& vertex = vertices[0];

  Vector3 position = ToVector3(vertex.vertex().position());
  ASSERT_VECTOR3_NEAR(position, Vector3(1, 1, 0));

  Vector3 normal = ToVector3(vertex.vertex().normal());
  ASSERT_VECTOR3_NEAR(normal, Vector3(0, 0, 1));

  Vector4 tangent = ToVector4(vertex.vertex().tangent());
  ASSERT_VECTOR4_NEAR(tangent, Vector4(1, 0, 0, -1));

  Vector2 texture_coords = ToVector2(vertex.vertex().texture_coords());
  ASSERT_POINT_NEAR(texture_coords, Vector2(0, 1));

  Color color = ToColor(vertex.vertex().color());
  ASSERT_COLOR_NEAR(color, Color(1, 1, 1, 1));

  Vector4 joints = ToVector4(vertex.joints());
  ASSERT_COLOR_NEAR(joints, Vector4(0, 0, 0, 0));

  Vector4 weights = ToVector4(vertex.weights());
  ASSERT_COLOR_NEAR(weights, Vector4(1, 0, 0, 0));

  ASSERT_EQ(scene.animations.size(), 2u);
  ASSERT_EQ(scene.animations[0]->name, "Idle");
  ASSERT_EQ(scene.animations[1]->name, "Metronome");
  ASSERT_EQ(scene.animations[1]->channels.size(), 6u);
  auto& channel = scene.animations[1]->channels[3];
  ASSERT_EQ(channel->keyframes.type, fb::Keyframes::RotationKeyframes);
  auto* keyframes = channel->keyframes.AsRotationKeyframes();
  ASSERT_EQ(keyframes->values.size(), 40u);
  ASSERT_VECTOR4_NEAR(ToVector4(keyframes->values[0]),
                      Vector4(0.653281, -0.270598, 0.270598, 0.653281));
  ASSERT_VECTOR4_NEAR(ToVector4(keyframes->values[10]),
                      Vector4(0.700151, 0.0989373, -0.0989373, 0.700151));
}

}  // namespace testing
}  // namespace importer
}  // namespace scene
}  // namespace impeller
