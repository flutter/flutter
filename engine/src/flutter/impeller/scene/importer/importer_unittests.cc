// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"
#include "impeller/geometry/geometry_unittests.h"
#include "impeller/geometry/matrix.h"
#include "impeller/scene/importer/conversions.h"
#include "impeller/scene/importer/importer.h"
#include "impeller/scene/importer/scene_flatbuffers.h"

namespace impeller {
namespace scene {
namespace importer {
namespace testing {

TEST(ImporterTest, CanParseGLTF) {
  auto mapping = flutter::testing::OpenFixtureAsMapping("flutter_logo.glb");

  fb::SceneT scene;
  ASSERT_TRUE(ParseGLTF(*mapping, scene));

  ASSERT_EQ(scene.children.size(), 1u);
  auto& node = *scene.children[0];

  Matrix node_transform = ToMatrix(*node.transform);
  ASSERT_MATRIX_NEAR(node_transform, Matrix());

  ASSERT_EQ(node.mesh_primitives.size(), 1u);
  auto& mesh = *node.mesh_primitives[0];
  ASSERT_EQ(mesh.indices->count, 918u);

  uint16_t first_index =
      *reinterpret_cast<uint16_t*>(mesh.indices->data.data());
  ASSERT_EQ(first_index, 45u);

  ASSERT_EQ(mesh.vertices.size(), 260u);
  auto& vertex = mesh.vertices[0];

  Vector3 position = ToVector3(vertex.position());
  ASSERT_VECTOR3_NEAR(position, Vector3(-0.0100185, -0.522907, -0.133178));

  Vector3 normal = ToVector3(vertex.normal());
  ASSERT_VECTOR3_NEAR(normal, Vector3(0.556997, -0.810833, 0.179733));

  Vector4 tangent = ToVector4(vertex.tangent());
  ASSERT_VECTOR4_NEAR(tangent, Vector4(0.155901, -0.110485, -0.981574, 1));

  Vector2 texture_coords = ToVector2(vertex.texture_coords());
  ASSERT_POINT_NEAR(texture_coords, Vector2(0.727937, 0.713817));

  Color color = ToColor(vertex.color());
  ASSERT_COLOR_NEAR(color, Color(0.0221714, 0.467781, 0.921584, 1));
}

}  // namespace testing
}  // namespace importer
}  // namespace scene
}  // namespace impeller
