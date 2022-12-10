// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <cmath>
#include <memory>

#include "flutter/testing/testing.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/constants.h"
#include "impeller/geometry/matrix.h"
#include "impeller/geometry/quaternion.h"
#include "impeller/geometry/vector.h"
#include "impeller/playground/playground.h"
#include "impeller/playground/playground_test.h"
#include "impeller/renderer/formats.h"
#include "impeller/scene/camera.h"
#include "impeller/scene/geometry.h"
#include "impeller/scene/importer/scene_flatbuffers.h"
#include "impeller/scene/material.h"
#include "impeller/scene/mesh.h"
#include "impeller/scene/scene.h"
#include "third_party/flatbuffers/include/flatbuffers/verifier.h"

// #include "third_party/tinygltf/tiny_gltf.h"

namespace impeller {
namespace scene {
namespace testing {

using SceneTest = PlaygroundTest;
INSTANTIATE_PLAYGROUND_SUITE(SceneTest);

TEST_P(SceneTest, CuboidUnlit) {
  Renderer::RenderCallback callback = [&](RenderTarget& render_target) {
    auto allocator = GetContext()->GetResourceAllocator();
    auto scene = Scene(GetContext());

    {
      Mesh mesh;

      auto material = Material::MakeUnlit();
      material->SetColor(Color::Red());

      Vector3 size(1, 1, 0);
      mesh.AddPrimitive({Geometry::MakeCuboid(size), std::move(material)});

      Node& root = scene.GetRoot();
      root.SetLocalTransform(Matrix::MakeTranslation(-size / 2));
      root.SetMesh(mesh);
    }

    // Face towards the +Z direction (+X right, +Y up).
    auto camera = Camera::MakePerspective(
                      /* fov */ Radians(kPiOver4),
                      /* position */ {2, 2, -5})
                      .LookAt(
                          /* target */ Vector3(),
                          /* up */ {0, 1, 0});

    scene.Render(render_target, camera);
    return true;
  };

  OpenPlaygroundHere(callback);
}

TEST_P(SceneTest, GLTFScene) {
  auto allocator = GetContext()->GetResourceAllocator();

  auto mapping =
      flutter::testing::OpenFixtureAsMapping("flutter_logo.glb.ipscene");

  flatbuffers::Verifier verifier(mapping->GetMapping(), mapping->GetSize());
  ASSERT_TRUE(fb::VerifySceneBuffer(verifier));

  // TODO(bdero): Add full scene deserialization utilities.
  const auto* fb_scene = fb::GetScene(mapping->GetMapping());
  const auto fb_nodes = fb_scene->children();
  ASSERT_EQ(fb_nodes->size(), 1u);
  const auto fb_meshes = fb_nodes->begin()->mesh_primitives();
  ASSERT_EQ(fb_meshes->size(), 1u);
  const auto* fb_mesh = fb_meshes->Get(0);
  auto geometry = Geometry::MakeFromFBMeshPrimitive(*fb_mesh, *allocator);
  ASSERT_NE(geometry, nullptr);

  std::shared_ptr<UnlitMaterial> material = Material::MakeUnlit();
  auto bridge = CreateTextureForFixture("flutter_logo_baked.png");
  material->SetColorTexture(bridge);
  material->SetVertexColorWeight(0);

  Renderer::RenderCallback callback = [&](RenderTarget& render_target) {
    auto scene = Scene(GetContext());

    Mesh mesh;
    mesh.AddPrimitive({geometry, material});

    scene.GetRoot().SetLocalTransform(Matrix::MakeScale({3, 3, 3}));
    scene.GetRoot().SetMesh(mesh);

    Quaternion rotation({0, 1, 0}, -GetSecondsElapsed() * 0.5);
    Vector3 start_position(-1, -1.5, -5);

    // Face towards the +Z direction (+X right, +Y up).
    auto camera = Camera::MakePerspective(
                      /* fov */ Degrees(60),
                      /* position */ rotation * start_position)
                      .LookAt(
                          /* target */ Vector3(),
                          /* up */ {0, 1, 0});

    scene.Render(render_target, camera);
    return true;
  };

  OpenPlaygroundHere(callback);
}

}  // namespace testing
}  // namespace scene
}  // namespace impeller
